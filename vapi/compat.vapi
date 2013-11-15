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
