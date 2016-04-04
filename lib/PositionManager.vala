//
//  Copyright (C) 2012 Robert Dyer, Rico Tzschichholz
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
	 * Handles computing any size/position information for the dock.
	 */
	public class PositionManager : GLib.Object
	{
		public DockController controller { private get; construct; }
		
		public bool screen_is_composited { get; private set; }
		
		Gdk.Rectangle static_dock_region;
		Gee.HashMap<DockElement, DockItemDrawValue> draw_values;
		
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
			static_dock_region = {};
			draw_values = new Gee.HashMap<DockElement, DockItemDrawValue> ();
		}
		
		/**
		 * Initializes the position manager.
		 */
		public void initialize ()
			requires (controller.window != null)
		{
			unowned Gdk.Screen screen = controller.window.get_screen ();
			
			controller.prefs.notify.connect (prefs_changed);
			screen.monitors_changed.connect (screen_changed);
			screen.size_changed.connect (screen_changed);
			screen.composited_changed.connect (screen_composited_changed);
			
			// NOTE don't call update_monitor_geo to avoid a double-call of dockwindow.set_size on startup
			screen.get_monitor_geometry (find_monitor_number (screen, controller.prefs.Monitor), out monitor_geo);
			
			screen_is_composited = screen.is_composited ();
		}
		
		~PositionManager ()
		{
			unowned Gdk.Screen screen = controller.window.get_screen ();
			
			screen.monitors_changed.disconnect (screen_changed);
			screen.size_changed.disconnect (screen_changed);
			screen.composited_changed.disconnect (screen_composited_changed);
			controller.prefs.notify.disconnect (prefs_changed);
			
			draw_values.clear ();
		}
		
		void prefs_changed (Object prefs, ParamSpec prop)
		{
			switch (prop.name) {
			case "Monitor":
				prefs_monitor_changed ();
				break;
			case "ZoomPercent":
			case "ZoomEnabled":
				prefs_zoom_changed ();
				break;
			default:
				// Nothing important for us changed
				break;
			}
		}
		
		public static string[] get_monitor_plug_names (Gdk.Screen screen)
		{
			int n_monitors = screen.get_n_monitors ();
			var result = new string[n_monitors];
			
			for (int i = 0; i < n_monitors; i++)
				result[i] = screen.get_monitor_plug_name (i) ?? "PLUG_MONITOR_%i".printf (i);
			
			return result;
		}
		
		static int find_monitor_number (Gdk.Screen screen, string plug_name)
		{
			if (plug_name == "")
				return screen.get_primary_monitor ();
			
			int n_monitors = screen.get_n_monitors ();
			
			for (int i = 0; i < n_monitors; i++) {
				var name = screen.get_monitor_plug_name (i) ?? "PLUG_MONITOR_%i".printf (i);
				if (plug_name == name)
					return i;
			}
			
			return screen.get_primary_monitor ();
		}
		
		void prefs_monitor_changed ()
		{
			screen_changed (controller.window.get_screen ());
		}

		void screen_changed (Gdk.Screen screen)
		{
			var old_monitor_geo = monitor_geo;
			
			screen.get_monitor_geometry (find_monitor_number (screen, controller.prefs.Monitor), out monitor_geo);
			
			// No need to do anything if nothing has actually changed
			if (old_monitor_geo.x == monitor_geo.x
				&& old_monitor_geo.y == monitor_geo.y
				&& old_monitor_geo.width == monitor_geo.width
				&& old_monitor_geo.height == monitor_geo.height)
				return;
			
			Logger.verbose ("PositionManager.monitor_geo_changed (%i,%i-%ix%i)",
				monitor_geo.x, monitor_geo.y, monitor_geo.width, monitor_geo.height);
			
			freeze_notify ();
			
			update_dimensions ();
			update_regions ();
			
			thaw_notify ();
		}
		
		void screen_composited_changed (Gdk.Screen screen)
		{
			freeze_notify ();
			
			screen_is_composited = screen.is_composited ();
			
			update (controller.renderer.theme);
 			
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
		 * Cached current icon size for the dock.
		 */
		public int ZoomIconSize { get; private set; }
		
		/**
		 * Cached position of the dock.
		 */
		public Gtk.PositionType Position { get; private set; }
		
		/**
		 * Cached alignment of the dock.
		 */
		public Gtk.Align Alignment { get; private set; }
		
		/**
		 * Cached alignment of the items.
		 */
		public Gtk.Align ItemsAlignment { get; private set; }
		
		/**
		 * Cached offset of the dock.
		 */
		public int Offset { get; private set; }
		
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
		
		double ZoomPercent;
		
		Gdk.Rectangle background_rect;
		
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
			update_regions ();
			
			thaw_notify ();
		}
		
		void update_caches (DockTheme theme)
		{
			unowned DockPreferences prefs = controller.prefs;
			
			Position = prefs.Position;
			Alignment = prefs.Alignment;
			ItemsAlignment = prefs.ItemsAlignment;
			Offset = prefs.Offset;
			
			// Mirror position/alignments/offset for RTL environments if needed
			if (Gtk.Widget.get_default_direction () == Gtk.TextDirection.RTL) {
				if (is_horizontal_dock ()) {
					if (Alignment == Gtk.Align.START)
						Alignment = Gtk.Align.END;
					else if (Alignment == Gtk.Align.END)
						Alignment = Gtk.Align.START;
					
					if (ItemsAlignment == Gtk.Align.START)
						ItemsAlignment = Gtk.Align.END;
					else if (ItemsAlignment == Gtk.Align.END)
						ItemsAlignment = Gtk.Align.START;
					
					Offset = -Offset;
				} else {
					if (Position == Gtk.PositionType.RIGHT)
						Position = Gtk.PositionType.LEFT;
					else
						Position = Gtk.PositionType.RIGHT;
				}
			}
			
			IconSize = int.min (MaxIconSize, prefs.IconSize);
			ZoomPercent = (screen_is_composited ? prefs.ZoomPercent / 100.0 : 1.0);
			ZoomIconSize = (screen_is_composited && prefs.ZoomEnabled ? (int) Math.round (IconSize * ZoomPercent) : IconSize);
			
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
		}
		
		void prefs_zoom_changed ()
		{
			unowned DockPreferences prefs = controller.prefs;
			
			ZoomPercent = (screen_is_composited ? prefs.ZoomPercent / 100.0 : 1.0);
			ZoomIconSize = (screen_is_composited && prefs.ZoomEnabled ? (int) Math.round (IconSize * ZoomPercent) : IconSize);
		}
		
		/**
		 * Find an appropriate MaxIconSize
		 */
		void update_max_icon_size (DockTheme theme)
		{
			unowned DockPreferences prefs = controller.prefs;
			
			// Check if the dock is oversized and doesn't fit the targeted screen-edge
			var item_count = controller.VisibleItems.size;
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
			switch (Alignment) {
			default:
			case Gtk.Align.START:
			case Gtk.Align.END:
			case Gtk.Align.CENTER:
				width = controller.VisibleItems.size * (ItemPadding + IconSize) + 2 * HorizPadding + 4 * LineWidth;
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
			window_scale_factor = controller.window.get_window ().get_scale_factor ();
			
			// If zoom is enabled extend cursor-region based on current hovered-item
			if (controller.prefs.ZoomEnabled) {
				unowned DockItem? hovered_item = controller.window.HoveredItem;
				if (hovered_item != null) {
					var hover_region = get_hover_region_for_element (hovered_item);
					cursor_region.union (hover_region, out cursor_region);
				}
			}
			
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
			Logger.verbose ("PositionManager.update_regions ()");
			
			var old_region = static_dock_region;
			
			// width of the items-area of the dock
			items_width = controller.VisibleItems.size * (ItemPadding + IconSize);
			
			static_dock_region.width = VisibleDockWidth;
			static_dock_region.height = VisibleDockHeight;
			
			var xoffset = (DockWidth - static_dock_region.width) / 2;
			var yoffset = (DockHeight - static_dock_region.height) / 2;
			
			if (screen_is_composited) {
				var offset = Offset;
				xoffset = (int) ((1 + offset / 100.0) * xoffset);
				yoffset = (int) ((1 + offset / 100.0) * yoffset);
				
				switch (Alignment) {
				default:
				case Gtk.Align.CENTER:
				case Gtk.Align.FILL:
					break;
				case Gtk.Align.START:
					if (is_horizontal_dock ()) {
						xoffset = 0;
						yoffset = (monitor_geo.height - static_dock_region.height);
					} else {
						xoffset = (monitor_geo.width - static_dock_region.width);
						yoffset = 0;
					}
					break;
				case Gtk.Align.END:
					if (is_horizontal_dock ()) {
						xoffset = (monitor_geo.width - static_dock_region.width);
						yoffset = 0;
					} else {
						xoffset = 0;
						yoffset = (monitor_geo.height - static_dock_region.height);
					}
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
			
			update_dock_position ();
			
			if (!screen_is_composited
				|| old_region.x != static_dock_region.x
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
			if (draw_values.size == 0) {
				debug ("Without draw_values there is trouble ahead");
				update_draw_values (controller.VisibleItems);
			}
			
			var draw_value = draw_values[item];
			if (draw_value == null) {
				warning ("Without a draw_value there is trouble ahead for '%s'", item.Text);
				draw_value = new DockItemDrawValue ();
			}
			
			return draw_value;
		}
		
		/**
		 * Update and recalculated all internal draw-values using the given methodes for custom manipulations.
		 *
		 * @param items the ordered list of all current item which are suppose to be shown on the dock
		 * @param func a function which adjusts the draw-value per item
		 * @param post_func a function which post-processes all draw-values
		 */
		public void update_draw_values (Gee.ArrayList<unowned DockItem> items, DrawValueFunc? func = null,
			DrawValuesFunc? post_func = null)
		{
			unowned DockPreferences prefs = controller.prefs;
			unowned DockRenderer renderer = controller.renderer;
			
			draw_values.clear ();
			
			// first we do the math as if this is a top dock, to do this we need to set
			// up some "pretend" variables. we pretend we are a top dock because 0,0 is
			// at the top.
			int width = DockWidth;
			int height = DockHeight;
			int icon_size = IconSize;
			
			Gdk.Point cursor = renderer.local_cursor;
			
			// "relocate" our cursor to be on the top
			switch (Position) {
			case Gtk.PositionType.RIGHT:
				cursor.x = width - cursor.x;
				break;
			case Gtk.PositionType.BOTTOM:
				cursor.y = height - cursor.y;
				break;
			default:
				break;
			}
			
			// our width and height switch around if we have a vertical dock
			if (!is_horizontal_dock ()) {
				int tmp = cursor.y;
				cursor.y = cursor.x;
				cursor.x = tmp;
				
				tmp = width;
				width = height;
				height = tmp;
			}
			
			//FIXME
			// the line along the dock width about which the center of unzoomed icons sit
			double center_y = (is_horizontal_dock () ? static_dock_region.height / 2.0 : static_dock_region.width / 2.0);
			
			double center_x = (icon_size + ItemPadding) / 2.0 + items_offset;
			if (Alignment == Gtk.Align.FILL) {
				switch (ItemsAlignment) {
				default:
				case Gtk.Align.FILL:
				case Gtk.Align.CENTER:
					if (is_horizontal_dock ())
						center_x += static_dock_region.x + (static_dock_region.width - 2 * items_offset - items_width) / 2;
					else
						center_x += static_dock_region.y + (static_dock_region.height - 2 * items_offset - items_width) / 2;
					break;
				case Gtk.Align.START:
					break;
				case Gtk.Align.END:
					if (is_horizontal_dock ())
						center_x += static_dock_region.x + (static_dock_region.width - 2 * items_offset - items_width);
					else
						center_x += static_dock_region.y + (static_dock_region.height - 2 * items_offset - items_width);
					break;
				}
			} else {
				if (is_horizontal_dock ())
					center_x += static_dock_region.x;
				else
					center_x += static_dock_region.y;
			}
			
			PointD center = { Math.floor (center_x), Math.floor (center_y) };
			
			// ZoomPercent is a number greater than 1.  It should never be less than one.
			
			// zoom_in_percent is a range of 1 to ZoomPercent.
			// We need a number that is 1 when ZoomIn is 0, and ZoomPercent when ZoomIn is 1.
			// Then we treat this as if it were the ZoomPercent for the rest of the calculation.
			bool expand_for_drop = (controller.drag_manager.ExternalDragActive && !prefs.LockItems);
			bool zoom_enabled = prefs.ZoomEnabled;
			double zoom_in_progress = (zoom_enabled || expand_for_drop ? renderer.zoom_in_progress : 0.0);
			double zoom_in_percent = (zoom_enabled ? 1.0 + (ZoomPercent - 1.0) * zoom_in_progress : 1.0);
			double zoom_icon_size = ZoomIconSize;
			
			foreach (unowned DockItem item in items) {
				DockItemDrawValue val = new DockItemDrawValue ();
				val.opacity = 1.0;
				val.darken = 0.0;
				val.lighten = 0.0;
				val.show_indicator = true;
				val.zoom = 1.0;
				
				val.static_center = center;
				
				// get us some handy doubles with fancy names
				double cursor_position = cursor.x;
				double center_position = center.x;
				
				// offset from the center of the true position, ranged between 0 and the zoom size
				double offset = double.min (Math.fabs (cursor_position - center_position), zoom_icon_size);
				
				double offset_percent;
				if (expand_for_drop) {
					// Provide space for dropping between items
					offset += offset * zoom_icon_size / icon_size;
					offset_percent = double.min (1.0, offset / (2.0 * zoom_icon_size));
				} else {
					offset_percent = offset / zoom_icon_size;
				}
				
				if (offset_percent > 0.99)
					offset_percent = 1.0;
				
				// pull in our offset to make things less spaced out
				// explaination since this is a bit tricky...
				// we have three terms, basically offset = f(x) * h(x) * g(x)
				// f(x) == offset identity
				// h(x) == a number from 0 to DockPreference.ZoomPercent - 1.  This is used to get the smooth "zoom in" effect.
				//         additionally serves to "curve" the offset based on the max zoom
				// g(x) == a term used to move the ends of the zoom inward.  Precalculated that the edges should be 66% of the current
				//         value. The center is 100%. (1 - offset_percent) == 0,1 distance from center
				// The .66 value comes from the area under the curve.  Dont ask me to explain it too much because it's too clever for me.
				
				if (expand_for_drop)
					offset *= zoom_in_progress / 2.0;
				else
					offset *= zoom_in_percent - 1.0;
				offset *= 1.0 - offset_percent / 3.0;
				
				if (cursor_position > center_position)
					center_position -= offset;
				else
					center_position += offset;
				
				// zoom is calculated as 1 through target_zoom (default 2).
				// The larger your offset, the smaller your zoom
				
				// First we get the point on our curve that defines our current zoom
				// offset is always going to fall on a point on the curve >= 0
				var zoom = 1.0 - Math.pow (offset_percent, 2);
				
				// scale this to match our zoom_in_percent
				zoom = 1.0 + zoom * (zoom_in_percent - 1.0);
				
				double zoomed_center_height = (icon_size * zoom / 2.0);
				
				if (zoom == 1.0)
					center_position = Math.round (center_position);
				
				val.center = { center_position, zoomed_center_height };
				val.zoom = zoom;
				val.icon_size = Math.round (zoom * icon_size);
				
				// now we undo our transforms to the point
				if (!is_horizontal_dock ()) {
					double tmp = val.center.y;
					val.center.y = val.center.x;
					val.center.x = tmp;
					
					tmp = val.static_center.y;
					val.static_center.y = val.static_center.x;
					val.static_center.x = tmp;
				}
				
				switch (Position) {
				case Gtk.PositionType.RIGHT:
					val.center.x = height - val.center.x;
					val.static_center.x = height - val.static_center.x;
					break;
				case Gtk.PositionType.BOTTOM:
					val.center.y = height - val.center.y;
					val.static_center.y = height - val.static_center.y;
					break;
				default:
					break;
				}
				
				//FIXME
				val.move_in (Position, bottom_offset);
				
				// let the draw-value be modified by the given function
				if (func != null)
					func (item, val);
				
				draw_values[item] = val;
				
				//FIXME
				// Don't reserve space for removed items
				if (item.RemoveTime == 0)
					center.x += icon_size + ItemPadding;
			}
			
			if (post_func != null)
				post_func (draw_values);
			
			update_background_region (draw_values[items.first ()], draw_values[items.last ()]);
			
			// precalculate and cache regions (for the current frame)
			draw_values.map_iterator ().foreach ((i, val) => {
				val.draw_region = get_item_draw_region (val);
				val.hover_region = get_item_hover_region (val);
				val.background_region = get_item_background_region (val);
				return true;
			});
		}
		/**
		 * The region for drawing a dock item.
		 *
		 * @param val the item's DockItemDrawValue
		 * @return the region for the dock item
		 */
		Gdk.Rectangle get_item_draw_region (DockItemDrawValue val)
		{
			var width = val.icon_size, height = val.icon_size;
			
			return { (int) Math.round (val.center.x - width / 2.0),
				(int) Math.round (val.center.y - height / 2.0),
				(int) width,
				(int) height };
		}
		
		/**
		 * The intersecting region of a dock item's hover region and the background.
		 *
		 * @param val the item's DockItemDrawValue
		 * @return the region for the dock item
		 */
		Gdk.Rectangle get_item_background_region (DockItemDrawValue val)
		{
			Gdk.Rectangle rect;
			var hover_region = val.hover_region;
			
			// FIXME Do this a better way
			switch (Position) {
			default:
			case Gtk.PositionType.BOTTOM:
				hover_region.height = (background_rect.y + background_rect.height - hover_region.y).abs ();
				break;
			case Gtk.PositionType.TOP:
				hover_region.y = background_rect.y;
				hover_region.height = (hover_region.y - background_rect.y + background_rect.height).abs ();
				break;
			case Gtk.PositionType.LEFT:
				hover_region.x = background_rect.x;
				hover_region.width = (hover_region.x - background_rect.x + background_rect.width).abs ();
				break;
			case Gtk.PositionType.RIGHT:
				hover_region.width = (background_rect.x + background_rect.width - hover_region.x).abs ();
				break;
			}
			
			if (!hover_region.intersect (background_rect, out rect))
				return {};
			
			return rect;
		}
		
		/**
		 * The cursor region for interacting with a dock element.
		 *
		 * @param val the item's DockItemDrawValue
		 * @return the region for the dock item
		 */
		Gdk.Rectangle get_item_hover_region (DockItemDrawValue val)
		{
			Gdk.Rectangle rect;
			
			var item_padding = ItemPadding;
			var top_padding = (top_offset < 0 ? 0 : top_offset);
			var bottom_padding = bottom_offset;
			var width = val.icon_size, height = val.icon_size;
			
			// Apply scalable padding
			switch (Position) {
			default:
			case Gtk.PositionType.BOTTOM:
				width += item_padding;
				break;
			case Gtk.PositionType.TOP:
				width += item_padding;
				break;
			case Gtk.PositionType.LEFT:
				height += item_padding;
				break;
			case Gtk.PositionType.RIGHT:
				height += item_padding;
				break;
			}
			
			rect = { (int) Math.round (val.center.x - width / 2.0),
				(int) Math.round (val.center.y - height / 2.0),
				(int) width,
				(int) height };
			
			// Apply static padding
			switch (Position) {
			default:
			case Gtk.PositionType.BOTTOM:
				rect.y -= top_padding;
				rect.height += bottom_padding + top_padding;
				break;
			case Gtk.PositionType.TOP:
				rect.y -= bottom_padding;
				rect.height += bottom_padding + top_padding;
				break;
			case Gtk.PositionType.LEFT:
				rect.x -= bottom_padding;
				rect.width += bottom_padding + top_padding;
				break;
			case Gtk.PositionType.RIGHT:
				rect.x -= top_padding;
				rect.width += bottom_padding + top_padding;
				break;
			}
			
			Gdk.Rectangle background_region;
			
			if (rect.intersect (get_background_region (), out background_region))
				background_region.union (get_item_draw_region (val), out rect);
			
			return rect;
		}
		
		/**
		 * The cursor region for interacting with a dock element.
		 *
		 * @param element the dock element to find a region for
		 * @return the region for the dock item
		 */
		public Gdk.Rectangle get_hover_region_for_element (DockElement element)
		{
			unowned DockItem? item = (element as DockItem);
			if (item != null)
				return get_draw_value_for_item (item).hover_region;
			
			unowned DockContainer? container = (element as DockContainer);
			if (container == null)
				return {};
			
			unowned Gee.ArrayList<DockElement> items = container.VisibleElements;
			
			if (items.size == 0)
				return {};
			
			var first_rect = get_hover_region_for_element (items.first ());
			if (items.size == 1)
				return first_rect;
			
			var last_rect = get_hover_region_for_element (items.last ());
			
			Gdk.Rectangle result;
			first_rect.union (last_rect, out result);
			return result;
		}
		
		/**
		 * Get the item which is the nearest at the given coordinates. If a container is given
		 * the result will be restricted to its children.
		 *
		 * @param x the x position
		 * @param y the y position
		 * @param container a container or NULL 
		 */
		public unowned DockItem? get_nearest_item_at (int x, int y, DockContainer? container = null)
		{
			unowned DockItem? result = null;
			var square_distance = double.MAX;
			
			var draw_values_it = draw_values.map_iterator ();
			while (draw_values_it.next ()) {
				var val = draw_values_it.get_value ();
				var center = val.static_center;
				var new_square_distance = (x - center.x) * (x - center.x) + (y - center.y) * (y - center.y);
				if (square_distance > new_square_distance) {
					DockItem? item = (draw_values_it.get_key () as DockItem);
					if (item == null)
						continue;
					if (container == null || item.Container == container) {
						square_distance = new_square_distance;
						result = item;
					}				
				}				
			}
			
			return result;
		}
		
		/**
		 * Get the item which is the appropriate target for a drag'n'drop action.
		 * The returned item may not hovered and is meant to be used as target
		 * for e.g. DockContainer.add/move_to functions.
		 * If a container is given the result will be restricted to its children.
		 *
		 * @param container a container or NULL 
		 */
		public unowned DockItem? get_current_target_item (DockContainer? container = null)
		{
			unowned DockRenderer renderer = controller.renderer;
			var cursor = renderer.local_cursor;
			var offset = (int) ((renderer.zoom_in_progress * ZoomIconSize + ItemPadding) / 2.0);
			
			return get_nearest_item_at (cursor.x + offset, cursor.y + offset, container);
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
			var rect = get_hover_region_for_element (hovered);
			
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
			var center = get_draw_value_for_item (hovered).static_center;
			var offset = (ZoomIconSize - IconSize / 2.0);
			
			switch (Position) {
			default:
			case Gtk.PositionType.BOTTOM:
				x = (int) Math.round (center.x + win_x);
				y = (int) Math.round (center.y + win_y - offset);
				break;
			case Gtk.PositionType.TOP:
				x = (int) Math.round (center.x + win_x);
				y = (int) Math.round (center.y + win_y + offset);
				break;
			case Gtk.PositionType.LEFT:
				x = (int) Math.round (center.x + win_x + offset);
				y = (int) Math.round (center.y + win_y);
				break;
			case Gtk.PositionType.RIGHT:
				x = (int) Math.round (center.x + win_x - offset);
				y = (int) Math.round (center.y + win_y);
				break;
			}
		}
		
		/**
		 * Get's the x and y position to display a hover window for the given coordinates.
		 *
		 * @param x the resulting x position
		 * @param y the resulting y position
		 */
		public void get_hover_position_at (ref int x, ref int y)
		{
			// Any element will suffice since only the constant coordinate of center is used
			var center = get_draw_value_for_item (controller.VisibleItems.first ()).static_center;
			var offset = (ZoomIconSize - IconSize / 2.0);
			
			switch (Position) {
			default:
			case Gtk.PositionType.BOTTOM:
				y = (int) Math.round (center.y + win_y - offset);
				break;
			case Gtk.PositionType.TOP:
				y = (int) Math.round (center.y + win_y + offset);
				break;
			case Gtk.PositionType.LEFT:
				x = (int) Math.round (center.x + win_x + offset);
				break;
			case Gtk.PositionType.RIGHT:
				x = (int) Math.round (center.x + win_x - offset);
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
			var rect = get_hover_region_for_element (item);
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
			var xoffset = 0;
			var yoffset = 0;
			
			if (!screen_is_composited) {
				var offset = Offset;
				xoffset = (int) ((1 + offset / 100.0) * (monitor_geo.width - DockWidth) / 2);
				yoffset = (int) ((1 + offset / 100.0) * (monitor_geo.height - DockHeight) / 2);
				
				switch (Alignment) {
				default:
				case Gtk.Align.CENTER:
				case Gtk.Align.FILL:
					break;
				case Gtk.Align.START:
					if (is_horizontal_dock ()) {
						xoffset = 0;
						yoffset = (monitor_geo.height - static_dock_region.height);
					} else {
						xoffset = (monitor_geo.width - static_dock_region.width);
						yoffset = 0;
					}
					break;
				case Gtk.Align.END:
					if (is_horizontal_dock ()) {
						xoffset = (monitor_geo.width - static_dock_region.width);
						yoffset = 0;
					} else {
						xoffset = 0;
						yoffset = (monitor_geo.height - static_dock_region.height);
					}
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
		 * Get's the padding between background and icons of the dock.
		 *
		 * @param x the horizontal padding
		 * @param y the vertical padding
		 */
		public void get_background_padding (out int x, out int y)
		{
			switch (Position) {
			default:
			case Gtk.PositionType.BOTTOM:
				x = 0;
				y = VisibleDockHeight - DockBackgroundHeight + extra_hide_offset;
				break;
			case Gtk.PositionType.TOP:
				x = 0;
				y = -(VisibleDockHeight - DockBackgroundHeight + extra_hide_offset);
				break;
			case Gtk.PositionType.LEFT:
				x = -(VisibleDockWidth - DockBackgroundWidth + extra_hide_offset);
				y = 0;
				break;
			case Gtk.PositionType.RIGHT:
				x = VisibleDockWidth - DockBackgroundWidth + extra_hide_offset;
				y = 0;
				break;
			}
		}
		
		/**
		 * Get's the region for background of the dock.
		 *
		 * @return the region for the dock background
		 */
		public Gdk.Rectangle get_background_region ()
		{
			return background_rect;
		}
		
		void update_background_region (DockItemDrawValue val_first, DockItemDrawValue val_last)
		{
			var x = 0, y = 0, width = 0, height = 0;
			
			if (screen_is_composited) {
				x = static_dock_region.x;
				y = static_dock_region.y;
				width = VisibleDockWidth;
				height = VisibleDockHeight;
			} else {
				width = DockWidth;
				height = DockHeight;
			}
			
			if (Alignment == Gtk.Align.FILL) {
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
				
				background_rect = { x, y, DockBackgroundWidth, DockBackgroundHeight };
				return;
			}
			
			var center_first = val_first.center;
			var center_last = val_last.center;
			var padding = ItemPadding + 2 * HorizPadding + 4 * LineWidth;
			var padding_first = (val_first.icon_size + padding) / 2.0;
			var padding_last = (val_last.icon_size + padding) / 2.0;
			
			switch (Position) {
			default:
			case Gtk.PositionType.BOTTOM:
				x = (int) Math.round (center_first.x - padding_first);
				y += height - DockBackgroundHeight;
				width = (int) Math.round (center_last.x - center_first.x + padding_first + padding_last);
				height = DockBackgroundHeight;
				break;
			case Gtk.PositionType.TOP:
				x = (int) Math.round (center_first.x - padding_first);
				y = 0;
				width = (int) Math.round (center_last.x - center_first.x + padding_first + padding_last);
				height = DockBackgroundHeight;
				break;
			case Gtk.PositionType.LEFT:
				x = 0;
				y = (int) Math.round (center_first.y - padding_first);
				width = DockBackgroundWidth;
				height = (int) Math.round (center_last.y - center_first.y + padding_first + padding_last);
				break;
			case Gtk.PositionType.RIGHT:
				x += width - DockBackgroundWidth;
				y = (int) Math.round (center_first.y - padding_first);
				width = DockBackgroundWidth;
				height = (int) Math.round (center_last.y - center_first.y + padding_first + padding_last);
				break;
			}
			
			background_rect = { x, y, width, height };
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
			var region = get_hover_region_for_element (item);
			
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
			window_scale_factor = controller.window.get_window ().get_scale_factor ();
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
			Gdk.Rectangle barrier = {};
			
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
