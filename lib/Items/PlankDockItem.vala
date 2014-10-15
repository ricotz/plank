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

using Plank.Factories;
using Plank.Services;
using Plank.Widgets;

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
			GLib.Object (Prefs: new DockItemPreferences.with_file (file));
		}
		
		/**
		 * {@inheritDoc}
		 */
		public PlankDockItem.with_dockitem_filename (string filename)
		{
			GLib.Object (Prefs: new DockItemPreferences.with_filename (filename));
		}
		
		construct
		{
			// if plank is pinned indicate that it is running while it isnt user-visible
			Indicator = IndicatorState.SINGLE;
		}
		
		/**
		 * {@inheritDoc}
		 */
		protected override Animation on_clicked (PopupButton button, Gdk.ModifierType mod)
		{
			Application.get_default ().activate_action ("about", null);
			
			return Animation.DARKEN;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override Gee.ArrayList<Gtk.MenuItem> get_menu_items ()
		{
			return get_plank_menu_items ();
		}
		
		/**
		 * Returns a list of {@link Gtk.MenuItem}s to display in the popup menu for this item
		 *
		 * @return the {@link Gtk.MenuItem}s to display
		 */
		public static Gee.ArrayList<Gtk.MenuItem> get_plank_menu_items ()
		{
			var items = new Gee.ArrayList<Gtk.MenuItem> ();
			
			var item = create_menu_item (_("Get _Help Online..."), "help");
			item.activate.connect (() => Application.get_default ().activate_action ("help", null));
			items.add (item);
			
			item = create_menu_item (_("_Translate This Application..."), "locale");
			item.activate.connect (() => Application.get_default ().activate_action ("translate", null));
			items.add (item);
			
			items.add (new Gtk.SeparatorMenuItem ());
			
			// No explicit settings-item on elementary OS
			if (!System.is_desktop_session ("pantheon")) {
				item = new Gtk.ImageMenuItem.from_stock (Gtk.Stock.PREFERENCES, null);
				item.activate.connect (() => Application.get_default ().activate_action ("preferences", null));
				items.add (item);
			}
			
			item = new Gtk.ImageMenuItem.from_stock (Gtk.Stock.ABOUT, null);
			item.activate.connect (() => Application.get_default ().activate_action ("about", null));
			items.add (item);
			
			// No explicit quit-item on elementary OS
			if (!System.is_desktop_session ("pantheon")) {
				items.add (new Gtk.SeparatorMenuItem ());
			
				item = new Gtk.ImageMenuItem.from_stock (Gtk.Stock.QUIT, null);
				item.activate.connect (() => Application.get_default ().activate_action ("quit", null));
				items.add (item);
			}
			
			return items;
		}
	}
}
