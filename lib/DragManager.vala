//
//  Copyright (C) 2011-2012 Robert Dyer, Rico Tzschichholz
//
//  This file is part of Plank.
//
//  Plank is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Plank is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

namespace Plank
{
	/**
	 * Handles all of the drag'n'drop events for a dock.
	 */
	public class DragManager : GLib.Object
	{
		public DockController controller { private get; construct; }
		
		public bool InternalDragActive { get; private set; default = false; }

		public DockItem? DragItem { get; private set; default = null; }
		
		public bool DragNeedsCheck { get; private set; default = true; }
		
		bool external_drag_active = false;
		public bool ExternalDragActive {
			get { return external_drag_active; }
			private set {
				if (external_drag_active == value)
					return;
				external_drag_active = value;
				
				if (!value) {
					drag_known = false;
					drag_data = null;
					drag_data_requested = false;
					DragNeedsCheck = true;
				}
			}
		}
		
		bool reposition_mode = false;
		public bool RepositionMode {
			get { return reposition_mode; }
			private set {
				if (reposition_mode == value)
					return;
				reposition_mode = value;
				
				if (reposition_mode)
					disable_drag_to (controller.window);
				else
					enable_drag_to (controller.window);
			}
		}
		
		Gdk.Window? proxy_window = null;
		
		bool drag_canceled = false;
		bool drag_known = false;
		bool drag_data_requested = false;
		uint marker = 0U;
		uint drag_hover_timer_id = 0U;
		
		Gee.ArrayList<string>? drag_data = null;
		
		int window_scale_factor = 1;
		ulong drag_item_redraw_handler_id = 0UL;
		
		/**
		 * Creates a new instance of a DragManager, which handles
		 * drag'n'drop interactions of a dock.
		 *
		 * @param controller the {@link DockController} to manage drag'n'drop for
		 */
		public DragManager (DockController controller)
		{
			GLib.Object (controller : controller);
		}
		
		/**
		 * Initializes the drag-manager.  Call after the DockWindow is constructed.
		 */
		public void initialize ()
			requires (controller.window != null)
		{
			unowned DockWindow window = controller.window;
			unowned DockPreferences prefs = controller.prefs;
			
			window.drag_motion.connect (drag_motion);
			window.drag_begin.connect (drag_begin);
			window.drag_data_received.connect (drag_data_received);
			window.drag_data_get.connect (drag_data_get);
			window.drag_drop.connect (drag_drop);
			window.drag_end.connect (drag_end);
			window.drag_leave.connect (drag_leave);
			window.drag_failed.connect (drag_failed);
			
			prefs.notify["LockItems"].connect (lock_items_changed);
			
			enable_drag_to (window);
			if (!prefs.LockItems)
				enable_drag_from (window);
		}
		
		~DragManager ()
		{
			unowned DockWindow window = controller.window;
			
			window.drag_motion.disconnect (drag_motion);
			window.drag_begin.disconnect (drag_begin);
			window.drag_data_received.disconnect (drag_data_received);
			window.drag_data_get.disconnect (drag_data_get);
			window.drag_drop.disconnect (drag_drop);
			window.drag_end.disconnect (drag_end);
			window.drag_leave.disconnect (drag_leave);
			window.drag_failed.disconnect (drag_failed);
			
			controller.prefs.notify["LockItems"].disconnect (lock_items_changed);
			
			disable_drag_to (window);
			disable_drag_from (window);
		}
		
		void lock_items_changed ()
		{
			unowned DockWindow window = controller.window;
			
			if (controller.prefs.LockItems)
				disable_drag_from (window);
			else
				enable_drag_from (window);
		}
		
		[CCode (instance_pos = -1)]
		void drag_data_get (Gtk.Widget w, Gdk.DragContext context, Gtk.SelectionData selection_data, uint info, uint time_)
		{
			if (InternalDragActive && DragItem != null) {
				string uri = "%s\r\n".printf (DragItem.as_uri ());
				selection_data.set (selection_data.get_target (), 8, (uchar[]) uri.to_utf8 ());
			}
		}
		
		/**
		 * Whether the current dragged-data is accepted by the given dock-item
		 *
		 * @param item the dock-item
		 */
		public bool drop_is_accepted_by (DockItem item)
		{
			if (drag_data == null)
				return false;
			
			return item.can_accept_drop (drag_data);
		}
		
		void set_drag_icon (Gdk.DragContext context, DockItem? item, double opacity = 1.0)
		{
			if (item == null) {
				Gtk.drag_set_icon_default (context);
				return;
			}

			window_scale_factor = controller.window.get_window ().get_scale_factor ();
			var drag_icon_size = (int) (1.2 * controller.position_manager.ZoomIconSize);
			if (drag_icon_size % 2 == 1)
				drag_icon_size++;
			drag_icon_size *= window_scale_factor;
			var drag_surface = new Surface (drag_icon_size, drag_icon_size);
			drag_surface.Internal.set_device_scale (window_scale_factor, window_scale_factor);
			
			var item_surface = item.get_surface_copy (drag_icon_size, drag_icon_size, drag_surface);
			unowned Cairo.Context cr = drag_surface.Context;
			if (window_scale_factor > 1) {
				cr.save ();
				cr.scale (1.0 / window_scale_factor, 1.0 / window_scale_factor);
			}
			cr.set_operator (Cairo.Operator.OVER);
			cr.set_source_surface (item_surface.Internal, 0, 0);
			cr.paint_with_alpha (opacity);
			if (window_scale_factor > 1)
				cr.restore ();
			
			unowned Cairo.Surface surface = drag_surface.Internal;
			surface.set_device_offset (-drag_icon_size / 2.0, -drag_icon_size / 2.0);
			Gtk.drag_set_icon_surface (context, surface);
		}
		
		[CCode (instance_pos = -1)]
		void drag_begin (Gtk.Widget w, Gdk.DragContext context)
		{
			unowned DockWindow window = controller.window;
			
			window.notify["HoveredItem"].connect (hovered_item_changed);
			
			InternalDragActive = true;
			drag_canceled = false;
			
			if (proxy_window != null) {
				enable_drag_to (window);
				proxy_window = null;
			}
			
			DragItem = window.HoveredItem;
			
			if (RepositionMode)
				DragItem = null;
			
			if (DragItem == null) {
				Gdk.drag_abort (context, Gtk.get_current_event_time ());
				return;
			}
			
			set_drag_icon (context, DragItem, 0.8);
			drag_item_redraw_handler_id = DragItem.needs_redraw.connect (() => {
				set_drag_icon (context, DragItem, 0.8);
			});
			
			context.get_device ().grab (window.get_window (), Gdk.GrabOwnership.APPLICATION, true,
				Gdk.EventMask.ALL_EVENTS_MASK, null, Gtk.get_current_event_time ());
		}

		[CCode (instance_pos = -1)]
		void drag_data_received (Gtk.Widget w, Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint info, uint time_)
		{
			if (drag_data_requested) {
				unowned string? data = (string?) selection_data.get_data ();
				if (data == null) {
					drag_data_requested = false;
					Gdk.drag_status (context, Gdk.DragAction.COPY, time_);
					return;
				}
				
				var uris = Uri.list_extract_uris (data);
				
				drag_data = new Gee.ArrayList<string> ();
				foreach (unowned string s in uris) {
					if (s.has_prefix (DOCKLET_URI_PREFIX)) {
						drag_data.add (s);
						continue;
					}
					
					var uri = File.new_for_uri (s).get_uri ();
					if (uri != null)
						drag_data.add (uri);
				}
				
				drag_data_requested = false;
				
				if (drag_data.size == 1) {
					var uri = drag_data[0];
					DragNeedsCheck = !(uri.has_prefix (DOCKLET_URI_PREFIX) || uri.has_suffix (".desktop"));
				} else {
					DragNeedsCheck = true;
				}
				
				// Force initial redraw for ExternalDrag to pick up new
				// drag_data for can_accept_drop check
				controller.renderer.animated_draw ();
				
				// Trigger this manually since we will miss to receive the very first emmit
				// after entering the dock-window
				hovered_item_changed ();
			}
			
			Gdk.drag_status (context, Gdk.DragAction.COPY, time_);
		}

		[CCode (instance_pos = -1)]
		bool drag_drop (Gtk.Widget w, Gdk.DragContext context, int x, int y, uint time_)
		{
			Gtk.drag_finish (context, true, false, time_);
			
			if (drag_hover_timer_id > 0U) {
				GLib.Source.remove (drag_hover_timer_id);
				drag_hover_timer_id = 0U;
			}
			
			if (drag_data == null)
				return true;
			
			unowned DockWindow window = controller.window;
			unowned DockItem? item = window.HoveredItem;
			unowned DockItemProvider? provider = window.HoveredItemProvider;
			
			if (DragNeedsCheck && item != null && item.can_accept_drop (drag_data))
				item.accept_drop (drag_data);
			else if (!controller.prefs.LockItems && provider != null && provider.can_accept_drop (drag_data))
				provider.accept_drop (drag_data);
			
			ExternalDragActive = false;
			return true;
		}
		
		[CCode (instance_pos = -1)]
		void drag_end (Gtk.Widget w, Gdk.DragContext context)
		{
			unowned HideManager hide_manager = controller.hide_manager;
			
			if (drag_item_redraw_handler_id > 0UL) {
				if (DragItem != null)
					GLib.SignalHandler.disconnect (DragItem, drag_item_redraw_handler_id);
				drag_item_redraw_handler_id = 0UL;
			}
			
			if (!drag_canceled && DragItem != null) {
				hide_manager.update_hovered ();
				if (!hide_manager.Hovered) {
					if (DragItem.can_be_removed ()) {
						// Remove from dock
						unowned ApplicationDockItem? app_item = (DragItem as ApplicationDockItem);
						if (app_item == null || !(app_item.is_running () || app_item.has_unity_info ())) {
							DragItem.IsVisible = false;
							DragItem.Container.remove (DragItem);
						}
						DragItem.delete ();
						
						int x, y;
						context.get_device ().get_position (null, out x, out y);
						PoofWindow.get_default ().show_at (x, y);
					}
				} else if (controller.window.HoveredItem == null) {
					// Dropped somewhere on dock
					// Pin this item if possible/needed, so we assume the user cares
					// about this application when changing its position
					if (controller.prefs.AutoPinning && DragItem is TransientDockItem) {
						unowned DefaultApplicationDockItemProvider? provider = (DragItem.Container as DefaultApplicationDockItemProvider);
						if (provider != null)
							provider.pin_item (DragItem);
					}
				} else {
					// Dropped onto another dockitem
					/* TODO
					DockItem item = controller.window.HoveredItem;
					if (item != null && item.CanAcceptDrop (DragItem))
						item.AcceptDrop (DragItem);
					*/
				}
			}
			
			InternalDragActive = false;
			DragItem = null;
			context.get_device ().ungrab (Gtk.get_current_event_time ());
			
			controller.window.notify["HoveredItem"].disconnect (hovered_item_changed);

			controller.hover.hide ();
			
			// Force last redraw for InternalDrag
			controller.renderer.animated_draw ();
			
			// Make sure to hide the dock again if needed
			hide_manager.update_hovered ();
		}

		[CCode (instance_pos = -1)]
		void drag_leave (Gtk.Widget w, Gdk.DragContext context, uint time_)
		{
			if (drag_hover_timer_id > 0U) {
				GLib.Source.remove (drag_hover_timer_id);
				drag_hover_timer_id = 0U;
			}
			
			controller.hide_manager.update_hovered ();
			drag_known = false;
			
			if (ExternalDragActive) {
				controller.window.notify["HoveredItem"].disconnect (hovered_item_changed);
				
				// Make sure ExternalDragActive gets set to false to reactivate HideManager.
				// This is needed while getting a leave event without followed by a drop.
				// Delay it to preserve functionality in drag_drop.
				Gdk.threads_add_idle (() => {
					ExternalDragActive = false;
					
					controller.hover.hide ();
					
					// If an item was hovered we need it in drag_drop,
					// so reset HoveredItem here not earlier.
					controller.window.update_hovered (-1, -1);
					
					// Force last redraw for ExternalDrag
					controller.renderer.animated_draw ();
					
					// Make sure to hide the dock again if needed
					controller.hide_manager.update_hovered ();
					
					return false;
				});
			}
			
			if (DragItem == null)
				return;
			
			if (!controller.hide_manager.Hovered) {
				controller.window.update_hovered (-1, -1);
				controller.renderer.animated_draw ();
			}
		}
		
		[CCode (instance_pos = -1)]
		bool drag_failed (Gtk.Widget w, Gdk.DragContext context, Gtk.DragResult result)
		{
			drag_canceled = result == Gtk.DragResult.USER_CANCELLED;
			
			return !drag_canceled;
		}

		[CCode (instance_pos = -1)]
		bool drag_motion (Gtk.Widget w, Gdk.DragContext context, int x, int y, uint time_)
		{
			if (RepositionMode)
				return true;

			if (ExternalDragActive == InternalDragActive)
				ExternalDragActive = !InternalDragActive;
			
			if (marker != direct_hash (context)) {
				marker = direct_hash (context);
				drag_known = false;
			}
			
			unowned DockWindow window = controller.window;
			unowned HideManager hide_manager = controller.hide_manager;
			
			// we own the drag if InternalDragActive is true, lets not be silly
			if (ExternalDragActive && !drag_known) {
				drag_known = true;
				
				window.notify["HoveredItem"].connect (hovered_item_changed);
				
				Gdk.Atom atom = Gtk.drag_dest_find_target (window, context, Gtk.drag_dest_get_target_list (window));
				if (atom.name () != Gdk.Atom.NONE.name ()) {
					drag_data_requested = true;
					Gtk.drag_get_data (window, context, atom, time_);
				} else {
					Gdk.drag_status (context, Gdk.DragAction.PRIVATE, time_);
				}
			} else {
				Gdk.drag_status (context, Gdk.DragAction.COPY, time_);
			}
			
			if (ExternalDragActive) {
				unowned PositionManager position_manager = controller.position_manager;
				unowned DockItem hovered_item = window.HoveredItem;
				unowned HoverWindow hover = controller.hover;
				if (DragNeedsCheck && hovered_item != null && hovered_item.can_accept_drop (drag_data)) {
					int hx, hy;
					position_manager.get_hover_position (hovered_item, out hx, out hy);
					hover.set_text (hovered_item.get_drop_text ());
					hover.show_at (hx, hy, position_manager.Position);
				} else if (hide_manager.Hovered && !controller.prefs.LockItems) {
					int hx = x, hy = y;
					position_manager.get_hover_position_at (ref hx, ref hy);
					hover.set_text (_("Drop to add to dock"));
					hover.show_at (hx, hy, position_manager.Position);
				} else {
					hover.hide ();
				}
			}
			
			controller.renderer.update_local_cursor (x, y);
			hide_manager.update_hovered_with_coords (x, y);
			window.update_hovered (x, y);
			
			return true;
		}
		
		void hovered_item_changed ()
		{
			unowned DockItem hovered_item = controller.window.HoveredItem;
			
			if (InternalDragActive && DragItem != null && hovered_item != null
				&& DragItem != hovered_item
				&& DragItem.Container == hovered_item.Container) {
				DragItem.Container.move_to (DragItem, hovered_item);
			}
			
			if (drag_hover_timer_id > 0U) {
				GLib.Source.remove (drag_hover_timer_id);
				drag_hover_timer_id = 0U;
			}
			
			if (ExternalDragActive && drag_data != null)
				drag_hover_timer_id = Gdk.threads_add_timeout (1500, () => {
					unowned DockItem item = controller.window.HoveredItem;
					if (item != null)
						item.scrolled (Gdk.ScrollDirection.DOWN, 0, Gtk.get_current_event_time ());
					else
						drag_hover_timer_id = 0U;
					return item != null;
				});
		}
		
		Gdk.Window? best_proxy_window ()
		{
			var window_stack = controller.window.get_screen ().get_window_stack ();
			window_stack.reverse ();
			
			foreach (var window in window_stack) {
				int w_x, w_y, w_width, w_height;
				window.get_position (out w_x, out w_y);
				w_width = window.get_width ();
				w_height = window.get_height ();
				Gdk.Rectangle w_geo = { w_x, w_y, w_width, w_height };
				
				int x, y;
				controller.window.get_display ().get_device_manager ().get_client_pointer ().get_position (null, out x, out y);
				
				if (window.is_visible () && w_geo.intersect ({ x, y, 0, 0 }, null))
					return window;
			}
			
			return null;
		}
		
		public void ensure_proxy ()
		{
			// having a proxy window here is VERY bad ju-ju
			if (InternalDragActive)
				return;
			
			if (controller.hide_manager.Hovered) {
				if (proxy_window == null)
					return;
				proxy_window = null;
				enable_drag_to (controller.window);
				return;
			}
			
			Gdk.ModifierType mod;
			double[] axes = {};
			controller.window.get_display ().get_device_manager ().get_client_pointer ().get_state (controller.window.get_window (), axes, out mod);
			
			if ((mod & Gdk.ModifierType.BUTTON1_MASK) == Gdk.ModifierType.BUTTON1_MASK) {
				Gdk.Window bestProxy = best_proxy_window ();
				if (bestProxy != null && proxy_window != bestProxy) {
					proxy_window = bestProxy;
					Gtk.drag_dest_set_proxy (controller.window, proxy_window, Gdk.DragProtocol.XDND, true);
				}
			}
		}

		void enable_drag_to (DockWindow window)
		{
			Gtk.TargetEntry te1 = { "text/uri-list", 0, 0 };
			Gtk.TargetEntry te2 = { "text/plank-uri-list", 0, 0 };
			Gtk.drag_dest_set (window, 0, {te1, te2}, Gdk.DragAction.COPY);
		}
		
		void disable_drag_to (DockWindow window)
		{
			Gtk.drag_dest_unset (window);
		}
		
		void enable_drag_from (DockWindow window)
		{
			// we dont really want to offer the drag to anything, merely pretend to, so we set a mimetype nothing takes
			Gtk.TargetEntry te = { "text/plank-uri-list", Gtk.TargetFlags.SAME_APP, 0};
			Gtk.drag_source_set (window, Gdk.ModifierType.BUTTON1_MASK, { te }, Gdk.DragAction.PRIVATE);
		}
		
		void disable_drag_from (DockWindow window)
		{
			Gtk.drag_source_unset (window);
		}
	}
}
