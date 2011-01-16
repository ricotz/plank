//  
//  Copyright (C) 2011 Robert Dyer
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

namespace Plank
{
	public class CompositedWindow : Gtk.Window
	{
		public CompositedWindow ()
		{
			GLib.Object (type: Gtk.WindowType.TOPLEVEL);
			
			app_paintable = true;
			decorated = false;
			resizable = false;
			double_buffered = false;
			
            set_default_colormap (get_screen ().get_rgba_colormap () ?? get_screen ().get_rgb_colormap ());
			
			realize.connect (() => {
				get_window ().set_back_pixmap (null, false);
			});
		}
		
		public override bool expose_event (EventExpose event)
		{
			var cr = cairo_create (event.window);
			
			cr.save ();
			
			cr.set_operator (Cairo.Operator.CLEAR);
			cr.rectangle (0, 0, width_request, height_request);
			cr.fill ();
			
			cr.restore ();
			
			return true;
		}
	}
}
