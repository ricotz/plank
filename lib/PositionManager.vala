//
//  Copyright (C) 2012 Robert Dyer, Rico Tzschichholz
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

using Plank.Items;
using Plank.Drawing;
using Plank.Services;
using Plank.Services.Windows;

namespace Plank
{
	/**
	 * Handles computing any size/position information for the dock.
	 */
	public class PositionManager : GLib.Object
	{
		public struct DockItemDrawValue
		{
			public Gdk.Rectangle hover_region;
			public Gdk.Rectangle draw_region;
			public Gdk.Rectangle background_region;
			
			public void move_in (Gtk.PositionType position, double damount)
			{
				var amount = (int) damount;
				
				switch (position) {
				default:
				case Gtk.PositionType.BOTTOM:
					hover_region.y -= amount;
					draw_region.y -= amount;
					break;
				case Gtk.PositionType.TOP:
					hover_region.y += amount;
					draw_region.y += amount;
					break;
				case Gtk.PositionType.LEFT:
					hover_region.x += amount;
					draw_region.x += amount;
					break;
				case Gtk.PositionType.RIGHT:
					hover_region.x -= amount;
					draw_region.x -= amount;
					break;
				}
			}
			
			public void move_right (Gtk.PositionType position, double damount)
			{
				var amount = (int) damount;
				
				switch (position) {
				default:
				case Gtk.PositionType.BOTTOM:
					hover_region.x += amount;
					draw_region.x += amount;
					background_region.x += amount;
					break;
				case Gtk.PositionType.TOP:
					hover_region.x += amount;
					draw_region.x += amount;
					background_region.x += amount;
					break;
				case Gtk.PositionType.LEFT:
					hover_region.y += amount;
					draw_region.y += amount;
					background_region.y += amount;
					break;
				case Gtk.PositionType.RIGHT:
					hover_region.y += amount;
					draw_region.y += amount;
					background_region.y += amount;
					break;
				}
			}
		}
		
		public DockController controller { private get; construct; }
		
		public bool screen_is_composited { get; private set; }
		
		Gdk.Rectangle static_dock_region;
		Gee.HashMap<DockElement, DockItemDrawValue?> draw_values;
		
		Gdk.Rectangle monitor_geo;
		
		int window_scale_factor = 1;
		
		/**
		 * Creates a new position manager.
		 *
		 * @param controller the dock controller to manage positions for
		 */
		public PositionManager (DockController controller)
		{
			GLib.Object (controller : controller);
		}
		
		construct
		{
			static_dock_region = Gdk.Rectangle ();
			draw_values = new Gee.HashMap<DockElement, DockItemDrawValue?> ();			
			
			controller.prefs.notify["Monitor"].connect (update_monitor_geo);
		}
		
		/**
		 * Initializes the position manager.
		 */
		public void initialize ()
			requires (controller.window != null)
		{
			unowned Gdk.Screen screen = controller.window.get_screen ();
			
			screen.monitors_changed.connect (update_monitor_geo);
			screen.size_changed.connect (update_monitor_geo);
			screen.composited_changed.connect (composited_changed);
			
			// NOTE don't call update_monitor_geo to avoid a double-call of dockwindow.set_size on startup
			screen.get_monitor_geometry (controller.prefs.get_monitor (), out monitor_geo);
			
			screen_is_composited = screen.is_composited ();
		}
		
		~PositionManager ()
		{
			unowned Gdk.Screen screen = controller.window.get_screen ();
			
			screen.monitors_changed.disconnect (update_monitor_geo);
			screen.size_changed.disconnect (update_monitor_geo);
			screen.composited_changed.disconnect (composited_changed);
			controller.prefs.notify["Monitor"].disconnect (update_monitor_geo);
			
			draw_values.clear ();
		}
		
		void update_monitor_geo ()
		{
			freeze_notify ();
			
			controller.window.get_screen ().get_monitor_geometry (controller.prefs.get_monitor (), out monitor_geo);
			update_dimensions ();
			update_dock_position ();
			update_regions ();
			
			thaw_notify ();
		}
		
		void composited_changed (Gdk.Screen screen)
		{
			freeze_notify ();
			
			screen_is_composited = screen.is_composited ();
			
			update (controller.renderer.theme);
			update_regions ();
 			
			thaw_notify ();
		}
 		
		//
		// used to cache various sizes calculated from the theme and preferences
		//
		
		/**
		 * Theme-based line-width.
		 */
		public int LineWidth { get; private set; }
		
		/**
		 * Cached current icon size for the dock.
		 */
		public int IconSize { get; private set; }
			
		/**
		 * Cached position of the dock.
		 */
		public Gtk.PositionType Position { get; private set; }
		
		/**
		 * Theme-based indicator size, scaled by icon size.
		 */
		public int IndicatorSize { get; private set; }
		/**
		 * Theme-based icon-shadow size, scaled by icon size.
		 */
		public int IconShadowSize { get; private set; }
		/**
		 * Theme-based urgent glow size, scaled by icon size.
		 */
		public int GlowSize { get; private set; }
		/**
		 * Theme-based horizontal padding, scaled by icon size.
		 */
		public int HorizPadding  { get; private set; }
		/**
		 * Theme-based top padding, scaled by icon size.
		 */
		public int TopPadding    { get; private set; }
		/**
		 * Theme-based bottom padding, scaled by icon size.
		 */
		public int BottomPadding { get; private set; }
		/**
		 * Theme-based item padding, scaled by icon size.
		 */
		public int ItemPadding   { get; private set; }
		/**
		 * Theme-based urgent-bounce height, scaled by icon size.
		 */
		public int UrgentBounceHeight { get; private set; }
		/**
		 * Theme-based launch-bounce height, scaled by icon size.
		 */
		public int LaunchBounceHeight { get; private set; }
		
		int items_width;
		int items_offset;
		int top_offset;
		int bottom_offset;
		int extra_hide_offset;
		
		/**
		 * x position of the dock window.
		 */
		int win_x;
		/**
		 * y position of the dock window.
		 */
		int win_y;

		/**
		 * The currently visible height of the dock.
		 */
		int VisibleDockHeight;
		/**
		 * The static height of the dock.
		 */
		int DockHeight;
		/**
		 * The height of the dock's background image.
		 */
		int DockBackgroundHeight;
		
		/**
		 * The currently visible width of the dock.
		 */
		int VisibleDockWidth;
		/**
		 * The static width of the dock.
		 */
		int DockWidth;
		/**
		 * The width of the dock's background image.
		 */
		int DockBackgroundWidth;
		
		/**
		 * The maximum item count which fit the dock in its maximum
		 * size with the current theme and icon-size.
		 */
		public int MaxItemCount { get; private set; }
		
		/**
		 * The maximum icon-size which results in a dock which fits on
		 * the target screen edge.
		 */
		int MaxIconSize { get; private set; default = DockPreferences.MAX_ICON_SIZE; }
		
		/**
		 * Updates all internal caches.
		 *
		 * @param theme the current dock theme
		 */
		public void update (DockTheme theme)
		{
			Logger.verbose ("PositionManager.update ()");
			
			screen_is_composited = controller.window.get_screen ().is_composited ();
			
			freeze_notify ();
			
			update_caches (theme);
			update_max_icon_size (theme);
			update_dimensions ();
			update_dock_position ();
			update_regions ();
			
			thaw_notify ();
		}
		
		/**
		 * Resets all internal caches for the given item.
		 *
		 * @param item the dock item
		 */
		public void reset_item_cache (DockElement item)
		{
			draw_values.unset (item);
		}
		
		/**
		 * Resets all internal item caches.
		 */
		public void reset_item_caches ()
		{
			draw_values.clear ();
		}
		
		void update_caches (DockTheme theme)
		{
			unowned DockPreferences prefs = controller.prefs;
			
			Position = prefs.Position;
			IconSize = int.min (MaxIconSize, prefs.IconSize);
			
			var scaled_icon_size = IconSize / 10.0;
			
			IconShadowSize = (int) Math.ceil (theme.IconShadowSize * scaled_icon_size);
			IndicatorSize = (int) (theme.IndicatorSize * scaled_icon_size);
			GlowSize      = (int) (theme.GlowSize      * scaled_icon_size);
			HorizPadding  = (int) (theme.HorizPadding  * scaled_icon_size);
			TopPadding    = (int) (theme.TopPadding    * scaled_icon_size);
			BottomPadding = (int) (theme.BottomPadding * scaled_icon_size);
			ItemPadding   = (int) (theme.ItemPadding   * scaled_icon_size);
			UrgentBounceHeight = (int) (theme.UrgentBounceHeight * IconSize);
			LaunchBounceHeight = (int) (theme.LaunchBounceHeight * IconSize);
			LineWidth     = theme.LineWidth;
			
			if (!screen_is_composited) {
				if (HorizPadding < 0)
					HorizPadding = (int) scaled_icon_size;
				if (TopPadding < 0)
					TopPadding = (int) scaled_icon_size;
			}
			
			items_offset  = (int) (2 * LineWidth + (HorizPadding > 0 ? HorizPadding : 0));
			
			top_offset = theme.get_top_offset () + TopPadding;
			bottom_offset = theme.get_bottom_offset () + BottomPadding;
			
			if (top_offset < 0)
				extra_hide_offset = IconShadowSize;
			else if (top_offset < IconShadowSize)
				extra_hide_offset = (IconShadowSize - top_offset);
			else
				extra_hide_offset = 0;
			
			draw_values.clear ();
		}
		
		/**
		 * Find an appropriate MaxIconSize
		 */
		void update_max_icon_size (DockTheme theme)
		{
			unowned DockPreferences prefs = controller.prefs;
			
			// Check if the dock is oversized and doesn't fit the targeted screen-edge
			var item_count = controller.Items.size;
			var width = item_count * (ItemPadding + IconSize) + 2 * HorizPadding + 4 * LineWidth;
			var max_width = (is_horizontal_dock () ? monitor_geo.width : monitor_geo.height);
			var step_size = int.max (1, (int) (Math.fabs (width - max_width) / item_count));
			
			if (width > max_width && MaxIconSize > DockPreferences.MIN_ICON_SIZE) {
				MaxIconSize -= step_size;
			} else if (width < max_width && MaxIconSize < prefs.IconSize && step_size > 1) {
				MaxIconSize += step_size;
			} else {
				// Make sure the MaxIconSize is even and restricted properly
				MaxIconSize = int.max (DockPreferences.MIN_ICON_SIZE,
					int.min (DockPreferences.MAX_ICON_SIZE, (int) (MaxIconSize / 2.0) * 2));
				Logger.verbose ("PositionManager.MaxIconSize = %i", MaxIconSize);
				update_caches (theme);
				return;
			}
			
			update_caches (theme);
			update_max_icon_size (theme);
		}
		
		void update_dimensions ()
		{
			unowned DockPreferences prefs = controller.prefs;
			
			Logger.verbose ("PositionManager.update_dimensions ()");
			
			// height of the visible (cursor) rect of the dock
			var height = IconSize + top_offset + bottom_offset;
			
			// height of the dock background image, as drawn
			var background_height = int.max (0, height);
			
			if (top_offset < 0)
				height -= top_offset;
			
			// height of the dock window
			var dock_height = height + (screen_is_composited ? UrgentBounceHeight : 0);
			
			var width = 0;
			switch (prefs.Alignment) {
			default:
			case Gtk.Align.START:
			case Gtk.Align.END:
			case Gtk.Align.CENTER:
				width = controller.Items.size * (ItemPadding + IconSize) + 2 * HorizPadding + 4 * LineWidth;
				break;
			case Gtk.Align.FILL:
				if (is_horizontal_dock ())
					width = monitor_geo.width;
				else
					width = monitor_geo.height;
				break;
			}
			
			// width of the dock background image, as drawn
			var background_width = int.max (0, width);
			
			// width of the visible (cursor) rect of the dock
			if (HorizPadding < 0)
				width -= 2 * HorizPadding;
			
			if (is_horizontal_dock ()) {
				width = int.min (monitor_geo.width, width);
				VisibleDockHeight = height;
				VisibleDockWidth = width;
				DockHeight = dock_height;
				DockWidth = (screen_is_composited ? monitor_geo.width : width);
				DockBackgroundHeight = background_height;
				DockBackgroundWidth = background_width;
				MaxItemCount = (int) Math.floor ((double) (monitor_geo.width - 2 * HorizPadding + 4 * LineWidth) / (ItemPadding + IconSize));
			} else {
				width = int.min (monitor_geo.height, width);
				VisibleDockHeight = width;
				VisibleDockWidth = height;
				DockHeight = (screen_is_composited ? monitor_geo.height : width);
				DockWidth = dock_height;
				DockBackgroundHeight = background_width;
				DockBackgroundWidth = background_height;
				MaxItemCount = (int) Math.floor ((double) (monitor_geo.height - 2 * HorizPadding + 4 * LineWidth) / (ItemPadding + IconSize));
			}
		}
		
		/**
		 * Return whether or not a dock is a horizontal dock.
		 *
		 * @return true if the dock's position indicates it is horizontal
		 */
		public bool is_horizontal_dock ()
		{
			return (Position == Gtk.PositionType.TOP || Position == Gtk.PositionType.BOTTOM);
		}
		
		/**
		 * Returns the cursor region for the dock.
		 * This is the region that the cursor can interact with the dock.
		 *
		 * @return the cursor region for the dock
		 */
		public Gdk.Rectangle get_cursor_region ()
		{
			var cursor_region = static_dock_region;
			var progress = 1.0 - controller.renderer.hide_progress;
#if HAVE_HIDPI
			window_scale_factor = controller.window.get_window ().get_scale_factor ();
#endif
			
			switch (Position) {
			default:
			case Gtk.PositionType.BOTTOM:
				cursor_region.height = int.max (1 * window_scale_factor, (int) (progress * cursor_region.height));
				cursor_region.y = DockHeight - cursor_region.height + (window_scale_factor - 1);
				break;
			case Gtk.PositionType.TOP:
				cursor_region.height = int.max (1 * window_scale_factor, (int) (progress * cursor_region.height));
				cursor_region.y = 0;
				break;
			case Gtk.PositionType.LEFT:
				cursor_region.width = int.max (1 * window_scale_factor, (int) (progress * cursor_region.width));
				cursor_region.x = 0;
				break;
			case Gtk.PositionType.RIGHT:
				cursor_region.width = int.max (1 * window_scale_factor, (int) (progress * cursor_region.width));
				cursor_region.x = DockWidth - cursor_region.width + (window_scale_factor - 1);
				break;
			}
			
			return cursor_region;
		}
		
		/**
		 * Returns the static dock region for the dock.
		 * This is the region that the dock occupies when not hidden.
		 *
		 * @return the static dock region for the dock
		 */
		public Gdk.Rectangle get_static_dock_region ()
		{
			var dock_region = static_dock_region;
			dock_region.x += win_x;
			dock_region.y += win_y;
			
			// Revert adjustments made by update_dock_position () for non-compositing mode
			if (!screen_is_composited && controller.hide_manager.Hidden) {
				switch (Position) {
				default:
				case Gtk.PositionType.BOTTOM:
					dock_region.y -= DockHeight - 1;
					break;
				case Gtk.PositionType.TOP:
					dock_region.y += DockHeight - 1;
					break;
				case Gtk.PositionType.LEFT:
					dock_region.x += DockWidth - 1;
					break;
				case Gtk.PositionType.RIGHT:
					dock_region.x -= DockWidth - 1;
					break;
				}
			}
			
			return dock_region;
		}
		
		/**
		 * Call when any cached region needs updating.
		 */
		public void update_regions ()
		{
			unowned DockPreferences prefs = controller.prefs;
			
			Logger.verbose ("PositionManager.update_regions ()");
			
			var old_region = static_dock_region;
			
			// width of the items-area of the dock
			items_width = controller.Items.size * (ItemPadding + IconSize);
			
			static_dock_region.width = VisibleDockWidth;
			static_dock_region.height = VisibleDockHeight;
			
			var xoffset = (DockWidth - static_dock_region.width) / 2;
			var yoffset = (DockHeight - static_dock_region.height) / 2;
			
			if (screen_is_composited) {
				var offset = prefs.Offset;
				xoffset = (int) ((1 + offset / 100.0) * xoffset);
				yoffset = (int) ((1 + offset / 100.0) * yoffset);
				
				switch (prefs.Alignment) {
				default:
				case Gtk.Align.CENTER:
				case Gtk.Align.FILL:
					break;
				case Gtk.Align.START:
					xoffset = 0;
					yoffset = (monitor_geo.height - static_dock_region.height);
					break;
				case Gtk.Align.END:
					xoffset = (monitor_geo.width - static_dock_region.width);
					yoffset = 0;
					break;
				}
			}
			
			switch (Position) {
			default:
			case Gtk.PositionType.BOTTOM:
				static_dock_region.x = xoffset;
				static_dock_region.y = DockHeight - static_dock_region.height;
				break;
			case Gtk.PositionType.TOP:
				static_dock_region.x = xoffset;
				static_dock_region.y = 0;
				break;
			case Gtk.PositionType.LEFT:
				static_dock_region.y = yoffset;
				static_dock_region.x = 0;
				break;
			case Gtk.PositionType.RIGHT:
				static_dock_region.y = yoffset;
				static_dock_region.x = DockWidth - static_dock_region.width;
				break;
			}
			
			// FIXME Maybe no need to purge all cached values?
			draw_values.clear ();
			
			if (old_region.x != static_dock_region.x
				|| old_region.y != static_dock_region.y
				|| old_region.width != static_dock_region.width
				|| old_region.height != static_dock_region.height) {
				controller.window.update_size_and_position ();
#if HAVE_BARRIERS
				controller.hide_manager.update_barrier ();
#endif
				
				// With active compositing support update_size_and_position () won't trigger a redraw
				// (a changed static_dock_region doesn't implicate the window-size changed)
				if (screen_is_composited)
					controller.renderer.animated_draw ();
			} else {
				controller.renderer.animated_draw ();
			}
		}
		
		/**
		 * The draw-value for a dock item.
		 *
		 * @param item the dock item to find the drawvalue for
		 * @return the region for the dock item
		 */
		public DockItemDrawValue get_draw_value_for_item (DockItem item)
		{
			DockItemDrawValue? draw_value;
			
			if ((draw_value = draw_values.get (item)) == null) {
				var hover_rect = internal_get_item_hover_region (item);
				var draw_rect = get_item_draw_region (hover_rect);
				var background_rect = get_item_background_region (hover_rect);
			
				draw_value = { hover_rect, draw_rect, background_rect };
				draw_values.set (item, draw_value);
			}
			
			return draw_value;
		}
		
		/**
		 * The region for drawing a dock item.
		 *
		 * @param hover_rect the item's hover region
		 * @return the region for the dock item
		 */
		Gdk.Rectangle get_item_draw_region (Gdk.Rectangle hover_rect)
		{
			var item_padding = ItemPadding;
			var top_padding = (top_offset < 0 ? 0 : top_offset);
			var bottom_padding = bottom_offset;
			
			switch (Position) {
			default:
			case Gtk.PositionType.BOTTOM:
				hover_rect.x += item_padding / 2;
				hover_rect.y += top_padding;
				hover_rect.width -= item_padding;
				hover_rect.height -= bottom_padding + top_padding;
				break;
			case Gtk.PositionType.TOP:
				hover_rect.x += item_padding / 2;
				hover_rect.y += bottom_padding;
				hover_rect.width -= item_padding;
				hover_rect.height -= bottom_padding + top_padding;
				break;
			case Gtk.PositionType.LEFT:
				hover_rect.x += bottom_padding;
				hover_rect.y += item_padding / 2;
				hover_rect.width -= bottom_padding + top_padding;
				hover_rect.height -= item_padding;
				break;
			case Gtk.PositionType.RIGHT:
				hover_rect.x += top_padding;
				hover_rect.y += item_padding / 2;
				hover_rect.width -= bottom_padding + top_padding;
				hover_rect.height -= item_padding;
				break;
			}
			
			return hover_rect;
		}
		
		/**
		 * The intersecting region of a dock item's hover region and the background.
		 *
		 * @param rect the item's hover region
		 * @return the region for the dock item
		 */
		Gdk.Rectangle get_item_background_region (Gdk.Rectangle rect)
		{
			var top_padding = (top_offset > 0 ? 0 : top_offset);
			
			switch (Position) {
			default:
			case Gtk.PositionType.BOTTOM:
				rect.y -= top_padding;
				rect.height += top_padding;
				break;
			case Gtk.PositionType.TOP:
				rect.height += top_padding;
				break;
			case Gtk.PositionType.LEFT:
				rect.width += top_padding;
				break;
			case Gtk.PositionType.RIGHT:
				rect.x -= top_padding;
				rect.width += top_padding;
				break;
			}
			
			return rect;
		}
		
		/**
		 * The cursor region for interacting with a dock element.
		 *
		 * @param element the dock element to find a region for
		 * @return the region for the dock item
		 */
		public Gdk.Rectangle get_item_hover_region (DockElement element)
		{
			unowned DockItem? item = (element as DockItem);
			if (item != null)
				return get_draw_value_for_item (item).hover_region;
			
			unowned DockContainer? container = (element as DockContainer);
			return_val_if_fail (container != null, Gdk.Rectangle ());
			
			unowned Gee.ArrayList<DockElement> items = container.Elements;
			
			if (items.size == 0)
				return { 0 };
			
			var first_rect = get_item_hover_region (items.first ());
			if (items.size == 1)
				return first_rect;
			
			var last_rect = get_item_hover_region (items.last ());
			
			return { first_rect.x, first_rect.y, last_rect.x + last_rect.width, last_rect.y + last_rect.height };
		}
			
		Gdk.Rectangle internal_get_item_hover_region (DockItem item)
		{
			unowned DockPreferences prefs = controller.prefs;
			
			var rect = Gdk.Rectangle ();
			
			switch (Position) {
			default:
			case Gtk.PositionType.BOTTOM:
				rect.width = IconSize + ItemPadding;
				rect.height = VisibleDockHeight;
				rect.x = static_dock_region.x + items_offset + item.Position * (ItemPadding + IconSize);
				rect.y = DockHeight - rect.height;
				break;
			case Gtk.PositionType.TOP:
				rect.width = IconSize + ItemPadding;
				rect.height = VisibleDockHeight;
				rect.x = static_dock_region.x + items_offset + item.Position * (ItemPadding + IconSize);
				rect.y = 0;
				break;
			case Gtk.PositionType.LEFT:
				rect.height = IconSize + ItemPadding;
				rect.width = VisibleDockWidth;
				rect.y = static_dock_region.y + items_offset + item.Position * (ItemPadding + IconSize);
				rect.x = 0;
				break;
			case Gtk.PositionType.RIGHT:
				rect.height = IconSize + ItemPadding;
				rect.width = VisibleDockWidth;
				rect.y = static_dock_region.y + items_offset + item.Position * (ItemPadding + IconSize);
				rect.x = DockWidth - rect.width;
				break;
			}
			
			if (prefs.Alignment != Gtk.Align.FILL)
				return rect;
			
			switch (prefs.ItemsAlignment) {
			default:
			case Gtk.Align.FILL:
			case Gtk.Align.CENTER:
				if (is_horizontal_dock ())
					rect.x += (static_dock_region.width - 2 * items_offset - items_width) / 2;
				else
					rect.y += (static_dock_region.height - 2 * items_offset - items_width) / 2;
				break;
			case Gtk.Align.START:
				break;
			case Gtk.Align.END:
				if (is_horizontal_dock ())
					rect.x += (static_dock_region.width - 2 * items_offset - items_width);
				else
					rect.y += (static_dock_region.height - 2 * items_offset - items_width);
				break;
			}
			
			return rect;
		}
		
		/**
		 * Get's the x and y position to display a menu for a dock item.
		 *
		 * @param hovered the item that is hovered
		 * @param requisition the menu's requisition
		 * @param x the resulting x position
		 * @param y the resulting y position
		 */
		public void get_menu_position (DockItem hovered, Gtk.Requisition requisition, out int x, out int y)
		{
			var rect = get_item_hover_region (hovered);
			
			var offset = 10;
			switch (Position) {
			default:
			case Gtk.PositionType.BOTTOM:
				x = win_x + rect.x + (rect.width - requisition.width) / 2;
				y = win_y + rect.y - requisition.height - offset;
				break;
			case Gtk.PositionType.TOP:
				x = win_x + rect.x + (rect.width - requisition.width) / 2;
				y = win_y + rect.height + offset;
				break;
			case Gtk.PositionType.LEFT:
				y = win_y + rect.y + (rect.height - requisition.height) / 2;
				x = win_x + rect.x + rect.width + offset;
				break;
			case Gtk.PositionType.RIGHT:
				y = win_y + rect.y + (rect.height - requisition.height) / 2;
				x = win_x + rect.x - requisition.width - offset;
				break;
			}
		}
		
		/**
		 * Get's the x and y position to display a hover window for a dock item.
		 *
		 * @param hovered the item that is hovered
		 * @param x the resulting x position
		 * @param y the resulting y position
		 */
		public void get_hover_position (DockItem hovered, out int x, out int y)
		{
			var rect = get_item_hover_region (hovered);
			
			switch (Position) {
			default:
			case Gtk.PositionType.BOTTOM:
				x = rect.x + win_x + rect.width / 2;
				y = rect.y + win_y;
				break;
			case Gtk.PositionType.TOP:
				x = rect.x + win_x + rect.width / 2;
				y = rect.y + win_y + rect.height;
				break;
			case Gtk.PositionType.LEFT:
				y = rect.y + win_y + rect.height / 2;
				x = rect.x + win_x + rect.width;
				break;
			case Gtk.PositionType.RIGHT:
				y = rect.y + win_y + rect.height / 2;
				x = rect.x + win_x;
				break;
			}
		}
		
		/**
		 * Get's the x and y position to display the urgent-glow for a dock item.
		 *
		 * @param item the item to show urgent-glow for
		 * @param x the resulting x position
		 * @param y the resulting y position
		 */
		public void get_urgent_glow_position (DockItem item, out int x, out int y)
		{
			var rect = get_item_hover_region (item);
			var glow_size = GlowSize;
			
			switch (Position) {
			default:
			case Gtk.PositionType.BOTTOM:
				x = rect.x + (rect.width - glow_size) / 2;
				y = DockHeight - glow_size / 2;
				break;
			case Gtk.PositionType.TOP:
				x = rect.x + (rect.width - glow_size) / 2;
				y = - glow_size / 2;
				break;
			case Gtk.PositionType.LEFT:
				y = rect.y + (rect.height - glow_size) / 2;
				x = - glow_size / 2;
				break;
			case Gtk.PositionType.RIGHT:
				y = rect.y + (rect.height - glow_size) / 2;
				x = DockWidth - glow_size / 2;
				break;
			}
		}

		/**
		 * Caches the x and y position of the dock window.
		 */
		public void update_dock_position ()
		{
			unowned DockPreferences prefs = controller.prefs;
			
			var xoffset = 0;
			var yoffset = 0;
			
			if (!screen_is_composited) {
				var offset = prefs.Offset;
				xoffset = (int) ((1 + offset / 100.0) * (monitor_geo.width - DockWidth) / 2);
				yoffset = (int) ((1 + offset / 100.0) * (monitor_geo.height - DockHeight) / 2);
				
				switch (prefs.Alignment) {
				default:
				case Gtk.Align.CENTER:
				case Gtk.Align.FILL:
					break;
				case Gtk.Align.START:
					xoffset = 0;
					yoffset = (monitor_geo.height - static_dock_region.height);
					break;
				case Gtk.Align.END:
					xoffset = (monitor_geo.width - static_dock_region.width);
					yoffset = 0;
					break;
				}
			}
			
			switch (Position) {
			default:
			case Gtk.PositionType.BOTTOM:
				win_x = monitor_geo.x + xoffset;
				win_y = monitor_geo.y + monitor_geo.height - DockHeight;
				break;
			case Gtk.PositionType.TOP:
				win_x = monitor_geo.x + xoffset;
				win_y = monitor_geo.y;
				break;
			case Gtk.PositionType.LEFT:
				win_y = monitor_geo.y + yoffset;
				win_x = monitor_geo.x;
				break;
			case Gtk.PositionType.RIGHT:
				win_y = monitor_geo.y + yoffset;
				win_x = monitor_geo.x + monitor_geo.width - DockWidth;
				break;
			}
			
			// Actually change the window position while hidden for non-compositing mode
			if (!screen_is_composited && controller.hide_manager.Hidden) {
				switch (Position) {
				default:
				case Gtk.PositionType.BOTTOM:
					win_y += DockHeight - 1;
					break;
				case Gtk.PositionType.TOP:
					win_y -= DockHeight - 1;
					break;
				case Gtk.PositionType.LEFT:
					win_x -= DockWidth - 1;
					break;
				case Gtk.PositionType.RIGHT:
					win_x += DockWidth - 1;
					break;
				}
			}
		}
		
		/**
		 * Get's the x and y position to display the main dock buffer.
		 *
		 * @param x the resulting x position
		 * @param y the resulting y position
		 */
		public void get_dock_draw_position (out int x, out int y)
		{
			if (!screen_is_composited) {
				x = 0;
				y = 0;
				return;
			}
			
			var progress = controller.renderer.hide_progress;
			
			switch (Position) {
			default:
			case Gtk.PositionType.BOTTOM:
				x = 0;
				y = (int) ((VisibleDockHeight + extra_hide_offset) * progress);
				break;
			case Gtk.PositionType.TOP:
				x = 0;
				y = (int) (- (VisibleDockHeight + extra_hide_offset) * progress);
				break;
			case Gtk.PositionType.LEFT:
				x = (int) (- (VisibleDockWidth + extra_hide_offset) * progress);
				y = 0;
				break;
			case Gtk.PositionType.RIGHT:
				x = (int) ((VisibleDockWidth + extra_hide_offset) * progress);
				y = 0;
				break;
			}
		}
		
		/**
		 * Get's the region to display the dock window at.
		 *
		 * @return the region for the dock window
		 */
		public Gdk.Rectangle get_dock_window_region ()
		{
			return { win_x, win_y, DockWidth, DockHeight };
		}
		
		/**
		 * Get's the region for background of the dock.
		 *
		 * @return the region for the dock background
		 */
		public Gdk.Rectangle get_background_region ()
		{
			var x = 0, y = 0;
			var width = 0, height = 0;
			
			if (screen_is_composited) {
				x = static_dock_region.x;
				y = static_dock_region.y;
				width = VisibleDockWidth;
				height = VisibleDockHeight;
			} else {
				width = DockWidth;
				height = DockHeight;
			}
			
			switch (Position) {
			default:
			case Gtk.PositionType.BOTTOM:
				x += (width - DockBackgroundWidth) / 2;
				y += height - DockBackgroundHeight;
				break;
			case Gtk.PositionType.TOP:
				x += (width - DockBackgroundWidth) / 2;
				y = 0;
				break;
			case Gtk.PositionType.LEFT:
				x = 0;
				y += (height - DockBackgroundHeight) / 2;
				break;
			case Gtk.PositionType.RIGHT:
				x += width - DockBackgroundWidth;
				y += (height - DockBackgroundHeight) / 2;
				break;
			}
			
			return { x, y, DockBackgroundWidth, DockBackgroundHeight };
		}
		
		/**
		 * Get the item's icon geometry for the dock.
		 *
		 * @param item an application-dockitem of the dock
		 * @param for_hidden whether the geometry should apply for a hidden dock
		 * @return icon geometry for the given application-dockitem
		 */
		public Gdk.Rectangle get_icon_geometry (ApplicationDockItem item, bool for_hidden)
		{
			var region = get_item_hover_region (item);
			
			if (!for_hidden) {
				region.x += win_x;
				region.y += win_y;
				
				return region;
			}
			
			var x = win_x, y = win_y;
			
			switch (Position) {
			default:
			case Gtk.PositionType.BOTTOM:
				x += region.x + region.width / 2;
				y += DockHeight;
				break;
			case Gtk.PositionType.TOP:
				x += region.x + region.width / 2;
				y += 0;
				break;
			case Gtk.PositionType.LEFT:
				x += 0;
				y += region.y + region.height / 2;
				break;
			case Gtk.PositionType.RIGHT:
				x += DockWidth;
				y += region.y + region.height / 2;
				break;
			}
			
			return { x, y, 0, 0 };
		}
		
		/**
		 * Computes the struts for the dock.
		 *
		 * @param struts the array to contain the struts
		 */
		public void get_struts (ref ulong[] struts)
		{
#if HAVE_HIDPI
			window_scale_factor = controller.window.get_window ().get_scale_factor ();
#endif
			switch (Position) {
			default:
			case Gtk.PositionType.BOTTOM:
				struts [Struts.BOTTOM] = (VisibleDockHeight + controller.window.get_screen ().get_height () - monitor_geo.y - monitor_geo.height) * window_scale_factor;
				struts [Struts.BOTTOM_START] = monitor_geo.x * window_scale_factor;
				struts [Struts.BOTTOM_END] = (monitor_geo.x + monitor_geo.width) * window_scale_factor - 1;
				break;
			case Gtk.PositionType.TOP:
				struts [Struts.TOP] = (monitor_geo.y + VisibleDockHeight) * window_scale_factor;
				struts [Struts.TOP_START] = monitor_geo.x * window_scale_factor;
				struts [Struts.TOP_END] = (monitor_geo.x + monitor_geo.width) * window_scale_factor - 1;
				break;
			case Gtk.PositionType.LEFT:
				struts [Struts.LEFT] = (monitor_geo.x + VisibleDockWidth) * window_scale_factor;
				struts [Struts.LEFT_START] = monitor_geo.y * window_scale_factor;
				struts [Struts.LEFT_END] = (monitor_geo.y + monitor_geo.height) * window_scale_factor - 1;
				break;
			case Gtk.PositionType.RIGHT:
				struts [Struts.RIGHT] = (VisibleDockWidth + controller.window.get_screen ().get_width () - monitor_geo.x - monitor_geo.width) * window_scale_factor;
				struts [Struts.RIGHT_START] = monitor_geo.y * window_scale_factor;
				struts [Struts.RIGHT_END] = (monitor_geo.y + monitor_geo.height) * window_scale_factor - 1;
				break;
			}
		}
		
#if HAVE_BARRIERS
		public Gdk.Rectangle get_barrier ()
		{
			Gdk.Rectangle barrier = {0};
			
			switch (Position) {
			default:
			case Gtk.PositionType.BOTTOM:
				barrier.x = monitor_geo.x + (monitor_geo.width - VisibleDockWidth) / 2;
				barrier.y = monitor_geo.y + monitor_geo.height;
				barrier.width = VisibleDockWidth;
				barrier.height = 0;
				break;
			case Gtk.PositionType.TOP:
				barrier.x = monitor_geo.x + (monitor_geo.width - VisibleDockWidth) / 2;
				barrier.y = monitor_geo.y;
				barrier.width = VisibleDockWidth;
				barrier.height = 0;
				break;
			case Gtk.PositionType.LEFT:
				barrier.x = monitor_geo.x;
				barrier.y = monitor_geo.y + (monitor_geo.height - VisibleDockHeight) / 2;
				barrier.width = 0;
				barrier.height = VisibleDockHeight;
				break;
			case Gtk.PositionType.RIGHT:
				barrier.x = monitor_geo.x + monitor_geo.width;
				barrier.y = monitor_geo.y + (monitor_geo.height - VisibleDockHeight) / 2;
				barrier.width = 0;
				barrier.height = VisibleDockHeight;
				break;
			}
			
			warn_if_fail (barrier.width > 0 || barrier.height > 0);
			
			return barrier;
		}
#endif
	}
}
