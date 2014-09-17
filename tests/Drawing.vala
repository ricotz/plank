//
//  Copyright (C) 2013 Rico Tzschichholz
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

using Plank.Drawing;
using Plank.Items;

namespace Plank.Tests
{
	public static void register_drawing_tests ()
	{
		Test.add_func ("/Drawing/Color/basics", drawing_color);
		
		Test.add_func ("/Drawing/DrawingService/basics", drawing_drawingservice);
		Test.add_func ("/Drawing/DrawingService/average_color", drawing_drawingservice_average_color);
		
		Test.add_func ("/Drawing/DockSurface/basics", drawing_docksurface);
		Test.add_func ("/Drawing/DockSurface/exponential_blur", drawing_docksurface_exponential_blur);
		Test.add_func ("/Drawing/DockSurface/fast_blur", drawing_docksurface_fast_blur);
		Test.add_func ("/Drawing/DockSurface/gaussian_blur", drawing_docksurface_gaussian_blur);
		Test.add_func ("/Drawing/DockSurface/to_pixbuf", drawing_docksurface_to_pixbuf);
		
		Test.add_func ("/Drawing/Theme/basics", drawing_theme);
	}
	
	void drawing_color ()
	{
		Drawing.Color color, color2, color3;
		double h, s, v;
		
		color = { 0.5, 0.5, 0.5, 0.5 };
		color2 = { 0.5, 0.5, 0.5, 0.5 };
		assert (color.equal (color2));
		
		color3 = color;
		color3.red = 0.75;
		color3.green = 0.37;
		color3.blue = 0.66;
		color3.alpha = 0.97;
		assert (!color.equal (color3));
		
		color.get_hsv (out h, out s, out v);
		color2.set_hsv (h, s, v);
		assert (color.equal (color2));
		
		assert (color.get_hue () == 0.0);

		color = color3;
		color.set_hue (187);
		assert (color.get_hue () == 187);
		
		color = color3;
		color.set_sat (0.75);
		assert (color.get_sat () == 0.75);
		
		color = color3;
		color.set_val (0.75);
		assert (color.get_val () == 0.75);
		
		color = color3;
		color.set_hue (187);
		color.add_hue (15);
		assert (color.get_hue () == 202);
		
		color = color3;
		color.set_sat (0.35);
		color.multiply_sat (2.0);
		assert (color.get_sat () == 0.7);
		
		color = Drawing.Color.from_prefs_string ("123;;234;;123;;234");
		assert (color.to_prefs_string () == "123;;234;;123;;234");
	}
	
	void drawing_drawingservice ()
	{
		var icon = DrawingService.load_icon (TEST_ICON, 256, 256);
		assert (icon != null);
		assert (icon.width == 256);
		assert (icon.height == 256);
		
		icon = DrawingService.ar_scale (icon, 127, 127);
		assert (icon != null);
		assert (icon.width == 127);
		assert (icon.height == 127);
		
		var icon2 = DrawingService.load_icon (TEST_ICON, 256, 256);
		icon2 = DrawingService.ar_scale (icon2, 1, 1);
		assert (icon2 != null);
		assert (icon2.width == 1);
		assert (icon2.height == 1);
		
		var icon_copy = icon.copy ();
		var color = DrawingService.average_color (icon);
		var color_copy = DrawingService.average_color (icon_copy);
		assert (color.equal (color_copy));
	}
	
	void drawing_drawingservice_average_color ()
	{
		// fully transparent surface
		drawing_drawingservice_average_color_helper ({ 0.0, 0.0, 0.0, 0.0 }, 0.0);
		
		// fully black surface
		drawing_drawingservice_average_color_helper ({ 0.0, 0.0, 0.0, 1.0 }, 0.0);
		
		// fully grey surface
		drawing_drawingservice_average_color_helper ({ 0.5, 0.5, 0.5, 1.0 }, 0.02);
		
		// fully white surface
		drawing_drawingservice_average_color_helper ({ 1.0, 1.0, 1.0, 1.0 }, 0.0);
	}
	
	void drawing_drawingservice_average_color_helper (Drawing.Color color, double delta)
	{
		Drawing.Color average;
		Drawing.DockSurface surface;
		surface = new DockSurface (256, 256);
		unowned Cairo.Context cr = surface.Context;
		
		cr.set_source_rgba (color.red, color.green, color.blue, color.alpha);
		cr.set_operator (Cairo.Operator.SOURCE);
		cr.paint ();
		average = surface.average_color ();
		
		assert ((Math.fabs (average.red - color.red) <= delta) && (Math.fabs (average.green - color.green) <= delta)
			&& (Math.fabs (average.blue - color.blue) <= delta) && (Math.fabs (average.alpha - color.alpha) <= delta));
	}

	void drawing_docksurface ()
	{
		Drawing.DockSurface surface, surface2, surface3;
		Gdk.Pixbuf pixbuf;
		
		surface = new DockSurface (256, 256);
		surface2 = new DockSurface.with_dock_surface (256, 256, new DockSurface (1, 1));
		surface3 = new DockSurface.with_surface (256, 256, new DockSurface (1, 1).Internal);
		
		surface.clear ();
		surface2.clear ();
		surface3.clear ();
		
		assert (surface.Width == surface2.Width);
		assert (surface.Height == surface2.Height);
		assert (surface.Width == surface3.Width);
		assert (surface.Height == surface3.Height);
		
		pixbuf = surface.to_pixbuf ();
		assert (surface.Width == pixbuf.width);
		assert (surface.Height == pixbuf.height);
	}
	
	void drawing_docksurface_fast_blur ()
	{
		Drawing.Color color, color2;
		Drawing.DockSurface surface, surface2;
		Gdk.Pixbuf pixbuf;
		
		pixbuf = DrawingService.load_icon (TEST_ICON, 256, 256);
		surface = new DockSurface (256, 256);
		surface2 = new DockSurface (256, 256);
		
		unowned Cairo.Context cr = surface.Context;
		Gdk.cairo_set_source_pixbuf (cr, pixbuf, 0, 0);
		cr.paint ();
		
		unowned Cairo.Context cr2 = surface2.Context;
		Gdk.cairo_set_source_pixbuf (cr2, pixbuf, 0, 0);
		cr2.paint ();
		
		surface.fast_blur (7, 3);
		surface.fast_blur (15, 3);
		surface.fast_blur (31, 3);
		surface2.fast_blur (7, 3);
		surface2.fast_blur (15, 3);
		surface2.fast_blur (31, 3);
		
		color = surface.average_color ();
		color2 = surface2.average_color ();
		assert (color.equal (color2));
	}
	
	void drawing_docksurface_exponential_blur ()
	{
		Drawing.Color color, color2;
		Drawing.DockSurface surface, surface2;
		Gdk.Pixbuf pixbuf;
		
		pixbuf = DrawingService.load_icon (TEST_ICON, 256, 256);
		surface = new DockSurface (256, 256);
		surface2 = new DockSurface (256, 256);
		
		unowned Cairo.Context cr = surface.Context;
		Gdk.cairo_set_source_pixbuf (cr, pixbuf, 0, 0);
		cr.paint ();
		
		unowned Cairo.Context cr2 = surface2.Context;
		Gdk.cairo_set_source_pixbuf (cr2, pixbuf, 0, 0);
		cr2.paint ();
		
		surface.exponential_blur (7);
		surface.exponential_blur (15);
		surface.exponential_blur (31);
		surface2.exponential_blur (7);
		surface2.exponential_blur (15);
		surface2.exponential_blur (31);
		
		color = surface.average_color ();
		color2 = surface2.average_color ();
		assert (color.equal (color2));
	}
	
	void drawing_docksurface_gaussian_blur ()
	{
		Drawing.Color color, color2;
		Drawing.DockSurface surface, surface2;
		Gdk.Pixbuf pixbuf;
		
		pixbuf = DrawingService.load_icon (TEST_ICON, 256, 256);
		surface = new DockSurface (256, 256);
		surface2 = new DockSurface (256, 256);
		
		unowned Cairo.Context cr = surface.Context;
		Gdk.cairo_set_source_pixbuf (cr, pixbuf, 0, 0);
		cr.paint ();
		
		unowned Cairo.Context cr2 = surface2.Context;
		Gdk.cairo_set_source_pixbuf (cr2, pixbuf, 0, 0);
		cr2.paint ();
		
		surface.gaussian_blur (7);
		surface.gaussian_blur (15);
		surface.gaussian_blur (31);
		surface2.gaussian_blur (7);
		surface2.gaussian_blur (15);
		surface2.gaussian_blur (31);
		
		color = surface.average_color ();
		color2 = surface2.average_color ();
		assert (color.equal (color2));
	}
	
	void drawing_docksurface_to_pixbuf ()
	{
		Drawing.Color color, color2;
		Drawing.DockSurface surface, surface2;
		Gdk.Pixbuf pixbuf, pixbuf2;
		
		pixbuf = DrawingService.load_icon (TEST_ICON, 256, 256);
		surface = new DockSurface (256, 256);
		surface2 = new DockSurface (256, 256);
		
		unowned Cairo.Context cr = surface.Context;
		Gdk.cairo_set_source_pixbuf (cr, pixbuf, 0, 0);
		cr.paint ();
		
		unowned Cairo.Context cr2 = surface2.Context;
		Gdk.cairo_set_source_pixbuf (cr2, pixbuf, 0, 0);
		cr2.paint ();
		
		pixbuf = surface.to_pixbuf ();
		pixbuf2 = surface2.to_pixbuf ();
		
		color = DrawingService.average_color (pixbuf);
		color2 = DrawingService.average_color (pixbuf2);
		assert (color.equal (color2));
	}
	
	void drawing_theme ()
	{
		Drawing.DockSurface surface, surface2, surface3;
		DockTheme docktheme;
		
		surface = new DockSurface (512, 512);
		
		surface.clear ();
		docktheme = new DockTheme ("Test");
		docktheme.draw_background (surface);
		
		surface.clear ();
		Drawing.Color color = { 0.5, 0.4, 0.3, 1.0 };
		
		docktheme.draw_item_count (surface, 64, color, 42);
		docktheme.draw_item_progress (surface, 64, color, 0.7);
		
		surface2 = docktheme.create_indicator (64, color, surface);
		surface2 = docktheme.create_urgent_glow (512, color, surface);
		
		surface2 = docktheme.create_background (1024, 256, Gtk.PositionType.RIGHT, surface);
		surface3 = docktheme.create_background (256, 1024, Gtk.PositionType.BOTTOM, surface);
		assert (DrawingService.average_color (surface2.to_pixbuf ()).equal (DrawingService.average_color (surface3.to_pixbuf ())));
	}
}
