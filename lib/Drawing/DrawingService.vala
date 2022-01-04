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
	/**
	 * Utility service for loading icons and working with pixbufs.
	 */
	public class DrawingService : GLib.Object
	{
		const string DEFAULT_ICON = "application-default-icon";
		
		const string FILE_ATTRIBUTE_CUSTOM_ICON = "metadata::custom-icon";
		const string FILE_ATTRIBUTE_CUSTOM_ICON_NAME = "metadata::custom-icon-name";
		
		// Parameters for average-color calculation
		const double SATURATION_WEIGHT = 1.5;
		const double WEIGHT_THRESHOLD = 1.0;
		const uint8 ALPHA_THRESHOLD = 24;
		
		static Mutex icon_theme_mutex;
		static Gtk.IconTheme icon_theme;
		
		DrawingService ()
		{
		}
		
		public static unowned Gtk.IconTheme get_icon_theme ()
		{
			icon_theme_mutex.lock ();
			
			if (icon_theme == null)
				icon_theme = Gtk.IconTheme.get_for_screen (Gdk.Screen.get_default ());
			
			icon_theme_mutex.unlock ();
			
			return icon_theme;
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
				var info = file.query_info (FileAttribute.STANDARD_ICON + ","
					+ FILE_ATTRIBUTE_CUSTOM_ICON_NAME + "," + FILE_ATTRIBUTE_CUSTOM_ICON + ","
					+ FileAttribute.THUMBNAIL_PATH, 0);
				
				// look for a custom icon-name
				unowned string custom_icon_name = info.get_attribute_string (FILE_ATTRIBUTE_CUSTOM_ICON_NAME);
				if (custom_icon_name != null && custom_icon_name != "")
					return custom_icon_name;
				
				// look for a custom icon
				unowned string custom_icon = info.get_attribute_string (FILE_ATTRIBUTE_CUSTOM_ICON);
				if (custom_icon != null && custom_icon != "") {
					if (custom_icon.has_prefix ("file://"))
						return custom_icon;
					return file.get_child (custom_icon).get_path ();
				}
				
				// look for a thumbnail
				unowned string thumb_icon = info.get_attribute_byte_string (FileAttribute.THUMBNAIL_PATH);
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
				var icons = string.joinv (";;", ((ThemedIcon) icon).get_names ());
				// Remove possible null values which sneaked through joinv, possibly a GTK+ bug?
				return icons.replace ("(null);;", "");
			}
			
			if (icon is FileIcon)
				return ((FileIcon) icon).get_file ().get_path ();
			
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
		public static Gdk.Pixbuf load_icon (string names, int width, int height)
		{
			Gdk.Pixbuf? pbuf = null;
			
			var all_names = names.split (";;");
			all_names += DEFAULT_ICON;
			
			foreach (unowned string name in all_names) {
				var file = try_get_icon_file (name);
				if (file != null) {
					pbuf = load_pixbuf_from_file (file, width, height);
					if (pbuf != null)
						break;
				}
				
				pbuf = load_pixbuf (name, int.max (width, height));
				if (pbuf != null)
					break;
				
				if (name != DEFAULT_ICON)
					message ("Could not find icon '%s'", name);
			}
			
			// Load internal default icon as last resort
			if (pbuf == null)
				pbuf = load_pixbuf_from_resource (Plank.G_RESOURCE_PATH + "/img/application-default-icon.svg", width, height);
			
			if (pbuf != null) {
				if (width != -1 && height != -1 && (width != pbuf.width || height != pbuf.height))
					return ar_scale (pbuf, width, height);
				return pbuf;
			}
			
			warning ("No icon found, return empty pixbuf");
			
			return get_empty_pixbuf (int.max (1, width), int.max (1, height));
		}
		
		static Gdk.Pixbuf get_empty_pixbuf (int width, int height)
		{
			var pbuf = new Gdk.Pixbuf (Gdk.Colorspace.RGB, true, 8, width, height);
			pbuf.fill (0x00000000);
			return pbuf;
		}
		
		/**
		 * Try to get a {@link GLib.File} for the given icon name
		 *
		 * @param name a string which might represent an existing file
		 * @return a {@link GLib.File}, or null if it failed
		 */
		public static File? try_get_icon_file (string name)
		{
			File? file = null;
			var name_down = name.down ();			
			
			if (name_down.has_prefix ("resource://"))
				file = File.new_for_uri (name);
			else if (name_down.has_prefix ("file://"))
				file = File.new_for_uri (name);
			else if (name.has_prefix ("~/"))
				file = File.new_for_path (name.replace ("~", Environment.get_home_dir ()));
			else if (name.has_prefix ("/"))
				file = File.new_for_path (name);
			
			if (file != null && file.query_exists ())
				return file;
			
			return null;
		}
		
		static Gdk.Pixbuf? load_pixbuf_from_file (File file, int width, int height)
		{
			Gdk.Pixbuf? pbuf = null;
			
			try {
				var fis = file.read ();
				pbuf = new Gdk.Pixbuf.from_stream_at_scale (fis, width, height, true);
			} catch { }
			
			return pbuf;
		}
		
		static Gdk.Pixbuf? load_pixbuf_from_resource (string resource, int width, int height)
		{
			Gdk.Pixbuf? pbuf = null;
			
			try {
				pbuf = new Gdk.Pixbuf.from_resource_at_scale (resource, width, height, true);
			} catch { }
			
			return pbuf;
		}
		
		static Gdk.Pixbuf? load_pixbuf (string icon, int size)
		{
			Gdk.Pixbuf? pbuf = null;
			unowned Gtk.IconTheme icon_theme = get_icon_theme ();
			
			icon_theme_mutex.lock ();
			
			try {
				pbuf = icon_theme.load_icon (icon, size, 0);
			} catch { }
			
			try {
				if (pbuf == null && icon.contains (".")) {
					var parts = icon.split (".");
					pbuf = icon_theme.load_icon (parts [0], size, 0);
				}
			} catch { }
			
			icon_theme_mutex.unlock ();
			
			return pbuf;
		}
		
		/**
		 * Loads an icon based on names and the given width/height
		 *
		 * @param names a delimited (with ";;") list of icon names, first one found is used
		 * @param width the requested width of the icon
		 * @param height the requested height of the icon
		 * @param scale the implicit requested scale of the icon
		 * @return the {link Cairo.Surface} containing the requested icon, do not alter this surface
		 */
		public static Cairo.Surface? load_icon_for_scale (string names, int width, int height, int scale)
		{
			Cairo.Surface? surface = null;
			
			var all_names = names.split (";;");
			all_names += DEFAULT_ICON;
			
			foreach (unowned string name in all_names) {
				var file = try_get_icon_file (name);
				if (file != null) {
					var pbuf = load_pixbuf_from_file (file, width, height);
					if (pbuf != null) {
						surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, width, height);
						var cr = new Cairo.Context (surface);
						Gdk.cairo_set_source_pixbuf (cr, pbuf, (width - pbuf.width) / 2, (height - pbuf.height) / 2);
						cr.paint ();
						surface.set_device_scale (scale, scale);
						break;
					}
				}
				
				surface = load_surface (name, int.max (width, height) / scale, scale);
				if (surface != null)
					break;
				
				if (name != DEFAULT_ICON)
					message ("Could not find icon '%s'", name);
			}
			
			// Load internal default icon as last resort
			if (surface == null)
				surface = load_surface_from_resource_at_scale (Plank.G_RESOURCE_PATH + "/img/application-default-icon.svg", width, height, scale);
			
			return surface;
		}
		
		static Cairo.Surface? load_surface_from_resource_at_scale (string resource, int width, int height, int scale)
		{
			Gdk.Pixbuf? pbuf = null;
			Cairo.Surface? surface = null;
			
			try {
				pbuf = new Gdk.Pixbuf.from_resource_at_scale (resource, width, height, true);
			} catch { }
			
			if (pbuf != null) {
				surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, width, height);
				var cr = new Cairo.Context (surface);
				Gdk.cairo_set_source_pixbuf (cr, pbuf, (width - pbuf.width) / 2, (height - pbuf.height) / 2);
				cr.paint ();
				surface.set_device_scale (scale, scale);
			}
			
			return surface;
		}
		
		static Cairo.Surface? load_surface (string icon, int size, int scale)
		{
			Cairo.Surface? surface = null;
			Gtk.IconInfo? info = null;
			unowned Gtk.IconTheme icon_theme = get_icon_theme ();
			
			icon_theme_mutex.lock ();
			
			try {
				info = icon_theme.lookup_icon_for_scale (icon, size, scale, Gtk.IconLookupFlags.FORCE_SIZE);
				if (info != null)
					surface = info.load_surface (null);
			} catch { }
			
			try {
				if (surface == null && icon.contains (".")) {
					var parts = icon.split (".");
					info = icon_theme.lookup_icon_for_scale (parts [0], size, scale, Gtk.IconLookupFlags.FORCE_SIZE);
					if (info != null)
						surface = info.load_surface (null);
				}
			} catch { }
			
			icon_theme_mutex.unlock ();
			
			return surface;
		}
		
		/**
		 * Scales a {@link Gdk.Pixbuf}, maintaining the original aspect ratio.
		 *
		 * @param source the pixbuf to scale
		 * @param width the width of the scaled pixbuf
		 * @param height the height of the scaled pixbuf
		 * @return the scaled pixbuf
		 */
		public static Gdk.Pixbuf ar_scale (Gdk.Pixbuf source, int width, int height)
		{
			var source_width = (double) source.width;
			var source_height = (double) source.height;
			
			var x_scale = width / source_width;
			var y_scale = height / source_height;
			var scale = double.min (x_scale, y_scale);
			
			if (scale == 1)
				return source;
			
			var scaled_width = int.max (1, (int) (source_width * scale));
			var scaled_height = int.max (1, (int) (source_height * scale));
			
			return source.scale_simple (scaled_width, scaled_height, Gdk.InterpType.HYPER);
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
		public static Color average_color (Gdk.Pixbuf source)
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
