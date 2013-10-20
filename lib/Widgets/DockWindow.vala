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

using Cairo;
using Gdk;
using Gee;
using Gtk;

using Plank.Items;
using Plank.Drawing;
using Plank.Factories;
using Plank.Services;
using Plank.Services.Windows;

namespace Plank.Widgets
{
	/**
	 * The main window for all docks.
	 */
	public class DockWindow : CompositedWindow
	{
		/**
		 * The controller for this dock.
		 */
		public DockController controller { private get; construct; }
		
		
		/**
		 * The currently hovered item (if any).
		 */
		public DockItem? HoveredItem { get; protected set; }
		
		
		/**
		 * The item which "received" the button-pressed signal (if any).
		 */
		unowned DockItem? ClickedItem { get; set; }
		
		/**
		 * The popup menu for this dock.
		 */
		protected Gtk.Menu? menu;
		
		
		uint reposition_timer = 0;
		uint hover_reposition_timer = 0;
		
		bool dock_is_starting = true;
		
		Cairo.RectangleInt input_rect;
		
		/**
		 * Creates a new dock window.
		 */
		public DockWindow (DockController controller)
		{
			GLib.Object (controller: controller, type: Gtk.WindowType.TOPLEVEL, type_hint: WindowTypeHint.DOCK);
		}
		
		construct
		{
			accept_focus = false;
			can_focus = false;
			skip_pager_hint = true;
			skip_taskbar_hint = true;
			
			stick ();
			
			add_events (EventMask.BUTTON_PRESS_MASK |
						EventMask.BUTTON_RELEASE_MASK |
						EventMask.ENTER_NOTIFY_MASK |
						EventMask.LEAVE_NOTIFY_MASK |
						EventMask.POINTER_MOTION_MASK |
						EventMask.SCROLL_MASK);
			
			controller.drag_manager.notify["DragItem"].connect (drag_item_changed);
			controller.prefs.notify["HideMode"].connect (set_struts);
		}
		
		~DockWindow ()
		{
			if (menu != null) {
				menu.show.disconnect (on_menu_show);
				menu.hide.disconnect (on_menu_hide);
			}
			
			controller.drag_manager.notify["DragItem"].disconnect (drag_item_changed);
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
		public override bool button_press_event (EventButton event)
		{
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
				&& (HoveredItem == null || (event.state & ModifierType.CONTROL_MASK) == ModifierType.CONTROL_MASK))
				show_menu (event.button, true);
			else if (HoveredItem != null && (HoveredItem.Button & button) == button)
				show_menu (event.button, false);
			
			return true;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool button_release_event (EventButton event)
		{
			if (controller.drag_manager.InternalDragActive)
				return true;

			// Make sure the HoveredItem is still the same since button-pressed
			if (ClickedItem != null && HoveredItem == ClickedItem && !menu_is_visible ())
				HoveredItem.clicked (PopupButton.from_event_button (event), event.state);
			
			return true;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool enter_notify_event (EventCrossing event)
		{
			update_hovered ((int) event.x, (int) event.y);
			
			return true;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool leave_notify_event (EventCrossing event)
		{
			// ignore this event if it was sent explicitly
			if ((bool) event.send_event)
				return false;
			
			if (!menu_is_visible ())
				set_hovered (null);
			else
				controller.hover.hide ();
			
			return true;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool motion_notify_event (EventMotion event)
		{
			update_hovered ((int) event.x, (int) event.y);
			return true;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool scroll_event (EventScroll event)
		{
			if (controller.drag_manager.InternalDragActive)
				return true;
			
			if ((event.state & ModifierType.CONTROL_MASK) != 0) {
				if (event.direction == ScrollDirection.UP)
					controller.prefs.increase_icon_size ();
				else if (event.direction == ScrollDirection.DOWN)
					controller.prefs.decrease_icon_size ();
				
				return true;
			}
			
			if (HoveredItem != null)
				HoveredItem.scrolled (event.direction, event.state);
			
			return true;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool draw (Context cr)
		{
			if (dock_is_starting) {
				debug ("dock window loaded");
				dock_is_starting = false;
				
				// slide the dock in, if it shouldnt start hidden
				Gdk.threads_add_timeout (400, () => {
					controller.hide_manager.update_dock_hovered ();
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
		public override bool map_event (EventAny event)
		{
			set_struts ();
			
			return base.map_event (event);
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
			
			HoveredItem = item;
			
			// if HoveredItem changed always stop scheduled popup and hide the tooltip
			if (hover_reposition_timer > 0)
				Source.remove (hover_reposition_timer);
			controller.hover.hide ();
			
			if (HoveredItem == null || controller.drag_manager.InternalDragActive) {
				ClickedItem = null;
				return;
			}
			
			// don't be that demanding this delay is still fast enough
			hover_reposition_timer = Gdk.threads_add_timeout (33, () => {
				hover_reposition_timer = 0;
				
				if (HoveredItem == null)
					return false;
				
				unowned HoverWindow hover = controller.hover;
				
				int x, y;
				hover.set_text (HoveredItem.Text);
				controller.position_manager.get_hover_position (HoveredItem, out x, out y);
				hover.show_at (x, y);
				
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
			unowned PositionManager position_manager = controller.position_manager;
			Gdk.Rectangle rect;
			
			// check if there already was a hovered-item and if it is still hovered to speed up things
			if (HoveredItem != null) {
				rect = position_manager.item_hover_region (HoveredItem);
				if (y >= rect.y && y < rect.y + rect.height && x >= rect.x && x < rect.x + rect.width)
					// nothing changed
					return true;
			}
			
			var cursor_rect = position_manager.get_cursor_region ();
			if (y < cursor_rect.y && y >= cursor_rect.y + cursor_rect.height
				&& x < cursor_rect.x && x >= cursor_rect.x + cursor_rect.width) {
				set_hovered (null);
				return false;
			}
			
			foreach (var provider in controller.Providers) {
				rect = position_manager.provider_hover_region (provider);
				if (y < rect.y || y >= rect.y + rect.height || x < rect.x || x >= rect.x + rect.width)
					continue;
				
				foreach (var item in provider.Items) {
					rect = position_manager.item_hover_region (item);
					if (y < rect.y || y >= rect.y + rect.height || x < rect.x || x >= rect.x + rect.width)
						continue;
				
					set_hovered (item);
					return true;
				}
			}
			
			set_hovered (null);
			return false;
		}
		
		/**
		 * Called when a dragged item changes.
		 */
		protected void drag_item_changed ()
		{
			if (controller.drag_manager.DragItem != null)
				set_hovered (null);
		}
		
		/**
		 * Sets the size of the dock window and repositions it if needed.
		 */
		public void update_size_and_position ()
		{
			unowned PositionManager position_manager = controller.position_manager;
			position_manager.update_dock_position ();
			
			var x = position_manager.win_x;
			var y = position_manager.win_y;
			
			var width = position_manager.DockWidth;
			var height = position_manager.DockHeight;
			
			int width_current, height_current;
			get_size_request (out width_current, out height_current);
			var needs_resize = (width != width_current || height != height_current);
			
			var needs_reposition = true;
			if (get_realized ()) {
				int x_current, y_current;
				get_position (out x_current, out y_current);
				needs_reposition = (x != x_current || y != y_current);
			}
			
			if (needs_resize) {
				Logger.verbose ("DockWindow.set_size_request (width = %i, height = %i)", width, height);
				set_size_request (width, height);
				controller.renderer.reset_buffers ();
				
				if (!needs_reposition) {
					update_icon_regions ();
					set_struts ();
					set_hovered (null);
				}
			}
			
			if (needs_reposition) {
				if (dock_is_starting) {
					position (x, y);
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
				position_manager.update_dock_position ();
				
				var x = position_manager.win_x;
				var y = position_manager.win_y;
				
				position (x, y);
				
				return false;
			});
		}
		
		void position (int x, int y)
		{
			Logger.verbose ("DockWindow.move (x = %i, y = %i)", x, y);
			move (x, y);
			
			update_icon_regions ();
			set_struts ();
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
			
			ArrayList<Gtk.MenuItem> items;
			if (show_plank_menu)
				items = PlankDockItem.get_plank_menu_items ();
			else
				items = HoveredItem.get_menu_items ();
			
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
				menu.popup (null, null, null, button, get_current_event_time ());
			else
				menu.popup (null, null, position_menu, button, get_current_event_time ());
		}
		
		/**
		 * Called when the popup menu hides.
		 */
		protected void on_menu_hide ()
		{
			update_icon_regions ();
			unowned HideManager hide_manager = controller.hide_manager;
			hide_manager.update_dock_hovered ();
			if (!hide_manager.DockHovered)
				set_hovered (null);
		}
		
		/**
		 * Called when the popup menu shows.
		 */
		protected void on_menu_show ()
		{
			update_icon_regions ();
			controller.hover.hide ();
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
			var requisition = menu.get_requisition ();
			controller.position_manager.get_menu_position (HoveredItem, requisition, out x, out y);
			push_in = false;
		}
		
		void set_input_mask ()
		{
			if (!get_realized ())
				return;
			
			var cursor = controller.position_manager.get_cursor_region ();
			// FIXME bug 768722 - this fixes the crash, but not WHY this happens
			return_if_fail (cursor.width > 0);
			return_if_fail (cursor.height > 0);
			
			RectangleInt rect = {cursor.x, cursor.y, cursor.width, cursor.height};
			if (rect != input_rect) {
				input_rect = rect;
				get_window ().input_shape_combine_region (new Region.rectangle (rect), 0, 0);
			}
		}
		
		void set_struts ()
		{
			if (!get_realized ())
				return;
			
			unowned Gdk.Display gdk_display = get_display ();
			if (!(gdk_display is Gdk.X11Display))
				return;
			
			var struts = new ulong [Struts.N_VALUES];
			
			if (controller.prefs.HideMode == HideType.NONE)
				controller.position_manager.get_struts (ref struts);
			
			var first_struts = new ulong [Struts.BOTTOM + 1];
			for (var i = 0; i < first_struts.length; i++)
				first_struts [i] = struts [i];
			
			unowned X.Display display = X11Display.get_xdisplay (gdk_display);
			var xid = X11Window.get_xid (get_window ());
			
			Gdk.error_trap_push ();
			display.change_property (xid, display.intern_atom ("_NET_WM_STRUT_PARTIAL", false), X.XA_CARDINAL,
			                      32, X.PropMode.Replace, (uchar[]) struts, struts.length);
			display.change_property (xid, display.intern_atom ("_NET_WM_STRUT", false), X.XA_CARDINAL,
			                      32, X.PropMode.Replace, (uchar[]) first_struts, first_struts.length);
			Gdk.error_trap_pop ();
		}
	}
}
