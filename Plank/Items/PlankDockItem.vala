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
using Gee;
using Gtk;

namespace Plank.Items
{
	public class PlankDockItem : ApplicationDockItem
	{
		public PlankDockItem.with_dockitem (string dockitem)
		{
			base.with_dockitem (dockitem);
		}
		
		protected override ClickAnimation on_clicked (uint button, ModifierType mod)
		{
			Plank.show_about ();
			return ClickAnimation.DARKEN;
		}
		
		public override ArrayList<MenuItem> get_menu_items ()
		{
			ArrayList<MenuItem> items = new ArrayList<MenuItem> ();
			
			var item = new ImageMenuItem.from_stock (STOCK_ABOUT, null);
			item.activate.connect (() => Plank.show_about ());
			items.add (item);
			
			item = new ImageMenuItem.from_stock (STOCK_QUIT, null);
			item.activate.connect (() => Plank.quit ());
			items.add (item);
			
			return items;
		}
	}
}
