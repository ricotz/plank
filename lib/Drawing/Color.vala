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

using Gdk;

using Plank.Services;

namespace Plank.Drawing
{
	/**
	 * Represents a RGBA color and has methods for manipulating
	 * the color to create similar colors.
	 */
	public class Color : GLib.Object, PrefsSerializable
	{
		/**
		 * The red value for the color.
		 */
		public double R;
		/**
		 * The green value for the color.
		 */
		public double G;
		/**
		 * The blue value for the color.
		 */
		public double B;
		/**
		 * The alpha value for the color.
		 */
		public double A;
		
		/**
		 * Creates a new color object.
		 *
		 * @param R the red value
		 * @param G the green value
		 * @param B the blue value
		 * @param A the alpha value
		 */
		public Color (double R, double G, double B, double A)
		{
			this.R = R;
			this.G = G;
			this.B = B;
			this.A = A;
		}
		
		/**
		 * Creates a new color object from a {@link Gdk.Color}.
		 *
		 * @param color the color to use
		 */
		public Color.from_gdk (Gdk.Color color)
		{
			R = color.red / (double) uint16.MAX;
			G = color.green / (double) uint16.MAX;
			B = color.blue / (double) uint16.MAX;
			A = 1.0;
		}
		
		/**
		 * Sets the hue for the color.
		 *
		 * @param hue the new hue for the color
		 * @return the new color
		 */
		public Color set_hue (double hue)
			requires (hue >= 0 && hue <= 360)
		{
			double h, s, v;
			rgb_to_hsv (R, G, B, out h, out s, out v);
			h = hue;
			hsv_to_rgb (h, s, v, out R, out G, out B);
			
			return this;
		}
		
		/**
		 * Sets the saturation for the color.
		 *
		 * @param sat the new saturation for the color
		 * @return the new color
		 */
		public Color set_sat (double sat)
			requires (sat >= 0 && sat <= 1)
		{
			double h, s, v;
			rgb_to_hsv (R, G, B, out h, out s, out v);
			s = sat;
			hsv_to_rgb (h, s, v, out R, out G, out B);
			
			return this;
		}
		
		/**
		 * Sets the value for the color.
		 *
		 * @param val the new value for the color
		 * @return the new color
		 */
		public Color set_val (double val)
			requires (val >= 0 && val <= 1)
		{
			double h, s, v;
			rgb_to_hsv (R, G, B, out h, out s, out v);
			v = val;
			hsv_to_rgb (h, s, v, out R, out G, out B);
			
			return this;
		}
		
		/**
		 * Sets the alpha for the color.
		 *
		 * @param alpha the new alpha for the color
		 * @return the new color
		 */
		public Color set_alpha (double alpha)
			requires (alpha >= 0 && alpha <= 1)
		{
			A = alpha;
			return this;
		}
		
		/**
		 * Returns the hue for the color.
		 *
		 * @return the hue for the color
		 */
		public double get_hue ()
		{
			double h, s, v;
			rgb_to_hsv (R, G, B, out h, out s, out v);
			return h;
		}
		
		/**
		 * Returns the saturation for the color.
		 *
		 * @return the saturation for the color
		 */
		public double get_sat ()
		{
			double h, s, v;
			rgb_to_hsv (R, G, B, out h, out s, out v);
			return s;
		}
		
		/**
		 * Returns the value for the color.
		 *
		 * @return the value for the color
		 */
		public double get_val ()
		{
			double h, s, v;
			rgb_to_hsv (R, G, B, out h, out s, out v);
			return v;
		}
		
		/**
		 * Increases the color's hue.
		 *
		 * @param val the amount to add to the hue
		 * @return the new color
		 */
		public Color add_hue (double val)
		{
			double h, s, v;
			rgb_to_hsv (R, G, B, out h, out s, out v);
			h = (((h + val) % 360) + 360) % 360;
			hsv_to_rgb (h, s, v, out R, out G, out B);
			
			return this;
		}
		
		/**
		 * Limits the color's saturation.
		 *
		 * @param sat the minimum saturation allowed
		 * @return the new color
		 */
		public Color set_min_sat (double sat)
			requires (sat >= 0 && sat <= 1)
		{
			double h, s, v;
			rgb_to_hsv (R, G, B, out h, out s, out v);
			s = double.max (s, sat);
			hsv_to_rgb (h, s, v, out R, out G, out B);
			
			return this;
		}
		
		/**
		 * Limits the color's value.
		 *
		 * @param val the minimum value allowed
		 * @return the new color
		 */
		public Color set_min_value (double val)
			requires (val >= 0 && val <= 1)
		{
			double h, s, v;
			rgb_to_hsv (R, G, B, out h, out s, out v);
			v = double.max (v, val);
			hsv_to_rgb (h, s, v, out R, out G, out B);
			
			return this;
		}
		
		/**
		 * Limits the color's saturation.
		 *
		 * @param sat the maximum saturation allowed
		 * @return the new color
		 */
		public Color set_max_sat (double sat)
			requires (sat >= 0 && sat <= 1)
		{
			double h, s, v;
			rgb_to_hsv (R, G, B, out h, out s, out v);
			s = double.min (s, sat);
			hsv_to_rgb (h, s, v, out R, out G, out B);
			
			return this;
		}

		/**
		 * Limits the color's value.
		 *
		 * @param val the maximum value allowed
		 * @return the new color
		 */
		public Color set_max_val (double val)
			requires (val >= 0 && val <= 1)
		{
			double h, s, v;
			rgb_to_hsv (R, G, B, out h, out s, out v);
			v = double.min (v, val);
			hsv_to_rgb (h, s, v, out R, out G, out B);
			
			return this;
		}
		
		/**
		 * Multiplies the color's saturation using the amount.
		 *
		 * @param amount amount to multiply the saturation by
		 * @return the new color
		 */
		public Color multiply_sat (double amount)
			requires (amount >= 0)
		{
			double h, s, v;
			rgb_to_hsv (R, G, B, out h, out s, out v);
			s = double.min (1, s * amount);
			hsv_to_rgb (h, s, v, out R, out G, out B);
			
			return this;
		}
		
		/**
		 * Brighten the color's value using the value.
		 *
		 * @param amount percent of the value to brighten by
		 * @return the new color
		 */
		public Color brighten_val (double amount)
			requires (amount >= 0 && amount <= 1)
		{
			double h, s, v;
			rgb_to_hsv (R, G, B, out h, out s, out v);
			v = double.min (1, v + (1 - v) * amount);
			hsv_to_rgb (h, s, v, out R, out G, out B);
			
			return this;
		}
		
		/**
		 * Darkens the color's value using the value.
		 *
		 * @param amount percent of the value to darken by
		 * @return the new color
		 */
		public Color darken_val (double amount)
			requires (amount >= 0 && amount <= 1)
		{
			double h, s, v;
			rgb_to_hsv (R, G, B, out h, out s, out v);
			v = double.max (0, v - (1 - v) * amount);
			hsv_to_rgb (h, s, v, out R, out G, out B);
			
			return this;
		}
		
		/**
		 * Darkens the color's value using the saturtion.
		 *
		 * @param amount percent of the saturation to darken by
		 * @return the new color
		 */
		public Color darken_by_sat (double amount)
			requires (amount >= 0 && amount <= 1)
		{
			double h, s, v;
			rgb_to_hsv (R, G, B, out h, out s, out v);
			v = double.max (0, v - amount * s);
			hsv_to_rgb (h, s, v, out R, out G, out B);
			
			return this;
		}
		
		void rgb_to_hsv (double r, double g, double b, out double h, out double s, out double v)
			requires (r >= 0 && r <= 1)
			requires (g >= 0 && g <= 1)
			requires (b >= 0 && b <= 1)
		{
			var min = double.min (r, double.min (g, b));
			var max = double.max (r, double.max (g, b));
			
			v = max;
			if (v == 0) {
				h = 0;
				s = 0;
				return;
			}
			
			// normalize value to 1
			r /= v;
			g /= v;
			b /= v;
			
			min = double.min (r, double.min (g, b));
			max = double.max (r, double.max (g, b));
			
			var delta = max - min;
			s = delta;
			if (s == 0) {
				h = 0;
				return;
			}
			
			// normalize saturation to 1
			r = (r - min) / delta;
			g = (g - min) / delta;
			b = (b - min) / delta;
			
			if (max == r) {
				h = 0 + 60 * (g - b);
				if (h < 0)
					h += 360;
			} else if (max == g) {
				h = 120 + 60 * (b - r);
			} else {
				h = 240 + 60 * (r - g);
			}
		}
		
		void hsv_to_rgb (double h, double s, double v, out double r, out double g, out double b)
			requires (h >= 0 && h <= 360)
			requires (s >= 0 && s <= 1)
			requires (v >= 0 && v <= 1)
		{
			r = 0; 
			g = 0; 
			b = 0;

			if (s == 0) {
				r = v;
				g = v;
				b = v;
			} else {
				var secNum = (int) Math.floor (h / 60);
				var fracSec = h / 60.0 - secNum;

				var p = v * (1 - s);
				var q = v * (1 - s * fracSec);
				var t = v * (1 - s * (1 - fracSec));
				
				switch (secNum) {
				case 0:
					r = v;
					g = t;
					b = p;
					break;
				case 1:
					r = q;
					g = v;
					b = p;
					break;
				case 2:
					r = p;
					g = v;
					b = t;
					break;
				case 3:
					r = p;
					g = q;
					b = v;
					break;
				case 4:
					r = t;
					g = p;
					b = v;
					break;
				case 5:
					r = v;
					g = p;
					b = q;
					break;
				}
			}
		}
		
		/**
		 * {@inheritDoc}
		 */
		public string prefs_serialize ()
		{
			return "%d;;%d;;%d;;%d".printf ((int) (R * uint8.MAX),
				(int) (G * uint8.MAX),
				(int) (B * uint8.MAX),
				(int) (A * uint8.MAX));
		}
		
		/**
		 * {@inheritDoc}
		 */
		public void prefs_deserialize (string s)
		{
			var parts = s.split (";;");
			
#if VALA_0_12
			R = double.min (uint8.MAX, double.max (0, int.parse (parts [0]))) / uint8.MAX;
			G = double.min (uint8.MAX, double.max (0, int.parse (parts [1]))) / uint8.MAX;
			B = double.min (uint8.MAX, double.max (0, int.parse (parts [2]))) / uint8.MAX;
			A = double.min (uint8.MAX, double.max (0, int.parse (parts [3]))) / uint8.MAX;
#else
			R = double.min (uint8.MAX, double.max (0, parts [0].to_int ())) / uint8.MAX;
			G = double.min (uint8.MAX, double.max (0, parts [1].to_int ())) / uint8.MAX;
			B = double.min (uint8.MAX, double.max (0, parts [2].to_int ())) / uint8.MAX;
			A = double.min (uint8.MAX, double.max (0, parts [3].to_int ())) / uint8.MAX;
#endif
		}
	}
}
