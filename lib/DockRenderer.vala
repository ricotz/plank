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
			
			controller.prefs.notify["IconSize"].connect (icon_size_changed);
			theme.changed.connect (theme_changed);
			controller.position_manager.reset_item_caches (theme, urgent_glow_size ());
			
			controller.items.item_removed.connect (items_changed);
			controller.items.item_added.connect (items_changed);
			controller.items.item_state_changed.connect (items_changed);
			
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
			controller.prefs.notify["IconSize"].disconnect (icon_size_changed);
			theme.changed.disconnect (theme_changed);
			
			controller.items.item_removed.disconnect (items_changed);
			controller.items.item_added.disconnect (items_changed);
			controller.items.item_state_changed.disconnect (items_changed);
			
			notify["Hidden"].disconnect (hidden_changed);
			
			controller.window.notify["HoveredItem"].disconnect (animated_draw);
		}
		
		void items_changed ()
		{
			controller.position_manager.reset_item_caches (theme, urgent_glow_size ());
			controller.position_manager.update_regions ();
			animated_draw ();
		}
		
		void icon_size_changed ()
		{
			controller.position_manager.reset_item_caches (theme, urgent_glow_size ());
			controller.position_manager.update_regions ();
			animated_draw ();
		}
		
		void theme_changed ()
		{
			controller.position_manager.reset_caches (theme);
			controller.position_manager.update_regions ();
			controller.window.set_size ();
			animated_draw ();
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
			if (main_buffer != null && (main_buffer.Width != controller.position_manager.VisibleDockWidth || main_buffer.Height != controller.position_manager.DockHeight))
				reset_buffers ();
			
			if (main_buffer == null)
				main_buffer = new DockSurface.with_surface (controller.position_manager.VisibleDockWidth, controller.position_manager.DockHeight, cr.get_target ());
			
			main_buffer.clear ();
			
#if BENCHMARK
			var start2 = new DateTime.now_local ();
#endif
			draw_dock_background (main_buffer);
#if BENCHMARK
			var end2 = new DateTime.now_local ();
			benchmark.add ("background render time - %f ms".printf (end2.difference (start2) / 1000.0));
#endif
			
			
			foreach (var item in controller.items.Items)
			{
#if BENCHMARK
				start2 = new DateTime.now_local ();
#endif
				// Do not draw the currently dragged item
				if (controller.drag_manager.DragItem != item)
					draw_item (main_buffer, item);
#if BENCHMARK
				end2 = new DateTime.now_local ();
				benchmark.add ("item render time - %f ms".printf (end2.difference (start2) / 1000.0));
#endif
			}
			
			var x_offset = (controller.window.width_request - main_buffer.Width) / 2;
			
			cr.set_operator (Operator.SOURCE);
			var y_offset = 0.0;
			if (theme.FadeOpacity == 1.0)
				y_offset = controller.position_manager.VisibleDockHeight * get_hide_offset ();
			cr.set_source_surface (main_buffer.Internal, x_offset, y_offset);
			cr.paint ();
			
			if (get_opacity () < 1.0) {
				cr.set_source_rgba (0, 0, 0, 0);
				cr.paint_with_alpha (1 - get_opacity ());
			}
			
			if (get_hide_offset () == 1) {
				if (urgent_glow_buffer == null)
					create_urgent_glow (background_buffer);
				
				foreach (var item in controller.items.Items) {
					var diff = new DateTime.now_utc ().difference (item.LastUrgent);
					
					if ((item.State & ItemState.URGENT) == ItemState.URGENT && diff < theme.GlowTime * 1000) {
						var rect = controller.position_manager.item_draw_region (item);
						cr.set_source_surface (urgent_glow_buffer.Internal,
							x_offset + rect.x + rect.width / 2.0 - urgent_glow_buffer.Width / 2.0,
							main_buffer.Height - urgent_glow_buffer.Height / 2.0);
						var opacity = 0.2 + (0.75 * (Math.sin (diff / (double) (theme.GlowPulseTime * 1000) * 2 * Math.PI) + 1) / 2);
						cr.paint_with_alpha (opacity);
					}
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
		
		void draw_dock_background (DockSurface surface)
		{
			if (background_buffer == null || background_buffer.Width != controller.position_manager.DockBackgroundWidth || background_buffer.Height != controller.position_manager.DockBackgroundHeight) {
				background_buffer = new DockSurface.with_dock_surface (controller.position_manager.DockBackgroundWidth, controller.position_manager.DockBackgroundHeight, surface);
				theme.draw_background (background_buffer);
			}
			
			surface.Context.set_source_surface (background_buffer.Internal, (surface.Width - background_buffer.Width) / 2.0, surface.Height - background_buffer.Height);
			surface.Context.paint ();
		}
		
		void draw_item (DockSurface surface, DockItem item)
		{
			var icon_surface = new DockSurface.with_dock_surface (controller.prefs.IconSize, controller.prefs.IconSize, surface);
			
			// load the icon
#if BENCHMARK
			var start = new DateTime.now_local ();
#endif
			var item_surface = item.get_surface (icon_surface);
#if BENCHMARK
			var end = new DateTime.now_local ();
			benchmark.add ("	item.get_surface time - %f ms".printf (end.difference (start) / 1000.0));
#endif
			icon_surface.Context.set_source_surface (item_surface.Internal, 0, 0);
			icon_surface.Context.paint ();
			
			// get draw regions
			var draw_rect = controller.position_manager.item_draw_region (item);
			var hover_rect = draw_rect;
			
			var top_padding = controller.position_manager.TopPadding;
			draw_rect.x += controller.position_manager.ItemPadding / 2;
			draw_rect.y += 2 * theme.get_top_offset () + (top_padding > 0 ? top_padding : 0);
			draw_rect.height -= top_padding;
			
			// lighten or darken the icon
			var lighten = 0.0;
			var darken = 0.0;
			
			var max_click_time = item.ClickedAnimation == ClickAnimation.BOUNCE ? theme.LaunchBounceTime : theme.ClickTime;
			max_click_time *= 1000;
			var click_time = new DateTime.now_utc ().difference (item.LastClicked);
			if (click_time < max_click_time) {
				var clickAnimationProgress = click_time / (double) max_click_time;
				
				switch (item.ClickedAnimation) {
				case ClickAnimation.BOUNCE:
					if (Gdk.Screen.get_default ().is_composited ())
						draw_rect.y -= ((int) (Math.sin (2 * Math.PI * clickAnimationProgress) * controller.prefs.IconSize * theme.LaunchBounceHeight)).abs ();
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
			else if (controller.drag_manager.ExternalDragActive && controller.drag_manager.drag_data != null && !item.can_accept_drop (controller.drag_manager.drag_data))
				darken += 0.6;
			
			// glow the icon
			if (lighten > 0) {
				icon_surface.Context.set_operator (Cairo.Operator.ADD);
				icon_surface.Context.paint_with_alpha (lighten);
				icon_surface.Context.set_operator (Cairo.Operator.OVER);
			}
			
			// draw badge text
			if (item.BadgeText != "")
				draw_badge (icon_surface, item.BadgeText);
			
			// darken the icon
			if (darken > 0) {
				icon_surface.Context.rectangle (0, 0, icon_surface.Width, icon_surface.Height);
				icon_surface.Context.set_source_rgba (0, 0, 0, darken);
				
				icon_surface.Context.set_operator (Cairo.Operator.ATOP);
				icon_surface.Context.fill ();
				icon_surface.Context.set_operator (Cairo.Operator.OVER);
			}
			
			// bounce icon on urgent state
			var urgent_time = new DateTime.now_utc ().difference (item.LastUrgent);
			if (Gdk.Screen.get_default().is_composited () && (item.State & ItemState.URGENT) != 0 && urgent_time < theme.UrgentBounceTime * 1000)
				draw_rect.y -= (int) Math.fabs (Math.sin (Math.PI * urgent_time / (double) (theme.UrgentBounceTime * 1000)) * controller.prefs.IconSize * theme.UrgentBounceHeight);
			
			// draw active glow
			var active_time = new DateTime.now_utc ().difference (item.LastActive);
			var opacity = double.min (1, active_time / (double) (theme.ActiveTime * 1000));
			if ((item.State & ItemState.ACTIVE) == 0)
				opacity = 1 - opacity;
			if (opacity > 0)
				theme.draw_active_glow (surface, controller.position_manager.HorizPadding, background_buffer, hover_rect, item.AverageIconColor, opacity);
			
			// draw the icon
			surface.Context.set_source_surface (icon_surface.Internal, draw_rect.x, draw_rect.y);
			surface.Context.paint ();
			
			// draw indicators
			if (item.Indicator != IndicatorState.NONE) {
				var indicator_size = controller.position_manager.IndicatorSize;
				if (indicator_buffer == null)
					create_normal_indicator (indicator_size);
				if (urgent_indicator_buffer == null)
					create_urgent_indicator (indicator_size);
				
				var indicator = (item.State & ItemState.URGENT) != 0 ? urgent_indicator_buffer : indicator_buffer;
				
				var x = hover_rect.x + hover_rect.width / 2 - indicator.Width / 2;
				// have to do the (int) cast to avoid valac segfault (valac 0.11.4)
 				var y = main_buffer.Height - indicator.Height / 2 - 2 * (int) theme.get_bottom_offset () - indicator_size / 24.0;
				
				if (item.Indicator == IndicatorState.SINGLE) {
					surface.Context.set_source_surface (indicator.Internal, x, y);
					surface.Context.paint ();
				} else {
					surface.Context.set_source_surface (indicator.Internal, x - controller.prefs.IconSize / 16.0, y);
					surface.Context.paint ();
					surface.Context.set_source_surface (indicator.Internal, x + controller.prefs.IconSize / 16.0, y);
					surface.Context.paint ();
				}
			}
		}
		
		Drawing.Color get_styled_color ()
		{
			return new Drawing.Color.from_gdk (controller.window.get_style ().bg [StateType.SELECTED]).set_min_value (90 / (double) uint16.MAX);
		}
		
		void create_normal_indicator (int size)
		{
			indicator_buffer = theme.create_indicator (background_buffer, size, get_styled_color ().set_min_sat (0.4));
		}
		
		int urgent_hue_shift = 150;
		
		void create_urgent_indicator (int size)
		{
			urgent_indicator_buffer = theme.create_indicator (background_buffer, size, get_styled_color ().add_hue (urgent_hue_shift).set_sat (1));
		}
		
		int urgent_glow_size ()
		{
			return (int) (theme.GlowSize / 10.0 * controller.prefs.IconSize);
		}
		
		void create_urgent_glow (DockSurface surface)
		{
			var color = get_styled_color ().add_hue (urgent_hue_shift).set_sat (1);
			
			var size = urgent_glow_size ();
			urgent_glow_buffer = new DockSurface.with_dock_surface (size, size, surface);
			
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
			var theme_color = new Drawing.Color.from_gdk (controller.window.get_style ().bg [StateType.SELECTED]);
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
				surface.Context.set_line_width (lineWidth);
				surface.Context.set_source_rgba (0, 0, 0, 0.5);
				surface.Context.arc (x, y + 1, size / 2 - lineWidth, 0, Math.PI * 2);
				surface.Context.stroke ();
				
				// draw filled gradient
				var rg = new Pattern.radial (x, lineWidth, 0, x, lineWidth, size);
				rg.add_color_stop_rgba (0, badge_color_start.R, badge_color_start.G, badge_color_start.B, badge_color_start.A);
				rg.add_color_stop_rgba (1.0, badge_color_end.R, badge_color_end.G, badge_color_end.B, badge_color_end.A);
				
				surface.Context.set_source (rg);
				surface.Context.arc (x, y, size / 2 - lineWidth, 0, Math.PI * 2);
				surface.Context.fill ();
				
				// draw outline
				surface.Context.set_source_rgba (1, 1, 1, 1);
				surface.Context.arc (x, y, size / 2 - lineWidth, 0, Math.PI * 2);
				surface.Context.stroke ();
				
				surface.Context.set_line_width (lineWidth / 2);
				surface.Context.set_source_rgba (badge_color_end.R, badge_color_end.G, badge_color_end.B, badge_color_end.A);
				surface.Context.arc (x, y, size / 2 - 2 * lineWidth, 0, Math.PI * 2);
				surface.Context.stroke ();
				
				surface.Context.set_source_rgba (0, 0, 0, 0.2);
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
				surface.Context.set_source_rgba (0, 0, 0, 0.2);
			} else {
				surface.Context.set_source_rgba (0, 0, 0, 0.6);
				x = surface.Width - scale * logical_rect.width / 2;
				y = scale * logical_rect.height / 2;
			}
			
			surface.Context.move_to (x - scale * logical_rect.width / 2, y - scale * logical_rect.height / 2);
			
			// draw text
			surface.Context.save ();
			if (scale < 1)
				surface.Context.scale (scale, scale);
			
			surface.Context.set_line_width (2);
			Pango.cairo_layout_path (surface.Context, layout);
			surface.Context.stroke_preserve ();
			surface.Context.set_source_rgba (1, 1, 1, 1);
			surface.Context.fill ();
			surface.Context.restore ();
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
