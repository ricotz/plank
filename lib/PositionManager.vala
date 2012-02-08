//  
//  Copyright (C) 2012 Robert Dyer
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
			requires (controller.renderer != null && controller.window != null)
		{
			controller.window.get_screen ().size_changed.connect (update_monitor_geo);
			update_monitor_geo ();
		}
		
		~PositionManager ()
		{
			controller.window.get_screen ().size_changed.disconnect (update_monitor_geo);
			controller.prefs.changed["Monitor"].disconnect (update_monitor_geo);
		}
		
		void update_monitor_geo ()
		{
			controller.window.get_screen ().get_monitor_geometry (controller.prefs.Monitor, out monitor_geo);
			controller.window.set_size ();
		}
		
		//
		// used to cache various sizes calculated from the theme and preferences
		//
		
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
		
		int items_offset;
		
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
		public void reset_caches (DockThemeRenderer theme)
		{
			var icon_size = controller.prefs.IconSize;
			var scaled_icon_size = icon_size / 10.0;
			
			IndicatorSize = (int) (theme.IndicatorSize * scaled_icon_size);
			GlowSize      = (int) (theme.GlowSize      * scaled_icon_size);
			HorizPadding  = (int) (theme.HorizPadding  * scaled_icon_size);
			TopPadding    = (int) (theme.TopPadding    * scaled_icon_size);
			BottomPadding = (int) (theme.BottomPadding * scaled_icon_size);
			ItemPadding   = (int) (theme.ItemPadding   * scaled_icon_size);
			
			items_offset  = (int) (2 * theme.LineWidth + (HorizPadding > 0 ? HorizPadding : 0));
			
			
			// height of the visible (cursor) rect of the dock
			var height = icon_size + 2 * (theme.get_top_offset () + theme.get_bottom_offset ()) + BottomPadding;
			if (TopPadding > 0)
				height += TopPadding;
			
			// height of the dock background image, as drawn
			var background_height = height;
			if (TopPadding < 0)
				background_height += TopPadding;
			
			// height of the dock window
			var dock_height = height + (int) (icon_size * theme.UrgentBounceHeight);
			
			
			var width = controller.items.Items.size * (ItemPadding + icon_size) + 2 * HorizPadding + 4 * theme.LineWidth;
			
			// width of the dock background image, as drawn
			var background_width = width;
			
			// width of the visible (cursor) rect of the dock
			if (HorizPadding < 0)
				width -= 2 * HorizPadding;
			
			// width of the dock window
			var dock_width = width + GlowSize / 2;
			
			
			if (controller.prefs.is_horizontal_dock ()) {
				VisibleDockHeight = height;
				VisibleDockWidth = width;
				DockHeight = dock_height;
				DockWidth = dock_width;
				DockBackgroundHeight = background_height;
				DockBackgroundWidth = background_width;
			} else {
				VisibleDockHeight = width;
				VisibleDockWidth = height;
				DockHeight = dock_width;
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
			if (controller.prefs.is_horizontal_dock ())
				cursor_region.height = int.max (1, (int) ((1 - controller.renderer.get_hide_offset ()) * VisibleDockHeight));
			else
				cursor_region.width = int.max (1, (int) ((1 - controller.renderer.get_hide_offset ()) * VisibleDockWidth));
			
			switch (controller.prefs.Position) {
			case PositionType.BOTTOM:
				cursor_region.y = controller.window.height_request - cursor_region.height;
				break;
			case PositionType.TOP:
				cursor_region.y = 0;
				break;
			case PositionType.LEFT:
				cursor_region.x = 0;
				break;
			case PositionType.RIGHT:
				cursor_region.x = controller.window.width_request - cursor_region.width;
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
			return static_dock_region;
		}
		
		/**
		 * Call when any cached region needs updating.
		 */
		public void update_regions ()
		{
			static_dock_region.width = VisibleDockWidth;
			static_dock_region.height = VisibleDockHeight;
			if (controller.prefs.is_horizontal_dock ()) {
				static_dock_region.x = (controller.window.width_request - static_dock_region.width) / 2;
				
				cursor_region.x = static_dock_region.x;
				cursor_region.width = static_dock_region.width;
			} else {
				static_dock_region.y = (controller.window.height_request - static_dock_region.height) / 2;
				
				cursor_region.y = static_dock_region.y;
				cursor_region.height = static_dock_region.height;
			}
			
			switch (controller.prefs.Position) {
			case PositionType.BOTTOM:
				static_dock_region.y = controller.window.height_request - static_dock_region.height;
				break;
			case PositionType.TOP:
				static_dock_region.y = 0;
				break;
			case PositionType.LEFT:
				static_dock_region.x = 0;
				break;
			case PositionType.RIGHT:
				static_dock_region.x = controller.window.width_request - static_dock_region.width;
				break;
			}
		}
		
		/**
		 * The cursor region for interacting with a dock item.
		 *
		 * @param item the dock item to find a region for
		 * @return the region for the dock item
		 */
		public Gdk.Rectangle item_hover_region (DockItem item)
		{
			var rect = item_draw_region (item);
			
			if (controller.prefs.is_horizontal_dock ())
				rect.x += (controller.window.width_request - VisibleDockWidth) / 2;
			else
				rect.y += (controller.window.height_request - VisibleDockHeight) / 2;
			
			return rect;
		}
		
		/**
		 * The region for drawing a dock item.
		 *
		 * @param item the dock item to find a region for
		 * @return the region for the dock item
		 */
		public Gdk.Rectangle item_draw_region (DockItem item)
		{
			var rect = Gdk.Rectangle ();
			
			if (controller.prefs.is_horizontal_dock ()) {
				rect.x = items_offset + item.Position * (ItemPadding + controller.prefs.IconSize);
				rect.width = controller.prefs.IconSize + ItemPadding;
				rect.height = VisibleDockHeight;
			} else {
				rect.y = items_offset + item.Position * (ItemPadding + controller.prefs.IconSize);
				rect.height = controller.prefs.IconSize + ItemPadding;
				rect.width = VisibleDockWidth;
			}
			
			switch (controller.prefs.Position) {
			case PositionType.BOTTOM:
				rect.y = DockHeight - VisibleDockHeight;
				break;
			case PositionType.TOP:
				rect.y = 0;
				break;
			case PositionType.LEFT:
				rect.x = 0;
				break;
			case PositionType.RIGHT:
				rect.x = DockWidth - VisibleDockWidth;
				break;
			}
			
			return rect;
		}
		
		/**
		 * Get's the x and y position to display a menu for a dock item.
		 *
		 * @param hovered the item that is hovered
		 * @param requisition the menu's requisition
		 * @param win_x the dock window's x position
		 * @param win_y the dock window's y position
		 * @param x the resulting x position
		 * @param y the resulting y position
		 */
		public void get_menu_position (DockItem hovered, Requisition requisition, int win_x, int win_y, out int x, out int y)
		{
			var rect = item_hover_region (hovered);
			
			if (controller.prefs.is_horizontal_dock ()) {
				x = win_x + rect.x + (rect.width - requisition.width) / 2;
				y = win_y;
			} else {
				y = win_y + rect.y + rect.width / 2;
				x = win_x + rect.x;
			}
			
			var offset = 10;
			switch (controller.prefs.Position) {
			case PositionType.BOTTOM:
				y += rect.y - requisition.height - offset;
				break;
			case PositionType.TOP:
				y += rect.height + offset;
				break;
			case PositionType.LEFT:
				x += rect.width + offset;
				break;
			case PositionType.RIGHT:
				x -= requisition.width + offset;
				break;
			}
		}
		
		/**
		 * Get's the x and y position to display a hover window for a dock item.
		 *
		 * @param hovered the item that is hovered
		 * @param win_x the dock window's x position
		 * @param win_y the dock window's y position
		 * @param x the resulting x position
		 * @param y the resulting y position
		 */
		public void get_hover_position (DockItem hovered, int win_x, int win_y, out int x, out int y)
		{
			var rect = item_hover_region (hovered);
			
			if (controller.prefs.is_horizontal_dock ()) {
				x = rect.x + win_x + rect.width / 2;
				y = rect.y + win_y;
				if (controller.prefs.Position == PositionType.TOP)
					y += rect.height;
			} else {
				y = rect.y + win_y + rect.height / 2;
				x = rect.x + win_x;
				if (controller.prefs.Position == PositionType.LEFT)
					x += rect.width;
			}
		}
		
		/**
		 * Get's the x and y position to display a hover window for a dock item.
		 *
		 * @param win_x the dock window's x position
		 * @param win_y the dock window's y position
		 */
		public void get_dock_position (out int win_x, out int win_y)
		{
			if (controller.prefs.is_horizontal_dock ()) {
				win_x = monitor_geo.x + (monitor_geo.width - controller.window.width_request) / 2;
				win_y = monitor_geo.y;
				if (controller.prefs.Position == PositionType.BOTTOM)
					win_y += monitor_geo.height - controller.window.height_request;
			} else {
				win_y = monitor_geo.y + (monitor_geo.height - controller.window.height_request) / 2;
				win_x = monitor_geo.x;
				if (controller.prefs.Position == PositionType.RIGHT)
					win_x += monitor_geo.width - controller.window.width_request;
			}
		}
		
		/**
		 * Computes the struts for the dock.
		 *
		 * @param struts the array to contain the struts
		 */
		public void get_struts (ref ulong[] struts)
		{
			if (controller.prefs.is_horizontal_dock ()) {
				struts [controller.prefs.Position + Struts.LEFT_START] = monitor_geo.x;
				struts [controller.prefs.Position + Struts.LEFT_END] = monitor_geo.x + monitor_geo.width - 1;
			} else {
				struts [controller.prefs.Position + Struts.LEFT_START] = monitor_geo.y;
				struts [controller.prefs.Position + Struts.LEFT_END] = monitor_geo.y + monitor_geo.height - 1;
			}
			
			switch (controller.prefs.Position) {
			case PositionType.BOTTOM:
				struts [controller.prefs.Position] = VisibleDockHeight + controller.window.get_screen ().get_height () - monitor_geo.y - monitor_geo.height;
				break;
			case PositionType.TOP:
				struts [controller.prefs.Position] = monitor_geo.y + VisibleDockHeight;
				break;
			case PositionType.LEFT:
				struts [controller.prefs.Position] = monitor_geo.x + VisibleDockWidth;
				break;
			case PositionType.RIGHT:
				struts [controller.prefs.Position] = VisibleDockWidth + controller.window.get_screen ().get_width () - monitor_geo.x - monitor_geo.width;
				break;
			}
		}
	}
}
