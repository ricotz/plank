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

using Gdk;

namespace Plank.Widgets
{
	/**
	 * A {@link Gtk.Window} with compositing support enabled.
	 * The default expose event will draw a completely transparent window.
	 */
	public class CompositedWindow : Gtk.Window
	{
		public CompositedWindow ()
		{
			this.with_type (Gtk.WindowType.TOPLEVEL);
		}
		
		public CompositedWindow.with_type (Gtk.WindowType window_type)
		{
			GLib.Object (type: window_type);
			
			app_paintable = true;
			decorated = false;
			resizable = false;
			double_buffered = false;
			
			var screen = get_screen ();
#if USE_GTK2
			set_default_colormap (screen.get_rgba_colormap () ?? screen.get_rgb_colormap ());
			
			realize.connect (() => {
				get_window ().set_back_pixmap (null, false);
			});
#else
			set_visual (screen.get_rgba_visual () ?? screen.get_system_visual ());
#endif
		}
		
#if USE_GTK2
		public override bool expose_event (EventExpose event)
		{
			var cr = cairo_create (event.window);
#else
		public override bool draw (Cairo.Context cr)
		{
#endif
			cr.set_operator (Cairo.Operator.CLEAR);
			cr.rectangle (0, 0, width_request, height_request);
			cr.fill ();
			
			return true;
		}
	}
}
