//
//  Copyright (C) 2011 Robert Dyer, Rico Tzschichholz
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
	 * A dock item for the dock itself.  Has things like about, help, quit etc.
	 */
	public class PlankDockItem : DockItem
	{
		static PlankDockItem? instance;
		
		public static unowned PlankDockItem get_instance ()
		{
			if (instance == null)
				instance = new PlankDockItem ();
			
			return instance;
		}
		
		PlankDockItem ()
		{
			GLib.Object (Prefs: new DockItemPreferences (), Text: "Plank", Icon: "plank");
		}
		
		construct
		{
			// if plank is pinned indicate that it is running while it isnt user-visible
			Indicator = IndicatorState.SINGLE;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool can_be_removed ()
		{
			return false;
		}
		
		/**
		 * {@inheritDoc}
		 */
		protected override AnimationType on_clicked (PopupButton button, Gdk.ModifierType mod, uint32 event_time)
		{
			Application.get_default ().activate_action ("preferences", null);
			
			return AnimationType.DARKEN;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override Gee.ArrayList<Gtk.MenuItem> get_menu_items ()
		{
			var items = new Gee.ArrayList<Gtk.MenuItem> ();
			
			var item = create_menu_item (_("Get _Help Online..."), "help");
			item.activate.connect (() => Application.get_default ().activate_action ("help", null));
			items.add (item);
			
			item = create_menu_item (_("_Translate This Application..."), "locale");
			item.activate.connect (() => Application.get_default ().activate_action ("translate", null));
			items.add (item);
			
			items.add (new Gtk.SeparatorMenuItem ());
			
			item = new Gtk.ImageMenuItem.from_stock (Gtk.Stock.PREFERENCES, null);
			item.activate.connect (() => Application.get_default ().activate_action ("preferences", null));
			items.add (item);
			
			item = new Gtk.ImageMenuItem.from_stock (Gtk.Stock.ABOUT, null);
			item.activate.connect (() => Application.get_default ().activate_action ("about", null));
			items.add (item);
			
			// No explicit quit-item on elementary OS
			if (!environment_is_session_desktop (XdgSessionDesktop.PANTHEON)) {
				items.add (new Gtk.SeparatorMenuItem ());
			
				item = new Gtk.ImageMenuItem.from_stock (Gtk.Stock.QUIT, null);
				item.activate.connect (() => Application.get_default ().activate_action ("quit", null));
				items.add (item);
			}
			
			return items;
		}
	}
}
