//  
//  Copyright (C) 2011 Robert Dyer, Michal Hruby, Rico Tzschichholz
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
using Plank.Services.Windows;

namespace Plank.Widgets
{
	/**
	 * Which side of the screen the dock sits on.
	 */
	public enum DockPosition
	{
		/**
		 * The dock is on the bottom of the screen (and is horizontal).
		 */
		BOTTOM,
		/**
		 * The dock is on the top of the screen (and is horizontal).
		 */
		TOP,
		/**
		 * The dock is on the left side of the screen (and is vertical).
		 */
		LEFT,
		/**
		 * The dock is on the right side of the screen (and is vertical).
		 */
		RIGHT
	}
	
	/**
	 * The main window for all docks.
	 */
	public class DockWindow : CompositedWindow
	{
		/**
		 * The controller for this dock.
		 */
		DockController controller { get; set; }
		
		/**
		 * The currently hovered item (if any).
		 */
		public DockItem? HoveredItem { get; protected set; }
		
		
		/**
		 * A hover window to use with this dock.
		 */
		protected HoverWindow hover = new HoverWindow ();
		
		/**
		 * The popup menu for this dock.
		 */
		protected Gtk.Menu menu = new Gtk.Menu ();
		
		
		/**
		 * The monitor's geometry - this is cached.
		 */
		protected Gdk.Rectangle monitor_geo;
		
		/**
		 * Cached x position of the dock window.
		 */
		public int win_x { get; protected set; }
		/**
		 * Cached y position of the dock window.
		 */
		public int win_y { get; protected set; }
		
		uint reposition_timer = 0;
		
		bool dock_is_starting = true;
		
		
		/**
		 * Creates a new dock window.
		 */
		public DockWindow (DockController controller)
		{
			base ();
			
			this.controller = controller;
			
			set_accept_focus (false);
			can_focus = false;
			skip_pager_hint = true;
			skip_taskbar_hint = true;
			set_type_hint (WindowTypeHint.DOCK);
			
			menu.attach_to_widget (this, null);
			menu.show.connect (update_icon_regions);
			menu.hide.connect (on_menu_hide);
			
			stick ();
			
			add_events (EventMask.BUTTON_PRESS_MASK |
						EventMask.BUTTON_RELEASE_MASK |
						EventMask.ENTER_NOTIFY_MASK |
						EventMask.LEAVE_NOTIFY_MASK |
						EventMask.POINTER_MOTION_MASK |
						EventMask.SCROLL_MASK);
			
			controller.items.item_added.connect (set_size);
			controller.items.item_removed.connect (set_size);
			controller.prefs.changed.connect (set_size);
			
			controller.renderer.notify["Hidden"].connect (update_icon_regions);
			
			get_screen ().size_changed.connect (update_monitor_geo);
			controller.prefs.changed["Monitor"].connect (update_monitor_geo);
			
			int x, y;
			get_position (out x, out y);
			win_x = x;
			win_y = y;
		}
		
		/**
		 * Initializes the window.
		 */
		public void initialize ()
		{
			update_monitor_geo ();
		}
		
		~DockWindow ()
		{
			menu.show.disconnect (update_icon_regions);
			menu.hide.disconnect (on_menu_hide);
			
			controller.items.item_added.disconnect (set_size);
			controller.items.item_removed.disconnect (set_size);
			controller.prefs.changed.disconnect (set_size);
			
			controller.renderer.notify["Hidden"].disconnect (update_icon_regions);
			
			get_screen ().size_changed.disconnect (update_monitor_geo);
			controller.prefs.changed["Monitor"].disconnect (update_monitor_geo);
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool button_press_event (EventButton event)
		{
			if (HoveredItem == null)
				return true;
			
			var button = PopupButton.from_event_button (event);
			if ((event.state & ModifierType.CONTROL_MASK) == ModifierType.CONTROL_MASK
					&& (button & PopupButton.RIGHT) == PopupButton.RIGHT)
				do_popup (event.button, true);
			else if ((HoveredItem.Button & button) == button)
				do_popup (event.button, false);
			
			return true;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool button_release_event (EventButton event)
		{
			if (HoveredItem != null && !menu_is_visible ())
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
			if (!menu_is_visible ())
				set_hovered (null);
			else
				hover.hide ();
			
			return true;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool motion_notify_event (EventMotion event)
		{
			if (update_hovered ((int) event.x, (int) event.y))
				return true;
			
			set_hovered (null);
			return true;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool scroll_event (EventScroll event)
		{
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
#if USE_GTK3
		public override bool draw (Context cr)
#else
		public override bool expose_event (EventExpose event)
#endif
		{
			if (dock_is_starting) {
				debug ("dock window loaded");
				dock_is_starting = false;
				
				// slide the dock in, if it shouldnt start hidden
				GLib.Timeout.add (400, () => {
					controller.hide_manager.update_dock_hovered ();
					return false;
				});
			}
			
			set_input_mask ();
#if USE_GTK3
			controller.renderer.draw_dock (cr);
#else
			controller.renderer.draw_dock (cairo_create (event.window));
#endif
			
			return true;
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
			
			if (HoveredItem == null) {
				hover.hide ();
				return;
			}
			
			if (hover.get_visible ())
				hover.hide ();
			
			hover.Text = HoveredItem.Text;
			position_hover ();
			
			if (!hover.get_visible ())
				hover.show ();
		}
		
		/**
		 * Determines if an item is hovered by the cursor at the x/y position.
		 *
		 * @param x the cursor x position
		 * @param y the cursor x position
		 * @return if a dock item is hovered
		 */
		protected bool update_hovered (int x, int y)
		{
			foreach (var item in controller.items.Items) {
				var rect = controller.renderer.item_hover_region (item);
				
				if (y >= rect.y && y <= rect.y + rect.height && x >= rect.x && x <= rect.x + rect.width) {
					set_hovered (item);
					return true;
				}
			}
			
			return false;
		}
		
		/**
		 * Updates the monitor geometry cache.
		 */
		protected void update_monitor_geo ()
		{
			get_screen ().get_monitor_geometry (controller.prefs.Monitor, out monitor_geo);
			
			set_size ();
		}
		
		/**
		 * Repositions the hover window for the hovered item.
		 */
		protected void position_hover ()
			requires (HoveredItem != null)
		{
			var rect = controller.renderer.item_hover_region (HoveredItem);
			hover.move_hover (win_x + rect.x + rect.width / 2, win_y + rect.y);
		}
		
		/**
		 * Sets the size of the dock window.
		 */
		public void set_size ()
		{
			set_size_request (controller.renderer.DockWidth, controller.renderer.DockHeight);
			reposition ();
			if (HoveredItem != null)
				position_hover ();
			
			controller.renderer.reset_buffers ();
		}
		
		/**
		 * Repositions the dock to keep it centered on the screen edge.
		 */
		protected void reposition ()
		{
			if (reposition_timer != 0) {
				GLib.Source.remove (reposition_timer);
				reposition_timer = 0;
			}
			
			reposition_timer = GLib.Timeout.add (50, () => {
				reposition_timer = 0;
				
				// put dock on bottom-center of monitor
				win_x = monitor_geo.x + (monitor_geo.width - width_request) / 2;
				win_y = monitor_geo.y + monitor_geo.height - height_request;
				move (win_x, win_y);
				
				update_icon_regions ();
				set_struts ();
				set_hovered (null);
				
				return false;
			});
		}
		
		/**
		 * Updates the icon regions for all items on the dock.
		 */
		protected void update_icon_regions ()
		{
			foreach (var item in controller.items.Items) {
				unowned ApplicationDockItem? appitem = (item as ApplicationDockItem);
				if (appitem == null || appitem.App == null)
					continue;
				
				if (menu_is_visible () || controller.renderer.Hidden)
					WindowControl.update_icon_regions (appitem.App, null, win_x, win_y);
				else
					WindowControl.update_icon_regions (appitem.App, controller.renderer.item_hover_region (appitem), win_x, win_y);
			}
			
			controller.renderer.animated_draw ();
		}
		
		/**
		 * If the popup menu is currently visible.
		 */
		public bool menu_is_visible ()
		{
			return menu.get_visible ();
		}
		
		/**
		 * Shows the popup menu.
		 *
		 * @param button the button used to trigger the popup
		 * @param show_plank_menu if the 'global' menu should be shown
		 */
		protected void do_popup (uint button, bool show_plank_menu)
		{
			foreach (var w in menu.get_children ()) {
				if (w is ImageMenuItem)
					(w as ImageMenuItem).get_image ().destroy ();
				menu.remove (w);
			}
			
			ArrayList<Gtk.MenuItem> items;
			if (show_plank_menu)
				items = PlankDockItem.get_plank_menu_items ();
			else
				items = HoveredItem.get_menu_items ();
			
			if (items.size == 0)
				return;
			
			foreach (var item in items)
				menu.append (item);
			
			menu.show_all ();
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
			controller.hide_manager.update_dock_hovered ();
			if (!controller.hide_manager.DockHovered)
				set_hovered (null);
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
			var rect = controller.renderer.item_hover_region (HoveredItem);
			
#if VALA_0_14
			var requisition = menu.get_requisition ();
			x = win_x + rect.x + rect.width / 2 - requisition.width / 2;
			y = win_y + rect.y - requisition.height - 10;
#else
			x = win_x + rect.x + rect.width / 2 - menu.requisition.width / 2;
			y = win_y + rect.y - menu.requisition.height - 10;
#endif
			push_in = false;
		}
		
		void set_input_mask ()
		{
#if USE_GTK3
			if (!get_realized ())
#else
			if (!is_realized ())
#endif
				return;
			
			var cursor = controller.renderer.get_cursor_region ();
			// FIXME bug 768722 - this fixes the crash, but not WHY this happens
			return_if_fail (cursor.width > 0);
			return_if_fail (cursor.height > 0);
			
#if USE_GTK3
			var region = new Region.rectangle (RectangleInt () {x = 0, y = 0, width = cursor.width, height = cursor.height});
#else
			var region = Gdk.Region.rectangle (Gdk.Rectangle () {x = 0, y = 0, width = cursor.width, height = cursor.height});
#endif
			get_window ().input_shape_combine_region (region, cursor.x, cursor.y);
		}
		
		enum Struts 
		{
			LEFT,
			RIGHT,
			TOP,
			BOTTOM,
			LEFT_START,
			LEFT_END,
			RIGHT_START,
			RIGHT_END,
			TOP_START,
			TOP_END,
			BOTTOM_START,
			BOTTOM_END,
			N_VALUES
		}
		
		void set_struts ()
		{
#if USE_GTK3
			if (!get_realized ())
#else
			if (!is_realized ())
#endif
				return;
			
			var struts = new ulong [Struts.N_VALUES];
			
			if (controller.prefs.HideMode == HideType.NONE) {
				struts [Struts.BOTTOM] = controller.renderer.VisibleDockHeight + get_screen ().get_height () - monitor_geo.y - monitor_geo.height;
				struts [Struts.BOTTOM_START] = monitor_geo.x;
				struts [Struts.BOTTOM_END] = monitor_geo.x + monitor_geo.width - 1;
			}
			
			var first_struts = new ulong [Struts.BOTTOM + 1];
			for (var i = 0; i < first_struts.length; i++)
				first_struts [i] = struts [i];
			
#if USE_GTK3
			unowned X.Display display = X11Display.get_xdisplay (get_display ());
			var window = X11Window.get_xid (get_window ());
			
			display.change_property (window, display.intern_atom ("_NET_WM_STRUT_PARTIAL", false), X.XA_CARDINAL,
			                      32, X.PropMode.Replace, (uchar[]) struts, struts.length);
			display.change_property (window, display.intern_atom ("_NET_WM_STRUT", false), X.XA_CARDINAL, 
			                      32, X.PropMode.Replace, (uchar[]) first_struts, first_struts.length);
#else
			unowned X.Display display = x11_drawable_get_xdisplay (get_window ());
			var xid = x11_drawable_get_xid (get_window ());
			
			display.change_property (xid, display.intern_atom ("_NET_WM_STRUT_PARTIAL", false), X.XA_CARDINAL,
			                      32, X.PropMode.Replace, (uchar[]) struts, struts.length);
			display.change_property (xid, display.intern_atom ("_NET_WM_STRUT", false), X.XA_CARDINAL, 
			                      32, X.PropMode.Replace, (uchar[]) first_struts, first_struts.length);
#endif
		}
	}
}
