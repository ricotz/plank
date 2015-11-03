//
//  Copyright (C) 2011-2012 Robert Dyer, Rico Tzschichholz
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
	 * A {@link Gtk.Window} with compositing support enabled.
	 * The default expose event will draw a completely transparent window.
	 */
	public class CompositedWindow : Gtk.Window
	{
		public CompositedWindow ()
		{
			GLib.Object (type: Gtk.WindowType.TOPLEVEL);
		}
		
		public CompositedWindow.with_type (Gtk.WindowType window_type)
		{
			GLib.Object (type: window_type);
		}
		
		construct
		{			
			app_paintable = true;
			decorated = false;
			resizable = false;
			double_buffered = false;
			
			unowned Gdk.Screen screen = get_screen ();
			set_visual (screen.get_rgba_visual () ?? screen.get_system_visual ());
		}
		
		public override bool draw (Cairo.Context cr)
		{
			cr.save ();
			cr.set_operator (Cairo.Operator.CLEAR);
			cr.paint ();
			cr.restore ();
			
			return Gdk.EVENT_STOP;
		}
	}
}
