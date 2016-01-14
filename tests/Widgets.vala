//
//  Copyright (C) 2013 Rico Tzschichholz
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

using Plank;

namespace PlankTests
{
	public static void register_widgets_tests ()
	{
		Test.add_func ("/Widgets/CompositedWindow/basics", composited_window_basics);
		Test.add_func ("/Widgets/PoofWindow/basics", poof_window_basics);
		Test.add_func ("/Widgets/HoverWindow/basics", hover_window_basics);
	}
	
	void composited_window_basics ()
	{
		CompositedWindow window, window2;
		int x, y, width, height;
		
		window = new CompositedWindow ();
		window.move (100, 100);
		window.set_size_request (300, 300);
		window.show_all ();
		
		wait (X_WAIT_MS);
		
		window.get_position (out x, out y);
		window.get_size (out width, out height);
		assert (window.visible == true);
		assert (x == 100);
		assert (y == 100);
		assert (width == 300);
		assert (height == 300);

		window2 = new CompositedWindow.with_type (Gtk.WindowType.POPUP);
		window2.move (50, 50);
		window2.set_size_request (100, 100);
		window2.show_all ();
		
		wait (X_WAIT_MS);
		
		window2.get_position (out x, out y);
		window2.get_size (out width, out height);
		assert (window2.visible == true);
		assert (x == 50);
		assert (y == 50);
		assert (width == 100);
		assert (height == 100);
	}
	
	void poof_window_basics ()
	{
		PoofWindow window;
		unowned PoofWindow default_window;
		
		default_window = PoofWindow.get_default ();
		
		window = new PoofWindow ();
		window.show_at (100, 100);
		
		wait (X_WAIT_MS);
		
		window.show_at (200, 200);
		
		wait (X_WAIT_MS);
	}
	
	void hover_window_basics ()
	{
		HoverWindow window;
		
		window = new HoverWindow ();
		window.set_text ("TEST");
		
		window.show_at (200, 200, Gtk.PositionType.BOTTOM);
		window.show_at (200, 200, Gtk.PositionType.TOP);
		window.show_at (200, 200, Gtk.PositionType.LEFT);
		window.show_at (200, 200, Gtk.PositionType.RIGHT);
		
		wait (X_WAIT_MS);
		
		window = null;
		
		wait (X_WAIT_MS);
	}
}

