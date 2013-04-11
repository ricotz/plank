//
//  Copyright (C) 2011-2012 Robert Dyer, Rico Tzschichholz
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
		
		// Parameters for average-color calculation
		const double SATURATION_WEIGHT = 1.5;
		const double WEIGHT_THRESHOLD = 1.0;
		const uint8 ALPHA_THRESHOLD = 24;
		
		DrawingService ()
		{
		}
		
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
				var thumb_icon = info.get_attribute_string (FileAttribute.THUMBNAIL_PATH);
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
			if (icon is ThemedIcon) {
				var icons = string.joinv (";;", (icon as ThemedIcon).get_names ());
				// Remove possible null values which sneaked through joinv, possibly a GTK+ bug?
				return icons.replace ("(null);;", "");
			}
			
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
			Pixbuf? pbuf = null;
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
			
			return pbuf;
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
		 * The resulting color is the average of all pixels which aren't
		 * nearly transparent while saturated pixels are weighted more than
		 * "grey" ones.
		 *
		 * @param source the pixbuf to use
		 * @return the average color of the pixbuf
		 */
		public static Drawing.Color average_color (Pixbuf source)
		{
			uint8 r, g, b, a, min, max;
			double delta;

			var rTotal = 0.0;
			var gTotal = 0.0;
			var bTotal = 0.0;
			
			var bTotal2 = 0.0;
			var gTotal2 = 0.0;
			var rTotal2 = 0.0;
			var aTotal2 = 0.0;
			
			uint8* dataPtr = source.get_pixels ();
			int n_channels = source.n_channels;
			int width = source.width;
			int height = source.height;
			int rowstride = source.rowstride;
			int length = width * height;
			int pixels = height * rowstride / n_channels;
			double scoreTotal = 0.0;
			
			for (var i = 0; i < pixels; i++) {
				r = dataPtr [0];
				g = dataPtr [1];
				b = dataPtr [2];
				a = dataPtr [3];
				
				// skip (nearly) invisible pixels
				if (a <= ALPHA_THRESHOLD) {
					length--;
					dataPtr += n_channels;
					continue;
				}
				
				min = uint8.min (r, uint8.min (g, b));
				max = uint8.max (r, uint8.max (g, b));
				delta = max - min;
				
				// prefer colored pixels over shades of grey
				var score = SATURATION_WEIGHT * (delta == 0 ? 0.0 : delta / max);
				
				// weighted sums, revert pre-multiplied alpha value
				bTotal += score * b / a;
				gTotal += score * g / a;
				rTotal += score * r / a;
				scoreTotal += score;
				
				// not weighted sums
				bTotal2 += b;
				gTotal2 += g;
				rTotal2 += r;
				aTotal2 += a;
				
				dataPtr += n_channels;
			}
			
			// looks like a fully transparent image
			if (length <= 0)
				return { 0.0, 0.0, 0.0, 0.0 };
			
			scoreTotal /= length;
			bTotal /= length;
			gTotal /= length;
			rTotal /= length;
			
			if (scoreTotal > 0.0) {
				bTotal /= scoreTotal;
				gTotal /= scoreTotal;
				rTotal /= scoreTotal;
			}
			
			bTotal2 /= length * uint8.MAX;
			gTotal2 /= length * uint8.MAX;
			rTotal2 /= length * uint8.MAX;
			aTotal2 /= length * uint8.MAX;
			
			// combine weighted and not weighted sum depending on the average "saturation"
			// if saturation isn't reasonable enough
			// s = 0.0 -> f = 0.0 ; s = WEIGHT_THRESHOLD -> f = 1.0
			if (scoreTotal <= WEIGHT_THRESHOLD) {
				var f = 1.0 / WEIGHT_THRESHOLD * scoreTotal;
				var rf = 1.0 - f;
				bTotal = bTotal * f + bTotal2 * rf;
				gTotal = gTotal * f + gTotal2 * rf;
				rTotal = rTotal * f + rTotal2 * rf;
			}
			
			// there shouldn't be values larger then 1.0
			var max_val = double.max (rTotal, double.max (gTotal, bTotal));
			if (max_val > 1.0) {
				bTotal /= max_val;
				gTotal /= max_val;
				rTotal /= max_val;
			}
			
			return { rTotal, gTotal, bTotal, aTotal2 };
		}
	}
}
