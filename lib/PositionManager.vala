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

using Plank.Items;
using Plank.Drawing;

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
		}
		
		//
		// used to cache various sizes calculated from the theme and preferences
		//
		
		/**
		 * Theme-based indicator size, scaled by icon size.
		 */
		public int IndicatorSize { get; private set; }
		/**
		 * Theme-based horizontal padding, scaled by icon size.
		 */
		public int HorizPadding  { get; private set; }
		/**
		 * Theme-based top padding, scaled by icon size.
		 */
		public int TopPadding    { get; private set; }
		/**
		 * Theme-based item padding, scaled by icon size.
		 */
		public int ItemPadding   { get; private set; }
		
		int BottomPadding { get; set; }
		int ItemsOffset   { get; set; }
		
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
		 * Resets any cache that doesn't rely on the current set of items.
		 *
		 * @param theme the current dock theme
		 */
		public void reset_caches (DockThemeRenderer theme)
		{
			var icon_size = controller.prefs.IconSize;
			
			IndicatorSize = (int) (theme.IndicatorSize / 10.0 * icon_size);
			HorizPadding  = (int) (theme.HorizPadding  / 10.0 * icon_size);
			TopPadding    = (int) (theme.TopPadding    / 10.0 * icon_size);
			ItemPadding   = (int) (theme.ItemPadding   / 10.0 * icon_size);
			BottomPadding = (int) (theme.BottomPadding / 10.0 * icon_size);
			ItemsOffset   = (int) (2 * theme.LineWidth + (HorizPadding > 0 ? HorizPadding : 0));
			
			// height of the visible (cursor) rect of the dock
			// use a temporary to avoid (possibly) doing more than 1 notify signal
			var tmp = icon_size + 2 * (theme.get_top_offset () + theme.get_bottom_offset ());
			if (TopPadding > 0)
				tmp += TopPadding;
			if (BottomPadding > 0)
				tmp += BottomPadding;
			VisibleDockHeight = tmp;
			
			// height of the dock window
			DockHeight = tmp + (int) (icon_size * theme.UrgentBounceHeight);
			
			// height of the dock background image, as drawn
			DockBackgroundHeight = tmp;
			if (TopPadding < 0)
				DockBackgroundHeight += TopPadding;
		}
		
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
		 * Resets any cache that relies on the current set of items.
		 *
		 * @param theme the current dock theme
		 * @param urgent_glow_size the size of the urgent glow
		 */
		public void reset_item_caches (DockThemeRenderer theme, int urgent_glow_size)
		{
			reset_caches (theme);
			
			var width = (int) controller.items.Items.size * (ItemPadding + controller.prefs.IconSize) + 2 * HorizPadding + 4 * theme.LineWidth;
			
			// width of the dock background image, as drawn
			DockBackgroundWidth = width;
			
			// width of the visible (cursor) rect of the dock
			if (HorizPadding < 0)
				width -= 2 * HorizPadding;
			VisibleDockWidth = width;
			
			// width of the dock window
			DockWidth = width + controller.prefs.IconSize + ItemPadding + urgent_glow_size / 2;
		}
		
		/**
		 * Returns the cursor region for the dock.
		 * This is the region that the cursor can interact with the dock.
		 *
		 * @return the cursor region for the dock
		 */
		public Gdk.Rectangle get_cursor_region ()
		{
			cursor_region.height = int.max (1, (int) ((1 - controller.renderer.get_hide_offset ()) * VisibleDockHeight));
			cursor_region.y = controller.window.height_request - cursor_region.height;
			
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
			static_dock_region.x = (controller.window.width_request - static_dock_region.width) / 2;
			static_dock_region.y = controller.window.height_request - static_dock_region.height;
			
			cursor_region.width = static_dock_region.width;
			cursor_region.x = static_dock_region.x;
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
			rect.x += (controller.window.width_request - VisibleDockWidth) / 2;
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
			
			rect.x = ItemsOffset + item.Position * (ItemPadding + controller.prefs.IconSize);
			rect.y = DockHeight - VisibleDockHeight;
			rect.width = controller.prefs.IconSize + ItemPadding;
			rect.height = VisibleDockHeight;
			
			return rect;
		}
	}
}
