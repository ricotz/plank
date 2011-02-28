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
		
		public void fast_blur (int radius, int process_count = 1)
		{
			if (radius < 1 || process_count < 1)
				return;
			
			int w = Width;
			int h = Height;
			int channels = 4;
			
			int wh = w * h;
			int[] r = new int[wh];
			int[] g = new int[wh];
			int[] b = new int[wh];
			int[] a = new int[wh];
			
			int[] vmin = new int[int.max (w, h)];
			int[] vmax = new int[int.max (w, h)];
			
			ImageSurface original = new ImageSurface (Format.ARGB32, w, h);
			Cairo.Context cr = new Cairo.Context (original);
			
			cr.set_operator (Operator.SOURCE);
			cr.set_source_surface (Internal, 0, 0);
			cr.paint ();
			
			unowned uint8[] pixels = original.get_data ();
			
			int div = 2 * radius + 1;
			uint8[] dv = new uint8[uint8.MAX * div];
			
			for (int i = 0; i < uint8.MAX * div; i++)
				dv[i] = (uint8) (i / div);
			
			while (process_count-- > 0) {
				int yw = 0;
				int yi = 0;
				
				for (int x = 0; x < w; x++) {
					vmin[x] = int.min (x + radius + 1, w - 1);
					vmax[x] = int.max (x - radius, 0);
				}
				
				for (int y = 0; y < h; y++) {
					int rsum = 0, gsum = 0, bsum = 0, asum = 0;
					
					for (int i = -radius; i <= radius; i++) {
						uint32 p = (yi + int.min (w - 1, int.max (i, 0))) * channels;
						rsum += pixels[p];
						gsum += pixels[p + 1];
						bsum += pixels[p + 2];
						asum += pixels[p + 3];
					}
					
					for (int x = 0; x < w; x++) {
						r[yi] = dv[rsum];
						g[yi] = dv[gsum];
						b[yi] = dv[bsum];
						a[yi] = dv[asum];
						
						uint32 p1 = (yw + vmin[x]) * channels;
						uint32 p2 = (yw + vmax[x]) * channels;
						
						rsum += pixels[p1] - pixels[p2];
						gsum += pixels[p1 + 1] - pixels[p2 + 1];
						bsum += pixels[p1 + 2] - pixels[p2 + 2];
						asum += pixels[p1 + 3] - pixels[p2 + 3];
						
						yi++;
					}
					
					yw += w;
				}
					
				for (int y = 0; y < h; y++) {
					vmin[y] = int.min (y + radius + 1, h - 1) * w;
					vmax[y] = int.max (y - radius, 0) * w;
				}
				
				for (int x = 0; x < w; x++) {
					int rsum = 0, gsum = 0, bsum = 0, asum = 0;
					int yp = -radius * w;
					
					for (int i = -radius; i <= radius; i++) {
						yi = int.max (0, yp) + x;
						
						rsum += r[yi];
						gsum += g[yi];
						bsum += b[yi];
						asum += a[yi];
						
						yp += w;
					}
					
					yi = x;
					
					for (int y = 0; y < h; y++) {
						pixels[yi * channels] = dv[rsum];
						pixels[yi * channels + 1] = dv[gsum];
						pixels[yi * channels + 2] = dv[bsum];
						pixels[yi * channels + 3] = dv[asum];
						
						uint32 p1 = x + vmin[y];
						uint32 p2 = x + vmax[y];
						
						rsum += r[p1] - r[p2];
						gsum += g[p1] - g[p2];
						bsum += b[p1] - b[p2];
						asum += a[p1] - a[p2];
						
						yi += w;
					}
				}
			}
			
			original.mark_dirty ();
			
			Context.set_operator (Operator.SOURCE);
			Context.set_source_surface (original, 0, 0);
			Context.paint ();
			Context.set_operator (Operator.OVER);
		}
		
		const int AlphaPrecision = 16;
		const int ParamPrecision = 7;
		
		public void exponential_blur (int radius)
		{
			if (radius < 1)
				return;
			
			int alpha = (int) ((1 << AlphaPrecision) * (1.0 - Math.exp (-2.3 / (radius + 1.0))));
			int height = Height;
			int width = Width;
			
			ImageSurface original = new ImageSurface (Format.ARGB32, width, height);
			Cairo.Context cr = new Cairo.Context (original);
			
			cr.set_operator (Operator.SOURCE);
			cr.set_source_surface (Internal, 0, 0);
			cr.paint ();
			
			uchar* pixels = original.get_data ();
			
			// Process Rows
			try {
				unowned Thread th = Thread.create<void*> (() => {
					exponential_blur_rows (pixels, width, height, 0, height / 2, 0, width, alpha);
				}, true);
				
				exponential_blur_rows (pixels, width, height, height / 2, height, 0, width, alpha);
				th.join ();
				
				// Process Columns
				th = Thread.create<void*> (() => {
					exponential_blur_columns (pixels, width, height, 0, width / 2, 0, height, alpha);
				}, true);
				
				exponential_blur_columns (pixels, width, height, width / 2, width, 0, height, alpha);
				th.join ();
			} catch { }
			
			original.mark_dirty ();
			
			Context.set_operator (Operator.SOURCE);
			Context.set_source_surface (original, 0, 0);
			Context.paint ();
			Context.set_operator (Operator.OVER);
		}
		
		void exponential_blur_columns (uchar* pixels, int width, int height, int startCol, int endCol, int startY, int endY, int alpha)
		{
			for (int columnIndex = startCol; columnIndex < endCol; columnIndex++) {
				// blur columns
				uchar *column = pixels + columnIndex * 4;
				
				int zR = column[0] << ParamPrecision;
				int zG = column[1] << ParamPrecision;
				int zB = column[2] << ParamPrecision;
				int zA = column[3] << ParamPrecision;
				
				// Top to Bottom
				for (int index = width * (startY + 1); index < (endY - 1) * width; index += width)
					exponential_blur_inner (&column[index * 4], ref zR, ref zG, ref zB, ref zA, alpha);
				
				// Bottom to Top
				for (int index = (endY - 2) * width; index >= startY; index -= width)
					exponential_blur_inner (&column[index * 4], ref zR, ref zG, ref zB, ref zA, alpha);
			}
		}
		
		void exponential_blur_rows (uchar* pixels, int width, int height, int startRow, int endRow, int startX, int endX, int alpha)
		{
			for (int rowIndex = startRow; rowIndex < endRow; rowIndex++) {
				// Get a pointer to our current row
				uchar* row = pixels + rowIndex * width * 4;
				
				int zR = row[startX + 0] << ParamPrecision;
				int zG = row[startX + 1] << ParamPrecision;
				int zB = row[startX + 2] << ParamPrecision;
				int zA = row[startX + 3] << ParamPrecision;
				
				// Left to Right
				for (int index = startX + 1; index < endX; index++)
					exponential_blur_inner (&row[index * 4], ref zR, ref zG, ref zB, ref zA, alpha);
				
				// Right to Left
				for (int index = endX - 2; index >= startX; index--)
					exponential_blur_inner (&row[index * 4], ref zR, ref zG, ref zB, ref zA, alpha);
			}
		}
		
		void exponential_blur_inner (uchar* pixel, ref int zR, ref int zG, ref int zB, ref int zA, int alpha)
		{
			zR += (alpha * ((pixel[0] << ParamPrecision) - zR)) >> AlphaPrecision;
			zG += (alpha * ((pixel[1] << ParamPrecision) - zG)) >> AlphaPrecision;
			zB += (alpha * ((pixel[2] << ParamPrecision) - zB)) >> AlphaPrecision;
			zA += (alpha * ((pixel[3] << ParamPrecision) - zA)) >> AlphaPrecision;
			
			pixel[0] = (uchar) (zR >> ParamPrecision);
			pixel[1] = (uchar) (zG >> ParamPrecision);
			pixel[2] = (uchar) (zB >> ParamPrecision);
			pixel[3] = (uchar) (zA >> ParamPrecision);
		}
	}
}
