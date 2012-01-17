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
using Gee;
using Gtk;

using Plank.Services;

namespace Plank.Drawing
{
	/**
	 * Utility service for loading icons and working with pixbufs.
	 */
	public class DrawingService : GLib.Object
	{
		const string MISSING_ICONS = "application-default-icon;;application-x-executable";
		
		/**
		 * Gets the icon name from a {@link GLib.File}.
		 *
		 * @param file the file to get the icon name for
		 * @return the icon name for the file, or null if none exists
		 */
		public static string? get_icon_from_file (File file)
		{
			try {
				var info = file.query_info ("*", 0);
				
				// look first for a custom icon
				var custom_icon = info.get_attribute_string ("metadata::custom-icon");
				if (custom_icon != null && custom_icon != "") {
					if (custom_icon.has_prefix ("file://"))
						return custom_icon;
					return file.get_child (custom_icon).get_path ();
				}
				
				// look for a thumbnail
				var thumb_icon = info.get_attribute_string (FILE_ATTRIBUTE_THUMBNAIL_PATH);
				if (thumb_icon != null && thumb_icon != "")
					return thumb_icon;
				
				// otherwise try to get the icon from the fileinfo
				return get_icon_from_gicon (info.get_icon ());
			} catch {
				debug ("Could not get file info for '%s'", file.get_path () ?? "");
			}
			
			return null;
		}
		
		/**
		 * Gets an icon from a {@link GLib.Icon}.
		 *
		 * @param icon the icon to get the name for
		 * @return the icon name, or null if none exists
		 */
		public static string? get_icon_from_gicon (Icon? icon)
		{
			if (icon is ThemedIcon)
				return string.joinv (";;", (string[]) (icon as ThemedIcon).get_names ());
			if (icon is FileIcon)
				return (icon as FileIcon).get_file ().get_path ();
			return null;
		}
		
		/**
		 * Loads an icon based on names and the given width/height
		 *
		 * @param names a delimited (with ";;") list of icon names, first one found is used
		 * @param width the requested width of the icon
		 * @param height the requested height of the icon
		 * @return the pixbuf representing the requested icon
		 */
		public static Pixbuf load_icon (string names, int width, int height)
		{
			var all_names = new ArrayList<string> ();
			
			foreach (var s in names.split (";;"))
				all_names.add (s);
			foreach (var s in MISSING_ICONS.split (";;"))
				all_names.add (s);
			
			Pixbuf? pbuf = null;
			
			foreach (var name in all_names) {
				if (icon_is_file (name)) {
					pbuf = load_pixbuf_from_file (name, width, height);
					if (pbuf != null)
						break;
				}
				
				pbuf = load_pixbuf (name, int.max (width, height));
				if (pbuf != null)
					break;
				
				if (name != all_names.last ())
					message ("Could not find icon '%s'", name);
			}
			
			if (pbuf != null) {
				if (width != -1 && height != -1 && (width != pbuf.width || height != pbuf.height))
					return ar_scale (pbuf, width, height);
				return pbuf;
			}
			
			return get_empty_pixbuf ();
		}
		
		static Pixbuf get_empty_pixbuf ()
		{
			var pbuf = new Pixbuf (Colorspace.RGB, true, 8, 1, 1);
			pbuf.fill (0x00000000);
			return pbuf;
		}
		
		static bool icon_is_file (string name)
		{
			return name.has_prefix ("/") || name.has_prefix ("~/") || name.down ().has_prefix ("file://");
		}
		
		static Pixbuf? load_pixbuf_from_file (string name, int width, int height)
		{
			Pixbuf? pbuf = null;
			
			var filename = name;
			if (name.has_prefix ("~/"))
				filename = name.replace ("~/", Paths.HomeFolder.get_path () ?? "");
			
			try {
				if (filename.has_prefix ("file://"))
					pbuf = new Pixbuf.from_file (File.new_for_uri (filename).get_path ());
				else
					pbuf = new Pixbuf.from_file (File.new_for_path (filename).get_path ());
			} catch { }
			
			return pbuf;
		}
		
		static Pixbuf? load_pixbuf (string icon, int size)
		{
#if VALA_0_12
			Pixbuf? pbuf = null;
#else
			unowned Pixbuf? pbuf = null;
#endif
			unowned IconTheme icon_theme = IconTheme.get_default ();
			
			try {
				if (icon_theme.has_icon (icon))
					pbuf = icon_theme.load_icon (icon, size, 0);
				else if (icon.contains (".")) {
					var parts = icon.split (".");
					if (icon_theme.has_icon (parts [0]))
						pbuf = icon_theme.load_icon (parts [0], size, 0);
				}
			} catch { }
			
#if VALA_0_12
			return pbuf;
#else
			if (pbuf == null)
				return null;
			
			var tmp = pbuf.copy ();
			pbuf.unref ();
			return tmp;
#endif
		}
		
		/**
		 * Scales a {@link Gdk.Pixbuf}, maintaining the original aspect ratio.
		 *
		 * @param source the pixbuf to scale
		 * @param width the width of the scaled pixbuf
		 * @param height the height of the scaled pixbuf
		 * @return the scaled pixbuf
		 */
		public static Pixbuf ar_scale (Pixbuf source, int width, int height)
		{
			var xScale = (double) width / (double) source.width;
			var yScale = (double) height / (double) source.height;
			var scale = double.min (xScale, yScale);
			
			if (scale == 1)
				return source;
			
			var tmp = source.scale_simple ((int) (source.width * scale),
				(int) (source.height * scale),
				InterpType.HYPER);
			
			return tmp;
		}
		
		/**
		 * Computes and returns the average color of a {@link Gdk.Pixbuf}.
		 *
		 * @param source the pixbuf to use
		 * @return the average color of the pixbuf
		 */
		public static Drawing.Color average_color (Pixbuf source)
		{
			var rTotal = 0.0;
			var gTotal = 0.0;
			var bTotal = 0.0;
			
			uint8* dataPtr = source.get_pixels ();
			double pixels = source.height * source.rowstride / source.n_channels;
			
			for (var i = 0; i < pixels; i++) {
				var r = dataPtr [0];
				var g = dataPtr [1];
				var b = dataPtr [2];
				
				var max = (uint8) double.max (r, double.max (g, b));
				var min = (uint8) double.min (r, double.min (g, b));
				double delta = max - min;
				
				var sat = delta == 0 ? 0.0 : delta / max;
				var score = 0.2 + 0.8 * sat;
				
				rTotal += r * score;
				gTotal += g * score;
				bTotal += b * score;
				
				dataPtr += source.n_channels;
			}
			
			return new Drawing.Color (rTotal / uint8.MAX / pixels,
							 gTotal / uint8.MAX / pixels,
							 bTotal / uint8.MAX / pixels,
							 1).set_val (0.8).multiply_sat (1.15);
		}
	}
}
