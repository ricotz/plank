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
using Gtk;

using Plank.Services;

namespace Plank.Drawing
{
	public class DrawingService : GLib.Object
	{
		const string MISSING_ICONS = "application-default-icon;;application-x-executable";
		
		public static Pixbuf load_icon (string names, int width, int height)
		{
			List<string> all_names = new List<string> ();
			
			foreach (string s in names.split (";;"))
				all_names.append (s);
			foreach (string s in MISSING_ICONS.split (";;"))
				all_names.append (s);
			
			Pixbuf pbuf = null;
			
			foreach (string name in all_names) {
				if (icon_is_file (name)) {
					pbuf = load_pixbuf_from_file (name, width, height);
					if (pbuf != null)
						break;
				}
				
				pbuf = load_pixbuf (name, (int) Math.fmax (width, height));
				if (pbuf != null)
					break;
				
				if (name != all_names.nth_data (all_names.length ()))
					Logger.info<DrawingService> ("Could not find icon '%s'".printf (name));
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
			Pixbuf pbuf = new Pixbuf (Colorspace.RGB, true, 8, 1, 1);
			pbuf.fill (0x00000000);
			return pbuf;
		}
		
		static bool icon_is_file (string name)
		{
			return name.has_prefix ("/") || name.has_prefix ("~/") || name.down ().has_prefix ("file://");
		}
		
		static Pixbuf? load_pixbuf_from_file (string name, int width, int height)
		{
			Pixbuf pbuf = null;
			
			string filename = name;
			if (name.has_prefix ("~/"))
				filename = name.replace ("~/", Paths.HomeFolder.get_path ());
			
			try {
				File file = File.new_for_path (filename);
				pbuf = new Pixbuf.from_file (file.get_path ());
			} catch { }
			
			return pbuf;
		}
		
		static Pixbuf? load_pixbuf (string icon, int size)
		{
#if VALA_0_12
			Pixbuf pbuf = null;
#else
			unowned Pixbuf pbuf = null;
#endif
			try {
				if (IconTheme.get_default ().has_icon (icon))
					pbuf = IconTheme.get_default ().load_icon (icon, size, 0);
				else if (icon.contains (".")) {
					string[] parts = icon.split (".");
					if (IconTheme.get_default ().has_icon (parts [0]))
						pbuf = IconTheme.get_default ().load_icon (parts [0], size, 0);
				}
			} catch { }
			
#if VALA_0_12
			return pbuf;
#else
			if (pbuf == null)
				return null;
			
			Pixbuf tmp = pbuf.copy ();
			pbuf.unref ();
			return tmp;
#endif
		}
		
		public static Pixbuf ar_scale (Pixbuf source, int width, int height)
		{
			var xScale = (double) width / (double) source.width;
			var yScale = (double) height / (double) source.height;
			var scale = Math.fmin (xScale, yScale);
			
			if (scale == 1)
				return source;
			
			Pixbuf tmp = source.scale_simple ((int) (source.width * scale),
				(int) (source.height * scale),
				InterpType.HYPER);
			
			return tmp;
		}
		
		public static Drawing.Color average_color (Pixbuf source)
		{
			double rTotal = 0;
			double gTotal = 0;
			double bTotal = 0;
			
			uchar* dataPtr = source.get_pixels ();
			double pixels = source.height * source.rowstride / source.n_channels;
			
			for (int i = 0; i < pixels; i++) {
				uchar r = dataPtr [0];
				uchar g = dataPtr [1];
				uchar b = dataPtr [2];
				
				uchar max = (uchar) Math.fmax (r, Math.fmax (g, b));
				uchar min = (uchar) Math.fmin (r, Math.fmin (g, b));
				double delta = max - min;
				
				double sat = delta == 0 ? 0 : delta / max;
				double score = 0.2 + 0.8 * sat;
				
				rTotal += r * score;
				gTotal += g * score;
				bTotal += b * score;
				
				dataPtr += source.n_channels;
			}
			
			return Drawing.Color (rTotal / uint8.MAX / pixels,
							 gTotal / uint8.MAX / pixels,
							 bTotal / uint8.MAX / pixels,
							 1).set_val (0.8).multiply_sat (1.15);
		}
	}
}
