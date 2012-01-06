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

using Bamf;
using Gee;
using Wnck;

namespace Plank.Services.Windows
{
	internal class WindowControl : GLib.Object
	{
		// when working on a group of windows, wait this amount between each action
		const uint WINDOW_GROUP_DELAY = 10000;
		// when changing a viewport, wait this time (for viewport change animations) before continuing
		public static const uint VIEWPORT_CHANGE_DELAY = 200;
		
		public static unowned Gdk.Pixbuf? get_app_icon (Bamf.Application app)
		{
			unowned Gdk.Pixbuf? pbuf = null;
			
			Screen.get_default ();
			unowned Array<uint32> xids = app.get_xids ();
			
			for (var i = 0; xids != null && i < xids.length && pbuf == null; i++) {
				var window = Wnck.Window.@get (xids.index (i));
				if (window != null)
					pbuf = window.get_icon ();
			}
			
			return pbuf;
		}
		
		public static unowned Gdk.Pixbuf? get_window_icon (Bamf.Window window)
		{
			var w = Wnck.Window.@get (window.get_xid ());
			return_val_if_fail (w != null, null);
			
			return w.get_icon ();
		}
		
		public static uint get_num_windows (Bamf.Application? app)
		{
			uint count = 0;
			
			if (app != null) {
				unowned GLib.List<Bamf.View> children = app.get_children ();
				for (var i = 0; i < children.length (); i++) {
					var view = children.nth_data (i);
					if (!(view is Bamf.Window && view.is_user_visible ()))
						continue;
					count++;
				}
			}
			
			return count;
		}
		
		public static bool has_maximized_window (Bamf.Application? app)
		{
			return_val_if_fail (app != null, false);
			
			Screen.get_default ();
			unowned Array<uint32> xids = app.get_xids ();
			
			for (var i = 0; xids != null && i < xids.length; i++) {
				var window = Wnck.Window.@get (xids.index (i));
				if (window != null && window.is_maximized ())
					return true;
			}
			
			return false;
		}
		
		public static bool has_minimized_window (Bamf.Application? app)
		{
			return_val_if_fail (app != null, false);
			
			Screen.get_default ();
			unowned Array<uint32> xids = app.get_xids ();
			
			for (var i = 0; xids != null && i < xids.length; i++) {
				var window = Wnck.Window.@get (xids.index (i));
				if (window != null && window.is_minimized ())
					return true;
			}
			
			return false;
		}
		
		public static ArrayList<Bamf.Window> get_windows (Bamf.Application? app)
		{
			var windows = new ArrayList<Bamf.Window> ();
			return_val_if_fail (app != null, windows);
			
			unowned GLib.List<Bamf.View> children = app.get_children ();
			for (var i = 0; i < children.length (); i++) {
				var view = children.nth_data (i);
				if (view is Bamf.Window)
					windows.add (view as Bamf.Window);
			}
			
			return windows;
		}
		
		public static void update_icon_regions (Bamf.Application? app, Gdk.Rectangle? rect, int x, int y)
		{
			return_if_fail (app != null);
			
			if (rect == null)
				rect = Gdk.Rectangle () { x = 0, y = 0, width = 0, height = 0 };
			
			Screen.get_default ();
			unowned Array<uint32> xids = app.get_xids ();
			
			for (var i = 0; xids != null && i < xids.length; i++) {
				var window = Wnck.Window.@get (xids.index (i));
				if (window != null)
					window.set_icon_geometry (x + rect.x, y + rect.y, rect.width, rect.height);
			}
		}
		
		public static void initialize ()
		{
			set_client_type (ClientType.PAGER);
			Screen.get_default ().force_update ();
		}
		
		public static void close_all (Bamf.Application? app)
		{
			return_if_fail (app != null);
			
			Screen.get_default ();
			unowned Array<uint32> xids = app.get_xids ();
			
			for (var i = 0; xids != null && i < xids.length; i++) {
				var window = Wnck.Window.@get (xids.index (i));
				if (window != null && !window.is_skip_tasklist ())
					window.close (Gtk.get_current_event_time ());
			}
		}
		
		public static void focus_window (Bamf.Window window)
		{
			Screen.get_default ();
			var w = Wnck.Window.@get (window.get_xid ());
			return_if_fail (w != null);
			
			center_and_focus_window (w);
		}
		
		public static void focus_window_by_xid (uint32 xid)
		{
			Screen.get_default ();
			var window = Wnck.Window.@get (xid);
			return_if_fail (window != null);
			
			center_and_focus_window (window);
		}
		
		public static void focus (Bamf.Application? app)
		{
			return_if_fail (app != null);
			
			foreach (var window in get_ordered_window_stack (app)) {
				center_and_focus_window (window);
				Thread.usleep (WINDOW_GROUP_DELAY);
			}
		}
		
		static int find_active_xid_index (Array<uint32> xids)
		{
			var i = 0;
			for (; xids != null && i < xids.length; i++) {
				var window = Wnck.Window.@get (xids.index (i));
				if (window != null && window.is_active ())
					break;
			}
			return i;
		}
		
		public static void focus_previous (Bamf.Application? app)
		{
			return_if_fail (app != null);
			
			Screen.get_default ();
			unowned Array<uint32> xids = app.get_xids ();
			
			var i = find_active_xid_index (xids);
			i = i < xids.length ? i - 1 : 0;
			
			if (i < 0)
				i = (int) xids.length - 1;
			
			focus_window_by_xid (xids.index (i));
		}
		
		public static void focus_next (Bamf.Application? app)
		{
			return_if_fail (app != null);
			
			Screen.get_default ();
			unowned Array<uint32> xids = app.get_xids ();
			
			var i = find_active_xid_index (xids);
			i = i < xids.length ? i + 1 : 0;
			
			if (i == xids.length)
				i = 0;
			
			focus_window_by_xid (xids.index (i));
		}
		
		public static void minimize (Bamf.Application? app)
		{
			return_if_fail (app != null);
			
			foreach (var window in get_ordered_window_stack (app))
				if (!window.is_minimized () && window.is_in_viewport (window.get_screen ().get_active_workspace ())) {
					window.minimize ();
					Thread.usleep (WINDOW_GROUP_DELAY);
				}
		}
		
		public static void restore (Bamf.Application? app)
		{
			return_if_fail (app != null);
			
			var stack = get_ordered_window_stack (app);
			for (var i = (int) stack.size - 1; i >= 0; i--) {
				var window = stack.get (i);
				if (window.is_minimized () && window.is_in_viewport (window.get_screen ().get_active_workspace ())) {
					window.unminimize (Gtk.get_current_event_time ());
					Thread.usleep (WINDOW_GROUP_DELAY);
				}
			}
		}
		
		public static void maximize (Bamf.Application? app)
		{
			return_if_fail (app != null);
			
			foreach (var window in get_ordered_window_stack (app))
				if (!window.is_maximized ())
					window.maximize ();
		}
		
		public static void unmaximize (Bamf.Application? app)
		{
			return_if_fail (app != null);
			
			foreach (var window in get_ordered_window_stack (app))
				if (window.is_maximized ())
					window.unmaximize ();
		}
		
		public static ArrayList<Wnck.Window> get_ordered_window_stack (Bamf.Application? app)
		{
			var windows = new ArrayList<Wnck.Window> ();
			return_val_if_fail (app != null, windows);
			
			Screen.get_default ();
			unowned Array<uint32> xids = app.get_xids ();
			unowned GLib.List<Wnck.Window> stack = Screen.get_default ().get_windows_stacked ();
			
			foreach (var window in stack)
				for (var j = 0; j < xids.length; j++)
					if (xids.index (j) == window.get_xid ())
						windows.add (window);
			
			return windows;
		}
		
		public static void smart_focus (Bamf.Application? app)
		{
			return_if_fail (app != null);

			var windows = get_ordered_window_stack (app);
			
			var not_in_viewport = true;
			var urgent = false;
			
			foreach (var window in windows) {
				if (!window.is_skip_tasklist () && window.is_in_viewport (window.get_screen ().get_active_workspace ()))
					not_in_viewport = false;
				if (window.needs_attention ())
					urgent = true;
			}
			
			if (not_in_viewport || urgent) {
				foreach (var window in windows) {
					if (urgent && !window.needs_attention ())
						continue;
					
					if (!window.is_skip_tasklist ()) {
						intelligent_focus_off_viewport_window (window, windows);
						return;
					}
				}
			}
			
			foreach (var window in windows)
				if (window.is_minimized () && window.is_in_viewport (window.get_screen ().get_active_workspace ())) {
					foreach (var w in windows)
						if (w.is_minimized () && w.is_in_viewport (w.get_screen ().get_active_workspace ())) {
							w.unminimize (Gtk.get_current_event_time ());
							Thread.usleep (WINDOW_GROUP_DELAY);
						}
					return;
				}
			
			foreach (var window in windows)
				if ((window.is_active () && window.is_in_viewport (window.get_screen ().get_active_workspace ())) ||
					window == Screen.get_default ().get_active_window ()) {
					foreach (var w in windows)
						if (!w.is_minimized () && w.is_in_viewport (w.get_screen ().get_active_workspace ())) {
							w.minimize ();
							Thread.usleep (WINDOW_GROUP_DELAY);
						}
					return;
				}
			
			foreach (var window in windows) {
				center_and_focus_window (window);
				Thread.usleep (WINDOW_GROUP_DELAY);
			}
		}
		
		static void intelligent_focus_off_viewport_window (Wnck.Window targetWindow, ArrayList<Wnck.Window> additional_windows)
		{
			for (var i = (int) additional_windows.size - 1; i >= 0; i--) {
				var window = additional_windows.get (i);
				if (!window.is_minimized () && windows_share_viewport (targetWindow, window)) {
					center_and_focus_window (window);
					Thread.usleep (WINDOW_GROUP_DELAY);
				}
			}
			
			center_and_focus_window (targetWindow);
			
			if (additional_windows.size <= 1)
				return;
			
			// we do this to make sure our active window is also at the front... Its a tricky thing to do.
			// sometimes compiz plays badly.  This hacks around it
			var time = Gtk.get_current_event_time () + VIEWPORT_CHANGE_DELAY;
			Timeout.add (VIEWPORT_CHANGE_DELAY, () => {
				targetWindow.activate (time);
				return false;
			});
		}
		
		static bool windows_share_viewport (Wnck.Window? first, Wnck.Window? second)
		{
			if (first == null || second == null)
				return false;
			
			var wksp = first.get_workspace () ?? second.get_workspace ();
			if (wksp == null)
				return false;
			
			var firstGeo = Gdk.Rectangle ();
			var secondGeo = Gdk.Rectangle ();
			
			first.get_geometry (out firstGeo.x, out firstGeo.y, out firstGeo.width, out firstGeo.height);
			second.get_geometry (out secondGeo.x, out secondGeo.y, out secondGeo.width, out secondGeo.height);
			
			firstGeo.x += wksp.get_viewport_x ();
			firstGeo.y += wksp.get_viewport_y ();
			
			secondGeo.x += wksp.get_viewport_x ();
			secondGeo.y += wksp.get_viewport_y ();
			
			var viewportWidth = first.get_screen ().get_width ();
			var viewportHeight = first.get_screen ().get_height ();
			
			var firstViewportX = ((firstGeo.x + firstGeo.width / 2) / viewportWidth) * viewportWidth;
			var firstViewportY = ((firstGeo.y + firstGeo.height / 2) / viewportHeight) * viewportHeight;
			
			var viewpRect = Gdk.Rectangle ();
			viewpRect.x = firstViewportX;
			viewpRect.y = firstViewportY;
			viewpRect.width = viewportWidth;
			viewpRect.height = viewportHeight;
			
#if VALA_0_12
			return viewpRect.intersect (secondGeo, null);
#else
			// FIXME this var is only needed due to a vapi bug where we cant use null
			var dest = Gdk.Rectangle ();
			return viewpRect.intersect (secondGeo, dest);
#endif
		}
		
		static void center_and_focus_window (Wnck.Window w) 
		{
			var time = Gtk.get_current_event_time ();
			if (w.get_workspace () != null && w.get_workspace () != w.get_screen ().get_active_workspace ()) 
				w.get_workspace ().activate (time);
			
			if (w.is_minimized ()) 
				w.unminimize (time);
			
			w.activate_transient (time);
		}
	}
}
