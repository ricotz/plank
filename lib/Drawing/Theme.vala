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

using Plank.Services;

namespace Plank.Drawing
{
	/**
	 * A themed renderer for windows.
	 */
	public abstract class Theme : Preferences
	{
		public const string DEFAULT_NAME = "Default";
		public const string GTK_THEME_NAME = "Gtk+";
		
		File? theme_folder;
		
		[Description(nick = "top-roundness", blurb = "The roundness of the top corners.")]
		public int TopRoundness { get; set; }
		
		[Description(nick = "bottom-roundness", blurb = "The roundness of the bottom corners.")]
		public int BottomRoundness { get; set; }
		
		[Description(nick = "line-width", blurb = "The thickness (in pixels) of lines drawn.")]
		public int LineWidth { get; set; }
		
		[Description(nick = "outer-stroke-color", blurb = "The color (RGBA) of the outer stroke.")]
		public Color OuterStrokeColor { get; set; }
		
		[Description(nick = "fill-start-color", blurb = "The starting color (RGBA) of the fill gradient.")]
		public Color FillStartColor { get; set; }
		
		[Description(nick = "fill-end-color", blurb = "The ending color (RGBA) of the fill gradient.")]
		public Color FillEndColor { get; set; }
		
		[Description(nick = "inner-stroke-color", blurb = "The color (RGBA) of the inner stroke.")]
		public Color InnerStrokeColor { get; set; }
		
		public Theme ()
		{
			theme_folder = get_theme_folder (DEFAULT_NAME);
		}
		
		public Theme.with_name (string name)
		{
			theme_folder = get_theme_folder (name);
		}
		
		/**
		 * {@inheritDoc}
		 */
		protected override void reset_properties ()
		{
			TopRoundness    = 6;
			BottomRoundness = 6;
			
			LineWidth = 1;
			
			OuterStrokeColor = { 0.1647, 0.1647, 0.1647, 1.0 };
			FillStartColor   = { 0.1647, 0.1647, 0.1647, 1.0 };
			FillEndColor     = { 0.3176, 0.3176, 0.3176, 1.0 };
			InnerStrokeColor = { 1.0, 1.0, 1.0, 1.0 };
		}
		
		/**
		 * Loads a theme for the renderer to use.
		 *
		 * @param type the type of theme to load
		 */
		public void load (string type)
		{
			// if there is no folder available, fallback to the internal defaults
			if (theme_folder == null) {
				reset_properties ();
				return;
			}
			
			init_from_file (theme_folder.get_child (type + ".theme"));
		}
		
		/**
		 * Returns the top offset.
		 *
		 * @return the top offset
		 */
		public int get_top_offset ()
		{
			return 2 * LineWidth;
		}
		
		/**
		 * Returns the bottom offset.
		 *
		 * @return the bottom offset
		 */
		public int get_bottom_offset ()
		{
			return BottomRoundness > 0 ? 2 * LineWidth : 0;
		}
		
		/**
		 * Draws a background onto the surface.
		 *
		 * @param surface the dock surface to draw on
		 */
		public void draw_background (DockSurface surface)
		{
			unowned Cairo.Context cr = surface.Context;
			
			var bottom_offset = BottomRoundness > 0 ? LineWidth : -LineWidth;
			
			var gradient = new Cairo.Pattern.linear (0, 0, 0, surface.Height);
			
			gradient.add_color_stop_rgba (0, FillStartColor.red, FillStartColor.green, FillStartColor.blue, FillStartColor.alpha);
			gradient.add_color_stop_rgba (1, FillEndColor.red, FillEndColor.green, FillEndColor.blue, FillEndColor.alpha);
			
			cr.save ();
			cr.set_source (gradient);
			
			draw_rounded_rect (cr,
				LineWidth / 2.0,
				LineWidth / 2.0,
				surface.Width - LineWidth,
				surface.Height - LineWidth / 2.0 - bottom_offset / 2.0,
				TopRoundness,
				BottomRoundness,
				LineWidth);
			cr.fill_preserve ();
			cr.restore ();
			
			cr.set_source_rgba (OuterStrokeColor.red, OuterStrokeColor.green, OuterStrokeColor.blue, OuterStrokeColor.alpha);
			cr.set_line_width (LineWidth);
			cr.stroke ();
			
			gradient = new Cairo.Pattern.linear (0, 2 * LineWidth, 0, surface.Height - 2 * LineWidth - bottom_offset);
			
			gradient.add_color_stop_rgba (0, InnerStrokeColor.red, InnerStrokeColor.green, InnerStrokeColor.blue, 0.5);
			gradient.add_color_stop_rgba ((TopRoundness > 0 ? TopRoundness : LineWidth) / (double) surface.Height, InnerStrokeColor.red, InnerStrokeColor.green, InnerStrokeColor.blue, 0.12);
			gradient.add_color_stop_rgba (1 - (BottomRoundness > 0 ? BottomRoundness : LineWidth) / (double) surface.Height, InnerStrokeColor.red, InnerStrokeColor.green, InnerStrokeColor.blue, 0.08);
			gradient.add_color_stop_rgba (1, InnerStrokeColor.red, InnerStrokeColor.green, InnerStrokeColor.blue, 0.19);
			
			cr.save ();
			cr.set_source (gradient);
			
			draw_inner_rect (cr, surface.Width, surface.Height);
			cr.stroke ();
			cr.restore ();
		}
		
		/**
		 * Similar to draw_rounded_rect, but moves in to avoid a containing rounded rect's lines.
		 *
		 * @param cr the context to draw with
		 * @param width the width of the rect
		 * @param height the height of the rect
		 */
		protected void draw_inner_rect (Cairo.Context cr, int width, int height)
		{
			var bottom_offset = BottomRoundness > 0 ? LineWidth : -LineWidth;
			
			draw_rounded_rect (cr,
				3 * LineWidth / 2.0,
				3 * LineWidth / 2.0,
				width - 3 * LineWidth,
				height - 3 * LineWidth / 2.0 - 3 * bottom_offset / 2.0,
				TopRoundness - LineWidth,
				BottomRoundness - LineWidth,
				LineWidth);
		}
		
		/**
		 * Draws a rounded rectangle.  If compositing is disabled, just draws a normal rectangle.
		 *
		 * @param cr the context to draw with
		 * @param x the x location of the rect
		 * @param y the y location of the rect
		 * @param width the width of the rect
		 * @param height the height of the rect
		 * @param top_radius the roundedness of the top edge
		 * @param bottom_radius the roundedness of the bottom edge
		 * @param line_width the line-width of the rect
		 */
		public static void draw_rounded_rect (Cairo.Context cr, double x, double y, double width, double height, double top_radius = 6.0, double bottom_radius = 6.0, double line_width = 1.0)
		{
			var min_size  = double.min (width, height);
			
			top_radius    = double.max (0, double.min (top_radius, min_size));
			bottom_radius = double.max (0, double.min (bottom_radius, min_size - top_radius));
			
			if (!Gdk.Screen.get_default ().is_composited ())
				top_radius = bottom_radius = 0.0;
			
			// if the top isnt round, we have to adjust the starting point a bit
			if (top_radius == 0.0)
				cr.move_to (x - line_width / 2.0, y);
			else
				cr.move_to (x + top_radius, y);
			
			cr.arc (x + width - top_radius,    y + top_radius,             top_radius,    -Math.PI_2, 0);
			cr.arc (x + width - bottom_radius, y + height - bottom_radius, bottom_radius, 0,           Math.PI_2);
			cr.arc (x + bottom_radius,         y + height - bottom_radius, bottom_radius, Math.PI_2,   Math.PI);
			cr.arc (x + top_radius,            y + top_radius,             top_radius,    Math.PI,     -Math.PI_2);
			cr.close_path ();
		}
		
		/**
		 * Draws a rounded horizontal line.
		 *
		 * @param cr the context to draw with
		 * @param x the x location of the line
		 * @param y the y location of the line
		 * @param width the width of the line
		 * @param height the height of the line
		 * @param is_round_left weather the left is round or not
		 * @param is_round_right weather the right is round or not
		 * @param stroke filling style of the outline
		 * @param fill filling style of the inner area
		 */
		public static void draw_rounded_line (Cairo.Context cr, double x, double y, double width, double height, bool is_round_left, bool is_round_right, Cairo.Pattern? stroke = null, Cairo.Pattern? fill = null)
		{
			if (height > width) {
				y += Math.floor ((height - width) / 2.0);
				height = width;
			}
			
			height = 2.0 * Math.floor (height / 2.0);
			
			var left_radius = is_round_left ? height / 2.0 : 0.0;
			var right_radius = is_round_right ? height / 2.0 : 0.0;
			
			cr.move_to (x + width - right_radius, y);
			cr.line_to (x + left_radius, y);
			if (is_round_left)
				cr.arc_negative (x + left_radius, y + left_radius, left_radius, -Math.PI_2, Math.PI_2);
			else
				cr.line_to (x, y + height);
			cr.line_to (x + width - right_radius, y + height);
			if (is_round_right)
				cr.arc_negative (x + width - right_radius, y + right_radius, right_radius, Math.PI_2, -Math.PI_2);
			else
				cr.line_to (x + width, y);
			cr.close_path ();
			
			if (fill != null) {
				cr.set_source (fill);
				cr.fill_preserve ();
			}
			if (stroke != null)
				cr.set_source (stroke);
			cr.stroke ();
		}
		
		/**
		 * {@inheritDoc}
		 */
		protected override void verify (string prop)
		{
			base.verify (prop);
			
			switch (prop) {
			case "TopRoundness":
				if (TopRoundness < 0)
					TopRoundness = 0;
				break;
			
			case "BottomRoundness":
				if (BottomRoundness < 0)
					BottomRoundness = 0;
				break;
			
			case "LineWidth":
				if (LineWidth < 0)
					LineWidth = 0;
				break;
			
			case "OuterStrokeColor":
				break;
			
			case "FillStartColor":
				break;
			
			case "FillEndColor":
				break;
			
			case "InnerStrokeColor":
				break;
			}
		}
		
		/**
		 * Get a sorted list of all available theme-names
		 *
		 * @return {@link Gee.ArrayList} the list of theme-names
		 */
		public static Gee.ArrayList<string> get_theme_list ()
		{
#if HAVE_GEE_0_8
			var list = new Gee.HashSet<string> ();
#else
			var list = new Gee.HashSet<string> (str_hash, str_equal);
#endif
			
			list.add (DEFAULT_NAME);
			list.add (GTK_THEME_NAME);
			
			// Look in user's themes-folder
			try {
				var enumerator = Paths.AppThemeFolder.enumerate_children ("standard::name,standard::type",
					GLib.FileQueryInfoFlags.NONE);
				FileInfo info;
				while ((info = enumerator.next_file ()) != null) {
					if (info.get_is_hidden ()
						|| info.get_file_type () != GLib.FileType.DIRECTORY)
						continue;
					
					list.add (info.get_name ());
				}
			} catch {}
			
			// Look in system's themes-folder
			try {
				var enumerator = Paths.ThemeFolder.enumerate_children ("standard::name,standard::type",
					GLib.FileQueryInfoFlags.NONE);
				FileInfo info;
				while ((info = enumerator.next_file ()) != null) {
					if (info.get_is_hidden ()
						|| info.get_file_type () != GLib.FileType.DIRECTORY)
						continue;
					
					list.add (info.get_name ());
				}
			} catch {}
			
			var result = new Gee.ArrayList<string> ();
			result.add_all (list);
#if HAVE_GEE_0_8
			result.sort ();
#else
			result.sort ((CompareFunc) strcmp);
#endif
			
			return result;
		}
		
		/**
		 * Try to get an already existing folder located in the
		 * themes folder while prefering the user's themes folder.
		 * If there is no folder found we fallback to the "Default" theme.
		 * If even that folder doesn't exist return NULL (and use built-in defaults)
		 *
		 * @param name the basename of the folder
		 * @return {@link GLib.File} the folder of the theme or NULL
		 */
		public static File? get_theme_folder (string name)
		{
			if (name == DEFAULT_NAME)
				return get_default_theme_folder ();
			
			if (name == GTK_THEME_NAME)
				return get_gtk_theme_folder ();
			
			File folder;
			
			// Look in user's themes-folder
			folder = Paths.AppThemeFolder.get_child (name);
			if (folder.query_exists ()
				&& folder.query_file_type (FileQueryInfoFlags.NONE, null) == FileType.DIRECTORY)
				return folder;
			
			// Look in system's themes-folder
			folder = Paths.ThemeFolder.get_child (name);
			if (folder.query_exists ()
				&& folder.query_file_type (FileQueryInfoFlags.NONE, null) == FileType.DIRECTORY)
				return folder;
			
			warning ("%s not found, falling back to %s.", name, DEFAULT_NAME);
			
			return get_default_theme_folder ();
		}
		
		static File? get_default_theme_folder ()
		{
			File folder;
			
			// "Default" folder located in system's themes-folder
			folder = Paths.ThemeFolder.get_child (DEFAULT_NAME);
			if (folder.query_exists ()
				&& folder.query_file_type (FileQueryInfoFlags.NONE, null) == FileType.DIRECTORY)
				return folder;
			
			warning ("%s is not a folder fallback to the built-in defaults!", folder.get_path ());
			
			return null;
		}
		
		static File? get_gtk_theme_folder ()
		{
			File folder;
			unowned string exec_name = Paths.AppName;
			var name = Gtk.Settings.get_default ().gtk_theme_name;
					
			// Look in user's xdg-themes-folder
			folder = Paths.DataHomeFolder.get_child ("themes/%s".printf (name));
			if (folder.query_exists ()) {
				folder = folder.get_child (exec_name);
				if (folder.query_exists ()
					&& folder.query_file_type (FileQueryInfoFlags.NONE, null) == FileType.DIRECTORY)
					return folder;
				
				warning ("Currently selected gtk+ theme '%s' does not provide a dock theme, fallback to the built-in defaults!", name);
				return null;
			}
			
			// Look in user's legacy xdg-themes-folder
			folder = Paths.HomeFolder.get_child (".themes/%s".printf (name));
			if (folder.query_exists ()) {
				folder = folder.get_child (exec_name);
				if (folder.query_exists ()
					&& folder.query_file_type (FileQueryInfoFlags.NONE, null) == FileType.DIRECTORY)
					return folder;
				
				warning ("Currently selected gtk+ theme '%s' does not provide a dock theme, fallback to the built-in defaults!", name);
				return null;
			}
			
			// Look in system's xdg-themes-folders
			foreach (var datafolder in Paths.DataDirFolders) {
				folder = datafolder.get_child ("themes/%s/%s".printf (name, exec_name));
				if (folder.query_exists ()
					&& folder.query_file_type (FileQueryInfoFlags.NONE, null) == FileType.DIRECTORY)
					return folder;
			}
			
			warning ("Currently selected gtk+ theme '%s' does not provide a dock theme, fallback to the built-in defaults!", name);
			return null;
		}
	}
}
