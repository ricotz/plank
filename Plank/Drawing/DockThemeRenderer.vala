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
	public class DockThemeRenderer : ThemeRenderer
	{
		const double MIN_INDICATOR_SIZE = 0.0;
		const double MAX_INDICATOR_SIZE = 10.0;
		
		public double HorizPadding { get; set; default = 0.0; }
		
		public double TopPadding { get; set; default = -11.0; }
		
		public double BottomPadding { get; set; default = 2.5; }
		
		public double ItemPadding { get; set; default = 2.0; }
		
		public double IndicatorSize { get; set; default = 5.0; }
		
		public int UrgentBounceHeight { get; set; default = 80; }
		
		public int LaunchBounceHeight { get; set; default = 30; }
		
		public int GlowSize { get; set; default = 30; }
		
		public int ClickTime { get; set; default = 600; }
		
		public int BounceTime { get; set; default = 600; }
		
		public int ActiveTime { get; set; default = 300; }
		
		public int FadeTime { get; set; default = 200; }
		
		public int SlideTime { get; set; default = 200; }
		
		public DockSurface create_indicator (DockSurface background, int size, double r, double g, double b)
		{
			DockSurface surface = new DockSurface.with_dock_surface (size, size, background);
			surface.Clear ();

			var cr = surface.Context;
			
			var x = size / 2;
			var y = x;
			
			cr.move_to (x, y);
			cr.arc (x, y, size / 2, 0, Math.PI * 2);
			
			var rg = new Pattern.radial (x, y, 0, x, y, size / 2);
			rg.add_color_stop_rgba (0, 1, 1, 1, 1);
			rg.add_color_stop_rgba (0.1, r, g, b, 1);
			rg.add_color_stop_rgba (0.2, r, g, b, 0.6);
			rg.add_color_stop_rgba (0.25, r, g, b, 0.25);
			rg.add_color_stop_rgba (0.5, r, g, b, 0.15);
			rg.add_color_stop_rgba (1.0, r, g, b, 0.0);
			
			cr.set_source (rg);
			cr.fill ();
			
			return surface;
		}
		
		public void draw_active_glow (DockSurface surface, DockSurface clip_buffer, Gdk.Rectangle rect, Drawing.Color color, double opacity)
		{
			if (opacity == 0)
				return;
			
			surface.Context.translate (0, surface.Height - clip_buffer.Height + LineWidth);
			draw_inner_rect (surface.Context, clip_buffer);
			surface.Context.clip ();
			surface.Context.translate (0, clip_buffer.Height - surface.Height - LineWidth);
			
			rect.y += 2 * get_top_offset ();
			rect.height -= 2 * get_top_offset () + 2 * get_bottom_offset ();
			surface.Context.rectangle (rect.x, rect.y, rect.width, rect.height);
			
			var gradient = new Pattern.linear (0, rect.y, 0, rect.y + rect.height);
			gradient.add_color_stop_rgba (0, color.R, color.G, color.B, 0);
			gradient.add_color_stop_rgba (1, color.R, color.G, color.B, 0.6 * opacity);
			
			surface.Context.set_source (gradient);
			surface.Context.fill ();
			surface.Context.reset_clip ();
		}
		
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
}
