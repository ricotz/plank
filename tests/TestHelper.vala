//
//  Copyright (C) 2015 Rico Tzschichholz
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
	public class TestDockItem : DockItem
	{
	}
	
	public static bool pixbuf_equal (Gdk.Pixbuf p1, Gdk.Pixbuf p2)
	{
		if (p1.get_colorspace () != p2.get_colorspace ())
			return false;
		
		if (p1.get_n_channels () != p2.get_n_channels ())
			return false;
		
		if (p1.get_bits_per_sample () != p2.get_bits_per_sample ())
			return false;
		
		if (p1.get_width () != p2.get_width ())
			return false;
		
		if (p1.get_height () != p2.get_height ())
			return false;
		
		if (p1.get_rowstride () != p2.get_rowstride ())
			return false;
		
		if (Memory.cmp ((void*)p1.get_pixels (), (void*)p2.get_pixels (), p1.get_byte_length ()) != 0)
			return false;

		return true;
	}
}
