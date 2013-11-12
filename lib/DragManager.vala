//
//  Copyright (C) 2011-2012 Robert Dyer, Rico Tzschichholz
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

using Gdk;
using Gee;
using Gtk;

using Plank.Drawing;
using Plank.Factories;
using Plank.Items;
using Plank.Services.Windows;
using Plank.Widgets;

namespace Plank
{
	/**
	 * Handles all of the drag'n'drop events for a dock.
	 */
	public class DragManager : GLib.Object
	{
		public DockController controller { private get; construct; }
		
		Gdk.Window proxy_window;
		
		bool drag_canceled;
		bool drag_known;
		bool drag_data_requested;
		uint marker = 0;
		uint drag_hover_timer = 0;
		
		ArrayList<string>? drag_data;
		
		public bool InternalDragActive { get; private set; }

		public bool HoveredAcceptsDrop { get; private set; }
		
		public DockItem? DragItem { get; private set; }
		
		public bool DragIsDesktopFile { get; private set; }
		
		bool externalDragActive;
		public bool ExternalDragActive {
			get { return externalDragActive; }
			private set {
				if (externalDragActive == value)
					return;
				externalDragActive = value;
				
				if (!value) {
					drag_known = false;
					drag_data = null;
					drag_data_requested = false;
					DragIsDesktopFile = false;
				}
			}
		}
		
		bool repositionMode = false;
		public bool RepositionMode {
			get { return repositionMode; }
			private set {
				if (repositionMode == value)
					return;
				repositionMode = value;
				
				if (repositionMode)
					disable_drag_to (controller.window);
				else
					enable_drag_to (controller.window);
			}
		}
		
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
			
			window.motion_notify_event.connect (window_motion_notify_event);

			prefs.notify["LockItems"].connect (lock_items_changed);
			
			if (!prefs.LockItems) {
				enable_drag_to (window);
				enable_drag_from (window);
			}
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
			
			window.motion_notify_event.disconnect (window_motion_notify_event);
			
			controller.prefs.notify["LockItems"].disconnect (lock_items_changed);
			
			disable_drag_to (window);
			disable_drag_from (window);
		}
		
		bool window_motion_notify_event (Widget w, EventMotion event)
		{
			ExternalDragActive = false;
			return false;
		}
		
		void lock_items_changed ()
		{
			unowned DockWindow window = controller.window;
			
			if (controller.prefs.LockItems) {
				disable_drag_from (window);
				disable_drag_to (window);
			} else {
				enable_drag_from (window);
				enable_drag_to (window);
			}
		}
		
		void drag_data_get (Widget w, DragContext context, SelectionData selection_data, uint info, uint time_)
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
		
		void drag_begin (Widget w, DragContext context)
		{
			unowned DockWindow window = controller.window;
			
			window.notify["HoveredItem"].connect (hovered_item_changed);
			
			// Delay persistent write of dock-preference until drag_end ()
			controller.prefs.delay ();
			
			InternalDragActive = true;
			context.get_device ().grab (window.get_window (), GrabOwnership.APPLICATION, true, EventMask.ALL_EVENTS_MASK, null, get_current_event_time ());
			drag_canceled = false;
			
			if (proxy_window != null) {
				enable_drag_to (window);
				proxy_window = null;
			}
			
			Pixbuf pbuf;
			DragItem = window.HoveredItem;
			
			if (RepositionMode)
				DragItem = null;
			
			if (DragItem != null) {
				unowned ApplicationDockItemProvider app_provider = (DragItem.Provider as ApplicationDockItemProvider);
				if (app_provider != null)
					app_provider.save_item_positions ();
				
				// FIXME
				var drag_icon_size = (int) (1.2 * controller.position_manager.IconSize);
				var icon_surface = new DockSurface (drag_icon_size, drag_icon_size);
				pbuf = DragItem.get_surface_copy (drag_icon_size, drag_icon_size, icon_surface).to_pixbuf ();
				controller.renderer.animated_draw ();
			} else {
				pbuf = new Pixbuf (Colorspace.RGB, true, 8, 1, 1);
			}
			
			drag_set_icon_pixbuf (context, pbuf, pbuf.width / 2, pbuf.height / 2);
		}

		void drag_data_received (Widget w, DragContext context, int x, int y, SelectionData selection_data, uint info, uint time_)
		{
			if (drag_data_requested) {
				string uris = (string) selection_data.get_data ();
				
				drag_data = new ArrayList<string> ();
				foreach (string s in uris.split ("\r\n"))
					if (s.has_prefix ("file://"))
						drag_data.add (s);
				
				drag_data_requested = false;
				
				if (drag_data.size == 1)
					DragIsDesktopFile = drag_data[0].has_suffix (".desktop");
				else
					DragIsDesktopFile = false;
				
				// Force initial redraw for ExternalDrag to pick up new
				// drag_data for can_accept_drop check
				controller.renderer.animated_draw ();
			}
			
			drag_status (context, DragAction.COPY, time_);
		}

		bool drag_drop (Widget w, DragContext context, int x, int y, uint time_)
		{
			drag_finish (context, true, false, time_);
			
			if (drag_hover_timer > 0) {
				GLib.Source.remove (drag_hover_timer);
				drag_hover_timer = 0;
			}
			
			if (drag_data == null)
				return true;
			
			unowned DockItem item = controller.window.HoveredItem;
			unowned DockItemProvider items = item.Provider;
			
			if (DragIsDesktopFile) {
				var uri = drag_data[0];
				if (!items.item_exists_for_uri (uri))
					items.add_item_with_uri (uri, item);
				
				ExternalDragActive = false;
				return true;
			}
			
			if (item != null && item.can_accept_drop (drag_data)) {
				item.accept_drop (drag_data);
			} else {
				foreach (var uri in drag_data) {
					if (!items.item_exists_for_uri (uri))
						items.add_item_with_uri (uri, item);
				}
			}
			
			ExternalDragActive = false;
			return true;
		}
		
		void drag_end (Widget w, DragContext context)
		{
			if (!drag_canceled && DragItem != null) {
				unowned HideManager hide_manager = controller.hide_manager;
				hide_manager.update_dock_hovered ();
				if (!hide_manager.DockHovered) {
					if (DragItem.can_be_removed ()) {
						// Remove from dock
						unowned ApplicationDockItem? app_item = (DragItem as ApplicationDockItem);
						if (app_item == null || !(app_item.is_running ()))
							DragItem.Provider.remove_item (DragItem);
						DragItem.delete ();
						
						int x, y;
						context.get_device ().get_position (null, out x, out y);
						PoofWindow.get_default ().show_at (x, y);
					}
				} else if (controller.window.HoveredItem == null) {
					// Dropped somewhere on dock
					// Pin this item if possible/needed, so we assume the user cares
					// about this application when changing its position
					if (DragItem is TransientDockItem) {
						unowned DefaultApplicationDockItemProvider? provider = (DragItem.Provider as DefaultApplicationDockItemProvider);
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
			context.get_device ().ungrab (get_current_event_time ());
			
			controller.window.notify["HoveredItem"].disconnect (hovered_item_changed);

			// Perform persistent write of dock-preference
			controller.prefs.apply ();
			
			// Force last redraw for InternalDrag
			controller.renderer.animated_draw ();
		}

		void drag_leave (Widget w, DragContext context, uint time_)
		{
			if (drag_hover_timer > 0) {
				GLib.Source.remove (drag_hover_timer);
				drag_hover_timer = 0;
			}
			
			controller.hide_manager.update_dock_hovered ();
			drag_known = false;
			
			if (ExternalDragActive) {
				controller.window.notify["HoveredItem"].disconnect (hovered_item_changed);
				
				// Make sure ExternalDragActive gets set to false to reactivate HideManager.
				// This is needed while getting a leave event without followed by a drop.
				// Delay it to preserve functionality in drag_drop.
				Gdk.threads_add_idle (() => {
					ExternalDragActive = false;
					
					// If an item was hovered we need it in drag_drop,
					// so reset HoveredItem here not earlier.
					controller.window.update_hovered (-1, -1);
					
					// Force last redraw for ExternalDrag
					controller.renderer.animated_draw ();
					
					return false;
				});
			}
			
			if (DragItem == null)
				return;
			
			if (!controller.hide_manager.DockHovered) {
				unowned ApplicationDockItemProvider app_provider = (DragItem.Provider as ApplicationDockItemProvider);
				if (app_provider != null)
					app_provider.restore_item_positions ();
			}
		}
		
		bool drag_failed (Widget w, DragContext context, DragResult result)
		{
			drag_canceled = result == DragResult.USER_CANCELLED;
			
			if (drag_canceled) {
				unowned ApplicationDockItemProvider app_provider = (DragItem.Provider as ApplicationDockItemProvider);
				if (app_provider != null)
					app_provider.restore_item_positions ();
			}
			
			return !drag_canceled;
		}

		bool drag_motion (Widget w, DragContext context, int x, int y, uint time_)
		{
			if (RepositionMode)
				return true;

			ExternalDragActive = !InternalDragActive;
			
			if (marker != direct_hash (context)) {
				marker = direct_hash (context);
				drag_known = false;
			}
			
			unowned DockWindow window = controller.window;
			
			// we own the drag if InternalDragActive is true, lets not be silly
			if (ExternalDragActive && !drag_known) {
				drag_known = true;
				
				window.notify["HoveredItem"].connect (hovered_item_changed);
				
				Atom atom = drag_dest_find_target (window, context, drag_dest_get_target_list (window));
				if (atom.name () != Atom.NONE.name ()) {
					drag_data_requested = true;
					drag_get_data (window, context, atom, time_);
				} else {
					drag_status (context, DragAction.PRIVATE, time_);
				}
			} else {
				drag_status (context, DragAction.COPY, time_);
			}
			
			window.update_hovered (x, y);
			
			return true;
		}
		
		void hovered_item_changed ()
		{
			unowned DockItem hovered_item = controller.window.HoveredItem;
			
			if (InternalDragActive && DragItem != null && hovered_item != null
				&& DragItem != hovered_item) {
				DragItem.Provider.move_item_to (DragItem, hovered_item);
			}
			
			if (drag_hover_timer > 0) {
				GLib.Source.remove (drag_hover_timer);
				drag_hover_timer = 0;
			}
			
			if (ExternalDragActive && drag_data != null)
				drag_hover_timer = Gdk.threads_add_timeout (1500, () => {
					unowned DockItem item = controller.window.HoveredItem;
					if (item != null)
						item.scrolled (ScrollDirection.DOWN, 0);
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
			
			if (controller.hide_manager.DockHovered) {
				if (proxy_window == null)
					return;
				proxy_window = null;
				enable_drag_to (controller.window);
				return;
			}
			
			ModifierType mod;
			double[] axes = {};
			controller.window.get_display ().get_device_manager ().get_client_pointer ().get_state (controller.window.get_window (), axes, out mod);
			
			if ((mod & ModifierType.BUTTON1_MASK) == ModifierType.BUTTON1_MASK) {
				Gdk.Window bestProxy = best_proxy_window ();
				if (bestProxy != null && proxy_window != bestProxy) {
					proxy_window = bestProxy;
					drag_dest_set_proxy (controller.window, proxy_window, DragProtocol.XDND, true);
				}
			}
		}

		void enable_drag_to (DockWindow window)
		{
			TargetEntry te1 = { "text/uri-list", 0, 0 };
			TargetEntry te2 = { "text/plank-uri-list", 0, 0 };
			drag_dest_set (window, 0, {te1, te2}, DragAction.COPY);
		}
		
		void disable_drag_to (DockWindow window)
		{
			drag_dest_unset (window);
		}
		
		void enable_drag_from (DockWindow window)
		{
			// we dont really want to offer the drag to anything, merely pretend to, so we set a mimetype nothing takes
			TargetEntry te = { "text/plank-uri-list", TargetFlags.SAME_APP, 0};
			drag_source_set (window, ModifierType.BUTTON1_MASK, { te }, DragAction.PRIVATE);
		}
		
		void disable_drag_from (DockWindow window)
		{
			drag_source_unset (window);
		}
	}
}
