//
//  Copyright (C) 2011 Robert Dyer
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
	 * Represents a RGBA color and has methods for manipulating the color.
	 */
	public struct Color : Gdk.RGBA
	{
		/**
		 * Create new color for the given HSV values while
		 * h in [0,360), s in [0,1] and v in [0,1]
		 *
		 * @param h the hue for the color
		 * @param s the saturation for the color
		 * @param v the value for the color
		 * @return new {@link Color} based on the HSV values
		 */
		public static Color from_hsv (double h, double s, double v)
		{
			Color result = { 1.0, 1.0, 1.0, 1.0 };
			result.set_hsv (h, s, v);
			return result;
		}
		
		/**
		 * Create new color for the given HSL values while
		 * h in [0,360), s in [0,1] and l in [0,1]
		 *
		 * @param h the hue for the color
		 * @param s the saturation for the color
		 * @param l the lightness for the color
		 * @return new {@link Color} based on the HSL values
		 */
		public static Color from_hsl (double h, double s, double l)
		{
			Color result = { 1.0, 1.0, 1.0, 1.0 };
			result.set_hsl (h, s, l);
			return result;
		}
		
		/**
		 * Set HSV color values of this color.
		 */
		public void set_hsv (double h, double s, double v)
		{
			hsv_to_rgb (h, s, v, out red, out green, out blue);
		}
		
		/**
		 * Sets the hue for the color.
		 *
		 * @param hue the new hue for the color
		 */
		public void set_hue (double hue)
			requires (hue >= 0 && hue <= 360)
		{
			double h, s, v;
			rgb_to_hsv (red, green, blue, out h, out s, out v);
			h = hue;
			hsv_to_rgb (h, s, v, out red, out green, out blue);
		}
		
		/**
		 * Sets the saturation for the color.
		 *
		 * @param sat the new saturation for the color
		 */
		public void set_sat (double sat)
			requires (sat >= 0 && sat <= 1)
		{
			double h, s, v;
			rgb_to_hsv (red, green, blue, out h, out s, out v);
			s = sat;
			hsv_to_rgb (h, s, v, out red, out green, out blue);
		}
		
		/**
		 * Sets the value for the color.
		 *
		 * @param val the new value for the color
		 */
		public void set_val (double val)
			requires (val >= 0 && val <= 1)
		{
			double h, s, v;
			rgb_to_hsv (red, green, blue, out h, out s, out v);
			v = val;
			hsv_to_rgb (h, s, v, out red, out green, out blue);
		}
		
		/**
		 * Get HSV color values of this color.
		 */
		public void get_hsv (out double h, out double s, out double v)
		{
			rgb_to_hsv (red, green, blue, out h, out s, out v);
		}
		
		/**
		 * Returns the hue for the color.
		 *
		 * @return the hue for the color
		 */
		public double get_hue ()
		{
			double h, s, v;
			rgb_to_hsv (red, green, blue, out h, out s, out v);
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
			rgb_to_hsv (red, green, blue, out h, out s, out v);
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
			rgb_to_hsv (red, green, blue, out h, out s, out v);
			return v;
		}
		
		/**
		 * Increases the color's hue.
		 *
		 * @param val the amount to add to the hue
		 */
		public void add_hue (double val)
		{
			double h, s, v;
			rgb_to_hsv (red, green, blue, out h, out s, out v);
			h = (((h + val) % 360) + 360) % 360;
			hsv_to_rgb (h, s, v, out red, out green, out blue);
		}
		
		/**
		 * Assures the color's saturation is greater than or equal to the given one.
		 *
		 * @param sat the minimum saturation
		 */
		public void set_min_sat (double sat)
			requires (sat >= 0 && sat <= 1)
		{
			double h, s, v;
			rgb_to_hsv (red, green, blue, out h, out s, out v);
			s = double.max (s, sat);
			hsv_to_rgb (h, s, v, out red, out green, out blue);
		}
		
		/**
		 * Assures the color's value is greater than or equal to the given one.
		 *
		 * @param val the minimum value
		 */
		public void set_min_val (double val)
			requires (val >= 0 && val <= 1)
		{
			double h, s, v;
			rgb_to_hsv (red, green, blue, out h, out s, out v);
			v = double.max (v, val);
			hsv_to_rgb (h, s, v, out red, out green, out blue);
		}
		
		/**
		 * Assures the color's saturation is less than or equal to the given one.
		 *
		 * @param sat the maximum saturation
		 */
		public void set_max_sat (double sat)
			requires (sat >= 0 && sat <= 1)
		{
			double h, s, v;
			rgb_to_hsv (red, green, blue, out h, out s, out v);
			s = double.min (s, sat);
			hsv_to_rgb (h, s, v, out red, out green, out blue);
		}

		/**
		 * Assures the color's value is less than or equal to the given one.
		 *
		 * @param val the maximum value
		 */
		public void set_max_val (double val)
			requires (val >= 0 && val <= 1)
		{
			double h, s, v;
			rgb_to_hsv (red, green, blue, out h, out s, out v);
			v = double.min (v, val);
			hsv_to_rgb (h, s, v, out red, out green, out blue);
		}
		
		/**
		 * Multiplies the color's saturation using the amount.
		 *
		 * @param amount amount to multiply the saturation by
		 */
		public void multiply_sat (double amount)
			requires (amount >= 0)
		{
			double h, s, v;
			rgb_to_hsv (red, green, blue, out h, out s, out v);
			s = double.min (1, s * amount);
			hsv_to_rgb (h, s, v, out red, out green, out blue);
		}
		
		/**
		 * Brighten the color's value using the value.
		 *
		 * @param amount percent of the value to brighten by
		 */
		public void brighten_val (double amount)
			requires (amount >= 0 && amount <= 1)
		{
			double h, s, v;
			rgb_to_hsv (red, green, blue, out h, out s, out v);
			v = double.min (1, v + (1 - v) * amount);
			hsv_to_rgb (h, s, v, out red, out green, out blue);
		}
		
		/**
		 * Darkens the color's value using the value.
		 *
		 * @param amount percent of the value to darken by
		 */
		public void darken_val (double amount)
			requires (amount >= 0 && amount <= 1)
		{
			double h, s, v;
			rgb_to_hsv (red, green, blue, out h, out s, out v);
			v = double.max (0, v - (1 - v) * amount);
			hsv_to_rgb (h, s, v, out red, out green, out blue);
		}
		
		/**
		 * Darkens the color's value using the saturtion.
		 *
		 * @param amount percent of the saturation to darken by
		 */
		public void darken_by_sat (double amount)
			requires (amount >= 0 && amount <= 1)
		{
			double h, s, v;
			rgb_to_hsv (red, green, blue, out h, out s, out v);
			v = double.max (0, v - amount * s);
			hsv_to_rgb (h, s, v, out red, out green, out blue);
		}
		
		/**
		 * Get HSL color values of this color.
		 */
		public void get_hsl (out double h, out double s, out double l)
		{
			rgb_to_hsl (red, green, blue, out h, out s, out l);
		}
		
		/**
		 * Set HSL color values of this color.
		 */
		public void set_hsl (double h, double s, double v)
		{
			hsl_to_rgb (h, s, v, out red, out green, out blue);
		}
		
		static void rgb_to_hsv (double r, double g, double b, out double h, out double s, out double v)
			requires (r >= 0 && r <= 1)
			requires (g >= 0 && g <= 1)
			requires (b >= 0 && b <= 1)
		{
			v = double.max (r, double.max (g, b));
			if (v == 0) {
				h = 0;
				s = 0;
				return;
			}
			
			// normalize value to 1
			r /= v;
			g /= v;
			b /= v;
			
			var min = double.min (r, double.min (g, b));
			var max = double.max (r, double.max (g, b));
			
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
		
		static void hsv_to_rgb (double h, double s, double v, out double r, out double g, out double b)
			requires (h >= 0 && h < 360)
			requires (s >= 0 && s <= 1)
			requires (v >= 0 && v <= 1)
		{
			if (s == 0) {
				r = v;
				g = v;
				b = v;
			} else {
				var secNum = (int) (h / 60);
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
				default:
					assert_not_reached ();
				}
			}
		}
		
		static void rgb_to_hsl (double r, double g, double b, out double h, out double s, out double l)
			requires (r >= 0 && r <= 1)
			requires (g >= 0 && g <= 1)
			requires (b >= 0 && b <= 1)
		{
			var max = double.max (r, double.max (g, b));
			if (max == 0.0) {
				h = 0.0;
				s = 0.0;
				l = 0.0;
				return;
			}
			
			var min = double.min (r, double.min (g, b));
			l = (min + max) / 2.0;
			if (l <= 0.0) {
				h = 0.0;
				s = 0.0;
				return;
			}
			
			var delta = max - min;
			if (delta <= 0.0) {
				h = 0.0;
				s = 0.0;
				return;
			}
			
			s = delta / (l <= 0.5 ? min + max : 2.0 - min - max);
			
			var r2 = 60 * (max - r) / delta;
			var g2 = 60 * (max - g) / delta;
			var b2 = 60 * (max - b) / delta;
			
			if (max == r) {
				h = (b2 - g2);
				if (h < 0)
					h += 360;
			} else if (max == g) {
				h = 120 + (r2 - b2);
			} else {
				h = 240 + (g2 - r2);
			}
		}
		
		static void hsl_to_rgb (double h, double s, double l, out double r, out double g, out double b)
			requires (h >= 0 && h < 360)
			requires (s >= 0 && s <= 1)
			requires (l >= 0 && l <= 1)
		{
			var v = (l <= 0.5 ? l * (1.0 + s) : l + s - l * s);
			if (v <= 0.0) {
				r = l;
				g = l;
				b = l;
				return;
			}
			
			var secNum = (int) (h / 60);
			var fracSec = h / 30.0 - 2 * secNum;
			
			var p = l - (v - l);
			var q = v - (v - l) * fracSec;
			var t = l + (v - l) * (fracSec - 1);
			
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
			default:
				assert_not_reached ();
			}
		}
		
		/**
		 * Convert color to string formatted like "%d;;%d;;%d;;%d"
		 * with numeric entries ranged in 0..255
		 *
		 * @return the string representation of this color
		 */
		public string to_prefs_string ()
		{
			return "%d;;%d;;%d;;%d".printf ((int) (red * uint8.MAX),
				(int) (green * uint8.MAX),
				(int) (blue * uint8.MAX),
				(int) (alpha * uint8.MAX));
		}
		
		/**
		 * Create new color converted from string formatted like
		 * "%d;;%d;;%d;;%d" with numeric entries ranged in 0..255
		 *
		 * @return new {@link Color} based on the given string
		 */
		public static Color from_prefs_string (string s)
		{
			var parts = s.split (";;");
			
			if (parts.length != 4) {
				critical ("Malformed color string '%s'", s);
				return {};
			}
			
			return { fclamp (int.parse (parts [0]), 0.0, uint8.MAX) / uint8.MAX,
				fclamp (int.parse (parts [1]), 0.0, uint8.MAX) / uint8.MAX,
				fclamp (int.parse (parts [2]), 0.0, uint8.MAX) / uint8.MAX,
				fclamp (int.parse (parts [3]), 0.0, uint8.MAX) / uint8.MAX };
		}
	}
}
