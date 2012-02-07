//  
//  Copyright (C) 2011 Robert Dyer, Rico Tzschichholz
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
	/**
	 * A themed renderer for windows.
	 */
	public class ThemeRenderer : Preferences
	{
		[Description(nick = "top-roundness", blurb = "The roundness of the top corners.")]
		public int TopRoundness { get; set; }
		
		[Description(nick = "bottom-roundness", blurb = "The roundness of the bottom corners.")]
		public int BottomRoundness { get; set; }
		
		[Description(nick = "line-width", blurb = "The thickness (in pixels) of lines drawn.")]
		public int LineWidth { get; set; }
		
		[Description(nick = "outer-stroke-color", blurb = "The color (RGBA) of the outer stroke.")]
		public Color OuterStrokeColor { get; set; }
		
		[Description(nick = "fill-start-color", blurb = "The starting color (RGBA) of the fill gradient.")]
		public Color FillStartColor { get; set; }
		
		[Description(nick = "fill-end-color", blurb = "The ending color (RGBA) of the fill gradient.")]
		public Color FillEndColor { get; set; }
		
		[Description(nick = "inner-stroke-color", blurb = "The color (RGBA) of the inner stroke.")]
		public Color InnerStrokeColor { get; set; }
		
		public ThemeRenderer ()
		{
			base ();
		}
		
		/**
		 * {@inheritDoc}
		 */
		protected override void reset_properties ()
		{
			TopRoundness    = 6;
			BottomRoundness = 6;
			
			LineWidth = 1;
			
			OuterStrokeColor = new Color (0.1647, 0.1647, 0.1647, 1);
			FillStartColor   = new Color (0.1647, 0.1647, 0.1647, 1);
			FillEndColor     = new Color (0.3176, 0.3176, 0.3176, 1);
			InnerStrokeColor = new Color (1, 1, 1, 1);
		}
		
		/**
		 * Loads a theme for the renderer to use.
		 *
		 * @param type the type of theme to load
		 */
		public void load (string type)
		{
			Paths.ensure_directory_exists (Paths.AppConfigFolder.get_child ("theme"));
			init_from_file ("theme/" + type + ".theme");
		}
		
		/**
		 * Returns the top offset.
		 *
		 * @return the top offset
		 */
		public int get_top_offset ()
		{
			return TopRoundness > 0 ? LineWidth : 0;
		}
		
		/**
		 * Returns the bottom offset.
		 *
		 * @return the bottom offset
		 */
		public int get_bottom_offset ()
		{
			return BottomRoundness > 0 ? LineWidth : 0;
		}
		
		/**
		 * Draws a background onto the surface.
		 *
		 * @param surface the dock surface to draw on
		 */
		public void draw_background (DockSurface surface)
		{
			var cr = surface.Context;
			
			var top_offset    = get_top_offset ();
			var bottom_offset = get_bottom_offset ();
			
			var gradient = new Pattern.linear (0, 0, 0, surface.Height);
			
			gradient.add_color_stop_rgba (0, FillStartColor.R, FillStartColor.G, FillStartColor.B, FillStartColor.A);
			gradient.add_color_stop_rgba (1, FillEndColor.R, FillEndColor.G, FillEndColor.B, FillEndColor.A);
			
			cr.save ();
			cr.set_source (gradient);
			
			draw_rounded_rect (cr,
				LineWidth / 2.0,
				top_offset / 2.0,
				surface.Width - LineWidth,
				surface.Height - top_offset / 2.0 - bottom_offset / 2.0,
				TopRoundness,
				BottomRoundness);
			cr.fill_preserve ();
			cr.restore ();
			
			cr.set_source_rgba (OuterStrokeColor.R, OuterStrokeColor.G, OuterStrokeColor.B, OuterStrokeColor.A);
			cr.set_line_width (LineWidth);
			cr.stroke ();
			
			gradient = new Pattern.linear (0, top_offset, 0, surface.Height - top_offset - bottom_offset);
			
			gradient.add_color_stop_rgba (0, InnerStrokeColor.R, InnerStrokeColor.G, InnerStrokeColor.B, 0.5);
			gradient.add_color_stop_rgba ((TopRoundness > 0 ? TopRoundness : LineWidth) / (double) surface.Height, InnerStrokeColor.R, InnerStrokeColor.G, InnerStrokeColor.B, 0.12);
			gradient.add_color_stop_rgba ((surface.Height - (BottomRoundness > 0 ? BottomRoundness : LineWidth)) / (double) surface.Height, InnerStrokeColor.R, InnerStrokeColor.G, InnerStrokeColor.B, 0.08);
			gradient.add_color_stop_rgba (1, InnerStrokeColor.R, InnerStrokeColor.G, InnerStrokeColor.B, 0.19);
			
			cr.save ();
			cr.set_source (gradient);
			
			draw_inner_rect (cr, surface.Width, surface.Height);
			cr.set_line_width (LineWidth);
			cr.stroke ();
			cr.restore ();
		}
		
		/**
		 * Similar to draw_rounded_rect, but moves in to avoid a containing rounded rect's lines.
		 *
		 * @param cr the context to draw with
		 * @param width the width of the rect
		 * @param height the height of the rect
		 */
		protected void draw_inner_rect (Context cr, int width, int height)
		{
			var top_offset    = get_top_offset ();
			var bottom_offset = get_bottom_offset ();
			
			draw_rounded_rect (cr,
				3 * LineWidth / 2.0,
				3 * top_offset / 2.0,
				width - 3 * LineWidth,
				height - 3 * top_offset / 2.0 - 3 * bottom_offset / 2.0,
				TopRoundness,
				BottomRoundness);
		}
		
		/**
		 * Draws a rounded rectangle.  If compositing is disabled, just draws a normal rectangle.
		 *
		 * @param cr the context to draw with
		 * @param x the x location of the rect
		 * @param y the y location of the rect
		 * @param width the width of the rect
		 * @param height the height of the rect
		 * @param top_radius the roundedness of the top edge
		 * @param bottom_radius the roundedness of the bottom edge
		 */
		protected void draw_rounded_rect (Context cr, double x, double y, double width, double height, double top_radius = 6.0, double bottom_radius = 6.0)
		{
			var min_size  = double.min (width, height);
			
			top_radius    = double.min (top_radius, min_size);
			bottom_radius = double.min (bottom_radius, min_size - top_radius);
			
			if (!Gdk.Screen.get_default ().is_composited ())
				top_radius = bottom_radius = 0.0;
			
			// if the top isnt round, we have to adjust the starting point a bit
			if (top_radius == 0.0)
				cr.move_to (x - LineWidth / 2.0, y);
			else
				cr.move_to (x + top_radius, y);
			
			cr.arc (x + width - top_radius,    y + top_radius,             top_radius,    Math.PI * 1.5, Math.PI * 2.0);
			cr.arc (x + width - bottom_radius, y + height - bottom_radius, bottom_radius, 0,             Math.PI * 0.5);
			cr.arc (x + bottom_radius,         y + height - bottom_radius, bottom_radius, Math.PI * 0.5, Math.PI);
			cr.arc (x + top_radius,            y + top_radius,             top_radius,    Math.PI,       Math.PI * 1.5);
		}
		
		/**
		 * {@inheritDoc}
		 */
		protected override void verify (string prop)
		{
			base.verify (prop);
			
			switch (prop) {
			case "TopRoundness":
				if (TopRoundness < 0)
					TopRoundness = 0;
				break;
			
			case "BottomRoundness":
				if (BottomRoundness < 0)
					BottomRoundness = 0;
				break;
			
			case "LineWidth":
				if (LineWidth < 0)
					LineWidth = 0;
				break;
			
			case "OuterStrokeColor":
			case "FillStartColor":
			case "FillEndColor":
			case "InnerStrokeColor":
				break;
			}
		}
	}
}
