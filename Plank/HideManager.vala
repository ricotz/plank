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
		
		bool hidden;
		bool windows_intersect;
		bool dock_hovered;
		
		public HideManager (DockWindow window)
		{
			this.window = window;
			
			dock_hovered = false;
			update_window_intersect ();
			
			hide ();
			
			window.Prefs.notify["HideMode"].connect (prefs_changed);
			
			window.enter_notify_event.connect (enter_notify_event);
			window.leave_notify_event.connect (leave_notify_event);
			window.motion_notify_event.connect (motion_notify_event);
			
			Matcher.get_default ().app_changed.connect (app_changed);
		}
		
		public bool is_hidden ()
		{
			return window.Prefs.HideMode != HideType.NONE && hidden;
		}
		
		public void update_hidden ()
		{
			switch (window.Prefs.HideMode) {
			case HideType.NONE:
				show ();
				break;
			
			case HideType.INTELLIGENT:
				if (dock_hovered && !windows_intersect)
					show ();
				else
					hide ();
				break;
			
			case HideType.AUTO:
				if (dock_hovered)
					show ();
				else
					hide ();
				break;
			}
		}
		
		void show ()
		{
			if (!hidden)
				return;
			
			hidden = false;
			window.Renderer.show ();
		}
		
		void hide ()
		{
			if (window.Prefs.HideMode == HideType.NONE || hidden)
				return;
			
			hidden = true;
			window.Renderer.hide ();
		}
		
		bool enter_notify_event (EventCrossing event)
		{
			if (hidden && event.y >= window.Renderer.DockHeight - 1) {
				dock_hovered = true;
				update_hidden ();
			}
			
			return hidden;
		}
		
		bool leave_notify_event (EventCrossing event)
		{
			if (!window.menu_is_visible ()) {
				dock_hovered = false;
				update_hidden ();
			}
			
			return false;
		}
		
		bool motion_notify_event (EventMotion event)
		{
			dock_hovered = true;
			update_hidden ();
			
			return hidden;
		}
		
		void prefs_changed ()
		{
			update_hidden ();
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
