//
//  Copyright (C) 2011-2012 Robert Dyer, Michal Hruby, Rico Tzschichholz
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
	 * The main window for all docks.
	 */
	public class DockWindow : CompositedWindow
	{
		const uint LONG_PRESS_TIME = 750U;
		const uint HOVER_DELAY_TIME = 200U;
		
		/**
		 * The controller for this dock.
		 */
		public DockController controller { private get; construct; }
		
		
		/**
		 * The currently hovered item (if any).
		 */
		public DockItem? HoveredItem { get; private set; }
		
		/**
		 * The currently hovered item-provider (if any).
		 */
		public DockItemProvider? HoveredItemProvider { get; private set; }
		
		
		/**
		 * The item which "received" the button-pressed signal (if any).
		 */
		unowned DockItem? ClickedItem { get; private set; }
		
		/**
		 * The popup menu for this dock.
		 */
		Gtk.Menu? menu;
		
		uint hover_reposition_timer_id = 0U;
		
		uint long_press_timer_id = 0U;
		bool long_press_active = false;
		uint long_press_button = 0U;

		Gdk.Rectangle input_rect;
		int requested_x;
		int requested_y;
		int window_position_retry = 0;
		
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
						Gdk.EventMask.SCROLL_MASK |
						Gdk.EventMask.STRUCTURE_MASK);
			
			controller.prefs.notify["HideMode"].connect (set_struts);
		}
		
		~DockWindow ()
		{
			if (menu != null) {
				menu.show.disconnect (on_menu_show);
				menu.hide.disconnect (on_menu_hide);
			}
			
			controller.prefs.notify["HideMode"].disconnect (set_struts);
			
			if (hover_reposition_timer_id > 0U) {
				GLib.Source.remove (hover_reposition_timer_id);
				hover_reposition_timer_id = 0U;
			}
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool button_press_event (Gdk.EventButton event)
		{
			// FIXME Needed for gtk+ 3.14+
			if (menu_is_visible ())
				return Gdk.EVENT_PROPAGATE;
			
			// If the dock is hidden we should ignore it.
			if (controller.hide_manager.Hidden)
				return Gdk.EVENT_STOP;
			
			// This event gets fired before the drag end event,
			// in this case we ignore it.
			if (controller.drag_manager.InternalDragActive)
				return Gdk.EVENT_STOP;
			
			// If the cursor got hidden due inactivity or the HoveredItem got
			// set null for other reasons we need to make sure this click gets
			// delegated correctly
			if (HoveredItem == null)
				update_hovered ((int) event.x, (int) event.y);
			
			ClickedItem = HoveredItem;
			
			// Check and try to show the menu
			if (show_menu (HoveredItem, event))
				return Gdk.EVENT_STOP;
			
			long_press_active = false;
			long_press_button = event.button;
			if (long_press_timer_id > 0U)
				Source.remove (long_press_timer_id);
			long_press_timer_id = Gdk.threads_add_timeout (LONG_PRESS_TIME, () => {
				long_press_active = true;
				long_press_timer_id = 0U;
				return false;
			});
			
			return Gdk.EVENT_PROPAGATE;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool button_release_event (Gdk.EventButton event)
		{
			// If the dock is hidden we should ignore it.
			if (controller.hide_manager.Hidden)
				return Gdk.EVENT_STOP;
			
			if (long_press_timer_id > 0U) {
				Source.remove (long_press_timer_id);
				long_press_timer_id = 0U;
			}
			
			if (long_press_active && long_press_button == event.button) {
				long_press_active = false;
				long_press_button = 0;
				return Gdk.EVENT_STOP;
			}
			
			if (controller.drag_manager.InternalDragActive)
				return Gdk.EVENT_STOP;

			// FIXME Needed for gtk+ 3.14+
			if (HoveredItem != null && ClickedItem == null && menu_is_visible ())
				menu.hide ();
			
			// Make sure the HoveredItem is still the same since button-pressed
			if (ClickedItem != null && HoveredItem == ClickedItem && !menu_is_visible ()) {
				// The user made a choice so hide tooltip to avoid obstructing anything
				controller.hover.hide ();
				
				HoveredItem.clicked (PopupButton.from_event_button (event), event.state, event.time);
			}
			
			ClickedItem = null;
			
			return Gdk.EVENT_PROPAGATE;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool enter_notify_event (Gdk.EventCrossing event)
		{
			controller.renderer.update_local_cursor ((int) event.x, (int) event.y);
			update_hovered ((int) event.x, (int) event.y);
			
			return Gdk.EVENT_STOP;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool leave_notify_event (Gdk.EventCrossing event)
		{
			// ignore this event if it was sent explicitly
			if ((bool) event.send_event)
				return Gdk.EVENT_PROPAGATE;
			
			if (!menu_is_visible ()) {
				set_hovered_provider (null);
				set_hovered (null);
			} else
				controller.hover.hide ();
			
			return Gdk.EVENT_STOP;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool motion_notify_event (Gdk.EventMotion event)
		{
			// FIXME Needed for gtk+ 3.14+
			if (menu_is_visible ())
				return Gdk.EVENT_STOP;
			
			controller.renderer.update_local_cursor ((int) event.x, (int) event.y);
			update_hovered ((int) event.x, (int) event.y);
			
			return Gdk.EVENT_PROPAGATE;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override void drag_begin (Gdk.DragContext context)
		{
			long_press_active = false;
			if (long_press_timer_id > 0U) {
				Source.remove (long_press_timer_id);
				long_press_timer_id = 0U;
			}
		}

		/**
		 * {@inheritDoc}
		 */
		public override bool scroll_event (Gdk.EventScroll event)
		{
			// If the dock is hidden we should ignore it.
			if (controller.hide_manager.Hidden)
				return Gdk.EVENT_STOP;
			
			if (controller.drag_manager.InternalDragActive)
				return Gdk.EVENT_STOP;
			
			// FIXME Ignore events for ScrollDirection.SMOOTH (since gtk+ 3.4)
			if (event.direction >= 4)
				return Gdk.EVENT_STOP;
			
			if ((event.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
				if (event.direction == Gdk.ScrollDirection.UP)
					controller.prefs.increase_icon_size ();
				else if (event.direction == Gdk.ScrollDirection.DOWN)
					controller.prefs.decrease_icon_size ();
				
				return Gdk.EVENT_STOP;
			}
			
			if (HoveredItem != null) {
				// The user made a choice so hide tooltip to avoid obstructing anything
				controller.hover.hide ();
				
				HoveredItem.scrolled (event.direction, event.state, event.time);
				controller.renderer.animated_draw ();
			}
			
			return Gdk.EVENT_STOP;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool configure_event (Gdk.EventConfigure event)
		{
			var win_rect = controller.position_manager.get_dock_window_region ();
			var needs_update = (win_rect.width != event.width || win_rect.height != event.height
				|| win_rect.x != event.x || win_rect.y != event.y);
			
			if (needs_update) {
				if (++window_position_retry < 3) {
					critical ("Retry #%i update_size_and_position() to force requested values!", window_position_retry);
					update_size_and_position ();
				}
			} else {
				window_position_retry = 0;
			}
			
			return base.configure_event (event);
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool draw (Cairo.Context cr)
		{
			set_input_mask ();
			
			return Gdk.EVENT_STOP;
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
		void set_hovered_provider (DockItemProvider? provider)
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
		void set_hovered (DockItem? item)
		{
			if (HoveredItem == item)
				return;
			
			if (HoveredItem != null)
				HoveredItem.hovered ();
			
			if (item != null)
				item.hovered ();
			
			HoveredItem = item;
			
			// if HoveredItem changed always stop scheduled popup and hide the tooltip
			if (hover_reposition_timer_id > 0U) {
				Source.remove (hover_reposition_timer_id);
				hover_reposition_timer_id = 0U;
			}
			
			if (controller.drag_manager.ExternalDragActive)
				return;
			
			controller.hover.hide ();
			
			if (HoveredItem == null
				|| !controller.prefs.TooltipsEnabled
				|| controller.drag_manager.InternalDragActive)
				return;
			
			// don't be that demanding this delay is still fast enough
			hover_reposition_timer_id = Gdk.threads_add_timeout (HOVER_DELAY_TIME, () => {
				if (HoveredItem == null) {
					hover_reposition_timer_id = 0U;
					return false;
				}
				
				// wait for the dock to be completely unhidden if it was
				if (!controller.hide_manager.Hidden
					&& controller.renderer.hide_progress > 0.0)
					return true;
				
				hover_reposition_timer_id = 0U;
				unowned HoverWindow hover = controller.hover;
				
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
				rect = position_manager.get_hover_region_for_element (HoveredItem);
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
			unowned DockItem? item = null;
			unowned DockItemProvider? provider = null;
			
			foreach (var element in controller.VisibleElements) {
				item = (element as DockItem);
				if (item != null) {
					rect = position_manager.get_hover_region_for_element (item);
					if (y < rect.y || y >= rect.y + rect.height || x < rect.x || x >= rect.x + rect.width)
						continue;
					
					// Do not allow the hovered-item to be the drag-item
					if (drag_item == item)
						break;
					
					set_hovered_provider (null);
					set_hovered (item as DockItem);
					return true;
				}
				
				provider = (element as DockItemProvider);
				if (provider == null)
					continue;
				
				rect = position_manager.get_hover_region_for_element (provider);
				if (y < rect.y || y >= rect.y + rect.height || x < rect.x || x >= rect.x + rect.width)
					continue;
				
				set_hovered_provider (provider);
				found_hovered_provider = true;
				
				foreach (var element2 in provider.VisibleElements) {
					rect = position_manager.get_hover_region_for_element (element2);
					if (y < rect.y || y >= rect.y + rect.height || x < rect.x || x >= rect.x + rect.width)
						continue;
					
					// Do not allow the hovered-item to be the drag-item
					if (drag_item == element2)
						break;
				
					set_hovered (element2 as DockItem);
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
				needs_reposition = (win_rect.x != x_current || win_rect.y != y_current
					|| win_rect.x != requested_x || win_rect.y != requested_y);
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
				Logger.verbose ("DockWindow.move (x = %i, y = %i)", win_rect.x, win_rect.y);
				requested_x = win_rect.x;
				requested_y = win_rect.y;
				move (win_rect.x, win_rect.y);
				
				update_icon_regions ();
				set_struts ();
				set_hovered_provider (null);
				set_hovered (null);
			}
		}
		
		/**
		 * Updates the icon regions for all items on the dock.
		 */
		public void update_icon_regions ()
		{
			Logger.verbose ("DockWindow.update_icon_regions ()");
			
			var use_hidden_region = (menu_is_visible () || controller.hide_manager.Hidden);
			
			foreach (var item in controller.VisibleItems) {
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
		 * @param item the item to show a menu for, or NULL
		 * @param event the event which triggerd this request
		 */
		bool show_menu (DockItem? item, Gdk.EventButton event)
		{
			if (menu != null) {
				foreach (var w in menu.get_children ())
					menu.remove (w);
				
				menu.show.disconnect (on_menu_show);
				menu.hide.disconnect (on_menu_hide);
				menu.detach ();
				menu = null;
			}
			
			Gee.ArrayList<Gtk.MenuItem>? menu_items = null;
			Gtk.MenuPositionFunc? position_func = null;
			var button = PopupButton.from_event_button (event);
			
			if ((button & PopupButton.RIGHT) != 0
				&& (item == null || (event.state & Gdk.ModifierType.CONTROL_MASK) != 0)) {
				menu_items = Factory.item_factory.get_item_for_dock ().get_menu_items ();
				if ((event.state & Gdk.ModifierType.MOD1_MASK) != 0
					&& (event.state & Gdk.ModifierType.SHIFT_MASK) != 0)
					menu_items.add_all (get_dock_debug_menu_items (controller));
				set_hovered_provider (null);
				set_hovered (null);
			} else if (item != null && item.is_valid () && (item.Button & button) != 0) {
				menu_items = item.get_menu_items ();
				if ((event.state & Gdk.ModifierType.MOD1_MASK) != 0
					&& (event.state & Gdk.ModifierType.SHIFT_MASK) != 0)
					menu_items.add_all (get_item_debug_menu_items (item));
				position_func = (Gtk.MenuPositionFunc) position_menu;
			}
			
			if (menu_items == null || menu_items.size == 0)
				return false;
			
			menu = new Gtk.Menu ();
			menu.attach_to_widget (this, null);
			menu.show.connect (on_menu_show);
			menu.hide.connect (on_menu_hide);
			
			var iterator = menu_items.bidir_list_iterator ();
			if (controller.prefs.Position == Gtk.PositionType.TOP) {
				iterator.last ();
				do {
					var menu_item = iterator.get ();
					menu_item.show ();
					menu.append (menu_item);
				} while (iterator.previous ());
			} else {
				iterator.first ();
				do {
					var menu_item = iterator.get ();
					menu_item.show ();
					menu.append (menu_item);
				} while (iterator.next ());
			}
			
			menu.popup (null, null, position_func, event.button, event.time);
			
			return true;
		}
		
		static Gee.ArrayList<Gtk.MenuItem> get_dock_debug_menu_items (DockController controller)
		{
			var debug_items = new Gee.ArrayList<Gtk.MenuItem> ();
			
			debug_items.add (new Gtk.SeparatorMenuItem ());
			debug_items.add (new TitledSeparatorMenuItem.no_line ("debug this dock"));
			
			Gtk.MenuItem menu_item;
			
			menu_item = new Gtk.MenuItem.with_mnemonic ("Open config folder");
			menu_item.activate.connect (() => {
				System.get_default ().open (controller.config_folder);
			});
			debug_items.add (menu_item);
			
			menu_item = new Gtk.MenuItem.with_mnemonic ("Open current theme file");
			menu_item.activate.connect (() => {
				System.get_default ().open (controller.renderer.theme.get_backing_file ());
			});
			debug_items.add (menu_item);
			
			return debug_items;
		}
		
		static Gee.ArrayList<Gtk.MenuItem> get_item_debug_menu_items (DockItem item)
		{
			var debug_items = new Gee.ArrayList<Gtk.MenuItem> ();
			
			debug_items.add (new Gtk.SeparatorMenuItem ());
			debug_items.add (new TitledSeparatorMenuItem.no_line ("debug this item"));
			
			Gtk.MenuItem menu_item;
			
			var dock_item_file = item.Prefs.get_backing_file ();
			menu_item = new Gtk.MenuItem.with_mnemonic ("Print info to stdout");
			menu_item.activate.connect (() => {
				print ("DockItemFile: '%s'\nText = '%s'\nIcon = '%s'\nLauncher = '%s'\n",
					dock_item_file != null ? dock_item_file.get_uri () : "",
					item.Text, item.Icon, item.Launcher);
			});
			debug_items.add (menu_item);
			
			menu_item = new Gtk.MenuItem.with_mnemonic ("Open dockitem file");
			menu_item.activate.connect (() => {
				System.get_default ().open (dock_item_file);
			});
			menu_item.sensitive = (dock_item_file != null && dock_item_file.query_exists ());
			debug_items.add (menu_item);
			
			menu_item = new Gtk.MenuItem.with_mnemonic ("Open launcher file");
			menu_item.activate.connect (() => {
				System.get_default ().open (File.new_for_uri (item.Launcher));
			});
			menu_item.sensitive = (item.Launcher != "");
			debug_items.add (menu_item);
			
			return debug_items;
		}
		
		/**
		 * Called when the popup menu hides.
		 */
		void on_menu_hide ()
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
		void on_menu_show ()
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
		[CCode (instance_pos = -1)]
		void position_menu (Gtk.Menu menu, ref int x, ref int y, out bool push_in)
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
			if (gdk_display.error_trap_pop () != X.Success)
				critical ("Error while setting struts");
		}
	}
}
