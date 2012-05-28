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
using Plank.Services;
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
			
			controller.prefs.notify.connect (prefs_changed);
			theme.changed.connect (theme_changed);
			controller.position_manager.reset_caches (theme);
			
			controller.items.item_removed.connect (items_changed);
			controller.items.item_added.connect (items_changed);
			controller.items.item_state_changed.connect (item_state_changed);
			
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
			controller.prefs.notify.disconnect (prefs_changed);
			theme.changed.disconnect (theme_changed);
			
			controller.items.item_removed.disconnect (items_changed);
			controller.items.item_added.disconnect (items_changed);
			controller.items.item_state_changed.disconnect (item_state_changed);
			
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
		
		void item_state_changed ()
		{
			animated_draw ();
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
			Logger.verbose ("DockRenderer.reset_buffers ()");
			
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
			var width = controller.position_manager.DockWidth;
			var height = controller.position_manager.DockHeight;
			
#if BENCHMARK
			benchmark.clear ();
			var start = new DateTime.now_local ();
#endif
			if (main_buffer != null && (main_buffer.Width != width || main_buffer.Height != height))
				reset_buffers ();
			
			if (main_buffer == null)
				main_buffer = new DockSurface.with_surface (width, height, cr.get_target ());
			
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
			var x_offset = 0, y_offset = 0;
			if (theme.FadeOpacity == 1.0)
				controller.position_manager.get_dock_draw_position (out x_offset, out y_offset);
			
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
					urgent_glow_buffer = theme.create_urgent_glow (controller.position_manager.GlowSize, get_styled_color ().add_hue (theme.UrgentHueShift).set_sat (1), background_buffer);
				
				foreach (var item in controller.items.Items) {
					if ((item.State & ItemState.URGENT) == 0)
						continue;
					
					var diff = new DateTime.now_utc ().difference (item.LastUrgent);
					if (diff >= theme.GlowTime * 1000)
						continue;
					
					controller.position_manager.get_urgent_glow_position (item, out x_offset, out y_offset);
					
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
			var width = controller.position_manager.DockBackgroundWidth;
			var height = controller.position_manager.DockBackgroundHeight;
			
			if (background_buffer == null || background_buffer.Width != width || background_buffer.Height != height)
				background_buffer = theme.create_background (width, height, controller.prefs.Position, main_buffer);
			
			var x_offset = 0, y_offset = 0;
			controller.position_manager.get_background_position (out x_offset, out y_offset);
			
			var cr = main_buffer.Context;
			cr.set_source_surface (background_buffer.Internal, x_offset, y_offset);
			cr.paint ();
		}
		
		void draw_item (DockItem item)
		{
			var main_cr = main_buffer.Context;
			var icon_size = controller.prefs.IconSize;
			
			// load the icon
#if BENCHMARK
			var start = new DateTime.now_local ();
#endif
			var icon_surface = item.get_surface_copy (icon_size, icon_size, main_buffer);
			var icon_cr = icon_surface.Context;
#if BENCHMARK
			var end = new DateTime.now_local ();
			benchmark.add ("	item.get_surface time - %f ms".printf (end.difference (start) / 1000.0));
#endif
			
			// get regions
			var hover_rect = controller.position_manager.item_hover_region (item);
			var draw_rect = controller.position_manager.item_draw_region (hover_rect);
			
			// lighten or darken the icon
			var lighten = 0.0, darken = 0.0;
			
			var max_click_time = item.ClickedAnimation == ClickAnimation.BOUNCE ? theme.LaunchBounceTime : theme.ClickTime;
			max_click_time *= 1000;
			var click_time = new DateTime.now_utc ().difference (item.LastClicked);
			if (click_time < max_click_time) {
				var clickAnimationProgress = click_time / (double) max_click_time;
				
				switch (item.ClickedAnimation) {
				default:
				case ClickAnimation.NONE:
					break;
				case ClickAnimation.BOUNCE:
					if (!screen_is_composited)
						break;
					var change = ((int) (Math.sin (2 * Math.PI * clickAnimationProgress) * icon_size * theme.LaunchBounceHeight)).abs ();
					switch (controller.prefs.Position) {
					default:
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
			
			
			// TODO put them onto a cached icon_overlay_surface for performance reasons?
			// maybe even draw outside of the item-draw-area (considering the hover-area)
			
			// draw item's count
			if (item.CountVisible)
				theme.draw_item_count (icon_surface, icon_size, get_styled_color ().add_hue (theme.UrgentHueShift), item.Count);
			
			// draw item's progress
			if (item.ProgressVisible)
				theme.draw_item_progress (icon_surface, icon_size, get_styled_color (), item.Progress);
			
			
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
				var change = (int) Math.fabs (Math.sin (Math.PI * urgent_time / (double) (theme.UrgentBounceTime * 1000)) * icon_size * theme.UrgentBounceHeight);
				switch (controller.prefs.Position) {
				default:
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
			if (opacity > 0) {
				var glow_rect = controller.position_manager.item_background_region (hover_rect);
				theme.draw_active_glow (main_buffer, background_buffer, glow_rect, item.AverageIconColor, opacity, controller.prefs.Position);
			}
			
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
				indicator_buffer = theme.create_indicator (controller.position_manager.IndicatorSize, get_styled_color ().set_min_sat (0.4), background_buffer);
			if (urgent_indicator_buffer == null)
				urgent_indicator_buffer = theme.create_indicator (controller.position_manager.IndicatorSize, get_styled_color ().add_hue (theme.UrgentHueShift).set_sat (1), background_buffer);
			
			var indicator_surface = (item_state & ItemState.URGENT) != 0 ? urgent_indicator_buffer : indicator_buffer;
			var main_cr = main_buffer.Context;
			
			var x = 0.0, y = 0.0;
			switch (controller.prefs.Position) {
			default:
			case PositionType.BOTTOM:
				x = item_rect.x + item_rect.width / 2.0 - indicator_surface.Width / 2.0;
				y = main_buffer.Height - indicator_surface.Height / 2.0 - 2.0 * theme.get_bottom_offset () - indicator_surface.Height / 24.0;
				break;
			case PositionType.TOP:
				x = item_rect.x + item_rect.width / 2.0 - indicator_surface.Width / 2.0;
				y = - indicator_surface.Height / 2.0 + 2.0 * theme.get_bottom_offset () + indicator_surface.Height / 24.0;
				break;
			case PositionType.LEFT:
				x = - indicator_surface.Width / 2.0 + 2.0 * theme.get_bottom_offset () + indicator_surface.Width / 24.0;
				y = item_rect.y + item_rect.height / 2.0 - indicator_surface.Height / 2.0;
				break;
			case PositionType.RIGHT:
				x = main_buffer.Width - indicator_surface.Width / 2.0 - 2.0 * theme.get_bottom_offset () - indicator_surface.Width / 24.0;
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
		
		void hidden_changed ()
		{
			var now = new DateTime.now_utc ();
			var diff = now.difference (last_hide);
			
			if (diff < theme.HideTime * 1000)
				last_hide = now.add_seconds ((diff - theme.HideTime * 1000) / 1000000.0);
			else
				last_hide = new DateTime.now_utc ();
			
			controller.window.update_icon_regions ();
			
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
