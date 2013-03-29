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
	public static void register_items_tests ()
	{
		Test.add_func ("/Items/DockItem", items_dockitem);
	}
	
	void items_dockitem ()
	{
		DockItem item, item2;
		
		item = new DockItem ();
		item.Text = "Plank";
		item.Icon = PLANK_ICON;
		item.Count = 42;
		item.CountVisible = true;
		item.Progress = 0.42;
		item.ProgressVisible = true;
		item.Position = 1;
		
		assert (item.Text == "Plank");
		assert (item.Icon == PLANK_ICON);
		assert (item.Count == 42);
		assert (item.CountVisible == true);
		assert (item.Progress == 0.42);
		assert (item.ProgressVisible == true);
		assert (item.Position == 1);
		
		item2 = new DockItem ();
		item.copy_values_to (item2);
		assert (item.Count == item2.Count);
		assert (item.CountVisible == item2.CountVisible);
		assert (item.Icon == item2.Icon);
		assert (item.Position == item2.Position);
		assert (item.Progress == item2.Progress);
		assert (item.ProgressVisible == item2.ProgressVisible);
		assert (item.Text == item2.Text);
		
		var icon = item.get_surface_copy (64, 64, new DockSurface (1, 1));
		assert (icon != null);
		assert (icon.Width == 64);
		assert (icon.Height == 64);
	}
}
