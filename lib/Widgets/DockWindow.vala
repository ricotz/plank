//
//  Copyright (C) 2011-2012 Robert Dyer, Michal Hruby, Rico Tzschichholz
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

using Plank.Items;
using Plank.Services;
using Plank.Services.Windows;

namespace Plank.Widgets
{
	/**
	 * The main window for all docks.
	 */
	public class DockWindow : CompositedWindow
	{
		const uint LONG_PRESS_TIME = 750;
		const uint HOVER_DELAY_TIME = 200;
		
		/**
		 * The controller for this dock.
		 */
		public DockController controller { private get; construct; }
		
		
		/**
		 * The currently hovered item (if any).
		 */
		public DockItem? HoveredItem { get; protected set; }
		
		/**
		 * The currently hovered item-provider (if any).
		 */
		public DockItemProvider? HoveredItemProvider { get; protected set; }
		
		
		/**
		 * The item which "received" the button-pressed signal (if any).
		 */
		unowned DockItem? ClickedItem { get; protected set; }
		
		/**
		 * The popup menu for this dock.
		 */
		protected Gtk.Menu? menu;
		
		/**
		 * The tooltip window for this dock.
		 */
		protected HoverWindow hover;
		
		uint reposition_timer = 0;
		uint hover_reposition_timer = 0;
		
		uint long_press_timer = 0;
		bool long_press_active = false;
		uint long_press_button = 0;

		bool dock_is_starting = true;
		
		Gdk.Rectangle input_rect;
		
		/**
		 * Creates a new dock window.
		 */
		public DockWindow (DockController controller)
		{
			GLib.Object (controller: controller, type: Gtk.WindowType.TOPLEVEL, type_hint: Gdk.WindowTypeHint.DOCK);
		}
		
		construct
		{
			accept_focus = false;
			can_focus = false;
			skip_pager_hint = true;
			skip_taskbar_hint = true;
			
			stick ();
			
			add_events (Gdk.EventMask.BUTTON_PRESS_MASK |
						Gdk.EventMask.BUTTON_RELEASE_MASK |
						Gdk.EventMask.ENTER_NOTIFY_MASK |
						Gdk.EventMask.LEAVE_NOTIFY_MASK |
						Gdk.EventMask.POINTER_MOTION_MASK |
						Gdk.EventMask.SCROLL_MASK);
			
			hover = new HoverWindow ();
			
			controller.prefs.notify["HideMode"].connect (set_struts);
		}
		
		~DockWindow ()
		{
			if (menu != null) {
				menu.show.disconnect (on_menu_show);
				menu.hide.disconnect (on_menu_hide);
			}
			
			controller.prefs.notify["HideMode"].disconnect (set_struts);
			
			if (hover_reposition_timer > 0) {
				GLib.Source.remove (hover_reposition_timer);
				hover_reposition_timer = 0;
			}
			if (reposition_timer != 0) {
				GLib.Source.remove (reposition_timer);
				reposition_timer = 0;
			}
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool button_press_event (Gdk.EventButton event)
		{
			// Needed for gtk+ 3.14+
			if (menu_is_visible ())
				return true;
			
			// If the dock is hidden we should ignore it.
			if (controller.hide_manager.Hidden)
				return true;
			
			// This event gets fired before the drag end event,
			// in this case we ignore it.
			if (controller.drag_manager.InternalDragActive)
				return true;
			
			// If the cursor got hidden due inactivity or the HoveredItem got
			// set null for other reasons we need to make sure this click gets
			// delegated correctly
			if (HoveredItem == null)
				update_hovered ((int) event.x, (int) event.y);
			
			ClickedItem = HoveredItem;
			
			var button = PopupButton.from_event_button (event);
			if ((button & PopupButton.RIGHT) == PopupButton.RIGHT
				&& (HoveredItem == null || (event.state & Gdk.ModifierType.CONTROL_MASK) == Gdk.ModifierType.CONTROL_MASK))
				show_menu (event.button, true);
			else if (HoveredItem != null && (HoveredItem.Button & button) == button)
				show_menu (event.button, false);
			else {
				long_press_active = false;
				long_press_button = event.button;
				if (long_press_timer > 0)
					Source.remove (long_press_timer);
				long_press_timer = Gdk.threads_add_timeout (LONG_PRESS_TIME, () => {
					long_press_active = true;
					long_press_timer = 0;
					return false;
				});
			}
			
			return true;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool button_release_event (Gdk.EventButton event)
		{
			// If the dock is hidden we should ignore it.
			if (controller.hide_manager.Hidden)
				return true;
			
			if (long_press_timer > 0) {
				Source.remove (long_press_timer);
				long_press_timer = 0;
			}
			
			if (long_press_active && long_press_button == event.button) {
				long_press_active = false;
				long_press_button = 0;
				return true;
			}
			
			if (controller.drag_manager.InternalDragActive)
				return true;

			// Needed for gtk+ 3.14+
			if (ClickedItem == null && menu_is_visible ())
				menu.hide ();
			
			// Make sure the HoveredItem is still the same since button-pressed
			if (ClickedItem != null && HoveredItem == ClickedItem && !menu_is_visible ())
				HoveredItem.clicked (PopupButton.from_event_button (event), event.state);
			
			ClickedItem = null;
			
			return true;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool enter_notify_event (Gdk.EventCrossing event)
		{
			update_hovered ((int) event.x, (int) event.y);
			
			return true;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool leave_notify_event (Gdk.EventCrossing event)
		{
			// ignore this event if it was sent explicitly
			if ((bool) event.send_event)
				return false;
			
			if (!menu_is_visible ()) {
				set_hovered_provider (null);
				set_hovered (null);
			} else
				hover.hide ();
			
			return true;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool motion_notify_event (Gdk.EventMotion event)
		{
			// Needed for gtk+ 3.14+
			if (menu_is_visible ())
				return true;
			
			update_hovered ((int) event.x, (int) event.y);
			return true;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override void drag_begin (Gdk.DragContext context)
		{
			long_press_active = false;
			if (long_press_timer > 0) {
				Source.remove (long_press_timer);
				long_press_timer = 0;
			}
		}

		/**
		 * {@inheritDoc}
		 */
		public override bool scroll_event (Gdk.EventScroll event)
		{
			// If the dock is hidden we should ignore it.
			if (controller.hide_manager.Hidden)
				return true;
			
			if (controller.drag_manager.InternalDragActive)
				return true;
			
			// Ignore events for ScrollDirection.SMOOTH (since Gtk+ 3.4)
			if (event.direction >= 4)
				return true;
			
			if ((event.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
				if (event.direction == Gdk.ScrollDirection.UP)
					controller.prefs.increase_icon_size ();
				else if (event.direction == Gdk.ScrollDirection.DOWN)
					controller.prefs.decrease_icon_size ();
				
				return true;
			}
			
			if (HoveredItem != null) {
				HoveredItem.scrolled (event.direction, event.state);
				controller.renderer.animated_draw ();
			}
			
			return true;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool draw (Cairo.Context cr)
		{
			if (dock_is_starting) {
				debug ("dock window loaded");
				dock_is_starting = false;
				
				// slide the dock in, if it shouldnt start hidden
				Gdk.threads_add_timeout (400, () => {
					controller.hide_manager.update_hovered ();
					return false;
				});
				
				set_input_mask ();
				return base.draw (cr);
			}
			
			controller.renderer.draw_dock (cr);
			set_input_mask ();
			
			return true;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool map_event (Gdk.EventAny event)
		{
			set_struts ();
			
			return base.map_event (event);
		}
		
		/**
		 * Sets the currently hovered item-provider for this dock.
		 *
		 * @param provider the hovered item-provider (if any) for this dock
		 */
		protected void set_hovered_provider (DockItemProvider? provider)
		{
			if (HoveredItemProvider == provider)
				return;
			
			HoveredItemProvider = provider;
		}
			
		/**
		 * Sets the currently hovered item for this dock.
		 *
		 * @param item the hovered item (if any) for this dock
		 */
		protected void set_hovered (DockItem? item)
		{
			if (HoveredItem == item)
				return;
			
			if (HoveredItem != null)
				HoveredItem.hovered ();
			
			if (item != null)
				item.hovered ();
			
			HoveredItem = item;
			
			// if HoveredItem changed always stop scheduled popup and hide the tooltip
			if (hover_reposition_timer > 0) {
				Source.remove (hover_reposition_timer);
				hover_reposition_timer = 0;
			}
			
			hover.hide ();
			
			if (HoveredItem == null || controller.drag_manager.InternalDragActive)
				return;
			
			// don't be that demanding this delay is still fast enough
			hover_reposition_timer = Gdk.threads_add_timeout (HOVER_DELAY_TIME, () => {
				if (HoveredItem == null) {
					hover_reposition_timer = 0;
					return false;
				}
				
				// wait for the dock to be completely unhidden if it was
				if (!controller.hide_manager.Hidden
					&& controller.renderer.hide_progress > 0.0)
					return true;
				
				hover_reposition_timer = 0;
				
				int x, y;
				hover.set_text (HoveredItem.Text);
				controller.position_manager.get_hover_position (HoveredItem, out x, out y);
				hover.show_at (x, y, controller.position_manager.Position);
				
				if (menu_is_visible ())
					hover.hide ();
				
				return false;
			});
		}
		
		/**
		 * Determines if an item is hovered by the cursor at the x/y position.
		 *
		 * @param x the cursor x position
		 * @param y the cursor x position
		 * @return if a dock item is hovered
		 */
		public bool update_hovered (int x, int y)
		{
			// If the dock is hidden there is nothing to set.
			if (controller.hide_manager.Hidden) {
				set_hovered_provider (null);
				set_hovered (null);
				return false;
			}
			
			unowned PositionManager position_manager = controller.position_manager;
			unowned DockItem? drag_item = controller.drag_manager.DragItem;
			Gdk.Rectangle rect;
			
			// check if there already was a hovered-item and if it is still hovered to speed up things
			if (HoveredItem != null) {
				rect = position_manager.get_item_hover_region (HoveredItem);
				if (y >= rect.y && y < rect.y + rect.height && x >= rect.x && x < rect.x + rect.width)
					// Do not allow the hovered-item to be the drag-item
					if (drag_item == HoveredItem) {
						set_hovered_provider (HoveredItem.Container as DockItemProvider);
						set_hovered (null);
						return false;
					} else {
						// nothing changed
						return true;
					}
			}
			
			rect = position_manager.get_cursor_region ();
			if (y < rect.y || y >= rect.y + rect.height || x < rect.x || x >= rect.x + rect.width) {
				set_hovered_provider (null);
				set_hovered (null);
				return false;
			}
			
			bool found_hovered_provider = false;
			
			foreach (var element in controller.Elements) {
				unowned DockItemProvider? provider = (element as DockItemProvider);
				if (provider == null)
					continue;
				
				rect = position_manager.get_item_hover_region (provider);
				if (y < rect.y || y >= rect.y + rect.height || x < rect.x || x >= rect.x + rect.width)
					continue;
				
				set_hovered_provider (provider);
				found_hovered_provider = true;
				
				foreach (var item in provider.Elements) {
					rect = position_manager.get_item_hover_region (item);
					if (y < rect.y || y >= rect.y + rect.height || x < rect.x || x >= rect.x + rect.width)
						continue;
					
					// Do not allow the hovered-item to be the drag-item
					if (drag_item == item)
						break;
				
					set_hovered (item as DockItem);
					return true;
				}
			}
			
			if (!found_hovered_provider)
				set_hovered_provider (null);
			set_hovered (null);
			return false;
		}
		
		/**
		 * Sets the size of the dock window and repositions it if needed.
		 */
		public void update_size_and_position ()
		{
			unowned PositionManager position_manager = controller.position_manager;
			
			var win_rect = position_manager.get_dock_window_region ();
			
			int width_current, height_current;
			get_size_request (out width_current, out height_current);
			var needs_resize = (win_rect.width != width_current || win_rect.height != height_current);
			
			var needs_reposition = true;
			if (get_realized ()) {
				int x_current, y_current;
				get_position (out x_current, out y_current);
				needs_reposition = (win_rect.x != x_current || win_rect.y != y_current);
			}
			
			if (needs_resize) {
				Logger.verbose ("DockWindow.set_size_request (width = %i, height = %i)", win_rect.width, win_rect.height);
				set_size_request (win_rect.width, win_rect.height);
				controller.renderer.reset_buffers ();
				
				if (!needs_reposition) {
					update_icon_regions ();
					set_struts ();
					set_hovered_provider (null);
					set_hovered (null);
				}
			}
			
			if (needs_reposition) {
				if (dock_is_starting) {
					position (win_rect.x, win_rect.y);
				} else {
					schedule_position ();
				}
			}
		}
		
		void schedule_position ()
		{
			if (reposition_timer != 0) {
				GLib.Source.remove (reposition_timer);
				reposition_timer = 0;
			}
			
			reposition_timer = Gdk.threads_add_timeout (50, () => {
				reposition_timer = 0;
				
				unowned PositionManager position_manager = controller.position_manager;
				var win_rect = position_manager.get_dock_window_region ();
				
				position (win_rect.x, win_rect.y);
				
				return false;
			});
		}
		
		void position (int x, int y)
		{
			Logger.verbose ("DockWindow.move (x = %i, y = %i)", x, y);
			move (x, y);
			
			update_icon_regions ();
			set_struts ();
			set_hovered_provider (null);
			set_hovered (null);
		}
		
		/**
		 * Updates the icon regions for all items on the dock.
		 */
		public void update_icon_regions ()
		{
			Logger.verbose ("DockWindow.update_icon_regions ()");
			
			var use_hidden_region = (menu_is_visible () || controller.hide_manager.Hidden);
			
			foreach (var item in controller.Items) {
				unowned ApplicationDockItem? appitem = (item as ApplicationDockItem);
				if (appitem == null || !appitem.is_running ())
					continue;
				
				var region = controller.position_manager.get_icon_geometry (appitem, use_hidden_region);
				WindowControl.update_icon_regions (appitem.App, region);
			}
		}
		
		/**
		 * Updates the icon region for the given item.
		 *
		 + @param appitem the item to update the icon region for
		 */
		public void update_icon_region (ApplicationDockItem appitem)
		{
			if (!appitem.is_running ())
				return;
			
			Logger.verbose ("DockWindow.update_icon_region ('%s')", appitem.Text);
			
			var use_hidden_region = (menu_is_visible () || controller.hide_manager.Hidden);
			var region = controller.position_manager.get_icon_geometry (appitem, use_hidden_region);
			WindowControl.update_icon_regions (appitem.App, region);
		}
		
		/**
		 * If the popup menu is currently visible.
		 */
		public bool menu_is_visible ()
		{
			return (menu != null && menu.get_visible ());
		}
		
		/**
		 * Shows the popup menu.
		 *
		 * @param button the button used to trigger the popup
		 * @param show_plank_menu if the 'global' menu should be shown
		 */
		protected void show_menu (uint button, bool show_plank_menu)
		{
			if (menu != null) {
				foreach (var w in menu.get_children ())
					menu.remove (w);
				
				menu.show.disconnect (on_menu_show);
				menu.hide.disconnect (on_menu_hide);
				menu.detach ();
				menu = null;
			}
			
			Gee.ArrayList<Gtk.MenuItem> items;
			if (show_plank_menu) {
				items = PlankDockItem.get_plank_menu_items ();
				set_hovered_provider (null);
				set_hovered (null);
			} else {
				items = HoveredItem.get_menu_items ();
			}
			
			if (items.size == 0)
				return;
			
			menu = new Gtk.Menu ();
			menu.attach_to_widget (this, null);
			menu.show.connect (on_menu_show);
			menu.hide.connect (on_menu_hide);
			
			foreach (var item in items) {
				item.show ();
				menu.append (item);
			}
			
			if (show_plank_menu)
				menu.popup (null, null, null, button, Gtk.get_current_event_time ());
			else
				menu.popup (null, null, position_menu, button, Gtk.get_current_event_time ());
		}
		
		/**
		 * Called when the popup menu hides.
		 */
		protected void on_menu_hide ()
		{
			update_icon_regions ();
			unowned HideManager hide_manager = controller.hide_manager;
			hide_manager.update_hovered ();
			if (!hide_manager.Hovered) {
				set_hovered_provider (null);
				set_hovered (null);
			}
		}
		
		/**
		 * Called when the popup menu shows.
		 */
		protected void on_menu_show ()
		{
			update_icon_regions ();
			hover.hide ();
			controller.renderer.animated_draw ();
		}
		
		/**
		 * Positions the popup menu.
		 *
		 * @param menu the popup menu to show
		 * @param x the x location to show the menu
		 * @param y the y location to show the menu
		 * @param push_in if the menu should push into the screen
		 */
		protected void position_menu (Gtk.Menu menu, out int x, out int y, out bool push_in)
		{
			Gtk.Requisition requisition;
			menu.get_preferred_size (null, out requisition);
			controller.position_manager.get_menu_position (HoveredItem, requisition, out x, out y);
			push_in = false;
		}
		
		void set_input_mask ()
		{
			if (!get_realized ())
				return;
			
			var cursor_rect = controller.position_manager.get_cursor_region ();
			// FIXME bug 768722 - this fixes the crash, but not WHY this happens
			return_if_fail (cursor_rect.width > 0);
			return_if_fail (cursor_rect.height > 0);
			
			if (cursor_rect != input_rect) {
				input_rect = cursor_rect;
				get_window ().input_shape_combine_region (new Cairo.Region.rectangle ((Cairo.RectangleInt) cursor_rect), 0, 0);
			}
		}
		
		void set_struts ()
		{
			if (!get_realized ())
				return;
			
			unowned Gdk.X11.Display gdk_display = (get_display () as Gdk.X11.Display);
			if (gdk_display == null)
				return;

			unowned Gdk.X11.Window gdk_window = (get_window () as Gdk.X11.Window);
			if (gdk_window == null)
				return;
			
			var struts = new ulong [Struts.N_VALUES];
			
			if (controller.prefs.HideMode == HideType.NONE)
				controller.position_manager.get_struts (ref struts);
			
			var first_struts = new ulong [Struts.BOTTOM + 1];
			for (var i = 0; i < first_struts.length; i++)
				first_struts [i] = struts [i];
			
			unowned X.Display display = gdk_display.get_xdisplay ();
			var xid = gdk_window.get_xid ();
			
			gdk_display.error_trap_push ();
			display.change_property (xid, display.intern_atom ("_NET_WM_STRUT_PARTIAL", false), X.XA_CARDINAL,
			                      32, X.PropMode.Replace, (uchar[]) struts, struts.length);
			display.change_property (xid, display.intern_atom ("_NET_WM_STRUT", false), X.XA_CARDINAL,
			                      32, X.PropMode.Replace, (uchar[]) first_struts, first_struts.length);
			gdk_display.error_trap_pop ();
		}
	}
}
