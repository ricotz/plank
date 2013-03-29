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

using Cairo;
using Gdk;

using Plank.Drawing;
using Plank.Items;

namespace Plank.Tests
{
	public static void register_drawing_tests ()
	{
		Test.add_func ("/Drawing/Color", drawing_color);
		
		Test.add_func ("/Drawing/DrawingService", drawing_drawingservice);
		Test.add_func ("/Drawing/DrawingService/average_color", drawing_drawingservice_average_color);
		
		Test.add_func ("/Drawing/DockSurface", drawing_docksurface);
		Test.add_func ("/Drawing/DockSurface/blur", drawing_docksurface_blur);
		
		Test.add_func ("/Drawing/Theme", drawing_theme);
	}
	
	void drawing_color ()
	{
		Drawing.Color color, color2, color3;
		Gdk.RGBA gdkrgba;
		Gdk.Color gdkcolor;
		double h, s, v;
		
		color = { 0.5, 0.5, 0.5, 0.5 };
		color2 = { 0.5, 0.5, 0.5, 0.5 };
		assert (color == color2);
		
		color3 = color;
		color3.R = 0.7;
		color3.G = 0.7;
		color3.B = 0.7;
		color3.A = 0.7;
		assert (color != color3);
		
		color.get_hsv (out h, out s, out v);
		color2.set_hsv (h, s, v);
		assert (color == color2);
		
		color = color3;
		color.set_hue (187);
		//FIXME assert (color.get_hue () == 187);
		
		color = color3;
		color.set_sat (0.75);
		assert (color.get_sat () == 0.75);
		
		color = color3;
		color.set_val (0.75);
		assert (color.get_val () == 0.75);
		
		color = color3;
		color.set_hue (187);
		color.add_hue (15);
		//FIXME assert (color.get_hue () == 202);
		
		color = color3;
		color.set_sat (0.35);
		color.multiply_sat (2.0);
		assert (color.get_sat () == 0.7);
		
		color = Drawing.Color.from_string ("123;;234;;123;;234");
		assert (color.to_string () == "123;;234;;123;;234");
		
		gdkrgba = { 0.5, 0.5, 0.5, 0.5 };
		color = Drawing.Color.from_gdk_rgba (gdkrgba);
		assert (color.to_gdk_rgba () == gdkrgba);
		
		gdkcolor = Gdk.Color () { red = 32768, green = 32768, blue = 32768 };
		color = Drawing.Color.from_gdk_color (gdkcolor);
		assert (color.to_gdk_color () == gdkcolor);
	}
	
	void drawing_drawingservice ()
	{
		var icon = DrawingService.load_icon (PLANK_ICON, 256, 256);
		assert (icon != null);
		assert (icon.width == 256);
		assert (icon.height == 256);
		
		icon = DrawingService.ar_scale (icon, 127, 127);
		assert (icon != null);
		assert (icon.width == 127);
		assert (icon.height == 127);
		
		var icon_copy = icon.copy ();
		var color = DrawingService.average_color (icon);
		var color_copy = DrawingService.average_color (icon_copy);
		assert (color == color_copy);
	}
	
	void drawing_drawingservice_average_color ()
	{
		Drawing.Color color;
		Drawing.DockSurface surface;
		
		surface = new DockSurface (256, 256);
		
		unowned Context cr = surface.Context;
		
		// fully transparent surface
		cr.set_source_rgba (0.0, 0.0, 0.0, 0.0);
		cr.set_operator (Operator.SOURCE);
		cr.paint ();
		color = surface.average_color ();
		assert (color == Drawing.Color () { R = 0.0, G = 0.0, B = 0.0, A = 0.0 });
		
		// fully black surface
		cr.set_source_rgba (0.0, 0.0, 0.0, 1.0);
		cr.set_operator (Operator.SOURCE);
		cr.paint ();
		color = surface.average_color ();
		assert (color == Drawing.Color () { R = 0.0, G = 0.0, B = 0.0, A = 1.0 });
		
		// fully white surface
		cr.set_source_rgba (1.0, 1.0, 1.0, 1.0);
		cr.set_operator (Operator.SOURCE);
		cr.paint ();
		color = surface.average_color ();
		assert (color == Drawing.Color () { R = 1.0, G = 1.0, B = 1.0, A = 1.0 });
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
	
	void drawing_docksurface_blur ()
	{
		Drawing.Color color, color2;
		Drawing.DockSurface surface, surface2;
		Gdk.Pixbuf pixbuf, pixbuf2;
		
		pixbuf = DrawingService.load_icon (PLANK_ICON, 256, 256);
		surface = new DockSurface (256, 256);
		surface2 = new DockSurface (256, 256);
		
		unowned Context cr = surface.Context;
		cairo_set_source_pixbuf (cr, pixbuf, 0, 0);
		cr.paint ();
		
		unowned Context cr2 = surface2.Context;
		cairo_set_source_pixbuf (cr2, pixbuf, 0, 0);
		cr2.paint ();
		
		surface.gaussian_blur (7);
		surface.fast_blur (7, 3);
		surface.exponential_blur (7);
		
		surface2.gaussian_blur (7);
		surface2.fast_blur (7, 3);
		surface2.exponential_blur (7);
		
		color = surface.average_color ();
		color2 = surface2.average_color ();
		assert (color == color2);
		
		pixbuf = surface.to_pixbuf ();
		pixbuf2 = surface2.to_pixbuf ();
		
		color = DrawingService.average_color (pixbuf);
		color2 = DrawingService.average_color (pixbuf2);
		assert (color == color2);
	}
	
	void drawing_theme ()
	{
		Drawing.DockSurface surface;
		DockTheme docktheme;
		HoverTheme hovertheme;
		
		surface = new DockSurface (512, 256);
		
		//TODO initalize special testing paths
		//docktheme = new DockTheme ("dock");
		//hovertheme = new HoverTheme ("hover");
	}
}
