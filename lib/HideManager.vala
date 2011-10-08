//  
//  Copyright (C) 2011 Robert Dyer, Rico Tzschichholz
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
using Wnck;

using Plank.Services.Windows;
using Plank.Widgets;

namespace Plank
{
	/**
	 * If/How the dock should hide itself.
	 */
	public enum HideType
	{
		/**
		 * The dock does not hide.  It should set struts to reserve space for it.
		 */
		NONE,
		/**
		 * The dock hides if a window in the active window group overlaps it.
		 */
		INTELLIGENT,
		/**
		 * The dock hides if the mouse is not over it.
		 */
		AUTO
	}
	
	/**
	 * Class to handle checking if a dock should hide or not.
	 */
	public class HideManager : GLib.Object
	{
		// a delay between window changes and updating our data
		// this allows window animations to occur, which might change
		// the results of our update
		const uint UPDATE_TIMEOUT = 200;
		
		DockWindow window;
		
		/**
		 * If the dock is currently hovered by the mouse cursor.
		 */
		public bool DockHovered { get; set; default = false; }
		
		/**
		 * Creates a new instance of a HideManager, which handles
		 * checking if a dock should hide or not.
		 *
		 * @param window the {@link Widgets.DockWindow} to manage hiding for
		 */
		public HideManager (DockWindow window)
		{
			this.window = window;
			
			windows_intersect = false;
			window.Renderer.hide ();
			
			notify["DockHovered"].connect (update_hidden);
			window.Prefs.changed.connect (prefs_changed);
			
			window.enter_notify_event.connect (enter_notify_event);
			window.leave_notify_event.connect (leave_notify_event);
			window.motion_notify_event.connect (motion_notify_event);
			
			Matcher.get_default ().window_opened.connect (update_window_intersect);
			Matcher.get_default ().window_closed.connect (update_window_intersect);
			
			Wnck.Screen.get_default ().active_window_changed.connect (handle_window_changed);
			setup_active_window ();
		}
		
		~HideManager ()
		{
			notify["DockHovered"].disconnect (update_hidden);
			window.Prefs.changed.disconnect (prefs_changed);
			
			window.enter_notify_event.disconnect (enter_notify_event);
			window.leave_notify_event.disconnect (leave_notify_event);
			window.motion_notify_event.disconnect (motion_notify_event);
			
			Matcher.get_default ().window_opened.disconnect (update_window_intersect);
			Matcher.get_default ().window_closed.disconnect (update_window_intersect);
			
			Wnck.Screen.get_default ().active_window_changed.disconnect (handle_window_changed);
			
			stop_timers ();
		}
		
		/**
		 * Checks to see if the dock is being hovered by the mouse cursor.
		 */
		public void update_dock_hovered ()
		{
			// get current mouse pointer location
			int x, y;
#if USE_GTK3
			window.get_display ().get_device_manager ().get_client_pointer ().get_position (null, out x, out y);
#else
			window.get_display ().get_pointer (null, out x, out y, null);
#endif
			
			// get window location
			var win_x = window.win_x;
			var win_y = window.win_y;
			
			// compute rect of the window
			var dock_rect = window.Renderer.get_cursor_region ();
			dock_rect.x += win_x;
			dock_rect.y += win_y;
			
			// use the dock rect and cursor location to determine if dock is hovered
			DockHovered = x >= dock_rect.x && x <= dock_rect.x + dock_rect.width &&
						  y >= dock_rect.y && y <= dock_rect.y + dock_rect.height;
		}
		
		uint timer_prefs_changed = 0;
		
		void prefs_changed ()
		{
			if (timer_prefs_changed > 0) {
				GLib.Source.remove (timer_prefs_changed);
				timer_prefs_changed = 0;
			}
			
			timer_prefs_changed = GLib.Timeout.add (UPDATE_TIMEOUT, () => {
				update_window_intersect ();
				timer_prefs_changed = 0;
				return false;
			});
		}
		
		void update_hidden ()
		{
			switch (window.Prefs.HideMode) {
			case HideType.NONE:
				window.Renderer.show ();
				break;
			
			case HideType.INTELLIGENT:
				if (DockHovered || !windows_intersect)
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
			if ((bool) event.send_event)
				DockHovered = true;
			else
				update_dock_hovered ();
			
			return window.Renderer.Hidden;
		}
		
		bool leave_notify_event (EventCrossing event)
		{
			if (DockHovered && !window.menu_is_visible ())
				DockHovered = false;
			
			return false;
		}
		
		bool motion_notify_event (EventMotion event)
		{
			update_dock_hovered ();
			
			return window.Renderer.Hidden;
		}
		
		//
		// intelligent hiding code
		//
		
		bool windows_intersect;
		Gdk.Rectangle last_window_rect;
		
		uint timer_geo;
		uint timer_window_changed;
		
		void update_window_intersect ()
		{
			// get window location
			var win_x = window.win_x;
			var win_y = window.win_y;
			
			// compute rect of the window
			var dock_rect = window.Renderer.get_static_dock_region ();
			dock_rect.x += win_x;
			dock_rect.y += win_y;
			
			var intersect = false;
			var screen = Wnck.Screen.get_default ();
			var active_window = screen.get_active_window ();
			var active_workspace = screen.get_active_workspace ();
			
			if (active_window != null && active_workspace != null)
				foreach (var w in screen.get_windows ()) {
					if (w.is_minimized ())
						continue;
					if ((w.get_window_type () & (Wnck.WindowType.DESKTOP | Wnck.WindowType.DOCK | Wnck.WindowType.SPLASHSCREEN | Wnck.WindowType.MENU)) != 0)
						continue;
					if (!w.is_visible_on_workspace (active_workspace))
						continue;
					if (w.get_pid () != active_window.get_pid ())
						continue;
					
#if VALA_0_12
					if (window_geometry (w).intersect (dock_rect, null)) {
#else
					// FIXME this var is only needed due to a vapi bug where we cant use null
					var dest_rect = Gdk.Rectangle ();
					if (window_geometry (w).intersect (dock_rect, dest_rect)) {
#endif
						intersect = true;
						break;
					}
				}
			
			if (windows_intersect != intersect)
				windows_intersect = intersect;
			
			update_hidden ();
		}
		
		void handle_window_changed (Wnck.Window? previous)
		{
			if (previous != null)
				previous.geometry_changed.disconnect (handle_geometry_changed);
			
			if (timer_window_changed > 0)
				return;
			
			timer_window_changed = GLib.Timeout.add (UPDATE_TIMEOUT, () => {
				setup_active_window ();
				timer_window_changed = 0;
				return false;
			});
		}
		
		void setup_active_window ()
		{
			var active_window = Wnck.Screen.get_default ().get_active_window ();
			
			if (active_window != null) {
				last_window_rect = window_geometry (active_window);
				active_window.geometry_changed.connect (handle_geometry_changed);
			}
			
			update_window_intersect ();
		}
		
		void handle_geometry_changed (Wnck.Window? w)
		{
			if (w == null)
				return;
			
			var geo = window_geometry (w);
			if (geo == last_window_rect)
				return;
			
			last_window_rect = geo;
			
			if (timer_geo > 0)
				return;
			
			timer_geo = GLib.Timeout.add (UPDATE_TIMEOUT, () => {
				update_window_intersect ();
				timer_geo = 0;
				return false;
			});
		}
		
		Gdk.Rectangle window_geometry (Wnck.Window w)
		{
			var win_rect = Gdk.Rectangle ();
			w.get_geometry (out win_rect.x, out win_rect.y, out win_rect.width, out win_rect.height);
			return win_rect;
		}
		
		void stop_timers ()
		{
			if (timer_geo > 0) {
				GLib.Source.remove (timer_geo);
				timer_geo = 0;
			}
			
			if (timer_window_changed > 0) {
				GLib.Source.remove (timer_window_changed);
				timer_window_changed = 0;
			}
			
			if (timer_prefs_changed > 0) {
				GLib.Source.remove (timer_prefs_changed);
				timer_prefs_changed = 0;
			}
		}
	}
}
