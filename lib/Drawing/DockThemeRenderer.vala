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
	/**
	 * A themed renderer for dock windows.
	 */
	public class DockThemeRenderer : ThemeRenderer
	{
		const double MIN_INDICATOR_SIZE = 0.0;
		const double MAX_INDICATOR_SIZE = 10.0;
		
		[Description(nick = "horizontal-padding", blurb = "The padding on the left/right dock edges, in tenths of a percent of IconSize.")]
		public double HorizPadding { get; set; }
		
		[Description(nick = "top-padding", blurb = "The padding on the top dock edge, in tenths of a percent of IconSize.")]
		public double TopPadding { get; set; }
		
		[Description(nick = "top-padding", blurb = "The padding on the bottom dock edge, in tenths of a percent of IconSize.")]
		public double BottomPadding { get; set; }
		
		[Description(nick = "item-padding", blurb = "The padding between items on the dock, in tenths of a percent of IconSize.")]
		public double ItemPadding { get; set; }
		
		[Description(nick = "indicator-size", blurb = "The size of item indicators, in tenths of a percent of IconSize.")]
		public double IndicatorSize { get; set; }
		
		[Description(nick = "urgent-bounce", blurb = "The height (in percent of IconSize) to bounce an icon when the application sets urgent.")]
		public double UrgentBounceHeight { get; set; }
		
		[Description(nick = "launch-bounce", blurb = "The height (in percent of IconSize) to bounce an icon when launching an application.")]
		public double LaunchBounceHeight { get; set; }
		
		[Description(nick = "fade-opacity", blurb = "The opacity value (0 to 1) to fade the dock to when hiding it.")]
		public double FadeOpacity { get; set; }
		
		[Description(nick = "click-time", blurb = "The amount of time (in ms) for click animations.")]
		public int ClickTime { get; set; }
		
		[Description(nick = "urgent-bounce-time", blurb = "The amount of time (in ms) to bounce an urgent icon.")]
		public int UrgentBounceTime { get; set; }
		
		[Description(nick = "launch-bounce-time", blurb = "The amount of time (in ms) to bounce an icon when launching an application.")]
		public int LaunchBounceTime { get; set; }
		
		[Description(nick = "active-time", blurb = "The amount of time (in ms) for active window indicator animations.")]
		public int ActiveTime { get; set; }
		
		[Description(nick = "slide-time", blurb = "The amount of time (in ms) to slide icons into/out of the dock.")]
		public int SlideTime { get; set; }
		
		[Description(nick = "fade-time", blurb = "The time (in ms) to fade the dock in/out on a hide (if FadeOpacity is < 1).")]
		public int FadeTime { get; set; }
		
		[Description(nick = "hide-time", blurb = "The time (in ms) to slide the dock in/out on a hide (if FadeOpacity is 1).")]
		public int HideTime { get; set; }
		
		[Description(nick = "glow-size", blurb = "The size of the urgent glow (shown when dock is hidden), in tenths of a percent of IconSize.")]
		public int GlowSize { get; set; }
		
		[Description(nick = "glow-time", blurb = "The total time (in ms) to show the hidden-dock urgent glow.")]
		public int GlowTime { get; set; }
		
		[Description(nick = "glow-pulse-time", blurb = "The time (in ms) of each pulse of the hidden-dock urgent glow.")]
		public int GlowPulseTime { get; set; }
		
		/**
		 * {@inheritDoc}
		 */
		protected override void reset_properties ()
		{
			base.reset_properties ();
			TopRoundness = 4;
			BottomRoundness = 0;
			HorizPadding = 0.0;
			TopPadding = -11.0;
			BottomPadding = 2.5;
			ItemPadding = 2.0;
			IndicatorSize = 5.0;
			UrgentBounceHeight = 5.0 / 3.0;
			LaunchBounceHeight = 0.625;
			FadeOpacity = 1.0;
			ClickTime = 300;
			UrgentBounceTime = 600;
			LaunchBounceTime = 600;
			ActiveTime = 300;
			SlideTime = 300;
			FadeTime = 250;
			HideTime = 150;
			GlowSize = 30;
			GlowTime = 10000;
			GlowPulseTime = 2000;
		}
		
		/**
		 * Creates a surface for an indicator.
		 *
		 * @param background a similar surface
		 * @param size the size of the indicator
		 * @param color the color of the indicator
		 * @return a new dock surface with the indicator drawn on it
		 */
		public DockSurface create_indicator (DockSurface background, int size, Color color)
		{
			var surface = new DockSurface.with_dock_surface (size, size, background);
			surface.clear ();

			var cr = surface.Context;
			
			var x = size / 2;
			var y = x;
			
			cr.move_to (x, y);
			cr.arc (x, y, size / 2, 0, Math.PI * 2);
			
			var rg = new Pattern.radial (x, y, 0, x, y, size / 2);
			rg.add_color_stop_rgba (0, 1, 1, 1, 1);
			rg.add_color_stop_rgba (0.1, color.R, color.G, color.B, 1);
			rg.add_color_stop_rgba (0.2, color.R, color.G, color.B, 0.6);
			rg.add_color_stop_rgba (0.25, color.R, color.G, color.B, 0.25);
			rg.add_color_stop_rgba (0.5, color.R, color.G, color.B, 0.15);
			rg.add_color_stop_rgba (1.0, color.R, color.G, color.B, 0.0);
			
			cr.set_source (rg);
			cr.fill ();
			
			return surface;
		}
		
		/**
		 * Draws an active glow for an item.
		 *
		 * @param surface the surface to draw onto
		 * @param horiz_pad any horizontal padding to account for
		 * @param clip_buffer a region to clip the glow to
		 * @param rect the rect for the glow
		 * @param color the color of the glow
		 * @param opacity the opacity of the glow
		 */
		public void draw_active_glow (DockSurface surface, int horiz_pad, DockSurface clip_buffer, Gdk.Rectangle rect, Color color, double opacity)
		{
			if (opacity == 0)
				return;
			
			var xoffset = horiz_pad < 0 ? -horiz_pad : 0;
			surface.Context.translate (xoffset, surface.Height - clip_buffer.Height + LineWidth);
			draw_inner_rect (surface.Context, clip_buffer.Width, clip_buffer.Height);
			surface.Context.clip ();
			surface.Context.translate (-xoffset, clip_buffer.Height - surface.Height - LineWidth);
			
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
		
		/**
		 * {@inheritDoc}
		 */
		protected override void verify (string prop)
		{
			base.verify (prop);
			
			switch (prop) {
			case "HorizPadding":
			case "TopPadding":
			case "BottomPadding":
				break;
			
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
			
			case "FadeOpacity":
				if (FadeOpacity < 0)
					FadeOpacity = 0;
				else if (FadeOpacity > 1)
					FadeOpacity = 1;
				break;
			
			case "ClickTime":
				if (ClickTime < 0)
					ClickTime = 0;
				break;
			
			case "UrgentBounceTime":
				if (UrgentBounceTime < 0)
					UrgentBounceTime = 0;
				break;
			
			case "LaunchBounceTime":
				if (LaunchBounceTime < 0)
					LaunchBounceTime = 0;
				break;
			
			case "ActiveTime":
				if (ActiveTime < 0)
					ActiveTime = 0;
				break;
			
			case "SlideTime":
				if (SlideTime < 0)
					SlideTime = 0;
				break;
			
			case "FadeTime":
				if (FadeTime < 0)
					FadeTime = 0;
				break;
			
			case "HideTime":
				if (HideTime < 0)
					HideTime = 0;
				break;
			
			case "GlowSize":
				if (GlowSize < 0)
					GlowSize = 0;
				break;
			
			case "GlowTime":
				if (GlowTime < 0)
					GlowTime = 0;
				break;
			
			case "GlowPulseTime":
				if (GlowPulseTime < 0)
					GlowPulseTime = 0;
				break;
			}
		}
	}
}
