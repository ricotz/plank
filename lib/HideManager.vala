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

using Plank.Services;
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
		AUTO,
		/**
		 * The dock hides if there is an active maximized window.
		 */
		DODGE_MAXIMIZED,
		/**
		 * The dock hides if there is any window overlapping it.
		 */
		WINDOW_DODGE,
		/**
		 * The dock hides if there is the active window overlapping it.
		 */
		DODGE_ACTIVE,
	}
	
	/**
	 * Handles checking if a dock should hide or not.
	 */
	public class HideManager : GLib.Object
	{
		// a delay between window changes and updating our data
		// this allows window animations to occur, which might change
		// the results of our update
		const uint UPDATE_TIMEOUT = 200;
		
#if HAVE_BARRIERS
		// FIXME Use an IconSize-based value?
		const double PRESSURE_THRESHOLD = 60.0;
		const int PRESSURE_TIMEOUT = 1000;
#endif
		
		static int plank_pid;
		
		static construct
		{
			plank_pid = getpid ();
		}
		
		public DockController controller { private get; construct; }
		
		/**
		 * If the dock is currently hidden.
		 */
		public bool Hidden { get; private set; default = true; }
		
		/**
		 * If hiding the dock is currently disabled
		 */
		public bool Disabled { get; private set; default = false; }
		
		/**
		 * If the dock is currently hovered by the mouse cursor.
		 */
		public bool Hovered { get; private set; default = false; }
		
		uint timer_hide = 0;
		uint timer_unhide = 0;
		bool pointer_update = true;
		
		uint timer_prefs_changed = 0;
		
		bool window_intersect = false;
		bool active_window_intersect = false;
		bool active_application_intersect = false;
		bool active_maximized_window_intersect = false;
		bool dialog_windows_intersect = false;
		Gdk.Rectangle last_window_rect;
		
		uint timer_geo = 0;
		uint timer_window_changed = 0;
		
#if HAVE_BARRIERS
		XFixes.PointerBarrier barrier = 0;
		int opcode = 0;
		double pressure = 0.0;
		uint pressure_timer = 0;
		bool barriers_supported = false;
#endif
		
		/**
		 * Creates a new instance of a HideManager, which handles
		 * checking if a dock should hide or not.
		 *
		 * @param controller the {@link DockController} to manage hiding for
		 */
		public HideManager (DockController controller)
		{
			GLib.Object (controller : controller);
		}
		
		construct
		{
			controller.prefs.notify.connect (prefs_changed);
		}
		
		/**
		 * Initializes the hide manager.  Call after the DockWindow is constructed.
		 */
		public void initialize ()
			requires (controller.window != null)
		{
			unowned DockWindow window = controller.window;
			unowned Wnck.Screen wnck_screen = Wnck.Screen.get_default ();
			
#if HAVE_BARRIERS
			initialize_barriers_support ();
#endif
			
			window.enter_notify_event.connect (handle_enter_notify_event);
			window.leave_notify_event.connect (handle_leave_notify_event);
			
			wnck_screen.window_opened.connect_after (schedule_update);
			wnck_screen.window_closed.connect_after (schedule_update);
			wnck_screen.active_window_changed.connect_after (handle_active_window_changed);
			wnck_screen.active_workspace_changed.connect_after (handle_workspace_changed);
			
			setup_active_window (wnck_screen);
		}
		
		~HideManager ()
		{
			unowned DockWindow window = controller.window;
			unowned DragManager drag_manager = controller.drag_manager;
			unowned Wnck.Screen wnck_screen = Wnck.Screen.get_default ();
			
			controller.prefs.notify.disconnect (prefs_changed);
			
			window.enter_notify_event.disconnect (handle_enter_notify_event);
			window.leave_notify_event.disconnect (handle_leave_notify_event);
			
			wnck_screen.window_opened.disconnect (schedule_update);
			wnck_screen.window_closed.disconnect (schedule_update);
			wnck_screen.active_window_changed.disconnect (handle_active_window_changed);
			wnck_screen.active_workspace_changed.disconnect (handle_workspace_changed);
			
			stop_timers ();
			
#if HAVE_BARRIERS
			gdk_window_remove_filter (null, (Gdk.FilterFunc)xevent_filter);
			
			if (barrier != 0) {
				unowned Gdk.X11.Display gdk_display = (controller.window.get_display () as Gdk.X11.Display);
				unowned X.Display display = gdk_display.get_xdisplay ();
				XFixes.destroy_pointer_barrier (display, barrier);
				barrier = 0;
			}
#endif
		}
		
		/**
		 * Checks to see if the dock is being hovered by the mouse cursor.
		 */
		public void update_hovered ()
		{
			unowned PositionManager position_manager = controller.position_manager;
			unowned DockWindow window = controller.window;
			
			// get current mouse pointer location
			int x, y;
			
			window.get_display ().
				get_device_manager ().get_client_pointer ().get_position (null, out x, out y);
			
			// get window location
			var win_rect = position_manager.get_dock_window_region ();
			x -= win_rect.x;
			y -= win_rect.y;
			
			update_hovered_with_coords (x, y);
		}
		
		/**
		 * Checks to see if the dock is being hovered by the mouse cursor.
		 *
		 * @param x the x coordinate of the pointer relative to the dock window
		 * @param y the y coordinate of the pointer relative to the dock window
		 */
		public void update_hovered_with_coords (int x, int y)
		{
			unowned PositionManager position_manager = controller.position_manager;
			unowned DockWindow window = controller.window;
			unowned DragManager drag_manager = controller.drag_manager;
			
			freeze_notify ();
			
			bool update_needed = false;
			
			// compute rect of the window
			var dock_rect = position_manager.get_cursor_region ();
			
			// use the dock rect and cursor location to determine if dock is hovered
			var hovered = (x >= dock_rect.x && x < dock_rect.x + dock_rect.width
				&& y >= dock_rect.y && y < dock_rect.y + dock_rect.height);
			
			if (Hovered != hovered) {
				Hovered = hovered;
				update_needed = true;
			}
			
			// disable hiding if menu is visible or drags are active
			var disabled = (window.menu_is_visible () || drag_manager.InternalDragActive || drag_manager.ExternalDragActive);
			if (Disabled != disabled) {
				Disabled = disabled;
				update_needed = true;
			}
			
			if (update_needed)
				update_hidden ();
			
			thaw_notify ();
		}
		
		void prefs_changed (Object prefs, ParamSpec prop)
		{
			switch (prop.name) {
			case "HideMode":
			case "Position":
				if (timer_prefs_changed > 0) {
					GLib.Source.remove (timer_prefs_changed);
					timer_prefs_changed = 0;
				}
				
				timer_prefs_changed = Gdk.threads_add_timeout (UPDATE_TIMEOUT, () => {
					update_window_intersect ();
#if HAVE_BARRIERS
					update_barrier ();
#endif
					timer_prefs_changed = 0;
					return false;
				});
				break;
			case "PressureReveal":
#if HAVE_BARRIERS
				update_barrier ();
#endif
				break;
			default:
				// Nothing important for us changed
				break;
			}
		}
		
		void update_hidden ()
		{
			if (Disabled) {
				if (Hidden)
					Hidden = false;
				return;
			}
			
			switch (controller.prefs.HideMode) {
			default:
			case HideType.NONE:
				show ();
				break;
			
			case HideType.INTELLIGENT:
				if (Hovered || !active_application_intersect)
					show ();
				else
					hide ();
				break;
			
			case HideType.AUTO:
				if (Hovered)
					show ();
				else
					hide ();
				break;
			
			case HideType.DODGE_MAXIMIZED:
				if (Hovered || !(active_maximized_window_intersect || dialog_windows_intersect))
					show ();
				else
					hide ();
				break;
			
			case HideType.WINDOW_DODGE:
				if (Hovered || !window_intersect)
					show ();
				else
					hide ();
				break;
			
			case HideType.DODGE_ACTIVE:
				if (Hovered || !active_window_intersect)
					show ();
				else
					hide ();
				break;
			}
			pointer_update = true;
		}
		
		void hide ()
		{
			if (timer_unhide > 0) {
				GLib.Source.remove (timer_unhide);
				timer_unhide = 0;
			}
			
			if (Hidden)
				return;
			
			if (controller.prefs.HideDelay == 0) {
				if (!Hidden)
					Hidden = true;
				return;
			}
			
			if (timer_hide > 0)
				return;
			
			timer_hide = Gdk.threads_add_timeout (controller.prefs.HideDelay, () => {
				if (!Hidden)
					Hidden = true;
				timer_hide = 0;
				return false;
			});
		}

		void show ()
		{
			if (timer_hide > 0) {
				GLib.Source.remove (timer_hide);
				timer_hide = 0;
			}
			
			if (!Hidden)
				return;
			
			if (!pointer_update || controller.prefs.UnhideDelay == 0) {
				if (Hidden)
					Hidden = false;
				return;
			}
			
			if (timer_unhide > 0)
				return;
			
			timer_unhide = Gdk.threads_add_timeout (controller.prefs.UnhideDelay, () => {
				if (Hidden)
					Hidden = false;
				timer_unhide = 0;
				return false;
			});
		}
		
		[CCode (instance_pos = -1)]
		bool handle_enter_notify_event (Gtk.Widget widget, Gdk.EventCrossing event)
		{
			if (event.detail == Gdk.NotifyType.INFERIOR)
				return Hidden;
			
#if HAVE_BARRIERS
			if (Hidden && barriers_supported && controller.prefs.PressureReveal)
				return Hidden;
#endif
			
			if (!Hovered)
				update_hovered_with_coords ((int) event.x, (int) event.y);
			
			return Hidden;
		}
		
		[CCode (instance_pos = -1)]
		bool handle_leave_notify_event (Gtk.Widget widget, Gdk.EventCrossing event)
		{
			if (event.detail == Gdk.NotifyType.INFERIOR)
				return Gdk.EVENT_PROPAGATE;
			
			if (Hovered)
				update_hovered_with_coords ((int) event.x, (int) event.y);
			
			return Gdk.EVENT_PROPAGATE;
		}
		
		//
		// intelligent hiding code
		//
		
		void update_window_intersect ()
		{
			var dock_rect = controller.position_manager.get_static_dock_region ();
#if HAVE_HIDPI
			var window_scale_factor = controller.window.get_window ().get_scale_factor ();
			if (window_scale_factor > 1) {
				dock_rect.x *= window_scale_factor;
				dock_rect.y *= window_scale_factor;
				dock_rect.width *= window_scale_factor;
				dock_rect.height *= window_scale_factor;
			}
#endif
			
			var intersect = false;
			var dialog_intersect = false;
			var active_intersect = false;
			var new_active_window_intersect = false;
			var active_maximized_intersect = false;
			unowned Wnck.Screen screen = Wnck.Screen.get_default ();
			unowned Wnck.Window? active_window = screen.get_active_window ();
			unowned Wnck.Workspace? active_workspace = screen.get_active_workspace ();
			
			if (active_window != null && active_workspace != null) {
				var active_pid = active_window.get_pid ();
				foreach (var w in screen.get_windows ()) {
					if (w.is_minimized ())
						continue;
					var type = w.get_window_type ();
					if (type == Wnck.WindowType.DESKTOP || type == Wnck.WindowType.DOCK
						|| type == Wnck.WindowType.MENU || type == Wnck.WindowType.SPLASHSCREEN)
						continue;
					if (!w.is_visible_on_workspace (active_workspace))
						continue;
					var pid = w.get_pid ();
					if (pid == plank_pid)
						continue;
					
					if (window_geometry (w).intersect (dock_rect, null)) {
						intersect = true;
						
						if (pid != active_pid)
							continue;
						
						active_intersect = true;
						
						new_active_window_intersect = new_active_window_intersect || (active_window == w);
						
						active_maximized_intersect = active_maximized_intersect || (active_window == w
							&& (w.is_maximized () || w.is_maximized_vertically () || w.is_maximized_horizontally ()));
						
						dialog_intersect = dialog_intersect || type == Wnck.WindowType.DIALOG;
						
						if (active_maximized_intersect && dialog_intersect)
							break;
					}
				}
			}
			
			window_intersect = intersect;
			dialog_windows_intersect = dialog_intersect;
			active_application_intersect = active_intersect;
			active_window_intersect = new_active_window_intersect;
			active_maximized_window_intersect = active_maximized_intersect;
			
			pointer_update = false;
			update_hidden ();
		}
		
		void schedule_update ()
		{
			if (timer_window_changed > 0)
				return;
			
			timer_window_changed = Gdk.threads_add_timeout (UPDATE_TIMEOUT, () => {
				update_window_intersect ();
				timer_window_changed = 0;
				return false;
			});
		}
		
		[CCode (instance_pos = -1)]
		void handle_workspace_changed (Wnck.Screen screen, Wnck.Workspace? previous)
		{
			schedule_update ();
		}
		
		[CCode (instance_pos = -1)]
		void handle_active_window_changed (Wnck.Screen screen, Wnck.Window? previous)
		{
			if (previous != null) {
				previous.geometry_changed.disconnect (handle_geometry_changed);
				previous.state_changed.disconnect (handle_state_changed);
			}
			
			setup_active_window (screen);
		}
		
		void setup_active_window (Wnck.Screen screen)
		{
			var active_window = screen.get_active_window ();
			
			if (active_window != null) {
				last_window_rect = window_geometry (active_window);
				active_window.geometry_changed.connect_after (handle_geometry_changed);
				active_window.state_changed.connect_after (handle_state_changed);
			}
			
			schedule_update ();
		}
		
		[CCode (instance_pos = -1)]
		void handle_state_changed (Wnck.Window window, Wnck.WindowState changed_mask, Wnck.WindowState new_state)
		{
			if ((changed_mask & Wnck.WindowState.MINIMIZED) == 0)
				return;
			
			schedule_update ();
		}
		
		[CCode (instance_pos = -1)]
		void handle_geometry_changed (Wnck.Window window)
		{
			var geo = window_geometry (window);
			if (geo == last_window_rect)
				return;
			
			last_window_rect = geo;
			
			if (timer_geo > 0)
				return;
			
			timer_geo = Gdk.threads_add_timeout (UPDATE_TIMEOUT, () => {
				update_window_intersect ();
				timer_geo = 0;
				return false;
			});
		}
		
		static Gdk.Rectangle window_geometry (Wnck.Window window)
		{
			Gdk.Rectangle win_rect = {};
			window.get_geometry (out win_rect.x, out win_rect.y, out win_rect.width, out win_rect.height);
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
			
			if (timer_hide > 0) {
				GLib.Source.remove (timer_hide);
				timer_hide = 0;
			}
			
			if (timer_unhide > 0) {
				GLib.Source.remove (timer_unhide);
				timer_unhide = 0;
			}
		}
		
#if HAVE_BARRIERS
		void initialize_barriers_support ()
		{
			unowned Gdk.X11.Display gdk_display = (controller.window.get_display () as Gdk.X11.Display);
			unowned X.Display display = gdk_display.get_xdisplay ();
			int error_base, first_event_return;
			
			gdk_window_remove_filter (null, (Gdk.FilterFunc)xevent_filter);
			
			if (!display.query_extension ("XInputExtension", out opcode, out first_event_return, out error_base)) {
				debug ("Barriers disabled (XInput needed)");
				barriers_supported = false;
			} else {
				int major = 2, minor = 3;
				var has_xinput = (XInput.query_version (display, ref major, ref minor) == X.Success);
				if (has_xinput && major >= 2 && minor >= 3) {
					message ("Barriers enabled (XInput %i.%i support)\n", major, minor);
					barriers_supported = true;
					gdk_window_add_filter (null, (Gdk.FilterFunc)xevent_filter);
				} else {
					debug ("Barriers disabled (XInput %i.%i not sufficient)", major, minor);
					barriers_supported = false;
				}
			}
		}

		/**
		 * Event filter method needed to fetch X.Events
		 */
		[CCode (instance_pos = -1)]
		Gdk.FilterReturn xevent_filter (Gdk.XEvent gdk_xevent, Gdk.Event gdk_event)
		{
			X.Event* xevent = (X.Event*) gdk_xevent;
			X.GenericEventCookie* xcookie = &xevent.xcookie;
			unowned X.Display display = xcookie.display;
			
			// Did we got a barrier-event?
			if (barrier == 0
				|| (xcookie.extension != opcode)
				|| (xcookie.evtype != XInput.EventType.BARRIER_HIT && xcookie.evtype != XInput.EventType.BARRIER_LEAVE))
				return Gdk.FilterReturn.CONTINUE;
			
			X.get_event_data (display, xcookie);
			
			// Does it match our registered barrier?
			XInput.BarrierEvent* barrier_event = (XInput.BarrierEvent*) (xcookie.data);
			if (barrier_event.barrier != barrier) {
				X.free_event_data (display, xcookie);
				return Gdk.FilterReturn.CONTINUE;
			}
			
			switch (xcookie.evtype) {
			case XInput.EventType.BARRIER_HIT:
				double slide = 0.0, distance = 0.0;
				switch (controller.position_manager.Position) {
				default:
				case Gtk.PositionType.BOTTOM:
				case Gtk.PositionType.TOP:
					distance = Math.fabs (barrier_event.dy);
					slide = Math.fabs (barrier_event.dx);
					break;
				case Gtk.PositionType.LEFT:
				case Gtk.PositionType.RIGHT:
					distance = Math.fabs (barrier_event.dx);
					slide = Math.fabs (barrier_event.dy);
					break;
				}
				
				if (slide < distance) {
					distance = Math.fmin (15.0, distance);
					pressure += distance;
					Logger.verbose ("HideManager (pressure = %f)", pressure);
				}
				
				if (pressure >= PRESSURE_THRESHOLD) {
					pressure = 0;
					
					if (pressure_timer > 0) {
						GLib.Source.remove (pressure_timer);
						pressure_timer = 0;
					}
					
					Logger.verbose ("HideManager (pressure-threshold reached > unhide (%f))", PRESSURE_THRESHOLD);
					
					freeze_notify ();
					
					if (!Hovered) {
						Hovered = true;
						update_hidden ();
					}
					
					thaw_notify ();
				}
				break;
			case XInput.EventType.BARRIER_LEAVE:
				if (pressure_timer == 0)
					pressure_timer = Gdk.threads_add_timeout (PRESSURE_TIMEOUT, () => {
						pressure = 0;
						pressure_timer = 0;
						return false;
					});
				break;
			default:
				break;
			}
			
			XInput.barrier_release_pointer (display, barrier_event.deviceid,
				barrier, barrier_event.eventid);
			
			display.flush ();
			
			X.free_event_data (display, xcookie);
			return Gdk.FilterReturn.REMOVE;
		}
		
		public void update_barrier ()
		{
			if (!barriers_supported)
				return;
			
			unowned Gdk.X11.Display gdk_display = (controller.window.get_display () as Gdk.X11.Display);
			unowned X.Display display = gdk_display.get_xdisplay ();
			
			if (barrier > 0) {
				XFixes.destroy_pointer_barrier (display, barrier);
				barrier = 0;
			}
			
			if (!controller.prefs.PressureReveal)
				return;
			
			if (controller.prefs.HideMode == HideType.NONE)
				return;
			
			var root_xwindow = display.default_root_window ();
			var barrier_area = controller.position_manager.get_barrier ();
			
			// Enable barrier events
			uchar[] mask_bits = new uchar[XInput.mask_length (XInput.EventType.LASTEVENT)];
			XInput.EventMask mask = { XInput.ALL_MASTER_DEVICES, (int) (sizeof (uchar) * mask_bits.length), (owned) mask_bits };
			XInput.set_mask (mask.mask, XInput.EventType.BARRIER_HIT);
			XInput.set_mask (mask.mask, XInput.EventType.BARRIER_LEAVE);
			XInput.select_events (display, root_xwindow, &mask, 1);

			debug ("Barrier: %i,%i - %i,%i\n", barrier_area.x, barrier_area.y, barrier_area.x + barrier_area.width, barrier_area.y + barrier_area.height);
			
			barrier = XFixes.create_pointer_barrier (
				display, root_xwindow,
				barrier_area.x, barrier_area.y, barrier_area.x + barrier_area.width,
				barrier_area.y + barrier_area.height,
				0,
				0, null);
			
			warn_if_fail (barrier > 0);
		}
#endif
	}
}
