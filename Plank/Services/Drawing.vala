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

using Cairo;
using Gdk;
using Gtk;

namespace Plank.Services.Drawing
{
	public class Drawing : GLib.Object
	{
		static Pixbuf get_empty_pixbuf ()
		{
			Pixbuf pbuf = new Pixbuf (Colorspace.RGB, true, 8, 1, 1);
			pbuf.fill (0x00000000);
			return pbuf;
		}
		
		public static Pixbuf load_pixbuf (string icon, int size)
		{
#if VALA_0_12
			Pixbuf pbuf = null;
#else
			unowned Pixbuf pbuf = null;
#endif
			try {
				if (IconTheme.get_default ().has_icon (icon))
					pbuf = IconTheme.get_default ().load_icon (icon, size, 0);
				else if (icon.contains (".")) {
					string[] parts = icon.split (".");
					if (IconTheme.get_default ().has_icon (parts [0]))
						pbuf = IconTheme.get_default ().load_icon (parts [0], size, 0);
				}
			} catch { }
			
			if (pbuf == null)
				return get_empty_pixbuf ();
			
#if VALA_0_12
			return pbuf;
#else
			Pixbuf tmp = pbuf.copy ();
			pbuf.unref ();
			return tmp;
#endif
		}
	}
}
