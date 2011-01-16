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

namespace Plank.Items
{
	public class DockItem : GLib.Object
	{
		public string Icon { get; set; default = "folder"; }
		
		public string Text { get; set; default = ""; }
		
		public int Position { get; set; default = 0; }
		
		protected DockItemPreferences Prefs { get; protected set; }
		
		public DockItem ()
		{
			Prefs = new DockItemPreferences ();
		}
		
		public int get_sort ()
		{
			return Prefs.Sort;
		}
		
		public void set_sort (int pos)
		{
			if (Prefs.Sort!= pos)
				Prefs.Sort = pos;
		}
		
		public string get_launcher ()
		{
			return Prefs.Launcher;
		}
	}
}
