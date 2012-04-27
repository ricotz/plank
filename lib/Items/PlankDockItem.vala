//  
//  Copyright (C) 2011 Robert Dyer, Rico Tzschichholz
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

using Plank.Factories;

namespace Plank.Items
{
	/**
	 * A dock item for the dock itself.  Has things like about, help, quit etc.
	 */
	public class PlankDockItem : ApplicationDockItem
	{
		/**
		 * {@inheritDoc}
		 */
		public PlankDockItem.with_dockitem_file (GLib.File file)
		{
			base.with_dockitem_file (file);
		}
		
		/**
		 * {@inheritDoc}
		 */
		public PlankDockItem.with_dockitem_filename (string filename)
		{
			base.with_dockitem_filename (filename);
		}
		
		/**
		 * {@inheritDoc}
		 */
		protected override ClickAnimation on_clicked (PopupButton button, ModifierType mod)
		{
			Factory.main.on_item_clicked ();
			return ClickAnimation.DARKEN;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override ArrayList<Gtk.MenuItem> get_menu_items ()
		{
			return get_plank_menu_items ();
		}
		
		/**
		 * Returns a list of {@link Gtk.MenuItem}s to display in the popup menu for this item
		 *
		 * @return the {@link Gtk.MenuItem}s to display
		 */
		public static ArrayList<Gtk.MenuItem> get_plank_menu_items ()
		{
			var items = new ArrayList<Gtk.MenuItem> ();
			
			var item = create_menu_item (_("Get _Help Online..."), "help");
			item.activate.connect (() => Factory.main.help ());
			items.add (item);
			
			item = create_menu_item (_("_Translate This Application..."), "locale");
			item.activate.connect (() => Factory.main.translate ());
			items.add (item);
			
			items.add (new SeparatorMenuItem ());
			
			item = new ImageMenuItem.from_stock (Gtk.Stock.ABOUT, null);
			item.activate.connect (() => Factory.main.show_about ());
			items.add (item);
			
			items.add (new SeparatorMenuItem ());
			
			item = new ImageMenuItem.from_stock (Gtk.Stock.QUIT, null);
			item.activate.connect (() => Factory.main.quit ());
			items.add (item);
			
			return items;
		}
	}
}
