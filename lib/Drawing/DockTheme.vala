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
	 * A themed renderer for dock windows.
	 */
	public class DockTheme : Theme
	{
		const double MIN_INDICATOR_SIZE = 0.0;
		const double MAX_INDICATOR_SIZE = 10.0;
		const double MAX_ICON_SHADOW_SIZE = 5.0;
		
		[Description(nick = "horizontal-padding", blurb = "The padding on the left/right dock edges, in tenths of a percent of IconSize.")]
		public double HorizPadding { get; set; }
		
		[Description(nick = "top-padding", blurb = "The padding on the top dock edge, in tenths of a percent of IconSize.")]
		public double TopPadding { get; set; }
		
		[Description(nick = "bottom-padding", blurb = "The padding on the bottom dock edge, in tenths of a percent of IconSize.")]
		public double BottomPadding { get; set; }
		
		[Description(nick = "item-padding", blurb = "The padding between items on the dock, in tenths of a percent of IconSize.")]
		public double ItemPadding { get; set; }
		
		[Description(nick = "indicator-color", blurb = "The color (RGBA) of the indicator.")]
		public Color IndicatorColor { get; set; }
		
		[Description(nick = "indicator-size", blurb = "The size of item indicators, in tenths of a percent of IconSize.")]
		public double IndicatorSize { get; set; }
		
		[Description(nick = "indicator-style", blurb = "The style of item indicators, styles: circle-glow, circle-color-glow, circle, underline.")]
		public IndicatorStyleType IndicatorStyle { get; set; }
		
		[Description(nick = "icon-shadow-size", blurb = "The size of the icon-shadow behind every item, in tenths of a percent of IconSize.")]
		public double IconShadowSize { get; set; }
		
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
		
		[Description(nick = "urgent-hue-shift", blurb = "The hue-shift (-180 to 180) of the urgent indicator color.")]
		public int UrgentHueShift { get; set; }
		
		[Description(nick = "item-move-time", blurb = "The time (in ms) to move an item to its new position or its addition/removal to/from the dock.")]
		public int ItemMoveTime { get; set; }
		
		[Description(nick = "cascade-hide", blurb = "Whether background and icons will unhide/hide with different speeds. The top-border of both will leave/hit the screen-edge at the same time.")]
		public bool CascadeHide { get; set; }
		
		[Description(nick = "badge-color", blurb = "The color (RGBA) of the badge displaying urgent count")]
		public Color BadgeColor { get; set; }

		[Description(nick = "selection-style", blurb = "Whether an item has an active background glow. If not, active-item-color (RGBA) will be used instead.")]
		public SelectionStyleType SelectionStyle { get; set; }
		
		[Description(nick = "selection-color", blurb = "The color (RGBA) of the active item background.")]
		public Color SelectionColor { get; set; }
		
		public DockTheme (string name)
		{
			base.with_name (name);
		}
		
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
			ItemPadding = 2.5;
			IndicatorColor = { 1.0, 1.0, 1.0, 1.0 };
			IndicatorSize = 5.0;
			IndicatorStyle = IndicatorStyleType.LEGACY;
			IconShadowSize = 1.0;
			UrgentBounceHeight = 5.0 / 3.0;
			LaunchBounceHeight = 0.625;
			FadeOpacity = 1.0;
			ClickTime = 300;
			UrgentBounceTime = 600;
			LaunchBounceTime = 600;
			ActiveTime = 300;
			SlideTime = 300;
			FadeTime = 250;
			HideTime = 250;
			GlowSize = 30;
			GlowTime = 10000;
			GlowPulseTime = 2000;
			UrgentHueShift = 150;
			ItemMoveTime = 450;
			CascadeHide = true;
			BadgeColor = { 0.0, 0.0, 0.0, 0.0 };
			SelectionColor = { 0.0, 0.0, 0.0, 1.0 };
			SelectionStyle = SelectionStyleType.LEGACY;
		}
		
		/**
		 * Creates a surface for the dock background.
		 *
		 * @param width the width of the background
		 * @param height the height of the background
		 * @param position the position of the dock
		 * @param model existing surface to use as basis of new surface
		 * @return a new surface with the background drawn on it
		 */
		public Surface create_background (int width, int height, Gtk.PositionType position, Surface model)
		{
			Logger.verbose ("DockTheme.create_background (width = %i, height = %i)", width, height);
			
			var surface = new Surface.with_surface (width, height, model);
			surface.clear ();
			
			if (width <= 0 || height <= 0)
				return surface;
			
			if (position == Gtk.PositionType.BOTTOM) {
				draw_background (surface);
				return surface;
			}
			
			Surface temp;
			if (position == Gtk.PositionType.TOP)
				temp = new Surface.with_surface (width, height, surface);
			else
				temp = new Surface.with_surface (height, width, surface);
			
			draw_background (temp);
			
			unowned Cairo.Context cr = surface.Context;
			
			var rotate = 0.0;
			var x_offset = 0.0, y_offset = 0.0;
			
			switch (position) {
			default:
			case Gtk.PositionType.BOTTOM:
				break;
			case Gtk.PositionType.TOP:
				rotate = Math.PI;
				x_offset = -width;
				y_offset = -height;
				break;
			case Gtk.PositionType.LEFT:
				rotate = Math.PI_2;
				y_offset = -width;
				break;
			case Gtk.PositionType.RIGHT:
				rotate = -Math.PI_2;
				x_offset = -height;
				break;
			}
			
			cr.save ();
			cr.rotate (rotate);
			cr.set_source_surface (temp.Internal, x_offset, y_offset);
			cr.paint ();
			cr.restore ();
			
			return surface;
		}
		
		/**
		 * Creates a surface for an indicator.
		 *
		 * @param size the size of the indicator
		 * @param color the color of the indicator
		 * @param model existing surface to use as basis of new surface
		 * @return a new surface with the indicator drawn on it
		 */
		public Surface create_indicator (int size, Color color, Surface model)
		{
			Logger.verbose ("DockTheme.create_indicator (size = %i)", size);
			
			var surface = new Surface.with_surface (size, size, model);
			surface.clear ();
			
			if (size <= 0)
				return surface;
			
			unowned Cairo.Context cr = surface.Context;
			
			var x = size / 2;
			var y = x;
			
			cr.move_to (x, y);
			cr.arc (x, y, size / 2, 0, Math.PI * 2);
			cr.close_path ();
			
			var rg = new Cairo.Pattern.radial (x, y, 0, x, y, size / 2);
			rg.add_color_stop_rgba (0, 1, 1, 1, 1);
			rg.add_color_stop_rgba (0.1, color.red, color.green, color.blue, 1);
			rg.add_color_stop_rgba (0.2, color.red, color.green, color.blue, 0.6);
			rg.add_color_stop_rgba (0.25, color.red, color.green, color.blue, 0.25);
			rg.add_color_stop_rgba (0.5, color.red, color.green, color.blue, 0.15);
			rg.add_color_stop_rgba (1.0, color.red, color.green, color.blue, 0.0);
			
			cr.set_source (rg);
			cr.fill ();
			
			return surface;
		}
		
		/**
		 * Creates a surface of an indicator for the given states.
		 *
		 * @param indicator_state the state of indicator
		 * @param item_state the state of item
		 * @param icon_size the size of icons
		 * @param color the color of the indicator
		 * @param position the position of the dock
		 * @param model existing surface to use as basis of new surface
		 * @return a new surface with the indicator drawn on it
		 */
		public Surface create_indicator_for_state (IndicatorState indicator_state, ItemState item_state, int icon_size,
			Gtk.PositionType position, Surface model)
		{
			double width = icon_size;
			double height = icon_size / 3.0 + get_bottom_offset ();
			var size = (int) (IndicatorSize * icon_size / 10.0);
			
			Logger.verbose ("DockTheme.create_indicator (width = %i, height = %i, state = [%i,%i])", (int) width, (int) height, indicator_state, item_state);
			
			var surface = new Surface.with_surface ((int) width, (int) height, model);
			surface.clear ();
			
			if (width <= 0 || height <= 0 || size <= 0 || indicator_state == IndicatorState.NONE)
				return surface;
			
			Color color;
			if ((item_state & ItemState.URGENT) != 0) {
				color = (IndicatorStyle == IndicatorStyleType.LEGACY ? get_styled_color () : IndicatorColor);
				color.add_hue (UrgentHueShift);
				color.set_sat (1.0);
			} else {
				if (IndicatorStyle == IndicatorStyleType.LEGACY) {
					color = get_styled_color ();
					color.set_min_sat (0.4);
				} else {
					color = IndicatorColor;
				}
			}
			
			unowned Cairo.Context cr = surface.Context;
			cr.save ();
			cr.set_line_width (1.0);
			
			switch (IndicatorStyle) {
			default:
			case IndicatorStyleType.LEGACY:
			case IndicatorStyleType.GLOW:
				var x = 0.0;
				var y = Math.round (height - size / 12.0 - get_bottom_offset ());
				
				for (var i = 0; i < indicator_state; i++) {
					x = Math.round (width / 2.0 + (2.0 * i - (indicator_state - 1)) * size / 8.0);
					
					cr.move_to (x, y);
					cr.arc (x, y, height / 2, 0, Math.PI * 2);
					cr.close_path ();
					
					var rg = new Cairo.Pattern.radial (x, y, 0, x, y, size / 2);
					rg.add_color_stop_rgba (0, 1, 1, 1, 1);
					rg.add_color_stop_rgba (0.1, color.red, color.green, color.blue, 1);
					rg.add_color_stop_rgba (0.2, color.red, color.green, color.blue, 0.6);
					rg.add_color_stop_rgba (0.25, color.red, color.green, color.blue, 0.25);
					rg.add_color_stop_rgba (0.5, color.red, color.green, color.blue, 0.15);
					rg.add_color_stop_rgba (1.0, color.red, color.green, color.blue, 0.0);
					
					cr.set_source (rg);
					cr.fill ();
				}
				break;
			case IndicatorStyleType.CIRCLE:
				var x = 0.0;
				var y = Math.round (height - size / 1.666 - get_bottom_offset ());
				
				for (var i = 0; i < indicator_state; i++) {
					x = Math.round (width / 2.0 + (2.0 * i - (indicator_state - 1)) * size / 1.2);
					
					cr.move_to (x, y);
					cr.arc (x, y, size / 2, 0, Math.PI * 2);
					cr.close_path ();
					
					cr.set_source_rgba (color.red, color.green, color.blue, color.alpha);
					cr.stroke_preserve ();
					cr.fill ();
				}
				break;
			case IndicatorStyleType.LINE:
				var x = Math.round (icon_size / 10.0);
				var y = Math.round (height - size - get_bottom_offset () - icon_size / 30.0);
				width = Math.round (width - icon_size / 5.0);
				
				cr.rectangle (x, y, width, size);
				cr.set_source_rgba (color.red, color.green, color.blue, color.alpha);
				cr.stroke_preserve ();
				cr.fill ();
				break;
			}
			
			cr.restore ();
			
			if (position != Gtk.PositionType.BOTTOM)
				surface = rotate_for_position ((owned) surface, position);
			
			return surface;
		}
		
		/**
		 * Creates a surface for an urgent glow.
		 *
		 * @param size the size of the urgent glow
		 * @param color the color of the urgent glow
		 * @param model existing surface to use as basis of new surface
		 * @return a new surface with the urgent glow drawn on it
		 */
		public Surface create_urgent_glow (int size, Color color, Surface model)
		{
			Logger.verbose ("DockTheme.create_urgent_glow (size = %i)", size);
			
			var surface = new Surface.with_surface (size, size, model);
			surface.clear ();
			
			if (size <= 0)
				return surface;
			
			unowned Cairo.Context cr = surface.Context;
			
			var x = size / 2.0;
			
			cr.move_to (x, x);
			cr.arc (x, x, size / 2, 0, Math.PI * 2);
			cr.close_path ();
			
			var rg = new Cairo.Pattern.radial (x, x, 0, x, x, size / 2);
			rg.add_color_stop_rgba (0, 1, 1, 1, 1);
			rg.add_color_stop_rgba (0.33, color.red, color.green, color.blue, 0.66);
			rg.add_color_stop_rgba (0.66, color.red, color.green, color.blue, 0.33);
			rg.add_color_stop_rgba (1.0, color.red, color.green, color.blue, 0.0);
			
			cr.set_source (rg);
			cr.fill ();
			
			return surface;
		}

		/**
		 * Draws an active glow for an item.
		 *
		 * @param surface the surface to draw onto
		 * @param clip_rect the rect to clip the glow to
		 * @param rect the rect for the glow
		 * @param color the color of the glow
		 * @param opacity the opacity of the glow
		 * @param pos the dock's position
		 */
		public void draw_active_glow (Surface surface, Gdk.Rectangle clip_rect, Gdk.Rectangle rect, Color color, double opacity, Gtk.PositionType pos)
		{
			if (opacity <= 0.0 || rect.width <= 0 || rect.height <= 0)
				return;
			
			unowned Cairo.Context cr = surface.Context;
			
			var rotate = 0.0;
			var xoffset = 0.0, yoffset = 0.0;
			
			Cairo.Pattern gradient = null;
			
			switch (pos) {
			default:
			case Gtk.PositionType.BOTTOM:
				xoffset = clip_rect.x;
				yoffset = clip_rect.y;
				
				gradient = new Cairo.Pattern.linear (0, rect.y, 0, rect.y + rect.height);
				break;
			case Gtk.PositionType.TOP:
				rotate = Math.PI;
				xoffset = -clip_rect.x - clip_rect.width;
				yoffset = -clip_rect.height;
				
				gradient = new Cairo.Pattern.linear (0, rect.y + rect.height, 0, rect.y);
				break;
			case Gtk.PositionType.LEFT:
				rotate = Math.PI_2;
				xoffset = clip_rect.y;
				yoffset = -clip_rect.width;
				
				gradient = new Cairo.Pattern.linear (rect.x + rect.width, 0, rect.x, 0);
				break;
			case Gtk.PositionType.RIGHT:
				rotate = -Math.PI_2;
				xoffset = -clip_rect.y - clip_rect.height;
				yoffset = clip_rect.x;
				
				gradient = new Cairo.Pattern.linear (rect.x, 0, rect.x + rect.width, 0);
				break;
			}
			
			cr.save ();
			cr.rotate (rotate);
			cr.translate (xoffset, yoffset);
			if (pos == Gtk.PositionType.BOTTOM || pos == Gtk.PositionType.TOP)
				draw_inner_rect (cr, clip_rect.width, clip_rect.height);
			else
				draw_inner_rect (cr, clip_rect.height, clip_rect.width);
			cr.restore ();
			
			cr.set_line_width (LineWidth);
			cr.clip ();
			
			cr.rectangle (rect.x, rect.y, rect.width, rect.height);
			
			if (SelectionStyle == SelectionStyleType.LEGACY) {
				gradient.add_color_stop_rgba (0, color.red, color.green, color.blue, 0);
				gradient.add_color_stop_rgba (1, color.red, color.green, color.blue, 0.6 * opacity);
				cr.set_source (gradient);
			} else {
				cr.set_source_rgba (color.red, color.green, color.blue, color.alpha * opacity);
			}
			
			cr.fill ();
			
			cr.reset_clip ();
		}
		
		/**
		 * Draws a badge for an item.
		 *
		 * @param surface the surface to draw the badge onto
		 * @param icon_size the icon-size of the dock
		 * @param color the color of the badge
		 * @param count the number for the badge to show
		 */
		public void draw_item_count (Surface surface, int icon_size, Color color, int64 count)
		{
			unowned Cairo.Context cr = surface.Context;
			
			// Expect the icon to be in the center of the given surface
			// and adjust the offset accordingly
			var x = Math.floor ((surface.Width - icon_size) / 2);
			var y = Math.floor ((surface.Height - icon_size) / 2);
			
			var badge_color_start = color;
			badge_color_start.brighten_val (1.0);
			var badge_color_middle = color;
			badge_color_middle.set_sat (0.87);
			var badge_color_end = color;
			badge_color_end.set_sat (0.87);
			badge_color_end.darken_val (0.7);
			var stroke_color_start = color;
			stroke_color_start.set_sat (0.9);
			var stroke_color_end = color;
			stroke_color_end.set_sat (0.9);
			stroke_color_end.darken_val (0.9);
			
			// FIXME enhance scalability and adjustments depending on icon-size
			var is_small = icon_size < 32;
			var is_large = icon_size > 54;
			var padding = (is_small ? 1.0 : (is_large ? 4.5 : 2.0));
			var line_width = (is_small ? 0.0 : (is_large ? 2.0 : 1.0));

			var height = Math.floor ((is_small ? 0.80 : 0.50) * icon_size - 2.0 * line_width);
			var width = Math.floor ((0.75 + 0.25 * count.to_string ().length) * height);
			var max_width = icon_size - 2.0 * line_width;
			if (width > max_width)
				width = max_width;

			// Mirror horizontal badge-position for RTL environments
			if (Gtk.Widget.get_default_direction () == Gtk.TextDirection.RTL)
				x += line_width + line_width / 2.0;
			else
				x += icon_size - width - 1.5 * line_width;
			y += line_width + line_width / 2.0;
			
			cr.set_line_width (line_width);
			
			Cairo.Pattern stroke, fill;
			
			if (!is_small) {
				// draw outline shadow
				stroke = new Cairo.Pattern.rgba (0.2, 0.2, 0.2, 0.3);
				draw_rounded_line (cr, x, y, width + line_width, height, true, true, stroke, null);
				
				// draw filled gradient with outline
				stroke = new Cairo.Pattern.linear (0, y, 0, y + height);
				stroke.add_color_stop_rgba (0.2, stroke_color_start.red, stroke_color_start.green, stroke_color_start.blue, 0.8);
				stroke.add_color_stop_rgba (0.8, stroke_color_end.red, stroke_color_end.green, stroke_color_end.blue, 0.8);
				fill = new Cairo.Pattern.linear (0, y, 0, y + height);
				fill.add_color_stop_rgba (0.1, badge_color_start.red, badge_color_start.green, badge_color_start.blue, 1.0);
				fill.add_color_stop_rgba (0.5, badge_color_middle.red, badge_color_middle.green, badge_color_middle.blue, 1.0);
				fill.add_color_stop_rgba (0.9, badge_color_end.red, badge_color_end.green, badge_color_end.blue, 1.0);
				draw_rounded_line (cr, x, y, width, height, true, true, stroke, fill);
				
				// draw inline highlight
				stroke = new Cairo.Pattern.rgba (0.9, 0.9, 0.9, 0.1);
				draw_rounded_line (cr, x + line_width, y + line_width, width - 2 * line_width, height - 2 * line_width, true, true, stroke, null);
			}
			
			var layout = new Pango.Layout (Gdk.pango_context_get ());
			layout.set_width ((int) (width * Pango.SCALE));
			layout.set_ellipsize (Pango.EllipsizeMode.NONE);
			
			unowned Gtk.StyleContext style_context = get_style_context ();
			unowned Pango.FontDescription font_description = style_context.get_font (style_context.get_state ());
			font_description.set_absolute_size ((int) (height * Pango.SCALE));
			font_description.set_weight (Pango.Weight.BOLD);
			layout.set_font_description (font_description);
			
			layout.set_text (count.to_string (), -1);
			Pango.Rectangle logical_rect;
			layout.get_pixel_extents (null, out logical_rect);
			
			var scale = double.min (1.0, double.min ((width - 2.0 * padding - 2.0 * line_width) / (double) logical_rect.width, (height - 2.0 * padding) / (double) logical_rect.height));
			
			if (!is_small)
				cr.set_source_rgba (0.0, 0.0, 0.0, 0.2);
			else
				cr.set_source_rgba (0.0, 0.0, 0.0, 0.6);
			
			cr.move_to (x + Math.floor (width / 2.0 - scale * logical_rect.width / 2.0), y + Math.floor (height / 2.0 - scale * logical_rect.height / 2.0));
			
			// draw text
			cr.save ();
			if (scale < 1)
				cr.scale (scale, scale);
			
			cr.set_line_width (line_width);
			Pango.cairo_layout_path (cr, layout);
			cr.stroke_preserve ();
			cr.set_source_rgba (1.0, 1.0, 1.0, 0.95);
			cr.fill ();
			cr.restore ();
		}


		/**
		 * Draws a progress bar for an item.
		 *
		 * @param surface the surface to draw the progress onto
		 * @param icon_size the icon-size of the dock
		 * @param color the color of the progress
		 * @param progress the value between 0.0 and 1.0
		 */
		public void draw_item_progress (Surface surface, int icon_size, Color color, double progress)
		{
			if (progress < 0)
				return;
			
			if (progress > 1.0)
				progress = 1.0;
			
			unowned Cairo.Context cr = surface.Context;
			
			// Expect the icon to be in the center of the given surface
			// and adjust the offset accordingly
			var x = Math.floor ((surface.Width - icon_size) / 2);
			var y = Math.floor ((surface.Height - icon_size) / 2);
			
			// FIXME enhance scalability and adjustments depending on icon-size
			var line_width = 1.0;
			var padding = 4.0;
			var width = icon_size - 2.0 * padding;
			var height = Math.floor (double.min (18.0, (int) (0.15 * icon_size)));
			x += padding;
			y += icon_size - height - padding;
			
			cr.set_line_width (line_width);
			
			Cairo.Pattern stroke, fill;
			
			// draw the outer stroke
			stroke = new Cairo.Pattern.linear (0, y, 0, y + height);
			stroke.add_color_stop_rgba (0.5, 0.5, 0.5, 0.5, 0.1);
			stroke.add_color_stop_rgba (0.9, 0.8, 0.8, 0.8, 0.4);
			draw_rounded_line (cr, x + line_width / 2.0, y + line_width / 2.0, width, height, true, true, stroke, null);
			
			// draw the background
			x += line_width;
			y += line_width;
			width -= 2.0 * line_width;
			height -= 2.0 * line_width;
			
			stroke = new Cairo.Pattern.rgba (0.20, 0.20, 0.20, 0.9);
			fill = new Cairo.Pattern.linear (0, y, 0, y + height);
			fill.add_color_stop_rgba (0.4, 0.25, 0.25, 0.25, 1.0);
			fill.add_color_stop_rgba (0.9, 0.35, 0.35, 0.35, 1.0);
			draw_rounded_line (cr, x + line_width / 2.0, y + line_width / 2.0, width, height, true, true, stroke, fill);
			
			// draw the finished bar
			x += line_width;
			y += line_width;
			width -= 2.0 * line_width;
			height -= 2.0 * line_width;
			
			var finished_width = Math.ceil (progress * width);
			stroke = new Cairo.Pattern.rgba (0.8, 0.8, 0.8, 1.0);
			fill = new Cairo.Pattern.rgba (0.9, 0.9, 0.9, 1.0);
			
			// Mirror progress-bar for RTL environments
			if (Gtk.Widget.get_default_direction () == Gtk.TextDirection.RTL)
				draw_rounded_line (cr, x + line_width / 2.0 + width - finished_width, y + line_width / 2.0, finished_width, height, true, true, stroke, fill);
			else
				draw_rounded_line (cr, x + line_width / 2.0, y + line_width / 2.0, finished_width, height, true, true, stroke, fill);
		}
		
		/**
		 * {@inheritDoc}
		 */
		protected override void verify (string prop)
		{
			base.verify (prop);
			
			switch (prop) {
			case "HorizPadding":
				break;
			
			case "TopPadding":
				break;
			
			case "BottomPadding":
				if (BottomPadding < 0)
					BottomPadding = 0;
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
			
			case "IndicatorStyle":
				if (IndicatorStyle < 0 || IndicatorStyle > 3)
					IndicatorStyle = IndicatorStyleType.LEGACY;
				break;
			
			case "IconShadowSize":
				if (IconShadowSize < 0)
					IconShadowSize = 0;
				else if (IconShadowSize > MAX_ICON_SHADOW_SIZE)
					IconShadowSize = MAX_ICON_SHADOW_SIZE;
				break;
			
			case "SelectionStyle":
				if (SelectionStyle < 0 || SelectionStyle > 2)
					SelectionStyle = SelectionStyleType.LEGACY;
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
			
			case "UrgentHueShift":
				if (UrgentHueShift < -180)
					UrgentHueShift = -180;
				else if (UrgentHueShift > 180)
					UrgentHueShift = 180;
				break;

			case "BadgeColor":
				break;
			}
		}
		
		static Surface rotate_for_position (owned Surface surface, Gtk.PositionType position)
		{
			if (position == Gtk.PositionType.BOTTOM)
				return surface;
			
			Surface result;
			var width = surface.Width;
			var height = surface.Height;
			var rotate = 0.0;
			
			if (position == Gtk.PositionType.TOP)
				result = new Surface.with_surface (width, height, surface);
			else
				result = new Surface.with_surface (height, width, surface);
			
			unowned Cairo.Context cr = result.Context;
			
			switch (position) {
			case Gtk.PositionType.TOP:
				rotate = Math.PI;
				break;
			case Gtk.PositionType.LEFT:
				rotate = Math.PI_2;
				break;
			case Gtk.PositionType.RIGHT:
				rotate = -Math.PI_2;
				break;
			default:
				assert_not_reached ();
			}
			
			cr.save ();
			cr.translate (result.Width / 2.0, result.Height / 2.0);
			cr.rotate (rotate);
			cr.translate (- width / 2.0, - height / 2.0);
			cr.set_source_surface (surface.Internal, 0.0, 0.0);
			cr.paint ();
			cr.restore ();
			
			return result;
		}
		
		Color get_styled_color ()
		{
			unowned Gtk.StyleContext context = get_style_context ();
			var color = (Color) context.get_background_color (context.get_state ());
			color.set_min_val (90 / (double) uint16.MAX);
			return color;
		}
	}
}
