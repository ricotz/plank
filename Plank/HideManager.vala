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

using Gdk;

using Plank.Services.Windows;
using Plank.Widgets;

namespace Plank
{
	public enum HideType
	{
		NONE,
		INTELLIGENT,
		AUTO
	}
	
	public class HideManager : GLib.Object
	{
		DockWindow window;
		bool windows_intersect;
		
		public bool DockHovered { get; private set; }
		
		public bool Disabled { get; set; }
		
		public HideManager (DockWindow window)
		{
			this.window = window;
			
			update_window_intersect ();
			DockHovered = false;
			
			window.Renderer.hide ();
			
			notify["DockHovered"].connect (update_hidden);
			notify["Disabled"].connect (update_hidden);
			window.Prefs.notify["HideMode"].connect (update_hidden);
			
			window.enter_notify_event.connect (enter_notify_event);
			window.leave_notify_event.connect (leave_notify_event);
			window.motion_notify_event.connect (motion_notify_event);
			
			Matcher.get_default ().app_changed.connect (app_changed);
		}
		
		public void update_dock_hovered ()
		{
			// get current mouse pointer location
			int x, y;
			ModifierType mod;
			Screen screen;
			window.get_display ().get_pointer (out screen, out x, out y, out mod);
			
			// get window location
			int win_x, win_y;
			window.get_position (out win_x, out win_y);
			
			// compute rect of the window
			var cursor_rect = window.Renderer.cursor_region ();
			
			// use the window rect and cursor location to determine if dock is hovered
			var x_pos = win_x + cursor_rect.x;
			var y_pos = win_y + cursor_rect.y;
			DockHovered = x >= x_pos && x <= x_pos + cursor_rect.width &&
						y >= y_pos && y <= y_pos + cursor_rect.height;
		}
		
		void update_hidden ()
		{
			if (Disabled) {
				window.Renderer.show ();
				return;
			}
			
			switch (window.Prefs.HideMode) {
			case HideType.NONE:
				window.Renderer.show ();
				break;
			
			case HideType.INTELLIGENT:
				if (DockHovered && !windows_intersect)
					window.Renderer.show ();
				else
					window.Renderer.hide ();
				break;
			
			case HideType.AUTO:
				if (DockHovered)
					window.Renderer.show ();
				else
					window.Renderer.hide ();
				break;
			}
		}
		
		bool enter_notify_event (EventCrossing event)
		{
			update_dock_hovered ();
			
			return window.Renderer.Hidden;
		}
		
		bool leave_notify_event (EventCrossing event)
		{
			// ignore this event if it was sent explicitly
			if ((bool) event.send_event)
				return false;
			
			if (DockHovered && !window.menu_is_visible ())
				DockHovered = false;
			
			return false;
		}
		
		bool motion_notify_event (EventMotion event)
		{
			update_dock_hovered ();
			
			return window.Renderer.Hidden;
		}
		
		void app_changed (Bamf.Application? old_app, Bamf.Application? new_app)
		{
			update_hidden ();
		}
		
		void update_window_intersect ()
		{
			windows_intersect = false;
		}
	}
}
