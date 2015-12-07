//
//  Copyright (C) 2013 Rico Tzschichholz
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
#if HAVE_HIDPI
	[CCode (cheader_filename = "cairo.h", cname = "cairo_surface_get_device_scale")]
	public void cairo_surface_get_device_scale (Cairo.Surface surface, out double x_scale, out double y_scale);
	[CCode (cheader_filename = "cairo.h", cname = "cairo_surface_set_device_scale")]
	public void cairo_surface_set_device_scale (Cairo.Surface surface, double x_scale, double y_scale);
#endif

#if VALA_0_26 && !VALA_0_32
	[CCode (array_length_type = "guint", cheader_filename = "glib-object.h", cname = "g_object_class_list_properties")]
	public (unowned GLib.ParamSpec)[] g_object_class_list_properties (GLib.ObjectClass oclass);
#endif

	[CCode (cheader_filename = "gdk/gdk.h", cname = "gdk_window_add_filter", instance_pos = 1.9)]
	public void gdk_window_add_filter (Gdk.Window? window, Gdk.FilterFunc function);
	[CCode (cheader_filename = "gdk/gdk.h", cname = "gdk_window_add_filter", instance_pos = 1.9)]
	public void gdk_window_remove_filter (Gdk.Window? window, Gdk.FilterFunc function);

#if HAVE_SYS_PRCTL_H
	[CCode (cheader_filename = "sys/prctl.h", cname = "prctl", sentinel = "")]
	public int prctl (int option, ...);
#else
	[CCode (cheader_filename = "unistd.h", cname = "setproctitle", sentinel = "")]
	public void setproctitle (string fmt, ...);
#endif

	[CCode (cheader_filename = "unistd.h", cname = "getpid")]
	public int getpid ();
}

[CCode (cheader_filename = "")]
namespace PlankCompat
{
	// Conditional compat-layer for Gtk+ 3.19.1+
	public void gtk_widget_class_set_css_name (GLib.ObjectClass widget_class, string name);
	public void gtk_widget_path_iter_set_object_name (Gtk.WidgetPath path, int pos, string? name);
}

[CCode (cheader_filename = "X11/Xlib.h")]
namespace X
{
	[CCode (cname = "XGetEventData")]
	public static bool get_event_data (X.Display display, X.GenericEventCookie* event_cookie);
	[CCode (cname = "XFreeEventData")]
	public static bool free_event_data (X.Display display, X.GenericEventCookie* event_cookie);
}	

