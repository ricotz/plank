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
	 * A surface is a wrapper class for a {@link Cairo.Surface}.
	 * It encapsulates a surface/context and provides utility methods.
	 */
	public class Surface : GLib.Object
	{
		const int EXP_BLUR_ALPHA_PRECISION = 16;
		const int EXP_BLUR_PARAM_PRECISION = 7;
		
		/**
		 * The internal {@link Cairo.Surface} backing the surface.
		 */
		public Cairo.Surface Internal { get; construct; }
		
		/**
		 * The width of the surface.
		 */
		public int Width { get; construct; }
		
		/**
		 * The height of the surface.
		 */
		public int Height { get; construct; }
		
		/**
		 * A {@link Cairo.Context} for the surface.
		 */
		public Cairo.Context Context { get; construct; }
		
		/**
		 * Creates a new surface.
		 *
		 * @param width width of the new surface
		 * @param height height of the new surface
		 */
		public Surface (int width, int height)
		{
			Object (Width: width, Height: height, Internal: new Cairo.ImageSurface (Cairo.Format.ARGB32, width, height));
		}
		
		/**
		 * Creates a new surface compatible with an existing {@link Cairo.Surface}.
		 *
		 * @param width width of the new surface
		 * @param height height of the new surface
		 * @param model existing {@link Cairo.Surface} to be similar to
		 */
		public Surface.with_cairo_surface (int width, int height, Cairo.Surface model)
		{
			Object (Width: width, Height: height, Internal: new Cairo.Surface.similar (model, Cairo.Content.COLOR_ALPHA, width, height));
		}

		/**
		 * Creates a new surface compatible with an existing {@link Surface}.
		 *
		 * @param width width of the new surface
		 * @param height height of the new surface
		 * @param model existing {@link Surface} to be similar to
		 */
		public Surface.with_surface (int width, int height, Surface model)
		{
			Object (Width: width, Height: height, Internal: new Cairo.Surface.similar (model.Internal, Cairo.Content.COLOR_ALPHA, width, height));
		}
		
		/**
		 * Creates a new surface with the given {@link Cairo.ImageSurface} as Internal.
		 *
		 * @param image existing {@link Cairo.ImageSurface} as Internal
		 */
		public Surface.with_internal (Cairo.ImageSurface image)
		{
			Object (Width: image.get_width (), Height: image.get_height (), Internal: image);
		}
		
		construct
		{
			Context = new Cairo.Context (Internal);
		}
		
		/**
		 * Clears the entire surface.
		 */
		public void clear ()
		{
			unowned Cairo.Context cr = Context;
			
			cr.save ();
			cr.set_operator (Cairo.Operator.CLEAR);
			cr.paint ();
			cr.restore ();
		}
		
		/**
		 * Create a copy of the surface
		 *
		 * @return copy of this surface
		 */
		public Surface copy ()
		{
			var copy = new Surface.with_surface (Width, Height, this);
			unowned Cairo.Context cr = copy.Context;
			
			cr.set_source_surface (Internal, 0, 0);
			cr.paint ();
			
			return copy;
		}
		
		/**
		 * Create a scaled copy of the surface
		 *
		 * @param width the resulting width
		 * @param height the resulting height
		 * @return scaled copy of this surface
		 */
		public Surface scaled_copy (int width, int height)
		{
			var result = new Surface.with_surface (width, height, this);
			unowned Cairo.Context cr = result.Context;
			
			cr.save ();
			cr.scale ((double) width / Width, (double) height / Height);
			cr.set_source_surface (Internal, 0, 0);
			cr.paint ();
			cr.restore ();
			
			return result;
		}
		
		/**
		 * Saves the current surface to a {@link Gdk.Pixbuf}.
		 *
		 * @return the {@link Gdk.Pixbuf}
		 */
		public Gdk.Pixbuf to_pixbuf ()
		{
			return Gdk.pixbuf_get_from_surface (Internal, 0, 0, Width, Height);
		}
		
		/**
		 * Computes the mask of the surface.
		 *
		 * @param threshold value defining the minimum opacity [0.0 .. 1.0]
		 * @param extent bounding box of the found mask
		 * @return a new surface containing the mask
		 */
		public Surface create_mask (double threshold, out Gdk.Rectangle extent)
			requires (threshold >= 0.0 && threshold <= 1.0)
		{
			var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, Width, Height);
			var cr = new Cairo.Context (surface);
			
			cr.set_operator (Cairo.Operator.SOURCE);
			cr.set_source_surface (Internal, 0, 0);
			cr.paint ();
			
			int w = surface.get_width ();
			int h = surface.get_height ();
			uint8 slice = (uint8) (uint8.MAX * threshold);
			
			int left = w;
			int right = 0;
			int top = h;
			int bottom = 0;
			
			uint8 *data = surface.get_data ();
			
			int src;
			bool mask;
			for (int y = 0; y < h; y++) {
				for (int x = 0; x < w; x++) {
					src = (y * w + x) * 4;
					
					mask = data[src + 3] > slice;
					
					data[src + 0] = 0;
					data[src + 1] = 0;
					data[src + 2] = 0;
					data[src + 3] = (mask ? uint8.MAX : 0);
					
					if (mask) {
						if (y < top)
							top = y;
						if (y > bottom)
							bottom = y;
						if (x < left)
							left = x;
						if (x > right)
							right = x;
					}
				}
			}
			
			extent = {left, top, right - left, bottom - top};
			
			return new Surface.with_internal (surface);
		}
		
		/**
		 * Computes and returns the average color of the surface.
		 *
		 * @return the average color of the surface
		 */
		public Color average_color ()
		{
			return DrawingService.average_color (Gdk.pixbuf_get_from_surface (Internal, 0, 0, Width, Height));
		}
		
		/**
		 * Performs a fast blur on the surface.
		 *
		 * @param radius the radius of the blur
		 * @param process_count how many iterations to blur
		 */
		public void fast_blur (int radius, int process_count = 1)
		{
			if (radius < 1 || process_count < 1)
				return;
			
			var w = Width;
			var h = Height;
			var channels = 4;
			
			if (radius > w - 1 || radius > h - 1)
				return;
			
			var original = new Cairo.ImageSurface (Cairo.Format.ARGB32, w, h);
			var cr = new Cairo.Context (original);
			
			cr.set_operator (Cairo.Operator.SOURCE);
			cr.set_source_surface (Internal, 0, 0);
			cr.paint ();
			
			uint8 *pixels = original.get_data ();
			var buffer = new uint8[w * h * channels];
			
			var vmin = new int[int.max (w, h)];
			var vmax = new int[int.max (w, h)];
			
			var div = 2 * radius + 1;
			var dv = new uint8[256 * div];
			for (var i = 0; i < dv.length; i++)
				dv[i] = (uint8) (i / div);
			
			while (process_count-- > 0) {
				for (var x = 0; x < w; x++) {
					vmin[x] = int.min (x + radius + 1, w - 1);
					vmax[x] = int.max (x - radius, 0);
				}
				
				for (var y = 0; y < h; y++) {
					var asum = 0, rsum = 0, gsum = 0, bsum = 0;
					
					uint32 cur_pixel = y * w * channels;
					
					asum += radius * pixels[cur_pixel + 0];
					rsum += radius * pixels[cur_pixel + 1];
					gsum += radius * pixels[cur_pixel + 2];
					bsum += radius * pixels[cur_pixel + 3];
					
					for (var i = 0; i <= radius; i++) {
						asum += pixels[cur_pixel + 0];
						rsum += pixels[cur_pixel + 1];
						gsum += pixels[cur_pixel + 2];
						bsum += pixels[cur_pixel + 3];
						
						cur_pixel += channels;
					}
					
					cur_pixel = y * w * channels;
					
					for (var x = 0; x < w; x++) {
						uint32 p1 = (y * w + vmin[x]) * channels;
						uint32 p2 = (y * w + vmax[x]) * channels;
						
						buffer[cur_pixel + 0] = dv[asum];
						buffer[cur_pixel + 1] = dv[rsum];
						buffer[cur_pixel + 2] = dv[gsum];
						buffer[cur_pixel + 3] = dv[bsum];
						
						asum += pixels[p1 + 0] - pixels[p2 + 0];
						rsum += pixels[p1 + 1] - pixels[p2 + 1];
						gsum += pixels[p1 + 2] - pixels[p2 + 2];
						bsum += pixels[p1 + 3] - pixels[p2 + 3];
						
						cur_pixel += channels;
					}
				}
				
				for (var y = 0; y < h; y++) {
					vmin[y] = int.min (y + radius + 1, h - 1) * w;
					vmax[y] = int.max (y - radius, 0) * w;
				}
				
				for (var x = 0; x < w; x++) {
					var asum = 0, rsum = 0, gsum = 0, bsum = 0;
					
					uint32 cur_pixel = x * channels;
					
					asum += radius * buffer[cur_pixel + 0];
					rsum += radius * buffer[cur_pixel + 1];
					gsum += radius * buffer[cur_pixel + 2];
					bsum += radius * buffer[cur_pixel + 3];
					
					for (var i = 0; i <= radius; i++) {
						asum += buffer[cur_pixel + 0];
						rsum += buffer[cur_pixel + 1];
						gsum += buffer[cur_pixel + 2];
						bsum += buffer[cur_pixel + 3];
						
						cur_pixel += w * channels;
					}
					
					cur_pixel = x * channels;
					
					for (var y = 0; y < h; y++) {
						uint32 p1 = (x + vmin[y]) * channels;
						uint32 p2 = (x + vmax[y]) * channels;
						
						pixels[cur_pixel + 0] = dv[asum];
						pixels[cur_pixel + 1] = dv[rsum];
						pixels[cur_pixel + 2] = dv[gsum];
						pixels[cur_pixel + 3] = dv[bsum];
						
						asum += buffer[p1 + 0] - buffer[p2 + 0];
						rsum += buffer[p1 + 1] - buffer[p2 + 1];
						gsum += buffer[p1 + 2] - buffer[p2 + 2];
						bsum += buffer[p1 + 3] - buffer[p2 + 3];
						
						cur_pixel += w * channels;
					}
				}
			}
			
			original.mark_dirty ();
			
			unowned Cairo.Context target_cr = Context;
			target_cr.save ();
			target_cr.set_operator (Cairo.Operator.SOURCE);
			target_cr.set_source_surface (original, 0, 0);
			target_cr.paint ();
			target_cr.restore ();
		}
		
		/**
		 * Performs an exponential blur on the surface.
		 *
		 * @param radius the radius of the blur
		 */
		public void exponential_blur (int radius)
		{
			if (radius < 1)
				return;
			
			var alpha = (int) ((1 << EXP_BLUR_ALPHA_PRECISION) * (1.0 - Math.exp (-2.3 / (radius + 1.0))));
			var height = Height;
			var width = Width;
			
			var original = new Cairo.ImageSurface (Cairo.Format.ARGB32, width, height);
			var cr = new Cairo.Context (original);
			
			cr.set_operator (Cairo.Operator.SOURCE);
			cr.set_source_surface (Internal, 0, 0);
			cr.paint ();
			
			uint8 *pixels = original.get_data ();
			
			var th = new Thread<void*> (null, () => {
				exponential_blur_rows (pixels, width, height, 0, height / 2, 0, width, alpha);
				return null;
			});
			
			exponential_blur_rows (pixels, width, height, height / 2, height, 0, width, alpha);
			th.join ();
			
			// Process Columns
			var th2 = new Thread<void*> (null, () => {
				exponential_blur_columns (pixels, width, height, 0, width / 2, 0, height, alpha);
				return null;
			});
			
			exponential_blur_columns (pixels, width, height, width / 2, width, 0, height, alpha);
			th2.join ();
			
			original.mark_dirty ();
			
			unowned Cairo.Context target_cr = Context;
			target_cr.save ();
			target_cr.set_operator (Cairo.Operator.SOURCE);
			target_cr.set_source_surface (original, 0, 0);
			target_cr.paint ();
			target_cr.restore ();
		}
		
		static void exponential_blur_columns (uint8* pixels, int width, int height, int startCol, int endCol, int startY, int endY, int alpha)
		{
			for (var columnIndex = startCol; columnIndex < endCol; columnIndex++) {
				// blur columns
				uint8 *column = pixels + columnIndex * 4;
				
				var zA = column[0] << EXP_BLUR_PARAM_PRECISION;
				var zR = column[1] << EXP_BLUR_PARAM_PRECISION;
				var zG = column[2] << EXP_BLUR_PARAM_PRECISION;
				var zB = column[3] << EXP_BLUR_PARAM_PRECISION;
				
				// Top to Bottom
				for (var index = width * (startY + 1); index < (endY - 1) * width; index += width)
					exponential_blur_inner (&column[index * 4], ref zA, ref zR, ref zG, ref zB, alpha);
				
				// Bottom to Top
				for (var index = (endY - 2) * width; index >= startY; index -= width)
					exponential_blur_inner (&column[index * 4], ref zA, ref zR, ref zG, ref zB, alpha);
			}
		}
		
		static void exponential_blur_rows (uint8* pixels, int width, int height, int startRow, int endRow, int startX, int endX, int alpha)
		{
			for (var rowIndex = startRow; rowIndex < endRow; rowIndex++) {
				// Get a pointer to our current row
				uint8* row = pixels + rowIndex * width * 4;
				
				var zA = row[startX + 0] << EXP_BLUR_PARAM_PRECISION;
				var zR = row[startX + 1] << EXP_BLUR_PARAM_PRECISION;
				var zG = row[startX + 2] << EXP_BLUR_PARAM_PRECISION;
				var zB = row[startX + 3] << EXP_BLUR_PARAM_PRECISION;
				
				// Left to Right
				for (var index = startX + 1; index < endX; index++)
					exponential_blur_inner (&row[index * 4], ref zA, ref zR, ref zG, ref zB, alpha);
				
				// Right to Left
				for (var index = endX - 2; index >= startX; index--)
					exponential_blur_inner (&row[index * 4], ref zA, ref zR, ref zG, ref zB, alpha);
			}
		}
		
		static inline void exponential_blur_inner (uint8* pixel, ref int zA, ref int zR, ref int zG, ref int zB, int alpha)
		{
			zA += (alpha * ((pixel[0] << EXP_BLUR_PARAM_PRECISION) - zA)) >> EXP_BLUR_ALPHA_PRECISION;
			zR += (alpha * ((pixel[1] << EXP_BLUR_PARAM_PRECISION) - zR)) >> EXP_BLUR_ALPHA_PRECISION;
			zG += (alpha * ((pixel[2] << EXP_BLUR_PARAM_PRECISION) - zG)) >> EXP_BLUR_ALPHA_PRECISION;
			zB += (alpha * ((pixel[3] << EXP_BLUR_PARAM_PRECISION) - zB)) >> EXP_BLUR_ALPHA_PRECISION;
			
			pixel[0] = (uint8) (zA >> EXP_BLUR_PARAM_PRECISION);
			pixel[1] = (uint8) (zR >> EXP_BLUR_PARAM_PRECISION);
			pixel[2] = (uint8) (zG >> EXP_BLUR_PARAM_PRECISION);
			pixel[3] = (uint8) (zB >> EXP_BLUR_PARAM_PRECISION);
		}
		
		/**
		 * Performs a gaussian blur on the surface.
		 * ''Note: This method is wickedly slow''
		 *
		 * @param radius the radius of the blur
		 */
		public void gaussian_blur (int radius)
		{
			if (radius < 1)
				return;
			
			var gaussWidth = radius * 2 + 1;
			var kernel = build_gaussian_kernel (gaussWidth);
			
			var width = Width;
			var height = Height;
			
			var original = new Cairo.ImageSurface (Cairo.Format.ARGB32, width, height);
			var cr = new Cairo.Context (original);
			
			cr.set_operator (Cairo.Operator.SOURCE);
			cr.set_source_surface (Internal, 0, 0);
			cr.paint ();
			
			uint8 *src = original.get_data ();
			
			var size = height * original.get_stride ();
			
			var abuffer = new double[size];
			var bbuffer = new double[size];
			
			// Copy image to double[] for faster horizontal pass
			for (var i = 0; i < size; i++)
				abuffer[i] = (double) src[i];
			
			// Precompute horizontal shifts
			var shiftar = new int[int.max (width, height), gaussWidth];
			for (var x = 0; x < width; x++)
				for (var k = 0; k < gaussWidth; k++) {
					var shift = k - radius;
					if (x + shift <= 0 || x + shift >= width)
						shiftar[x, k] = 0;
					else
						shiftar[x, k] = shift * 4;
				}
			
			var th = new Thread<void*> (null, () => {
				gaussian_blur_horizontal (abuffer, bbuffer, kernel, gaussWidth, width, height, 0, height / 2, shiftar);
				return null;
			});
			
			gaussian_blur_horizontal (abuffer, bbuffer, kernel, gaussWidth, width, height, height / 2, height, shiftar);
			th.join ();
			
			// Clear buffer
			Posix.memset (abuffer, 0, sizeof(double) * size);
			
			// Precompute vertical shifts
			shiftar = new int[int.max (width, height), gaussWidth];
			for (var y = 0; y < height; y++)
				for (var k = 0; k < gaussWidth; k++) {
					var shift = k - radius;
					if (y + shift <= 0 || y + shift >= height)
						shiftar[y, k] = 0;
					else
						shiftar[y, k] = shift * width * 4;
				}
			
			// Vertical Pass
			var th2 = new Thread<void*> (null, () => {
				gaussian_blur_vertical (bbuffer, abuffer, kernel, gaussWidth, width, height, 0, width / 2, shiftar);
				return null;
			});
			
			gaussian_blur_vertical (bbuffer, abuffer, kernel, gaussWidth, width, height, width / 2, width, shiftar);
			th2.join ();
			
			// Save blurred image to original uint8[]
			for (var i = 0; i < size; i++)
				src[i] = (uint8) abuffer[i];
			
			original.mark_dirty ();
			
			unowned Cairo.Context target_cr = Context;
			target_cr.save ();
			target_cr.set_operator (Cairo.Operator.SOURCE);
			target_cr.set_source_surface (original, 0, 0);
			target_cr.paint ();
			target_cr.restore ();
		}

		static void gaussian_blur_horizontal (double* src, double* dest, double* kernel, int gaussWidth, int width, int height,
			int startRow, int endRow, int[,] shift)
		{
			uint32 cur_pixel = startRow * width * 4;
			
			for (var y = startRow; y < endRow; y++) {
				for (var x = 0; x < width; x++) {
					for (var k = 0; k < gaussWidth; k++) {
						var source = cur_pixel + shift[x, k];
						var kernel_k = kernel[k];
						
						dest[cur_pixel + 0] += src[source + 0] * kernel_k;
						dest[cur_pixel + 1] += src[source + 1] * kernel_k;
						dest[cur_pixel + 2] += src[source + 2] * kernel_k;
						dest[cur_pixel + 3] += src[source + 3] * kernel_k;
					}
					
					cur_pixel += 4;
				}
			}
		}
		
		static void gaussian_blur_vertical (double* src, double* dest, double* kernel, int gaussWidth, int width, int height,
			int startCol, int endCol, int[,] shift)
		{
			uint32 cur_pixel = startCol * 4;
			
			for (var y = 0; y < height; y++) {
				for (var x = startCol; x < endCol; x++) {
					for (var k = 0; k < gaussWidth; k++) {
						var source = cur_pixel + shift[y, k];
						var kernel_k = kernel[k];
						
						dest[cur_pixel + 0] += src[source + 0] * kernel_k;
						dest[cur_pixel + 1] += src[source + 1] * kernel_k;
						dest[cur_pixel + 2] += src[source + 2] * kernel_k;
						dest[cur_pixel + 3] += src[source + 3] * kernel_k;
					}
					
					cur_pixel += 4;
				}
				cur_pixel += (width - endCol + startCol) * 4;
			}
		}
		
		static double[] build_gaussian_kernel (int gaussWidth)
			requires (gaussWidth % 2 == 1)
		{
			var kernel = new double[gaussWidth];
			
			// Maximum value of curve
			var sd = 255.0;
			
			// Width of curve
			var range = gaussWidth;
			
			// Average value of curve
			var mean = range / sd;
			
			for (var i = 0; i < gaussWidth / 2 + 1; i++)
				kernel[gaussWidth - i - 1] = kernel[i] = Math.pow (Math.sin (((i + 1) * Math.PI_2 - mean) / range), 2) * sd;
			
			// normalize the values
			var gaussSum = 0.0;
			foreach (var d in kernel)
				gaussSum += d;
			
			for (var i = 0; i < kernel.length; i++)
				kernel[i] = kernel[i] / gaussSum;
			
			return kernel;
		}
	}
}
