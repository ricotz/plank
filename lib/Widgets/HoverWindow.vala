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
using Pango;

using Plank.Drawing;

namespace Plank.Widgets
{
	/**
	 * A hover window that shows labels for dock items.
	 * This window floats outside (but near) the dock.
	 * The window uses a themed renderer and has its own theme file.
	 */
	public class HoverWindow : CompositedWindow
	{
		const int PADDING = 10;
		
		public DockController controller { private get; construct; }
		
		/**
		 * The text to display in the window.
		 */
		public string Text { get; set; default = ""; }
		
		DockSurface? background_buffer = null;
		
		HoverTheme theme;
		
		Pango.Layout layout;
		
		double text_offset;
		
		public HoverWindow (DockController controller)
		{
			GLib.Object (controller: controller, type: Gtk.WindowType.POPUP, type_hint: WindowTypeHint.TOOLTIP);
		}
		
		construct
		{
			accept_focus = false;
			can_focus = false;
			skip_pager_hint = true;
			skip_taskbar_hint = true;
			
			set_redraw_on_allocate (true);
			
			load_theme ();
			
			update_layout ();
			style_set.connect (() => update_layout ());
			
			notify["Text"].connect (invalidate);
			
			controller.prefs.notify["Theme"].connect (load_theme);
			
			stick ();
			show_all ();
			hide ();
		}
		
		void theme_changed ()
		{
			background_buffer = null;
			queue_draw ();
		}
		
		void load_theme ()
		{
			var is_reload = (theme != null);
			
			if (is_reload)
				theme.notify.disconnect (theme_changed);
			
			theme = new HoverTheme (controller.prefs.Theme);
			theme.load ("hover");
			theme.notify.connect (theme_changed);
			
			if (is_reload)
				theme_changed ();
		}
		
		/**
		 * Centers the window at the x/y location specified.
		 *
		 * @param item_x the x location
		 * @param item_y the y location
		 */
		public void move_hover (int item_x, int item_y)
		{
			var x = 0, y = 0;
			
			switch (controller.prefs.Position) {
			case PositionType.BOTTOM:
				x = item_x - width_request / 2;
				y = item_y - height_request - PADDING;
				break;
			case PositionType.TOP:
				x = item_x - width_request / 2;
				y = item_y + PADDING;
				break;
			case PositionType.LEFT:
				y = item_y - height_request / 2;
				x = item_x + PADDING;
				break;
			case PositionType.RIGHT:
				y = item_y - height_request / 2;
				x = item_x - width_request - PADDING;
				break;
			}
			
			unowned Screen screen = get_screen ();
			Gdk.Rectangle monitor;
			screen.get_monitor_geometry (screen.get_monitor_at_point (item_x, item_y), out monitor);
			
			x = int.max (monitor.x, int.min (x, monitor.x + monitor.width - width_request));
			y = int.max (monitor.y, int.min (y, monitor.y + monitor.height - height_request));
			
			show ();
			Gdk.flush ();
			move (x, y);
			Gdk.flush ();
			hide ();
			Gdk.flush ();
		}
		
		void update_layout ()
		{
			layout = new Pango.Layout (pango_context_get ());
			layout.set_ellipsize (EllipsizeMode.END);
			
			unowned FontDescription font_description = get_style_context ().get_font (StateFlags.NORMAL);
			font_description.set_size ((int) (9 * Pango.SCALE));
			font_description.set_weight (Weight.BOLD);
			layout.set_font_description (font_description);
			
			invalidate ();
		}
		
		void invalidate ()
		{
			unowned Screen screen = get_screen ();
			var max_width = 0.8 * screen.get_width ();
			
			background_buffer = null;
			
			if (Text == "")
				Text = " ";
			
			// calculate the text layout to find the size
			layout.set_text (Text, -1);
			
			// make the buffer
			Pango.Rectangle logical_rect;
			layout.get_pixel_extents (null, out logical_rect);
			if (logical_rect.width > max_width) {
				layout.set_width ((int) (max_width * Pango.SCALE));
				layout.get_pixel_extents (null, out logical_rect);
			}
			
			var buffer = (int) (logical_rect.height / 4.0) * 2;
			text_offset = buffer / 2;
			
			set_size_request (logical_rect.width + buffer, logical_rect.height + buffer);
			queue_resize ();
		}
		
		void draw_background ()
		{
			background_buffer = new DockSurface (width_request, height_request);
			
			// draw the background
			theme.draw_background (background_buffer);
			
			// draw the text
			unowned Cairo.Context cr = background_buffer.Context;
			cr.move_to (text_offset, text_offset);
			cr.set_source_rgb (1, 1, 1);
			Pango.cairo_show_layout (cr, layout);
		}
		
		public override bool draw (Cairo.Context cr)
		{
			if (background_buffer == null || background_buffer.Height != height_request || background_buffer.Width != width_request)
				draw_background ();
			
			cr.set_operator (Operator.SOURCE);
			cr.set_source_surface (background_buffer.Internal, 0, 0);
			cr.paint ();
			
			return true;
		}
	}
}
