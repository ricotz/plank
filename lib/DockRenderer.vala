//  
//  Copyright (C) 2011-2012 Robert Dyer, Rico Tzschichholz
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
#if BENCHMARK
using Gee;
#endif

using Plank.Items;
using Plank.Drawing;
using Plank.Widgets;

namespace Plank
{
	/**
	 * Handles all of the drawing for a dock.
	 */
	public class DockRenderer : AnimatedRenderer
	{
		DockController controller;
		
		DockThemeRenderer theme;
		
		DockSurface? background_buffer;
		DockSurface? main_buffer;
		DockSurface? indicator_buffer;
		DockSurface? urgent_indicator_buffer;
		DockSurface? urgent_glow_buffer;
		
		DateTime last_hide = new DateTime.from_unix_utc (0);
		
		bool screen_is_composited;
		
		/**
		 * If the dock is currently hidden.
		 */
		public bool Hidden { get; private set; default = true; }
		
		/**
		 * Returns an offset (as a percent) based on the current hide animation state.
		 *
		 * @return the offset (as a percent)
		 */
		public double get_hide_offset ()
		{
			var time = theme.FadeOpacity == 1.0 ? theme.HideTime : theme.FadeTime;
			var diff = double.min (1, new DateTime.now_utc ().difference (last_hide) / (double) (time * 1000));
			return Hidden ? diff : 1 - diff;
		}
		
		double get_opacity ()
		{
			return double.min (1, (1 - get_hide_offset ()) + theme.FadeOpacity);
		}
		
		/**
		 * Create a new dock renderer for a dock.
		 *
		 * @param controller the dock controller to manage drawing for
		 */
		public DockRenderer (DockController controller)
		{
			this.controller = controller;
			
			theme = new DockThemeRenderer ();
			theme.load ("dock");
			
			controller.prefs.notify["IconSize"].connect (prefs_changed);
			controller.prefs.notify["Position"].connect (prefs_changed);
			theme.changed.connect (theme_changed);
			controller.position_manager.reset_caches (theme);
			
			controller.items.item_removed.connect (items_changed);
			controller.items.item_added.connect (items_changed);
			controller.items.item_state_changed.connect (items_changed);
			
			screen_is_composited = Gdk.Screen.get_default ().is_composited ();
			Gdk.Screen.get_default ().composited_changed.connect (composited_changed);

			notify["Hidden"].connect (hidden_changed);
		}
		
		/**
		 * Initializes the renderer.  Call after the DockWindow is constructed.
		 */
		public void initialize ()
			requires (controller.window != null)
		{
			set_widget (controller.window);
			controller.position_manager.update_regions ();
			controller.window.notify["HoveredItem"].connect (animated_draw);
		}
		
		~DockRenderer ()
		{
			controller.prefs.notify["IconSize"].disconnect (prefs_changed);
			controller.prefs.notify["Position"].disconnect (prefs_changed);
			theme.changed.disconnect (theme_changed);
			
			controller.items.item_removed.disconnect (items_changed);
			controller.items.item_added.disconnect (items_changed);
			controller.items.item_state_changed.disconnect (items_changed);
			
			Gdk.Screen.get_default ().composited_changed.disconnect (composited_changed);

			notify["Hidden"].disconnect (hidden_changed);
			
			controller.window.notify["HoveredItem"].disconnect (animated_draw);
		}
		
		void composited_changed ()
		{
			screen_is_composited = Gdk.Screen.get_default ().is_composited ();
			
			controller.position_manager.reset_caches (theme);
			controller.position_manager.update_regions ();
		}
		
		void items_changed ()
		{
			controller.position_manager.reset_caches (theme);
			controller.position_manager.update_regions ();
		}
		
		void prefs_changed ()
		{
			controller.position_manager.reset_caches (theme);
			controller.position_manager.update_regions ();
		}
		
		void theme_changed ()
		{
			controller.position_manager.reset_caches (theme);
			controller.position_manager.update_regions ();
		}
		
		/**
		 * The dock should be shown.
		 */
		public void show ()
		{
			if (!Hidden)
				return;
			Hidden = false;
		}
		
		/**
		 * The dock should be hidden.
		 */
		public void hide ()
		{
			if (Hidden)
				return;
			Hidden = true;
		}
		
		/**
		 * Resets all internal buffers and forces a redraw.
		 */
		public void reset_buffers ()
		{
			main_buffer = null;
			background_buffer = null;
			indicator_buffer = null;
			urgent_indicator_buffer = null;
			urgent_glow_buffer = null;
			
			animated_draw ();
		}
		
#if BENCHMARK
		ArrayList<string> benchmark = new ArrayList<string> ();
#endif
		
		/**
		 * Draws the dock onto a context.
		 *
		 * @param cr the context to use for drawing
		 */
		public void draw_dock (Context cr)
		{
#if BENCHMARK
			benchmark.clear ();
			var start = new DateTime.now_local ();
#endif
			if (main_buffer != null && (main_buffer.Width != controller.position_manager.DockWidth || main_buffer.Height != controller.position_manager.DockHeight))
				reset_buffers ();
			
			if (main_buffer == null)
				main_buffer = new DockSurface.with_surface (controller.position_manager.DockWidth, controller.position_manager.DockHeight, cr.get_target ());
			
			main_buffer.clear ();
			
#if BENCHMARK
			var start2 = new DateTime.now_local ();
#endif
			draw_dock_background ();
#if BENCHMARK
			var end2 = new DateTime.now_local ();
			benchmark.add ("background render time - %f ms".printf (end2.difference (start2) / 1000.0));
#endif
			
			
			// draw each item onto the dock buffer
			foreach (var item in controller.items.Items)
			{
#if BENCHMARK
				start2 = new DateTime.now_local ();
#endif
				draw_item (item);
#if BENCHMARK
				end2 = new DateTime.now_local ();
				benchmark.add ("item render time - %f ms".printf (end2.difference (start2) / 1000.0));
#endif
			}
			
			// calculate drawing offset
			var x_offset = 0.0, y_offset = 0.0;
			
			if (theme.FadeOpacity == 1.0) {
				switch (controller.prefs.Position) {
				case PositionType.TOP:
					y_offset = -controller.position_manager.VisibleDockHeight * get_hide_offset ();
					break;
				case PositionType.BOTTOM:
					y_offset = controller.position_manager.VisibleDockHeight * get_hide_offset ();
					break;
				case PositionType.LEFT:
					x_offset = -controller.position_manager.VisibleDockWidth * get_hide_offset ();
					break;
				case PositionType.RIGHT:
					x_offset = controller.position_manager.VisibleDockWidth * get_hide_offset ();
					break;
				}
			}
			
			// draw the dock on the window
			cr.set_operator (Operator.SOURCE);
			cr.set_source_surface (main_buffer.Internal, x_offset, y_offset);
			cr.paint ();
			
			// fade the dock if need be
			if (get_opacity () < 1.0) {
				cr.set_source_rgba (0, 0, 0, 0);
				cr.paint_with_alpha (1 - get_opacity ());
			}
			
			// dock is completely hidden
			if (get_hide_offset () == 1) {
				if (urgent_glow_buffer == null)
					create_urgent_glow ();
				
				foreach (var item in controller.items.Items) {
					if ((item.State & ItemState.URGENT) == 0)
						continue;
					
					var diff = new DateTime.now_utc ().difference (item.LastUrgent);
					if (diff >= theme.GlowTime * 1000)
						continue;
					
					var rect = controller.position_manager.item_draw_region (item);
					switch (controller.prefs.Position) {
					case PositionType.BOTTOM:
						x_offset = rect.x + rect.width / 2.0 - urgent_glow_buffer.Width / 2.0;
						y_offset = main_buffer.Height - urgent_glow_buffer.Height / 2.0;
						break;
					case PositionType.TOP:
						x_offset = rect.x + rect.width / 2.0 - urgent_glow_buffer.Width / 2.0;
						y_offset = - urgent_glow_buffer.Height / 2.0;
						break;
					case PositionType.LEFT:
						y_offset = rect.y + rect.height / 2.0 - urgent_glow_buffer.Height / 2.0;
						x_offset = - urgent_glow_buffer.Width / 2.0;
						break;
					case PositionType.RIGHT:
						y_offset = rect.y + rect.height / 2.0 - urgent_glow_buffer.Height / 2.0;
						x_offset = main_buffer.Width - urgent_glow_buffer.Width / 2.0;
						break;
					}
					
					cr.set_source_surface (urgent_glow_buffer.Internal, x_offset, y_offset);
					var opacity = 0.2 + (0.75 * (Math.sin (diff / (double) (theme.GlowPulseTime * 1000) * 2 * Math.PI) + 1) / 2);
					cr.paint_with_alpha (opacity);
				}
			}
#if BENCHMARK
			var end = new DateTime.now_local ();
			var diff = end.difference (start) / 1000.0;
			if (diff > 5.0)
				foreach (var s in benchmark)
					message ("	" + s);
			message ("render time - %f ms", diff);
#endif
		}
		
		void draw_dock_background ()
		{
			var width = 0, height = 0;
			
			if (controller.prefs.is_horizontal_dock ()) {
				width = controller.position_manager.DockBackgroundWidth;
				height = controller.position_manager.DockBackgroundHeight;
			} else {
				width = controller.position_manager.DockBackgroundHeight;
				height = controller.position_manager.DockBackgroundWidth;
			}
			
			if (background_buffer == null || background_buffer.Width != width || background_buffer.Height != height) {
				background_buffer = new DockSurface.with_dock_surface (width, height, main_buffer);
				theme.draw_background (background_buffer);
			}
			
			var cr = main_buffer.Context;
			cr.save ();
			
			switch (controller.prefs.Position) {
			case PositionType.TOP:
				cr.scale (1, -1);
				cr.translate ((main_buffer.Width - background_buffer.Width) / 2.0, -background_buffer.Height);
				break;
			case PositionType.BOTTOM:
				cr.translate ((main_buffer.Width - background_buffer.Width) / 2.0, main_buffer.Height - background_buffer.Height);
				break;
			case PositionType.LEFT:
				cr.rotate (Math.PI * 0.5);
				cr.translate ((main_buffer.Height - background_buffer.Width) / 2.0, -background_buffer.Height);
				break;
			case PositionType.RIGHT:
				cr.rotate (Math.PI * -0.5);
				cr.translate ((-main_buffer.Height - background_buffer.Width) / 2.0, main_buffer.Width - background_buffer.Height);
				break;
			}
			
			cr.set_source_surface (background_buffer.Internal, 0, 0);
			cr.paint ();
			cr.restore ();
		}
		
		void draw_item (DockItem item)
		{
			var icon_surface = new DockSurface.with_dock_surface (controller.prefs.IconSize, controller.prefs.IconSize, main_buffer);
			var icon_cr = icon_surface.Context;
			var main_cr = main_buffer.Context;
			
			// load the icon
#if BENCHMARK
			var start = new DateTime.now_local ();
#endif
			var item_surface = item.get_surface (icon_surface);
#if BENCHMARK
			var end = new DateTime.now_local ();
			benchmark.add ("	item.get_surface time - %f ms".printf (end.difference (start) / 1000.0));
#endif
			icon_cr.set_source_surface (item_surface.Internal, 0, 0);
			icon_cr.paint ();
			
			// get draw regions
			var draw_rect = controller.position_manager.item_draw_region (item);
			var hover_rect = draw_rect;
			
			var top_padding = controller.position_manager.TopPadding;
			var bottom_padding = controller.position_manager.BottomPadding;

			switch (controller.prefs.Position) {
			case PositionType.TOP:
				draw_rect.x += controller.position_manager.ItemPadding / 2;
				draw_rect.y += 2 * theme.get_bottom_offset () + bottom_padding;
				draw_rect.height -= bottom_padding;
				break;
			case PositionType.BOTTOM:
				draw_rect.x += controller.position_manager.ItemPadding / 2;
				draw_rect.y += 2 * theme.get_top_offset () + (top_padding > 0 ? top_padding : 0);
				draw_rect.height -= top_padding;
				break;
			case PositionType.LEFT:
				draw_rect.y += controller.position_manager.ItemPadding / 2;
				draw_rect.x += 2 * theme.get_bottom_offset () + bottom_padding;
				draw_rect.width -= bottom_padding;
				break;
			case PositionType.RIGHT:
				draw_rect.y += controller.position_manager.ItemPadding / 2;
				draw_rect.x += 2 * theme.get_top_offset () + (top_padding > 0 ? top_padding : 0);
				draw_rect.width -= top_padding;
				break;
			}
			
			// lighten or darken the icon
			var lighten = 0.0, darken = 0.0;
			
			var max_click_time = item.ClickedAnimation == ClickAnimation.BOUNCE ? theme.LaunchBounceTime : theme.ClickTime;
			max_click_time *= 1000;
			var click_time = new DateTime.now_utc ().difference (item.LastClicked);
			if (click_time < max_click_time) {
				var clickAnimationProgress = click_time / (double) max_click_time;
				
				switch (item.ClickedAnimation) {
				case ClickAnimation.BOUNCE:
					if (!screen_is_composited)
						break;
					var change = ((int) (Math.sin (2 * Math.PI * clickAnimationProgress) * controller.prefs.IconSize * theme.LaunchBounceHeight)).abs ();
					switch (controller.prefs.Position) {
					case PositionType.BOTTOM:
						draw_rect.y -= change;
						break;
					case PositionType.TOP:
						draw_rect.y += change;
						break;
					case PositionType.LEFT:
						draw_rect.x += change;
						break;
					case PositionType.RIGHT:
						draw_rect.x -= change;
						break;
					}
					break;
				case ClickAnimation.DARKEN:
					darken = double.max (0, Math.sin (Math.PI * clickAnimationProgress)) * 0.5;
					break;
				case ClickAnimation.LIGHTEN:
					lighten = double.max (0, Math.sin (Math.PI * clickAnimationProgress)) * 0.5;
					break;
				}
			}
			
			if (controller.window.HoveredItem == item)
				lighten = 0.2;
			
			if (controller.window.HoveredItem == item && controller.window.menu_is_visible ())
				darken += 0.4;
			
			// glow the icon
			if (lighten > 0) {
				icon_cr.set_operator (Cairo.Operator.ADD);
				icon_cr.paint_with_alpha (lighten);
				icon_cr.set_operator (Cairo.Operator.OVER);
			}
			
			// draw badge text
			if (item.BadgeText != "")
				draw_badge (icon_surface, item.BadgeText);
			
			// darken the icon
			if (darken > 0) {
				icon_cr.rectangle (0, 0, icon_surface.Width, icon_surface.Height);
				icon_cr.set_source_rgba (0, 0, 0, darken);
				
				icon_cr.set_operator (Cairo.Operator.ATOP);
				icon_cr.fill ();
				icon_cr.set_operator (Cairo.Operator.OVER);
			}
			
			// bounce icon on urgent state
			var urgent_time = new DateTime.now_utc ().difference (item.LastUrgent);
			if (screen_is_composited && (item.State & ItemState.URGENT) != 0 && urgent_time < theme.UrgentBounceTime * 1000) {
				var change = (int) Math.fabs (Math.sin (Math.PI * urgent_time / (double) (theme.UrgentBounceTime * 1000)) * controller.prefs.IconSize * theme.UrgentBounceHeight);
				switch (controller.prefs.Position) {
				case PositionType.BOTTOM:
					draw_rect.y -= change;
					break;
				case PositionType.TOP:
					draw_rect.y += change;
					break;
				case PositionType.LEFT:
					draw_rect.x += change;
					break;
				case PositionType.RIGHT:
					draw_rect.x -= change;
					break;
				}
			}
			
			// draw active glow
			var active_time = new DateTime.now_utc ().difference (item.LastActive);
			var opacity = double.min (1, active_time / (double) (theme.ActiveTime * 1000));
			if ((item.State & ItemState.ACTIVE) == 0)
				opacity = 1 - opacity;
			if (opacity > 0)
				theme.draw_active_glow (main_buffer, controller.position_manager.HorizPadding, controller.position_manager.TopPadding, background_buffer, hover_rect, item.AverageIconColor, opacity, controller.prefs.Position);
			
			// draw the icon
			main_cr.set_source_surface (icon_surface.Internal, draw_rect.x, draw_rect.y);
			main_cr.paint ();
			
			// draw indicators
			if (item.Indicator != IndicatorState.NONE)
				draw_indicator_state (hover_rect, item.Indicator, item.State);
		}
		
		void draw_indicator_state (Gdk.Rectangle item_rect, IndicatorState indicator, ItemState item_state)
		{
			if (indicator_buffer == null)
				create_normal_indicator ();
			if (urgent_indicator_buffer == null)
				create_urgent_indicator ();
			
			var indicator_surface = (item_state & ItemState.URGENT) != 0 ? urgent_indicator_buffer : indicator_buffer;
			var main_cr = main_buffer.Context;
			
			var x = 0.0, y = 0.0;
			switch (controller.prefs.Position) {
			case PositionType.TOP:
				x = item_rect.x + item_rect.width / 2.0 - indicator_surface.Width / 2.0;
				y = - indicator_surface.Height / 2 + 2 * theme.get_bottom_offset () + indicator_surface.Height / 24.0;
				break;
			case PositionType.BOTTOM:
				x = item_rect.x + item_rect.width / 2.0 - indicator_surface.Width / 2.0;
				y = main_buffer.Height - indicator_surface.Height / 2 - 2 * theme.get_bottom_offset () - indicator_surface.Height / 24.0;
				break;
			case PositionType.LEFT:
				x = - indicator_surface.Width / 2 + 2 * theme.get_bottom_offset () + indicator_surface.Width / 24.0;
				y = item_rect.y + item_rect.height / 2.0 - indicator_surface.Height / 2.0;
				break;
			case PositionType.RIGHT:
				x = main_buffer.Width - indicator_surface.Width / 2 - 2 * theme.get_bottom_offset () - indicator_surface.Width / 24.0;
				y = item_rect.y + item_rect.height / 2.0 - indicator_surface.Height / 2.0;
				break;
			}
			
			if (indicator == IndicatorState.SINGLE) {
				main_cr.set_source_surface (indicator_surface.Internal, x, y);
				main_cr.paint ();
			} else {
				var x_offset = 0.0, y_offset = 0.0;
				if (controller.prefs.is_horizontal_dock ())
					x_offset = controller.prefs.IconSize / 16.0;
				else
					y_offset = controller.prefs.IconSize / 16.0;
				
				main_cr.set_source_surface (indicator_surface.Internal, x - x_offset, y - y_offset);
				main_cr.paint ();
				main_cr.set_source_surface (indicator_surface.Internal, x + x_offset, y + y_offset);
				main_cr.paint ();
			}
		}
		
		Drawing.Color get_styled_color ()
		{
			return new Drawing.Color.from_gdk (controller.window.get_style ().bg [StateType.SELECTED]).set_min_value (90 / (double) uint16.MAX);
		}
		
		void create_normal_indicator ()
		{
			indicator_buffer = theme.create_indicator (background_buffer, controller.position_manager.IndicatorSize, get_styled_color ().set_min_sat (0.4));
		}
		
		int urgent_hue_shift = 150;
		
		void create_urgent_indicator ()
		{
			urgent_indicator_buffer = theme.create_indicator (background_buffer, controller.position_manager.IndicatorSize, get_styled_color ().add_hue (urgent_hue_shift).set_sat (1));
		}
		
		void create_urgent_glow ()
		{
			var color = get_styled_color ().add_hue (urgent_hue_shift).set_sat (1);
			
			var size = controller.position_manager.GlowSize;
			urgent_glow_buffer = new DockSurface.with_dock_surface (size, size, background_buffer);
			var cr = urgent_glow_buffer.Context;
			
			var x = size / 2.0;
			
			cr.move_to (x, x);
			cr.arc (x, x, size / 2, 0, Math.PI * 2);
			
			var rg = new Pattern.radial (x, x, 0, x, x, size / 2);
			rg.add_color_stop_rgba (0, 1, 1, 1, 1);
			rg.add_color_stop_rgba (0.33, color.R, color.G, color.B, 0.66);
			rg.add_color_stop_rgba (0.66, color.R, color.G, color.B, 0.33);
			rg.add_color_stop_rgba (1.0, color.R, color.G, color.B, 0.0);
			
			cr.set_source (rg);
			cr.fill ();
		}
		
		/**
		 * Draws a badge for an item.
		 *
		 * @param surface the surface to draw the badge onto
		 * @param badge_text the text for the badge
		 */
		public void draw_badge (DockSurface surface, string badge_text)
		{
			var cr = surface.Context;
			
			var theme_color = get_styled_color ();
			var badge_color_start = theme_color.set_val (1).set_sat (0.47);
			var badge_color_end = theme_color.set_val (0.5).set_sat (0.51);
			
			var is_small = controller.prefs.IconSize < 32;
			var padding = 4;
			var lineWidth = 2;
			var size = (is_small ? 0.9 : 0.65) * double.min (surface.Width, surface.Height);
			var x = surface.Width - size / 2.0;
			var y = size / 2.0;
			
			if (!is_small) {
				// draw outline shadow
				cr.set_line_width (lineWidth);
				cr.set_source_rgba (0, 0, 0, 0.5);
				cr.arc (x, y + 1, size / 2 - lineWidth, 0, Math.PI * 2);
				cr.stroke ();
				
				// draw filled gradient
				var rg = new Pattern.radial (x, lineWidth, 0, x, lineWidth, size);
				rg.add_color_stop_rgba (0, badge_color_start.R, badge_color_start.G, badge_color_start.B, badge_color_start.A);
				rg.add_color_stop_rgba (1.0, badge_color_end.R, badge_color_end.G, badge_color_end.B, badge_color_end.A);
				
				cr.set_source (rg);
				cr.arc (x, y, size / 2 - lineWidth, 0, Math.PI * 2);
				cr.fill ();
				
				// draw outline
				cr.set_source_rgba (1, 1, 1, 1);
				cr.arc (x, y, size / 2 - lineWidth, 0, Math.PI * 2);
				cr.stroke ();
				
				cr.set_line_width (lineWidth / 2);
				cr.set_source_rgba (badge_color_end.R, badge_color_end.G, badge_color_end.B, badge_color_end.A);
				cr.arc (x, y, size / 2 - 2 * lineWidth, 0, Math.PI * 2);
				cr.stroke ();
				
				cr.set_source_rgba (0, 0, 0, 0.2);
			} else {
				lineWidth = 0;
				padding = 2;
			}
			
			var layout = new Pango.Layout (pango_context_get ());
			layout.set_width ((int) (surface.Height / 2 * Pango.SCALE));
			layout.set_ellipsize (Pango.EllipsizeMode.NONE);
			
			var font_description = new Gtk.Style ().font_desc;
			font_description.set_absolute_size ((int) (surface.Height / 2 * Pango.SCALE));
			font_description.set_weight (Pango.Weight.BOLD);
			layout.set_font_description (font_description);
			
			layout.set_text (badge_text, -1);
			Pango.Rectangle ink_rect, logical_rect;
			layout.get_pixel_extents (out ink_rect, out logical_rect);
			
			size -= 2 * padding + 2 * lineWidth;
			
			var scale = double.min (1, double.min (size / (double) logical_rect.width, size / (double) logical_rect.height));
			
			if (!is_small) {
				cr.set_source_rgba (0, 0, 0, 0.2);
			} else {
				cr.set_source_rgba (0, 0, 0, 0.6);
				x = surface.Width - scale * logical_rect.width / 2;
				y = scale * logical_rect.height / 2;
			}
			
			cr.move_to (x - scale * logical_rect.width / 2, y - scale * logical_rect.height / 2);
			
			// draw text
			cr.save ();
			if (scale < 1)
				cr.scale (scale, scale);
			
			cr.set_line_width (2);
			Pango.cairo_layout_path (cr, layout);
			cr.stroke_preserve ();
			cr.set_source_rgba (1, 1, 1, 1);
			cr.fill ();
			cr.restore ();
		}
		
		void hidden_changed ()
		{
			var now = new DateTime.now_utc ();
			var diff = now.difference (last_hide);
			
			if (diff < theme.HideTime * 1000)
				last_hide = now.add_seconds ((diff - theme.HideTime * 1000) / 1000000.0);
			else
				last_hide = new DateTime.now_utc ();
			
			animated_draw ();
		}
		
		/**
		 * {@inheritDoc}
		 */
		protected override bool animation_needed (DateTime render_time)
		{
			if (theme.FadeOpacity == 1.0) {
				if (render_time.difference (last_hide) <= theme.HideTime * 1000)
					return true;
			} else {
				if (render_time.difference (last_hide) <= theme.FadeTime * 1000)
					return true;
			}
			
			foreach (DockItem item in controller.items.Items) {
				if (render_time.difference (item.LastClicked) <= (item.ClickedAnimation == ClickAnimation.BOUNCE ? theme.LaunchBounceTime : theme.ClickTime) * 1000)
					return true;
				if (render_time.difference (item.LastActive) <= theme.ActiveTime * 1000)
					return true;
				if (render_time.difference (item.LastUrgent) <= (get_hide_offset () == 1.0 ? theme.GlowTime : theme.UrgentBounceTime) * 1000)
					return true;
			}
				
			return false;
		}
	}
}
