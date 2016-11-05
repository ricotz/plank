//
//  Copyright (C) 2011-2012 Robert Dyer, Rico Tzschichholz
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
	public enum Struts
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
	
	public class WindowControl : GLib.Object
	{
		// when working on a group of windows, wait this amount between each action
		public const uint WINDOW_GROUP_DELAY = 10000U;
		// when changing a viewport, wait this time (for viewport change animations) before continuing
		public const uint VIEWPORT_CHANGE_DELAY = 200U;
		
		static uint delayed_focus_timer_id = 0U;
		static Wnck.Window? delayed_focus_window = null;
		
		WindowControl ()
		{
		}
		
		public static void initialize ()
		{
			unowned Wnck.Screen screen = Wnck.Screen.get_default ();
			
			Wnck.set_client_type (Wnck.ClientType.PAGER);
			
			// Make sure internal window-list of Wnck is most up to date
			Gdk.error_trap_push ();
			screen.force_update ();
			if (Gdk.error_trap_pop () != 0)
				critical ("Wnck.Screen.force_update() caused a XError");
			
			screen.window_manager_changed.connect_after (window_manager_changed);
			screen.window_closed.connect_after (handle_window_closed);
			
			message ("Window-manager: %s", screen.get_window_manager_name ());
		}
		
		static void window_manager_changed (Wnck.Screen screen)
		{
			// Make sure internal window-list of Wnck is most up to date
			Gdk.error_trap_push ();
			screen.force_update ();
			if (Gdk.error_trap_pop () != 0)
				critical ("Wnck.Screen.force_update() caused a XError");
			
			warning ("Window-manager changed: %s", screen.get_window_manager_name ());
		}
		
		static void handle_window_closed (Wnck.Window window)
		{
			if (delayed_focus_timer_id > 0U && delayed_focus_window == window) {
				GLib.Source.remove (delayed_focus_timer_id);
				delayed_focus_timer_id = 0U;
				delayed_focus_window = null;
			}
		}
		
		public static unowned Gdk.Pixbuf? get_app_icon (Bamf.Application app)
		{
			unowned Gdk.Pixbuf? pbuf = null;
			
			Wnck.Screen.get_default ();
			Array<uint32>? xids = app.get_xids ();
			
			warn_if_fail (xids != null);
			
			Gdk.error_trap_push ();
			
			for (var i = 0; xids != null && i < xids.length && pbuf == null; i++) {
				unowned Wnck.Window window = Wnck.Window.@get (xids.index (i));
				if (window == null)
					continue;
				
				pbuf = window.get_icon ();
				if (window.get_icon_is_fallback ())
					pbuf = null;
				
				break;
			}
			
			if (Gdk.error_trap_pop () != 0)
				critical ("get_app_icon() for '%s' caused a XError", app.get_name ());
			
			return pbuf;
		}
		
		public static unowned Gdk.Pixbuf? get_window_icon (Bamf.Window window)
		{
			unowned Wnck.Window w = Wnck.Window.@get (window.get_xid ());
			unowned Gdk.Pixbuf? pbuf = null;
			
			warn_if_fail (w != null);
			
			if (w == null)
				return null;
			
			Gdk.error_trap_push ();
			
			pbuf = w.get_icon ();
			if (w.get_icon_is_fallback ())
				pbuf = null;
			
			if (Gdk.error_trap_pop () != 0)
				critical ("get_window_icon() for '%s' caused a XError", window.get_name ());
			
			return pbuf;
		}
		
		public static bool has_maximized_window (Bamf.Application app)
		{
			Wnck.Screen.get_default ();
			Array<uint32>? xids = app.get_xids ();
			
			warn_if_fail (xids != null);
			
			for (var i = 0; xids != null && i < xids.length; i++) {
				unowned Wnck.Window window = Wnck.Window.@get (xids.index (i));
				if (window != null && window.is_maximized ())
					return true;
			}
			
			return false;
		}
		
		public static bool has_minimized_window (Bamf.Application app)
		{
			Wnck.Screen.get_default ();
			Array<uint32>? xids = app.get_xids ();
			
			warn_if_fail (xids != null);
			
			for (var i = 0; xids != null && i < xids.length; i++) {
				unowned Wnck.Window window = Wnck.Window.@get (xids.index (i));
				if (window != null && window.is_minimized ())
					return true;
			}
			
			return false;
		}
		
		public static bool has_window_on_workspace (Bamf.Application app, Wnck.Workspace workspace)
		{
			Wnck.Screen.get_default ();
			Array<uint32>? xids = app.get_xids ();
			
			warn_if_fail (xids != null);
			
			var is_virtual = workspace.is_virtual ();
			
			for (var i = 0; xids != null && i < xids.length; i++) {
				unowned Wnck.Window window = Wnck.Window.@get (xids.index (i));
				if (window == null)
					continue;
				
				if (!is_virtual) {
					if (window.is_on_workspace (workspace))
						return true;
				} else {
					if (window.is_in_viewport (workspace))
						return true;
				}
			}
			
			return false;
		}
		
		public static void update_icon_regions (Bamf.Application app, Gdk.Rectangle rect)
		{
			Wnck.Screen.get_default ();
			Array<uint32>? xids = app.get_xids ();
			
			warn_if_fail (xids != null);
			
			for (var i = 0; xids != null && i < xids.length; i++) {
				unowned Wnck.Window window = Wnck.Window.@get (xids.index (i));
				if (window != null)
					window.set_icon_geometry (rect.x, rect.y, rect.width, rect.height);
			}
		}
		
		public static void close_all (Bamf.Application app, uint32 event_time)
		{
			Wnck.Screen.get_default ();
			Array<uint32>? xids = app.get_xids ();
			
			warn_if_fail (xids != null);
			
			for (var i = 0; xids != null && i < xids.length; i++) {
				unowned Wnck.Window window = Wnck.Window.@get (xids.index (i));
				if (window != null && !window.is_skip_tasklist ())
					window.close (event_time);
			}
		}
		
		public static void focus_window (Bamf.Window window, uint32 event_time)
		{
			Wnck.Screen.get_default ();
			unowned Wnck.Window w = Wnck.Window.@get (window.get_xid ());
			
			warn_if_fail (w != null);
			
			if (w == null)
				return;
			
			center_and_focus_window (w, event_time);
		}
		
		static void focus_window_by_xid (uint32 xid, uint32 event_time)
		{
			Wnck.Screen.get_default ();
			unowned Wnck.Window w = Wnck.Window.@get (xid);
			
			warn_if_fail (w != null);
			
			if (w == null)
				return;
			
			center_and_focus_window (w, event_time);
		}
		
		static int find_active_xid_index (Array<uint32>? xids)
		{
			var i = 0;
			for (; xids != null && i < xids.length; i++) {
				unowned Wnck.Window? window = Wnck.Window.@get (xids.index (i));
				if (window != null && window.is_active ())
					break;
			}
			return i;
		}
		
		public static void focus_previous (Bamf.Application app, uint32 event_time)
		{
			Wnck.Screen.get_default ();
			Array<uint32>? xids = app.get_xids ();
			
			warn_if_fail (xids != null);
			
			if (xids == null)
				return;
			
			var i = find_active_xid_index (xids);
			i = i < xids.length ? i - 1 : 0;
			
			if (i < 0)
				i = (int) xids.length - 1;
			
			focus_window_by_xid (xids.index (i), event_time);
		}
		
		public static void focus_next (Bamf.Application app, uint32 event_time)
		{
			Wnck.Screen.get_default ();
			Array<uint32>? xids = app.get_xids ();
			
			warn_if_fail (xids != null);
			
			if (xids == null)
				return;
			
			var i = find_active_xid_index (xids);
			i = i < xids.length ? i + 1 : 0;
			
			if (i == xids.length)
				i = 0;
			
			focus_window_by_xid (xids.index (i), event_time);
		}
		
		public static void minimize (Bamf.Application app)
		{
			foreach (unowned Wnck.Window window in get_ordered_window_stack (app)) {
				unowned Wnck.Workspace? active_workspace = window.get_screen ().get_active_workspace ();
				if (!window.is_minimized () && active_workspace != null && window.is_in_viewport (active_workspace)) {
					window.minimize ();
					Thread.usleep (WINDOW_GROUP_DELAY);
				}
			}
		}
		
		public static void restore (Bamf.Application app, uint32 event_time)
		{
			var stack = get_ordered_window_stack (app);
			stack.reverse ();
			foreach (unowned Wnck.Window window in stack) {
				unowned Wnck.Workspace? active_workspace = window.get_screen ().get_active_workspace ();
				if (window.is_minimized () && active_workspace != null && window.is_in_viewport (active_workspace)) {
					window.unminimize (event_time);
					Thread.usleep (WINDOW_GROUP_DELAY);
				}
			}
		}
		
		public static void maximize (Bamf.Application app)
		{
			foreach (unowned Wnck.Window window in get_ordered_window_stack (app))
				if (!window.is_maximized ())
					window.maximize ();
		}
		
		public static void unmaximize (Bamf.Application app)
		{
			foreach (unowned Wnck.Window window in get_ordered_window_stack (app))
				if (window.is_maximized ())
					window.unmaximize ();
		}
		
		public static GLib.List<unowned Wnck.Window> get_ordered_window_stack (Bamf.Application app)
		{
			var windows = new GLib.List<unowned Wnck.Window> ();
			
			Wnck.Screen.get_default ();
			Array<uint32>? xids = app.get_xids ();
			
			warn_if_fail (xids != null);
			
			if (xids == null)
				return windows;
			
			unowned GLib.List<Wnck.Window> stack = Wnck.Screen.get_default ().get_windows_stacked ();
			
			foreach (unowned Wnck.Window window in stack)
				for (var j = 0; j < xids.length; j++)
					if (xids.index (j) == window.get_xid ())
						windows.append (window);
			
			return windows;
		}
		
		public static void smart_focus (Bamf.Application app, uint32 event_time)
		{
			var windows = get_ordered_window_stack (app);
			
			var not_in_viewport = true;
			var urgent = false;
			
			foreach (unowned Wnck.Window window in windows) {
				unowned Wnck.Workspace? active_workspace = window.get_screen ().get_active_workspace ();
				if (!window.is_skip_tasklist () && active_workspace != null && window.is_in_viewport (active_workspace))
					not_in_viewport = false;
				if (window.needs_attention ())
					urgent = true;
			}
			
			// Focus off-viewport window if it needs attention
			if (not_in_viewport || urgent) {
				foreach (unowned Wnck.Window window in windows) {
					if (urgent && !window.needs_attention ())
						continue;
					
					if (!window.is_skip_tasklist ()) {
						intelligent_focus_off_viewport_window (window, windows, event_time);
						return;
					}
				}
			}
			
			// Unminimize minimized windows if there is one or more
			foreach (unowned Wnck.Window window in windows) {
				unowned Wnck.Workspace? active_workspace = window.get_screen ().get_active_workspace ();
				if (window.is_minimized () && active_workspace != null && window.is_in_viewport (active_workspace)) {
					foreach (unowned Wnck.Window w in windows)
						if (w.is_minimized () && w.is_in_viewport (active_workspace)) {
							w.unminimize (event_time);
							Thread.usleep (WINDOW_GROUP_DELAY);
						}
					return;
				}
			}
			
			// Minimize all windows if this application owns the active window
			foreach (unowned Wnck.Window window in windows) {
				unowned Wnck.Workspace? active_workspace = window.get_screen ().get_active_workspace ();
				if ((window.is_active () && active_workspace != null && window.is_in_viewport (active_workspace))
					|| window == window.get_screen ().get_active_window ()) {
					foreach (unowned Wnck.Window w in windows)
						if (!w.is_minimized () && w.is_in_viewport (active_workspace)) {
							w.minimize ();
							Thread.usleep (WINDOW_GROUP_DELAY);
						}
					return;
				}
			}

			// Get all windows on the current workspace in the foreground
			foreach (unowned Wnck.Window window in windows) {
				unowned Wnck.Workspace? active_workspace = window.get_screen ().get_active_workspace ();
				if (active_workspace != null && window.is_in_viewport (active_workspace)) {
					foreach (unowned Wnck.Window w in windows)
						if (w.is_in_viewport (active_workspace)) {
							center_and_focus_window (w, event_time);
							Thread.usleep (WINDOW_GROUP_DELAY);
						}
					return;
				}
			}
			
			// Focus most-top window and all others on its workspace
			intelligent_focus_off_viewport_window (windows.nth_data (0), windows, event_time);
		}
		
		static void intelligent_focus_off_viewport_window (Wnck.Window targetWindow,
			GLib.List<unowned Wnck.Window> additional_windows, uint32 event_time)
		{
			additional_windows.reverse ();
			
			foreach (unowned Wnck.Window window in additional_windows) {
				if (!window.is_minimized () && windows_share_viewport (targetWindow, window)) {
					center_and_focus_window (window, event_time);
					Thread.usleep (WINDOW_GROUP_DELAY);
				}
			}
			
			center_and_focus_window (targetWindow, event_time);
			
			if (additional_windows.length () <= 1)
				return;
			
			// we do this to make sure our active window is also at the front... Its a tricky thing to do.
			// sometimes compiz plays badly.  This hacks around it
			if (delayed_focus_timer_id > 0U)
				GLib.Source.remove (delayed_focus_timer_id);
			delayed_focus_window = targetWindow;
			delayed_focus_timer_id = Gdk.threads_add_timeout (VIEWPORT_CHANGE_DELAY, () => {
				delayed_focus_timer_id = 0U;
				delayed_focus_window.activate (event_time);
				delayed_focus_window = null;
				return false;
			});
		}
		
		static bool windows_share_viewport (Wnck.Window? first, Wnck.Window? second)
		{
			if (first == null || second == null)
				return false;
			
			unowned Wnck.Workspace wksp = first.get_workspace ();
			if (wksp == null)
				wksp = second.get_workspace ();
			
			if (wksp == null)
				return false;
			
			Gdk.Rectangle firstGeo = {};
			Gdk.Rectangle secondGeo = {};
			
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
			
			Gdk.Rectangle viewpRect = { firstViewportX, firstViewportY, viewportWidth, viewportHeight };
			return viewpRect.intersect (secondGeo, null);
		}
		
		static void center_and_focus_window (Wnck.Window w, uint32 event_time)
		{
			unowned Wnck.Workspace? workspace = w.get_workspace ();
			
			if (workspace != null && workspace != w.get_screen ().get_active_workspace ())
				workspace.activate (event_time);
			
			if (w.is_minimized ())
				w.unminimize (event_time);
			
			w.activate_transient (event_time);
		}
		
		public static Gdk.Rectangle get_easy_geometry (Wnck.Window w)
		{
			Gdk.Rectangle geo = {};
			
			w.get_geometry (out geo.x, out geo.y, out geo.width, out geo.height);
			
			return geo;
		}
	}
}
