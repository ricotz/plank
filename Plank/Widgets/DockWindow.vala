//  
//  Copyright (C) 2011 Robert Dyer
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
using Gtk;

using Plank.Items;
using Plank.Drawing;
using Plank.Services.Windows;

namespace Plank.Widgets
{
	public enum AutohideType
	{
		NONE,
		INTELLIHIDE
	}
	
	public class DockWindow : CompositedWindow
	{
		public DockPreferences Prefs { get; protected set; }
		
		public DockItem? HoveredItem { get; protected set; }
		
		public DockItems Items { get; protected set; }
		
		public bool MenuVisible { get; protected set; }
		
		protected DockRenderer Renderer { get; set; }
		
		HoverWindow hover = new HoverWindow ();
		
		Menu menu = new Menu ();
		
		public DockWindow ()
		{
			base ();
			
			Prefs = new DockPreferences.with_file ("settings");
			Items = new DockItems ();
			Renderer = new DockRenderer (this);
			
			set_accept_focus (false);
			can_focus = false;
			skip_pager_hint = true;
			skip_taskbar_hint = true;
			set_type_hint (WindowTypeHint.DOCK);
			
			menu.attach_to_widget (this, null);
			menu.hide.connect (() => {
				MenuVisible = false;
				update_icon_regions ();
				queue_draw ();
			});
			
			stick ();
			
			add_events (EventMask.BUTTON_PRESS_MASK |
						EventMask.BUTTON_RELEASE_MASK |
						EventMask.ENTER_NOTIFY_MASK |
						EventMask.LEAVE_NOTIFY_MASK |
						EventMask.POINTER_MOTION_MASK |
						EventMask.SCROLL_MASK);
			
			Items.items_changed.connect (set_size);
			Prefs.notify.connect (set_size);
			
			set_size ();
		}
		
		public override bool button_press_event (EventButton event)
		{
			if (HoveredItem == null)
				return true;
			
			if (event.button == 3)
				do_popup ();
			else
				HoveredItem.clicked (event.button, event.state);
			
			return true;
		}
		
		public override bool button_release_event (EventButton event)
		{
			if (HoveredItem == null)
				return true;
			
			if (!MenuVisible)
				HoveredItem.clicked (event.button, event.state);
			
			return true;
		}
		
		public override bool enter_notify_event (EventCrossing event)
		{
			if (update_hovered ((int) event.x, (int) event.y))
				return true;
			
			return true;
		}
		
		public override bool leave_notify_event (EventCrossing event)
		{
			if (!MenuVisible)
				set_hovered (null);
			else
				hover.hide ();
			
			return true;
		}
		
		public override bool motion_notify_event (EventMotion event)
		{
			if (update_hovered ((int) event.x, (int) event.y))
				return true;
			
			set_hovered (null);
			return true;
		}
		
		public override bool scroll_event (EventScroll event)
		{
			if ((event.state & ModifierType.CONTROL_MASK) != 0) {
				if (event.direction == ScrollDirection.UP)
					Prefs.increase_icon_size ();
				else if (event.direction == ScrollDirection.DOWN)
					Prefs.decrease_icon_size ();
				
				return true;
			}
			
			if (HoveredItem == null)
				return true;
			
			return true;
		}
		
		uint startup_show_timer = 0;
		
		public override bool expose_event (EventExpose event)
		{
			if (Renderer.hidden && startup_show_timer == 0)
				startup_show_timer = GLib.Timeout.add (100, () => {
					Renderer.show ();
					return false;
				});
			
			Renderer.draw_dock (cairo_create (event.window));
			set_input_mask ();
			
			return true;
		}
		
		protected void set_hovered (DockItem? item)
		{
			if (HoveredItem == item)
				return;
			
			HoveredItem = item;
			
			if (HoveredItem == null) {
				hover.hide ();
				return;
			}
			
			hover.Text = HoveredItem.Text;
			
			position_hover ();
			
			if (!hover.get_visible ())
				hover.show ();
		}
		
		bool update_hovered (int x, int y)
		{
			foreach (DockItem item in Items.Items) {
				var rect = Renderer.item_region (item);
				
				if (y >= rect.y && y <= rect.y + rect.height && x >= rect.x && x <= rect.x + rect.width) {
					set_hovered (item);
					return true;
				}
			}
			
			return false;
		}
		
		void position_hover ()
		{
			int x, y;
			get_position (out x, out y);
			var rect = Renderer.item_region (HoveredItem);
			hover.move_hover (x + rect.x + rect.width / 2, y + rect.y);
		}
		
		public void set_size ()
		{
			set_size_request (Renderer.DockWidth, Renderer.DockHeight);
			reposition ();
			if (HoveredItem != null)
				position_hover ();
			
			Renderer.reset_buffers ();
		}
		
		protected void reposition ()
		{
			move ((get_screen ().width () - width_request) / 2,
				get_screen ().height () - height_request);
			update_icon_regions ();
			set_struts ();
		}
		
		void update_icon_regions ()
		{
			int win_x, win_y;
			get_position (out win_x, out win_y);
			
			foreach (DockItem item in Items.Items) {
				if (item.App == null)
					continue;
				
				Gdk.Rectangle empty = Gdk.Rectangle ();
				empty.x = empty.y = empty.width = empty.height = 0;
				
				if (MenuVisible)
					WindowControl.update_icon_regions (item.App, empty, win_x, win_y);
				else
					WindowControl.update_icon_regions (item.App, Renderer.item_region (item), win_x, win_y);
			}
		}
		
		protected void do_popup ()
		{
			MenuVisible = true;
			update_icon_regions ();
			queue_draw ();
			
			foreach (Widget w in menu.get_children ()) {
				menu.remove (w);
				w.destroy ();
			}
			
			foreach (MenuItem item in HoveredItem.get_menu_items ())
				menu.append (item);
			
			menu.show_all ();
			menu.popup (null, null, position_menu, 3, get_current_event_time ());
		}
		
		void position_menu (Menu menu, out int x, out int y, out bool push_in)
		{
			int win_x, win_y;
			get_position (out win_x, out win_y);
			var rect = Renderer.item_region (HoveredItem);
			
			x = win_x + rect.x + rect.width / 2 - menu.requisition.width / 2;
			y = win_y + rect.y - menu.requisition.height - 10;
			push_in = false;
		}
		
		void set_input_mask ()
		{
			if (!is_realized ())
				return;
			
			var pixmap = new Pixmap(null, width_request, Renderer.VisibleDockHeight, 1);
			var cr = cairo_create (pixmap);
			
			cr.set_source_rgba (0, 0, 0, 1);
			cr.paint ();
			
			input_shape_combine_mask ((Bitmap*) pixmap, 0, height_request - Renderer.VisibleDockHeight);
		}
		
		void set_struts ()
		{
			if (!is_realized ())
				return;
			
			// since uchar is 8 bits in vala but the struts are 32 bits
			// we have to allocate 4 times as much and do bit-masking
			uchar[] struts = new uchar[12 * 4];
			
			if (Prefs.Autohide == AutohideType.NONE) {
				uint32 left, right, height;
				
				Gdk.Rectangle monitor_geo = Gdk.Rectangle ();
				get_screen ().get_monitor_geometry (get_screen ().get_primary_monitor (), out monitor_geo);
				
				left = monitor_geo.x;
				right = monitor_geo.x + monitor_geo.width - 1;
				height = Renderer.VisibleDockHeight + get_screen ().get_height () - monitor_geo.y - monitor_geo.height;
				
				struts [12] = (uchar) ((height & 0xff000000) >> 24);
				struts [12] = (uchar) ((height & 0x00ff0000) >> 16);
				struts [12] = (uchar) ((height & 0x0000ff00) >> 8);
				struts [12] = (uchar) (height & 0x000000ff);
				
				struts [40] = (uchar) ((left & 0xff000000) >> 24);
				struts [41] = (uchar) ((left & 0x00ff0000) >> 16);
				struts [42] = (uchar) ((left & 0x0000ff00) >> 8);
				struts [43] = (uchar) (left & 0x000000ff);
				
				struts [44] = (uchar) ((right & 0xff000000) >> 24);
				struts [45] = (uchar) ((right & 0x00ff0000) >> 16);
				struts [46] = (uchar) ((right & 0x0000ff00) >> 8);
				struts [47] = (uchar) (right & 0x000000ff);
			}
			
			uchar[] first_struts = new uchar [4 * 4];
			for (int i = 0; i < 4 * 4; i++)
				first_struts [i] = struts [i];
			
			var display = x11_drawable_get_xdisplay (get_window ());
			var xid = x11_drawable_get_xid (get_window ());
			
			display.change_property (xid, display.intern_atom ("_NET_WM_STRUT_PARTIAL", false), X.XA_CARDINAL,
			                      32, X.PropMode.Replace, struts, struts.length);
			display.change_property (xid, display.intern_atom ("_NET_WM_STRUT", false), X.XA_CARDINAL, 
			                      32, X.PropMode.Replace, first_struts, first_struts.length);
		}
	}
}
