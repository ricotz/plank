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

namespace Plank.Drawing
{
	public class DockSurface : GLib.Object
	{
		private Surface surface;
		public Surface Internal {
			get {
				if (surface == null)
					surface = new ImageSurface (Format.ARGB32, Width, Height);
				return surface;
			}
			private set { surface = value; }
		}
		
		public int Width { get; private set; }
		
		public int Height { get; private set; }
		
		private Context context;
		public Cairo.Context Context {
			get {
				if (context == null)
					context = new Cairo.Context (Internal);
				return context;
			}
		}
		
		public DockSurface (int width, int height)
		{
			Width = width;
			Height = height;
		}
		
		public DockSurface.with_surface (int width, int height, Surface model)
		{
			this (width, height);
			if (model != null)
				Internal = new Surface.similar (model, Content.COLOR_ALPHA, Width, Height);
		}

		public DockSurface.with_dock_surface (int width, int height, DockSurface model)
		{
			this (width, height);
			if (model != null)
				Internal = new Surface.similar (model.Internal, Content.COLOR_ALPHA, Width, Height);
		}
		
		public void clear ()
		{
			Context.save ();
			
			context.set_source_rgba (0, 0, 0, 0);
			context.set_operator (Operator.SOURCE);
			context.paint ();
			
			context.restore ();
		}
		
		public Gdk.Pixbuf load_to_pixbuf ()
		{
			ImageSurface image_surface = new ImageSurface (Format.ARGB32, Width, Height);
			Cairo.Context cr = new Cairo.Context (image_surface);
			cr.set_operator (Operator.SOURCE);
			cr.set_source_surface (Internal, 0, 0);
			cr.paint ();
			
			int width = image_surface.get_width ();
			int height = image_surface.get_height ();

			Gdk.Pixbuf pb = new Gdk.Pixbuf (Gdk.Colorspace.RGB, true, 8, width, height);
			pb.fill (0x00000000);
			
			uchar *data = image_surface.get_data ();
			uchar *pixels = pb.get_pixels ();
			int length = width * height;
			
			if (image_surface.get_format () == Format.ARGB32) {
				for (int i = 0; i < length; i++) {
					// if alpha is 0 set nothing
					if (data[3] > 0) {
						pixels[0] = (uchar) (data[2] * 255 / data[3]);
						pixels[1] = (uchar) (data[1] * 255 / data[3]);
						pixels[2] = (uchar) (data[0] * 255 / data[3]);
						pixels[3] = data[3];
					}
		
					pixels += 4;
					data += 4;
				}
			} else if (image_surface.get_format () == Format.RGB24) {
				for (int i = 0; i < length; i++) {
					pixels[0] = data[2];
					pixels[1] = data[1];
					pixels[2] = data[0];
					pixels[3] = data[3];
		
					pixels += 4;
					data += 4;
				}
			}
			
			return pb;
		}
	}
}
