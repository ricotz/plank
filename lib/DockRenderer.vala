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
using Gee;

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
		public DockController controller { private get; construct; }
		
		public DockTheme theme { get; private set; }
		
		/**
		 * The current progress [0.0..1.0] of the hide-animation of the dock.
		 */
		[CCode (notify = false)]
		public double hide_progress { get; private set; }
		
		/**
		 * The current opacity of the dock.
		 */
		[CCode (notify = false)]
		double opacity { get; private set; }

		DockSurface? background_buffer;
		Gdk.Rectangle background_rect;
		DockSurface? main_buffer;
		DockSurface? indicator_buffer;
		DockSurface? shadow_buffer;
		DockSurface? urgent_indicator_buffer;
		DockSurface? urgent_glow_buffer;
		
		DateTime last_hide = new DateTime.from_unix_utc (0);
		
		DateTime frame_time = new DateTime.from_unix_utc (0);
		
		bool screen_is_composited;
		uint reset_position_manager_timer = 0;
		
		/**
		 * Create a new dock renderer for a dock.
		 *
		 * @param controller the dock controller to manage drawing for
		 * @param window the dock window to be animated
		 */
		public DockRenderer (DockController controller, Gtk.Window window)
		{
			GLib.Object (controller : controller, widget : window);
		}
		
		construct
		{
			controller.prefs.notify.connect (prefs_changed);
			
			load_theme ();
		}
		
		/**
		 * Initializes the renderer.  Call after the DockWindow is constructed.
		 */
		public void initialize ()
			requires (controller.window != null)
		{
			unowned Screen screen = controller.window.get_screen ();
			screen_is_composited = screen.is_composited ();
			screen.composited_changed.connect (composited_changed);

			init_current_frame ();
			
			controller.position_manager.reset_caches (theme);
			controller.position_manager.update_regions ();
			
			controller.window.notify["HoveredItem"].connect (animated_draw);
			controller.hide_manager.notify["Hidden"].connect (hidden_changed);
		}
		
		~DockRenderer ()
		{
			controller.prefs.notify.disconnect (prefs_changed);
			theme.notify.disconnect (theme_changed);
			
			controller.window.get_screen ().composited_changed.disconnect (composited_changed);

			controller.hide_manager.notify["Hidden"].disconnect (hidden_changed);
			controller.window.notify["HoveredItem"].disconnect (animated_draw);
		}
		
		void composited_changed (Gdk.Screen screen)
		{
			screen_is_composited = screen.is_composited ();
			
			reset_position_manager ();
		}
		
		void prefs_changed (Object prefs, ParamSpec prop)
		{
			switch (prop.name) {
			case "Alignment":
			case "IconSize":
			case "ItemsAlignment":
			case "Offset":
				reset_position_manager ();
				break;
			case "Position":
				reset_buffers ();
				reset_item_buffers ();
				reset_position_manager ();
				break;
			case "Theme":
				load_theme ();
				break;
			default:
				// Nothing important for us changed
				break;
			}
		}
		
		void theme_changed ()
		{
			reset_buffers ();
			reset_item_buffers ();
			reset_position_manager ();
		}
		
		void reset_position_manager ()
		{
			// Don't perform an update immediately and summon further
			// update-requests, wait at least 50ms after the last request
			
			if (reset_position_manager_timer > 0)
				Source.remove (reset_position_manager_timer);
			
			reset_position_manager_timer = Gdk.threads_add_timeout (50, () => {
				reset_position_manager_timer = 0;
				controller.position_manager.reset_caches (theme);
				controller.position_manager.update_regions ();
				
				return false;
			});
		}
		
		void load_theme ()
		{
			var is_reload = (theme != null);
			
			if (is_reload)
				theme.notify.disconnect (theme_changed);
			
			theme = new DockTheme (controller.prefs.Theme);
			theme.load ("dock");
			theme.notify.connect (theme_changed);
			
			if (is_reload) {
				reset_position_manager ();
			}
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
			shadow_buffer = null;
			urgent_indicator_buffer = null;
			urgent_glow_buffer = null;
			
			animated_draw ();
		}
		
		/**
		 * Resets all internal item buffers and forces a redraw.
		 */
		void reset_item_buffers ()
		{
			Logger.verbose ("DockRenderer.reset_item_buffers ()");
			
			controller.reset_provider_buffers ();
			
			animated_draw ();
		}
		
		void init_current_frame ()
			requires (theme != null)
		{
			frame_time = new DateTime.now_utc ();
			
			var fade_opacity = theme.FadeOpacity;
			
			if (screen_is_composited) {
				var time = (fade_opacity == 1.0 ? theme.HideTime : theme.FadeTime);
				var diff = double.min (1, frame_time.difference (last_hide) / (double) (time * 1000));
				hide_progress = (controller.hide_manager.Hidden ? diff : 1.0 - diff);
			} else {
				hide_progress = 0.0;
			}
			
			if (fade_opacity < 1.0)
				opacity = double.min (1.0, double.max (0.0, 1.0 - (1.0 - fade_opacity) * hide_progress));
			else
				opacity = 1.0;
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
			// take the previous frame values into account to decide if we
			// can bail a full draw to not miss a finishing animation-frame
			var no_full_draw_needed = (hide_progress == 1.0 && opacity == 1.0);
			
			init_current_frame ();
			
			unowned PositionManager position_manager = controller.position_manager;
			unowned DockItem dragged_item = controller.drag_manager.DragItem;
			var width = position_manager.DockWidth;
			var height = position_manager.DockHeight;
			var items = controller.Items;
			
			if (main_buffer == null) {
				main_buffer = new DockSurface.with_surface (width, height, cr.get_target ());
			}
			
			if (shadow_buffer == null) {
				shadow_buffer = new DockSurface.with_surface (width, height, cr.get_target ());
			}
			
			// if the dock is completely hidden and not transparently drawn
			// only draw ugent-glow indicators and bail since there is no need
			// for further things
			if (no_full_draw_needed && hide_progress == 1.0 && opacity == 1.0) {
				// we still need to clear out the previous output
				cr.save ();
				cr.set_source_rgba (0, 0, 0, 0);
				cr.set_operator (Cairo.Operator.SOURCE);
				cr.paint ();
				cr.restore ();
				
				foreach (var item in items)
					draw_urgent_glow (item, cr);
				
				return;
			}

#if BENCHMARK
			benchmark.clear ();
			var start = new DateTime.now_local ();
#endif
			
			main_buffer.clear ();
			shadow_buffer.clear ();
			
#if BENCHMARK
			var start2 = new DateTime.now_local ();
#endif
			draw_dock_background ();
#if BENCHMARK
			var end2 = new DateTime.now_local ();
			benchmark.add ("background render time - %f ms".printf (end2.difference (start2) / 1000.0));
#endif
			
			
			// draw each item onto the dock buffer
			foreach (var item in items)
			{
#if BENCHMARK
				start2 = new DateTime.now_local ();
#endif
				// Do not draw the currently dragged item
				if (dragged_item != item)
					draw_item (item);
#if BENCHMARK
				end2 = new DateTime.now_local ();
				benchmark.add ("item render time - %f ms".printf (end2.difference (start2) / 1000.0));
#endif
			}
			
			// calculate drawing offset
			var x_offset = 0, y_offset = 0;
			if (opacity == 1.0)
				position_manager.get_dock_draw_position (out x_offset, out y_offset);
			
			// composite dock layers and make sure to draw onto the window's context with one operation
			unowned Cairo.Context composite_cr = shadow_buffer.Context;
			composite_cr.set_operator (Operator.OVER);
			composite_cr.set_source_surface (main_buffer.Internal, 0, 0);
			composite_cr.paint ();
			
			// fade the dock if need be
			if (opacity < 1.0) {
				composite_cr.set_operator (Operator.SOURCE);
				composite_cr.set_source_rgba (0, 0, 0, 0);
				composite_cr.paint_with_alpha (1 - opacity);
			}
			
			// draw the dock on the window
			cr.set_operator (Operator.SOURCE);
			cr.set_source_surface (shadow_buffer.Internal, x_offset, y_offset);
			cr.paint ();
			
			// draw urgent-glow if dock is completely hidden
			if (hide_progress == 1.0) {
				foreach (var item in items)
					draw_urgent_glow (item, cr);
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
			background_rect = controller.position_manager.get_background_region ();
			
			if (background_buffer == null || background_buffer.Width != background_rect.width
				|| background_buffer.Height != background_rect.height)
				background_buffer = theme.create_background (background_rect.width, background_rect.height,
					controller.prefs.Position, main_buffer);
			
			unowned Context cr = main_buffer.Context;
			cr.set_source_surface (background_buffer.Internal, background_rect.x, background_rect.y);
			cr.paint ();
		}
		
		void draw_item (DockItem item)
		{
			unowned PositionManager position_manager = controller.position_manager;
			unowned DockItem hovered_item = controller.window.HoveredItem;
			unowned DragManager drag_manager = controller.drag_manager;
			
			unowned Context main_cr = main_buffer.Context;
			unowned Context shadow_cr = shadow_buffer.Context;
			var icon_size = position_manager.IconSize;
			var shadow_size = controller.position_manager.IconShadowSize;
			
			// load the icon
#if BENCHMARK
			var start = new DateTime.now_local ();
#endif
			var icon_surface = item.get_surface_copy (icon_size, icon_size, main_buffer);
			unowned Context icon_cr = icon_surface.Context;
			
			DockSurface? icon_shadow_surface = null;
			if (shadow_size > 0)
				icon_shadow_surface = item.get_background_surface (draw_item_shadow);
			
			DockSurface? icon_overlay_surface = null;
			if (item.CountVisible || item.ProgressVisible)
				icon_overlay_surface = item.get_foreground_surface (draw_item_overlay);
			
			if (icon_overlay_surface != null) {
				icon_cr.set_source_surface (icon_overlay_surface.Internal, 0, 0);
				icon_cr.paint ();
			}
			
#if BENCHMARK
			var end = new DateTime.now_local ();
			benchmark.add ("	item.get_surface time - %f ms".printf (end.difference (start) / 1000.0));
#endif
			
			// get item's draw-value
			var draw_value = position_manager.get_draw_value_for_item (item);
			
			// lighten or darken the icon
			var lighten = 0.0, darken = 0.0;
			
			var max_click_time = item.ClickedAnimation == ClickAnimation.BOUNCE ? theme.LaunchBounceTime : theme.ClickTime;
			max_click_time *= 1000;
			var click_time = frame_time.difference (item.LastClicked);
			if (click_time < max_click_time) {
				var click_animation_progress = click_time / (double) max_click_time;
				
				switch (item.ClickedAnimation) {
				default:
				case ClickAnimation.NONE:
					break;
				case ClickAnimation.BOUNCE:
					if (!screen_is_composited)
						break;
					var change = Math.fabs (Math.sin (2 * Math.PI * click_animation_progress) * icon_size * theme.LaunchBounceHeight * double.min (1.0, 1.3333 * (1.0 - click_animation_progress)));
					draw_value = draw_value.move_in (controller.prefs.Position, change);
					break;
				case ClickAnimation.DARKEN:
					darken = double.max (0, Math.sin (Math.PI * click_animation_progress)) * 0.5;
					break;
				case ClickAnimation.LIGHTEN:
					lighten = double.max (0, Math.sin (Math.PI * click_animation_progress)) * 0.5;
					break;
				}
			}
			
			if (hovered_item == item)
				lighten = 0.2;
			
			if (hovered_item == item && controller.window.menu_is_visible ())
				darken += 0.4;
			else if (drag_manager.ExternalDragActive
				&& !drag_manager.DragIsDesktopFile
				&& !drag_manager.drop_is_accepted_by (item))
				darken += 0.6;
			
			// glow the icon
			if (lighten > 0) {
				icon_cr.set_operator (Cairo.Operator.ADD);
				icon_cr.paint_with_alpha (lighten);
				icon_cr.set_operator (Cairo.Operator.OVER);
			}
			
			// darken the icon
			if (darken > 0) {
				icon_cr.rectangle (0, 0, icon_surface.Width, icon_surface.Height);
				icon_cr.set_source_rgba (0, 0, 0, darken);
				
				icon_cr.set_operator (Cairo.Operator.ATOP);
				icon_cr.fill ();
				icon_cr.set_operator (Cairo.Operator.OVER);
			}
			
			// bounce icon on urgent state
			if (screen_is_composited && (item.State & ItemState.URGENT) != 0) {
				var urgent_time = frame_time.difference (item.LastUrgent);
				var bounce_animation_progress = urgent_time / (double) (theme.UrgentBounceTime * 1000);
				if (bounce_animation_progress < 1.0) {
					var change = Math.fabs (Math.sin (Math.PI * bounce_animation_progress) * icon_size * theme.UrgentBounceHeight * double.min (1.0, 2.0 * (1.0 - bounce_animation_progress)));
					draw_value = draw_value.move_in (controller.prefs.Position, change);
				}
			}
			
			// animate icon movement on move state
			if ((item.State & ItemState.MOVE) != 0) {
				var move_time = frame_time.difference (item.LastMove);
				var move_animation_progress = move_time / (double) (theme.ItemMoveTime * 1000);
				if (move_animation_progress < 1.0) {
					var change = (1.0 - move_animation_progress) * (icon_size + position_manager.ItemPadding);
					draw_value = draw_value.move_right (controller.prefs.Position, (item.Position < item.LastPosition ? change : -change));
				} else {
					item.unset_move_state ();
				}
			}

			// draw active glow
			var active_time = frame_time.difference (item.LastActive);
			var opacity = double.min (1, active_time / (double) (theme.ActiveTime * 1000));
			if ((item.State & ItemState.ACTIVE) == 0)
				opacity = 1 - opacity;
			if (opacity > 0) {
				theme.draw_active_glow (main_buffer, background_rect, draw_value.background_region, item.AverageIconColor, opacity, controller.prefs.Position);
			}
			
			// draw the icon shadow
			if (icon_shadow_surface != null) {
				shadow_cr.set_operator (Cairo.Operator.OVER);
				shadow_cr.set_source_surface (icon_shadow_surface.Internal, draw_value.draw_region.x - shadow_size, draw_value.draw_region.y - shadow_size);
				shadow_cr.paint ();
			}

			// draw the icon
			main_cr.set_source_surface (icon_surface.Internal, draw_value.draw_region.x, draw_value.draw_region.y);
			main_cr.paint ();
			
			// draw indicators
			if (item.Indicator != IndicatorState.NONE)
				draw_indicator_state (draw_value.hover_region, item.Indicator, item.State);
		}
		
		DockSurface draw_item_overlay (DockItem item, DockSurface icon_surface, DockSurface? current_surface)
		{
			unowned PositionManager position_manager = controller.position_manager;
			var width = icon_surface.Width;
			var height = icon_surface.Height;
			
			if (current_surface != null
				&& width == current_surface.Width && height == current_surface.Height)
				return current_surface;
			
			Logger.verbose ("DockItem.draw_item_overlay (width = %i, height = %i)", width, height);
			var surface = new DockSurface.with_dock_surface (width, height, icon_surface);
			
			var icon_size = position_manager.IconSize;
			var urgent_color = get_styled_color ();
			urgent_color.add_hue (theme.UrgentHueShift);
			
			// draw item's count
			if (item.CountVisible)
				theme.draw_item_count (surface, icon_size, urgent_color, item.Count);
			
			// draw item's progress
			if (item.ProgressVisible)
				theme.draw_item_progress (surface, icon_size, urgent_color, item.Progress);
			
			return surface;
		}
		
		DockSurface draw_item_shadow (DockItem item, DockSurface icon_surface, DockSurface? current_surface)
		{
			var shadow_size = controller.position_manager.IconShadowSize;
			
			// Inflate size to fit shadow
			var width = icon_surface.Width + 2 * shadow_size;
			var height = icon_surface.Height + 2 * shadow_size;
			
			if (current_surface != null
				&& width == current_surface.Width && height == current_surface.Height)
				return current_surface;
			
			Logger.verbose ("DockItem.draw_icon_with_shadow (width = %i, height = %i, shadow_size = %i)", width, height, shadow_size);
			var surface = new DockSurface.with_dock_surface (width, height, icon_surface);
			unowned Cairo.Context cr = surface.Context;
			var shadow_surface = icon_surface.create_mask (0.4, null);
			
			var xoffset = 0, yoffset = 0;
			switch (controller.prefs.Position) {
			default:
			case PositionType.BOTTOM:
				yoffset = -shadow_size / 4;
				break;
			case PositionType.TOP:
				yoffset = shadow_size / 4;
				break;
			case PositionType.LEFT:
				xoffset = shadow_size / 4;
				break;
			case PositionType.RIGHT:
				xoffset = -shadow_size / 4;
				break;
			}
			
			cr.set_source_surface (shadow_surface.Internal, shadow_size + xoffset, shadow_size + yoffset);
			cr.paint_with_alpha (0.44);
			surface.gaussian_blur (shadow_size);
			
			return surface;
		}
		
		void draw_indicator_state (Gdk.Rectangle item_rect, IndicatorState indicator, ItemState item_state)
		{
			if (indicator_buffer == null) {
				var indicator_color = get_styled_color ();
				indicator_color.set_min_sat (0.4);
				indicator_buffer = theme.create_indicator (controller.position_manager.IndicatorSize, indicator_color, background_buffer);
			}
			if (urgent_indicator_buffer == null) {
				var urgent_indicator_color = get_styled_color ();
				urgent_indicator_color.add_hue (theme.UrgentHueShift);
				urgent_indicator_color.set_sat (1.0);
				urgent_indicator_buffer = theme.create_indicator (controller.position_manager.IndicatorSize, urgent_indicator_color, background_buffer);
			}
			
			unowned DockSurface indicator_surface = (item_state & ItemState.URGENT) != 0 ? urgent_indicator_buffer : indicator_buffer;
			unowned Context main_cr = main_buffer.Context;
			
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
					x_offset = controller.position_manager.IconSize / 16.0;
				else
					y_offset = controller.position_manager.IconSize / 16.0;
				
				main_cr.set_source_surface (indicator_surface.Internal, x - x_offset, y - y_offset);
				main_cr.paint ();
				main_cr.set_source_surface (indicator_surface.Internal, x + x_offset, y + y_offset);
				main_cr.paint ();
			}
		}
		
		void draw_urgent_glow (DockItem item, Context cr)
		{
			if ((item.State & ItemState.URGENT) == 0)
				return;
			
			var diff = frame_time.difference (item.LastUrgent);
			if (diff >= theme.GlowTime * 1000)
				return;
			
			unowned PositionManager position_manager = controller.position_manager;
			var x_offset = 0, y_offset = 0;
			
			if (urgent_glow_buffer == null) {
				var urgent_color = get_styled_color ();
				urgent_color.add_hue (theme.UrgentHueShift);
				urgent_color.set_sat (1.0);
				urgent_glow_buffer = theme.create_urgent_glow (position_manager.GlowSize, urgent_color, main_buffer);
			}
			
			position_manager.get_urgent_glow_position (item, out x_offset, out y_offset);
			
			cr.set_source_surface (urgent_glow_buffer.Internal, x_offset, y_offset);
			var opacity = 0.2 + (0.75 * (Math.sin (diff / (double) (theme.GlowPulseTime * 1000) * 2 * Math.PI) + 1) / 2);
			cr.paint_with_alpha (opacity);
		}
		
		Drawing.Color get_styled_color ()
		{
			var background_selected_color = controller.window.get_style_context ().get_background_color (StateFlags.SELECTED);
			var selected_color = Drawing.Color.from_gdk_rgba (background_selected_color);
			selected_color.set_min_value (90 / (double) uint16.MAX);
			return selected_color;
		}
		
		void hidden_changed ()
		{
			var now = new DateTime.now_utc ();
			var diff = now.difference (last_hide);
			var time = (theme.FadeOpacity == 1.0 ? theme.HideTime : theme.FadeTime) * 1000;
			
			if (diff < time)
				last_hide = now.add_seconds ((diff - time) / 1000000.0);
			else
				last_hide = now;
			
			if (!screen_is_composited) {
				controller.window.update_size_and_position ();
				return;
			}
			
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
			
			foreach (var item in controller.Items) {
				if (render_time.difference (item.LastClicked) <= (item.ClickedAnimation == ClickAnimation.BOUNCE ? theme.LaunchBounceTime : theme.ClickTime) * 1000)
					return true;
				if (render_time.difference (item.LastActive) <= theme.ActiveTime * 1000)
					return true;
				if (render_time.difference (item.LastUrgent) <= (hide_progress == 1.0 ? theme.GlowTime : theme.UrgentBounceTime) * 1000)
					return true;
				if (render_time.difference (item.LastMove) <= theme.ItemMoveTime * 1000)
					return true;
			}
				
			return false;
		}
	}
}
