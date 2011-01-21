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

using Plank.Items;
using Plank.Services.Drawing;
using Plank.Services.Preferences;

namespace Plank
{
	public class DockThemeRenderer : ThemeRenderer
	{
		const double MIN_INDICATOR_SIZE = 0.0;
		const double MAX_INDICATOR_SIZE = 10.0;
		
		public double HorizPadding { get; set; default = 0.0; }
		
		public double TopPadding { get; set; default = -11.0; }
		
		public double BottomPadding { get; set; default = 5.0; }
		
		public double ItemPadding { get; set; default = 2.0; }
		
		public double IndicatorSize { get; set; default = 5.0; }
		
		public int UrgentBounceHeight { get; set; default = 80; }
		
		public int LaunchBounceHeight { get; set; default = 30; }
		
		public int GlowSize { get; set; default = 30; }
		
		public int ClickTime { get; set; default = 600; }
		
		public int BounceTime { get; set; default = 600; }
		
		public int ActiveTime { get; set; default = 300; }
		
		protected override void verify (string prop)
		{
			base.verify (prop);
			
			switch (prop) {
			case "ItemPadding":
				if (ItemPadding < 0)
					ItemPadding = 0;
				break;
			
			case "IndicatorSize":
				if (IndicatorSize < MIN_INDICATOR_SIZE)
					IndicatorSize = MIN_INDICATOR_SIZE;
				else if (IndicatorSize > MAX_INDICATOR_SIZE)
					IndicatorSize = MAX_INDICATOR_SIZE;
				break;
			
			case "UrgentBounceHeight":
				if (UrgentBounceHeight < 0)
					UrgentBounceHeight = 0;
				break;
			
			case "LaunchBounceHeight":
				if (LaunchBounceHeight < 0)
					LaunchBounceHeight = 0;
				break;
			
			case "GlowSize":
				if (GlowSize < 0)
					GlowSize = 0;
				break;
			
			case "ClickTime":
				if (ClickTime < 0)
					ClickTime = 0;
				break;
			
			case "BounceTime":
				if (BounceTime < 0)
					BounceTime = 0;
				break;
			
			case "ActiveTime":
				if (ActiveTime < 0)
					ActiveTime = 0;
				break;
			}
		}
	}
	
	public class ThemeRenderer : Preferences
	{
		public int TopRoundness { get; set; default = 6; }
		
		public int BottomRoundness { get; set; default = 6; }
		
		public int LineWidth { get; set; default = 1; }
		
		public ThemeRenderer ()
		{
		}
		
		public void load (string type)
		{
			init_from_file ("theme/" + type + ".theme");
		}
		
		public int get_top_offset ()
		{
			return TopRoundness > 0 ? LineWidth : 0;
		}
		
		public int get_bottom_offset ()
		{
			return BottomRoundness > 0 ? LineWidth : 0;
		}
		
		public void draw_background (PlankSurface surface)
		{
			var cr = surface.Context;
			
			var top_offset = get_top_offset ();
			var bottom_offset = get_bottom_offset ();
			
			var gradient = new Pattern.linear (0, 0, 0, surface.Height);
			gradient.add_color_stop_rgba (0, 0.1647, 0.1647, 0.1647, 1);
			gradient.add_color_stop_rgba (1, 0.3176, 0.3176, 0.3176, 1);
			
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
			
			cr.set_source_rgba (0.1647, 0.1647, 0.1647, 1);
			cr.set_line_width (LineWidth);
			cr.stroke ();
			
			gradient = new Pattern.linear (0, top_offset,
				0, surface.Height - top_offset - bottom_offset);
			
			gradient.add_color_stop_rgba (0, 1, 1, 1, 0.5);
			gradient.add_color_stop_rgba ((TopRoundness > 0 ? TopRoundness : LineWidth) / (double) surface.Height, 1, 1, 1, 0.12);
			gradient.add_color_stop_rgba ((surface.Height - (BottomRoundness > 0 ? BottomRoundness : LineWidth)) / (double) surface.Height, 1, 1, 1, 0.08);
			gradient.add_color_stop_rgba (1, 1, 1, 1, 0.19);
			
			cr.save ();
			cr.set_source (gradient);
			
			draw_inner_rect (cr, surface);
			cr.set_line_width (LineWidth);
			cr.stroke ();
			cr.restore ();
		}
		
		public void draw_inner_rect (Context cr, PlankSurface surface)
		{
			var top_offset = get_top_offset ();
			var bottom_offset = get_bottom_offset ();
			
			draw_rounded_rect (cr,
				3 * LineWidth / 2.0,
				3 * top_offset / 2.0,
				surface.Width - 3 * LineWidth,
				surface.Height - 3 * top_offset / 2.0 - 3 * bottom_offset / 2.0,
				TopRoundness,
				BottomRoundness);
		}
		
		static void draw_rounded_rect (Context cr, double x, double y, double width, double height, double top_radius = 6.0, double bottom_radius = 6.0)
		{
			top_radius = Math.fmin (top_radius, Math.fmin (width / 2.0, height / 2.0));
			bottom_radius = Math.fmin (bottom_radius, Math.fmin (width / 2.0, height / 2.0));
			
			cr.move_to (x + top_radius, y);
			cr.arc (x + width - top_radius, y + top_radius, top_radius, Math.PI * 1.5, Math.PI * 2.0);
			cr.arc (x + width - bottom_radius, y + height - bottom_radius, bottom_radius, 0, Math.PI * 0.5);
			cr.arc (x + bottom_radius, y + height - bottom_radius, bottom_radius, Math.PI * 0.5, Math.PI);
			cr.arc (x + top_radius, y + top_radius, top_radius, Math.PI, Math.PI * 1.5);
		}
		
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
			}
		}
	}
}
