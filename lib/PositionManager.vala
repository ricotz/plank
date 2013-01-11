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

using Gdk;
using Gtk;

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
		DockController controller;
		
		Gdk.Rectangle cursor_region;
		Gdk.Rectangle static_dock_region;
		
		Gdk.Rectangle monitor_geo;
		
		bool screen_is_composited;
		
		/**
		 * Creates a new position manager.
		 *
		 * @param controller the dock controller to manage positions for
		 */
		public PositionManager (DockController controller)
		{
			this.controller = controller;
			
			cursor_region = Gdk.Rectangle ();
			static_dock_region = Gdk.Rectangle ();
			
			controller.prefs.changed["Monitor"].connect (update_monitor_geo);
		}
		
		/**
		 * Initializes the position manager.
		 */
		public void initialize ()
			requires (controller.window != null)
		{
			var screen = controller.window.get_screen ();
			
			screen.monitors_changed.connect (update_monitor_geo);
			screen.size_changed.connect (update_monitor_geo);
			
			// NOTE don't call update_monitor_geo to avoid a double-call of dockwindow.set_size on startup
			screen.get_monitor_geometry (controller.prefs.get_monitor (), out monitor_geo);
			
			screen_is_composited = screen.is_composited ();
		}
		
		~PositionManager ()
		{
			var screen = controller.window.get_screen ();
			
			screen.monitors_changed.disconnect (update_monitor_geo);
			screen.size_changed.disconnect (update_monitor_geo);
			controller.prefs.changed["Monitor"].disconnect (update_monitor_geo);
		}
		
		void update_monitor_geo ()
		{
			controller.window.get_screen ().get_monitor_geometry (controller.prefs.get_monitor (), out monitor_geo);
			update_dimensions ();
			update_dock_position ();
			update_regions ();
			
			controller.window.update_size_and_position ();
		}
		
		//
		// used to cache various sizes calculated from the theme and preferences
		//
		
		/**
		 * Cached x position of the dock window.
		 */
		public int win_x { get; protected set; }
		
		/**
		 * Cached y position of the dock window.
		 */
		public int win_y { get; protected set; }
		
		
		public int LineWidth { get; private set; }
		
		public int IconSize { get; private set; }
		
		/**
		 * Theme-based indicator size, scaled by icon size.
		 */
		public int IndicatorSize { get; private set; }
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
		
		public int UrgentBounceHeight { get; private set; }
		
		int items_offset;
		int top_offset;
		int bottom_offset;
		
		/**
		 * The currently visible height of the dock.
		 */
		public int VisibleDockHeight { get; private set; }
		/**
		 * The static height of the dock.
		 */
		public int DockHeight { get; private set; }
		/**
		 * The height of the dock's background image.
		 */
		public int DockBackgroundHeight { get; private set; }
		
		/**
		 * The currently visible width of the dock.
		 */
		public int VisibleDockWidth { get; private set; }
		/**
		 * The static width of the dock.
		 */
		public int DockWidth { get; private set; }
		/**
		 * The width of the dock's background image.
		 */
		public int DockBackgroundWidth { get; private set; }
		
		/**
		 * Resets all internal caches.
		 *
		 * @param theme the current dock theme
		 */
		public void reset_caches (DockTheme theme)
		{
			Logger.verbose ("PositionManager.reset_caches ()");
			
			screen_is_composited = controller.window.get_screen ().is_composited ();
			
			IconSize = controller.prefs.IconSize;
			var scaled_icon_size = IconSize / 10.0;
			
			IndicatorSize = (int) (theme.IndicatorSize * scaled_icon_size);
			GlowSize      = (int) (theme.GlowSize      * scaled_icon_size);
			HorizPadding  = (int) (theme.HorizPadding  * scaled_icon_size);
			TopPadding    = (int) (theme.TopPadding    * scaled_icon_size);
			BottomPadding = (int) (theme.BottomPadding * scaled_icon_size);
			ItemPadding   = (int) (theme.ItemPadding   * scaled_icon_size);
			UrgentBounceHeight = (int) (theme.UrgentBounceHeight * IconSize);
			LineWidth     = theme.LineWidth;
			
			items_offset  = (int) (2 * LineWidth + (HorizPadding > 0 ? HorizPadding : 0));
			
			top_offset = theme.get_top_offset ();
			bottom_offset = theme.get_bottom_offset ();
			
			update_dimensions ();
			update_dock_position ();
		}
		
		void update_dimensions ()
		{
			Logger.verbose ("PositionManager.update_dimensions ()");
			
			if (!screen_is_composited) {
				HorizPadding = int.max (0, HorizPadding);
				TopPadding = int.max (0, TopPadding);
			}
			
			// height of the visible (cursor) rect of the dock
			var height = IconSize + top_offset + TopPadding + bottom_offset + BottomPadding;
			
			// height of the dock background image, as drawn
			var background_height = height;
			
			if (top_offset + TopPadding < 0)
				height -= top_offset + TopPadding;
			
			// height of the dock window
			var dock_height = height + (screen_is_composited ? UrgentBounceHeight : 0);
			
			
			var width = controller.items.Items.size * (ItemPadding + IconSize) + 2 * HorizPadding + 4 * LineWidth;
			
			// width of the dock background image, as drawn
			var background_width = width;
			
			// width of the visible (cursor) rect of the dock
			if (HorizPadding < 0)
				width -= 2 * HorizPadding;
			
			if (controller.prefs.is_horizontal_dock ()) {
				width = int.min (monitor_geo.width, width);
				VisibleDockHeight = height;
				VisibleDockWidth = width;
				DockHeight = dock_height;
				DockWidth = (screen_is_composited ? monitor_geo.width : width);
				DockBackgroundHeight = background_height;
				DockBackgroundWidth = background_width;
			} else {
				width = int.min (monitor_geo.height, width);
				VisibleDockHeight = width;
				VisibleDockWidth = height;
				DockHeight = (screen_is_composited ? monitor_geo.height : width);
				DockWidth = dock_height;
				DockBackgroundHeight = background_width;
				DockBackgroundWidth = background_height;
			}
		}
		
		/**
		 * Returns the cursor region for the dock.
		 * This is the region that the cursor can interact with the dock.
		 *
		 * @return the cursor region for the dock
		 */
		public Gdk.Rectangle get_cursor_region ()
		{
			switch (controller.prefs.Position) {
			default:
			case PositionType.BOTTOM:
				cursor_region.height = int.max (1, (int) ((1 - controller.renderer.get_hide_offset ()) * VisibleDockHeight));
				cursor_region.y = DockHeight - cursor_region.height;
				break;
			case PositionType.TOP:
				cursor_region.height = int.max (1, (int) ((1 - controller.renderer.get_hide_offset ()) * VisibleDockHeight));
				cursor_region.y = 0;
				break;
			case PositionType.LEFT:
				cursor_region.width = int.max (1, (int) ((1 - controller.renderer.get_hide_offset ()) * VisibleDockWidth));
				cursor_region.x = 0;
				break;
			case PositionType.RIGHT:
				cursor_region.width = int.max (1, (int) ((1 - controller.renderer.get_hide_offset ()) * VisibleDockWidth));
				cursor_region.x = DockWidth - cursor_region.width;
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
			if (!screen_is_composited && controller.renderer.Hidden) {
				switch (controller.prefs.Position) {
				default:
				case PositionType.BOTTOM:
					dock_region.y -= DockHeight - 1;
					break;
				case PositionType.TOP:
					dock_region.y += DockHeight - 1;
					break;
				case PositionType.LEFT:
					dock_region.x += DockWidth - 1;
					break;
				case PositionType.RIGHT:
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
			Logger.verbose ("PositionManager.update_regions ()");
			
			var old_region = static_dock_region;
			
			static_dock_region.width = VisibleDockWidth;
			static_dock_region.height = VisibleDockHeight;
			
			var xoffset = (DockWidth - static_dock_region.width) / 2;
			var yoffset = (DockHeight - static_dock_region.height) / 2;
			
			if (screen_is_composited) {
				xoffset = (int) ((1 + controller.prefs.Offset / 100.0) * xoffset);
				yoffset = (int) ((1 + controller.prefs.Offset / 100.0) * yoffset);
			}
			
			switch (controller.prefs.Position) {
			default:
			case PositionType.BOTTOM:
				static_dock_region.x = xoffset;
				static_dock_region.y = DockHeight - static_dock_region.height;
				
				cursor_region.x = static_dock_region.x;
				cursor_region.width = static_dock_region.width;
				break;
			case PositionType.TOP:
				static_dock_region.x = xoffset;
				static_dock_region.y = 0;
				
				cursor_region.x = static_dock_region.x;
				cursor_region.width = static_dock_region.width;
				break;
			case PositionType.LEFT:
				static_dock_region.y = yoffset;
				static_dock_region.x = 0;
				
				cursor_region.y = static_dock_region.y;
				cursor_region.height = static_dock_region.height;
				break;
			case PositionType.RIGHT:
				static_dock_region.y = yoffset;
				static_dock_region.x = DockWidth - static_dock_region.width;
				
				cursor_region.y = static_dock_region.y;
				cursor_region.height = static_dock_region.height;
				break;
			}
			
			if (old_region.x != static_dock_region.x
				|| old_region.y != static_dock_region.y
				|| old_region.width != static_dock_region.width
				|| old_region.height != static_dock_region.height) {
				controller.window.update_size_and_position ();
				
				// With active compositing support update_size_and_position () won't trigger a redraw
				// (a changed static_dock_region doesn't implicate the window-size changed)
				if (screen_is_composited)
					controller.renderer.animated_draw ();
			} else {
				controller.renderer.animated_draw ();
			}
		}
		
		/**
		 * The region for drawing a dock item.
		 *
		 * @param hover_rect the item's hover region
		 * @return the region for the dock item
		 */
		public Gdk.Rectangle item_draw_region (Gdk.Rectangle hover_rect)
		{
			var item_padding = ItemPadding;
			var top_padding = top_offset + TopPadding;
			var bottom_padding = BottomPadding;
			
			top_padding = (top_padding < 0 ? 0 : top_padding);
			bottom_padding = bottom_offset + bottom_padding;
			
			switch (controller.prefs.Position) {
			default:
			case PositionType.BOTTOM:
				hover_rect.x += item_padding / 2;
				hover_rect.y += top_padding;
				hover_rect.width -= item_padding;
				hover_rect.height -= bottom_padding + top_padding;
				break;
			case PositionType.TOP:
				hover_rect.x += item_padding / 2;
				hover_rect.y += bottom_padding;
				hover_rect.width -= item_padding;
				hover_rect.height -= bottom_padding + top_padding;
				break;
			case PositionType.LEFT:
				hover_rect.x += bottom_padding;
				hover_rect.y += item_padding / 2;
				hover_rect.width -= bottom_padding + top_padding;
				hover_rect.height -= item_padding;
				break;
			case PositionType.RIGHT:
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
		public Gdk.Rectangle item_background_region (Gdk.Rectangle rect)
		{
			var top_padding = top_offset + TopPadding;
			top_padding = (top_padding > 0 ? 0 : top_padding);
			
			switch (controller.prefs.Position) {
			default:
			case PositionType.BOTTOM:
				rect.y -= top_padding;
				rect.height += top_padding;
				break;
			case PositionType.TOP:
				rect.height += top_padding;
				break;
			case PositionType.LEFT:
				rect.width += top_padding;
				break;
			case PositionType.RIGHT:
				rect.x -= top_padding;
				rect.width += top_padding;
				break;
			}
			
			return rect;
		}

		/**
		 * The cursor region for interacting with a dock item.
		 *
		 * @param item the dock item to find a region for
		 * @return the region for the dock item
		 */
		public Gdk.Rectangle item_hover_region (DockItem item)
		{
			var rect = Gdk.Rectangle ();
			
			switch (controller.prefs.Position) {
			default:
			case PositionType.BOTTOM:
				rect.width = IconSize + ItemPadding;
				rect.height = VisibleDockHeight;
				rect.x = static_dock_region.x + items_offset + item.Position * (ItemPadding + IconSize);
				rect.y = DockHeight - rect.height;
				break;
			case PositionType.TOP:
				rect.width = IconSize + ItemPadding;
				rect.height = VisibleDockHeight;
				rect.x = static_dock_region.x + items_offset + item.Position * (ItemPadding + IconSize);
				rect.y = 0;
				break;
			case PositionType.LEFT:
				rect.height = IconSize + ItemPadding;
				rect.width = VisibleDockWidth;
				rect.y = static_dock_region.y + items_offset + item.Position * (ItemPadding + IconSize);
				rect.x = 0;
				break;
			case PositionType.RIGHT:
				rect.height = IconSize + ItemPadding;
				rect.width = VisibleDockWidth;
				rect.y = static_dock_region.y + items_offset + item.Position * (ItemPadding + IconSize);
				rect.x = DockWidth - rect.width;
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
		public void get_menu_position (DockItem hovered, Requisition requisition, out int x, out int y)
		{
			var rect = item_hover_region (hovered);
			
			var offset = 10;
			switch (controller.prefs.Position) {
			default:
			case PositionType.BOTTOM:
				x = win_x + rect.x + (rect.width - requisition.width) / 2;
				y = win_y + rect.y - requisition.height - offset;
				break;
			case PositionType.TOP:
				x = win_x + rect.x + (rect.width - requisition.width) / 2;
				y = win_y + rect.height + offset;
				break;
			case PositionType.LEFT:
				y = win_y + rect.y + rect.width / 2;
				x = win_x + rect.x + rect.width + offset;
				break;
			case PositionType.RIGHT:
				y = win_y + rect.y + rect.width / 2;
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
			var rect = item_hover_region (hovered);
			
			switch (controller.prefs.Position) {
			default:
			case PositionType.BOTTOM:
				x = rect.x + win_x + rect.width / 2;
				y = rect.y + win_y;
				break;
			case PositionType.TOP:
				x = rect.x + win_x + rect.width / 2;
				y = rect.y + win_y + rect.height;
				break;
			case PositionType.LEFT:
				y = rect.y + win_y + rect.height / 2;
				x = rect.x + win_x + rect.width;
				break;
			case PositionType.RIGHT:
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
			var rect = item_hover_region (item);
			var glow_size = controller.position_manager.GlowSize;
			
			switch (controller.prefs.Position) {
			default:
			case PositionType.BOTTOM:
				x = rect.x + (rect.width - glow_size) / 2;
				y = DockHeight - glow_size / 2;
				break;
			case PositionType.TOP:
				x = rect.x + (rect.width - glow_size) / 2;
				y = - glow_size / 2;
				break;
			case PositionType.LEFT:
				y = rect.y + (rect.height - glow_size) / 2;
				x = - glow_size / 2;
				break;
			case PositionType.RIGHT:
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
			var xoffset = 0;
			var yoffset = 0;
			
			if (!screen_is_composited) {
				xoffset = (int) ((1 + controller.prefs.Offset / 100.0) * (monitor_geo.width - DockWidth) / 2);
				yoffset = (int) ((1 + controller.prefs.Offset / 100.0) * (monitor_geo.height - DockHeight) / 2);
			}
			
			switch (controller.prefs.Position) {
			default:
			case PositionType.BOTTOM:
				win_x = monitor_geo.x + xoffset;
				win_y = monitor_geo.y + monitor_geo.height - DockHeight;
				break;
			case PositionType.TOP:
				win_x = monitor_geo.x + xoffset;
				win_y = monitor_geo.y;
				break;
			case PositionType.LEFT:
				win_y = monitor_geo.y + yoffset;
				win_x = monitor_geo.x;
				break;
			case PositionType.RIGHT:
				win_y = monitor_geo.y + yoffset;
				win_x = monitor_geo.x + monitor_geo.width - DockWidth;
				break;
			}
			
			// Actually change the window position while hidden for non-compositing mode
			if (!screen_is_composited && controller.renderer.Hidden) {
				switch (controller.prefs.Position) {
				default:
				case PositionType.BOTTOM:
					win_y += DockHeight - 1;
					break;
				case PositionType.TOP:
					win_y -= DockHeight - 1;
					break;
				case PositionType.LEFT:
					win_x -= DockWidth - 1;
					break;
				case PositionType.RIGHT:
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
			
			switch (controller.prefs.Position) {
			default:
			case PositionType.BOTTOM:
				x = 0;
				y = (int) (VisibleDockHeight * controller.renderer.get_hide_offset ());
				break;
			case PositionType.TOP:
				x = 0;
				y = (int) (- VisibleDockHeight * controller.renderer.get_hide_offset ());
				break;
			case PositionType.LEFT:
				x = (int) (- VisibleDockWidth * controller.renderer.get_hide_offset ());
				y = 0;
				break;
			case PositionType.RIGHT:
				x = (int) (VisibleDockWidth * controller.renderer.get_hide_offset ());
				y = 0;
				break;
			}
		}
		
		/**
		 * Get's the x and y position to display the background of the dock.
		 *
		 * @param x the resulting x position
		 * @param y the resulting y position
		 */
		public void get_background_position (out int x, out int y)
		{
			var xoffset = 0, yoffset = 0;
			var width = 0, height = 0;
			
			if (screen_is_composited) {
				xoffset = static_dock_region.x;
				yoffset = static_dock_region.y;
				width = VisibleDockWidth;
				height = VisibleDockHeight;
			} else {
				width = DockWidth;
				height = DockHeight;
			}
			
			switch (controller.prefs.Position) {
			default:
			case PositionType.BOTTOM:
				x = xoffset + (width - DockBackgroundWidth) / 2;
				y = yoffset + height - DockBackgroundHeight;
				break;
			case PositionType.TOP:
				x = xoffset + (width - DockBackgroundWidth) / 2;
				y = 0;
				break;
			case PositionType.LEFT:
				x = 0;
				y = yoffset + (height - DockBackgroundHeight) / 2;
				break;
			case PositionType.RIGHT:
				x = xoffset + width - DockBackgroundWidth;
				y = yoffset + (height - DockBackgroundHeight) / 2;
				break;
			}
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
			var region = item_hover_region (item);
			
			if (!for_hidden) {
				region.x += win_x;
				region.y += win_y;
				
				return region;
			}
			
			var x = win_x, y = win_y;
			
			switch (controller.prefs.Position) {
			default:
			case PositionType.BOTTOM:
				x += region.x + region.width / 2;
				y += DockHeight;
				break;
			case PositionType.TOP:
				x += region.x + region.width / 2;
				y += 0;
				break;
			case PositionType.LEFT:
				x += 0;
				y += region.y + region.height / 2;
				break;
			case PositionType.RIGHT:
				x += DockWidth;
				y += region.y + region.height / 2;
				break;
			}
			
			return Gdk.Rectangle () { x = x, y = y, width = 0, height = 0};
		}
		
		/**
		 * Computes the struts for the dock.
		 *
		 * @param struts the array to contain the struts
		 */
		public void get_struts (ref ulong[] struts)
		{
			switch (controller.prefs.Position) {
			default:
			case PositionType.BOTTOM:
				struts [Struts.BOTTOM] = VisibleDockHeight + controller.window.get_screen ().get_height () - monitor_geo.y - monitor_geo.height;
				struts [Struts.BOTTOM_START] = monitor_geo.x;
				struts [Struts.BOTTOM_END] = monitor_geo.x + monitor_geo.width - 1;
				break;
			case PositionType.TOP:
				struts [Struts.TOP] = monitor_geo.y + VisibleDockHeight;
				struts [Struts.TOP_START] = monitor_geo.x;
				struts [Struts.TOP_END] = monitor_geo.x + monitor_geo.width - 1;
				break;
			case PositionType.LEFT:
				struts [Struts.LEFT] = monitor_geo.x + VisibleDockWidth;
				struts [Struts.LEFT_START] = monitor_geo.y;
				struts [Struts.LEFT_END] = monitor_geo.y + monitor_geo.height - 1;
				break;
			case PositionType.RIGHT:
				struts [Struts.RIGHT] = VisibleDockWidth + controller.window.get_screen ().get_width () - monitor_geo.x - monitor_geo.width;
				struts [Struts.RIGHT_START] = monitor_geo.y;
				struts [Struts.RIGHT_END] = monitor_geo.y + monitor_geo.height - 1;
				break;
			}
		}
	}
}
