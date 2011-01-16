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
using Plank.Services.Drawing;

namespace Plank
{
	public class DockWindow : CompositedWindow
	{
		public DockPreferences Prefs { get; protected set; }
		
		public DockItem? HoveredItem { get; protected set; }
		
		public DockItems Items { get; protected set; }
		
		protected DockRenderer Renderer { get; set; }
		
		HoverWindow hover = new HoverWindow ();
		
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
			
			stick ();
			
			add_events (EventMask.BUTTON_PRESS_MASK |
						EventMask.BUTTON_RELEASE_MASK |
						EventMask.ENTER_NOTIFY_MASK |
						EventMask.LEAVE_NOTIFY_MASK |
						EventMask.POINTER_MOTION_MASK |
						EventMask.SCROLL_MASK);
			
			Items.items_changed.connect (set_size);
			Prefs.notify.connect (set_size);
			Renderer.render_needed.connect (queue_draw);
			
			set_size ();
		}
		
		public override bool button_press_event (EventButton event)
		{
			if (HoveredItem == null)
				return true;
			
			if (event.button == 1)
				Services.System.launch (File.new_for_path (HoveredItem.get_launcher ()), {});
			else if (event.button == 2)
				Services.System.launch (File.new_for_path (HoveredItem.get_launcher ()), {});
			else if (event.button == 3)
				stdout.printf("right click: %s\n", HoveredItem.get_launcher ());
			
			return true;
		}
		
		public override bool button_release_event (EventButton event)
		{
			return true;
		}
		
		public override bool enter_notify_event (EventCrossing event)
		{
			return true;
		}
		
		public override bool leave_notify_event (EventCrossing event)
		{
			set_hovered (null);
			
			return true;
		}
		
		public override bool motion_notify_event (EventMotion event)
		{
			foreach (DockItem item in Items.Items)
				if (rect_contains_point (Renderer.item_region (item), (int) event.x, (int) event.y)) {
					set_hovered (item);
					return true;
				}
			
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
		
		public override bool expose_event (EventExpose event)
		{
			Renderer.draw_dock (cairo_create (event.window));
			
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
			
			int x, y;
			get_position (out x, out y);
			var rect = Renderer.item_region (HoveredItem);
			hover.move_hover (x + rect.x + rect.width / 2, y);
			
			hover.show ();
		}
		
		protected void set_size ()
		{
			set_size_request (Renderer.DockWidth, Renderer.DockHeight);
			reposition ();
			
			Renderer.reset_buffers ();
		}
		
		protected void reposition ()
		{
			move ((get_screen ().width () - width_request) / 2,
				get_screen ().height () - height_request);
		}
		
		protected bool rect_contains_point (Gdk.Rectangle rect, int x, int y)
		{
			return y >= rect.y && y <= rect.y + rect.height &&
				x >= rect.x && x <= rect.x + rect.width;
		}
	}
}
