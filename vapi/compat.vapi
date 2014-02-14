//  
//  Copyright (C) 2013 Rico Tzschichholz
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

namespace Plank
{
#if !VALA_0_18
	[CCode (cheader_filename = "gdk-pixbuf/gdk-pixbuf.h", cname = "gdk_pixbuf_new_from_resource")]
	public Gdk.Pixbuf gdk_pixbuf_new_from_resource (string resource_path) throws GLib.Error;
#endif
#if !VALA_0_24
	[CCode (cheader_filename = "gtk/gtk.h", cname = "gtk_widget_shape_combine_region")]
	public void gtk_widget_shape_combine_region (Gtk.Widget widget, Cairo.Region? region);
#endif
	[CCode (cheader_filename = "sys/prctl.h", cname = "prctl", sentinel = "")]
	public int prctl (int option, ...);
}

[CCode (cheader_filename = "glib.h")]
namespace GLib
{
#if !VALA_0_22
	[CCode (lower_case_cprefix = "glib_version_")]
	namespace Version {
		[CCode (cname = "glib_major_version")]
		public const uint major;
		[CCode (cname = "glib_minor_version")]
		public const uint minor;
		[CCode (cname = "glib_micro_version")]
		public const uint micro;
	}
#endif
}

namespace Gdk
{
#if !VALA_0_24
	[CCode (cheader_filename = "gdk/gdkx.h")]
	namespace X11 {
		[CCode (cheader_filename = "gdk/gdkx.h", type_check_function = "GDK_IS_X11_DISPLAY", type_id = "gdk_x11_display_get_type ()")]
		public class Display : Gdk.Display {
			[CCode (has_construct_function = false)]
			protected Display ();
			public void broadcast_startup_message (string message_type, ...);
			public int error_trap_pop ();
			public void error_trap_pop_ignored ();
			public void error_trap_push ();
			public unowned string get_startup_notification_id ();
			public uint32 get_user_time ();
			public unowned X.Display get_xdisplay ();
			public void grab ();
			[CCode (cname = "gdk_x11_lookup_xdisplay")]
			public static unowned Gdk.X11.Display lookup_for_xdisplay (X.Display xdisplay);
			public void set_cursor_theme (string theme, int size);
			public void set_startup_notification_id (string startup_id);
			public void set_window_scale (int scale);
			public int string_to_compound_text (string str, out Gdk.Atom encoding, out int format, [CCode (array_length_cname = "length", array_length_pos = 4.1)] out uint8[] ctext);
			public int text_property_to_text_list (Gdk.Atom encoding, int format, uint8 text, int length, string list);
			public void ungrab ();
			public bool utf8_to_compound_text (string str, out Gdk.Atom encoding, out int format, [CCode (array_length_cname = "length", array_length_pos = 4.1)] out uint8[] ctext);
		}
		[CCode (cheader_filename = "gdk/gdkx.h", type_check_function = "GDK_IS_X11_SCREEN", type_id = "gdk_x11_screen_get_type ()")]
		public class Screen : Gdk.Screen {
			[CCode (has_construct_function = false)]
			protected Screen ();
			public uint32 get_current_desktop ();
			public X.ID get_monitor_output (int monitor_num);
			public uint32 get_number_of_desktops ();
			public int get_screen_number ();
			public unowned string get_window_manager_name ();
			public unowned X.Screen get_xscreen ();
			public bool supports_net_wm_hint (Gdk.Atom property);
			public signal void window_manager_changed ();
		}
		[CCode (cheader_filename = "gdk/gdkx.h", type_check_function = "GDK_IS_X11_WINDOW", type_id = "gdk_x11_window_get_type ()")]
		public class Window : Gdk.Window {
			[CCode (has_construct_function = false)]
			protected Window ();
			[CCode (cname = "gdk_x11_window_foreign_new_for_display", has_construct_function = false, type = "GdkWindow*")]
			public Window.foreign_for_display (Gdk.X11.Display display, X.Window window);
			public uint32 get_desktop ();
			public X.Window get_xid ();
			public static unowned Gdk.X11.Window lookup_for_display (Gdk.X11.Display display, X.Window window);
			public void move_to_current_desktop ();
			public void move_to_desktop (uint32 desktop);
			[Deprecated (since = "3.12")]
			public void set_frame_extents (int left, int right, int top, int bottom);
			public void set_frame_sync_enabled (bool frame_sync_enabled);
			public void set_hide_titlebar_when_maximized (bool hide_titlebar_when_maximized);
			public void set_theme_variant (string variant);
			public void set_user_time (uint32 timestamp);
			public void set_utf8_property (string name, string? value);
		}
		public static X.Atom atom_to_xatom (Gdk.Atom atom);
		public static X.Atom atom_to_xatom_for_display (Gdk.X11.Display display, Gdk.Atom atom);
		public static void free_compound_text ([CCode (array_length = false, type = "guchar*")] uint8[] ctext);
		public static void free_text_list (string list);
		public static X.Window get_default_root_xwindow ();
		public static int get_default_screen ();
		public static unowned X.Display get_default_xdisplay ();
		public static uint32 get_server_time (Gdk.X11.Window window);
		public static X.Atom get_xatom_by_name (string atom_name);
		public static X.Atom get_xatom_by_name_for_display (Gdk.X11.Display display, string atom_name);
		public static unowned string get_xatom_name (X.Atom xatom);
		public static unowned string get_xatom_name_for_display (Gdk.X11.Display display, X.Atom xatom);
		public static void grab_server ();
		public static void register_standard_event_type (Gdk.X11.Display display, int event_base, int n_events);
		public static void set_sm_client_id (string sm_client_id);
		public static void ungrab_server ();
		public static Gdk.Atom xatom_to_atom (X.Atom xatom);
		public static Gdk.Atom xatom_to_atom_for_display (Gdk.X11.Display display, X.Atom xatom);
	}
#endif
}
