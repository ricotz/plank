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

namespace Plank
{
	const string DBUS_PING_NAME = "Ping";
	
	const string DBUS_DOCK_INTERFACE_NAME = "net.launchpad.plank";
	const string DBUS_CLIENT_INTERFACE_NAME = "net.launchpad.plank.Client";

	/**
	 * Provide an interface to manage items of the dock
	 */
	[DBus (name = "net.launchpad.plank.Items")]
	interface DBusItemsIface : GLib.Object
	{
		/**
		 * Emmited when items are changed
		 */
		public signal void changed ();
		
		/**
		 * Add a new item for the given uri to the dock
		 *
		 * @param uri an URI
		 * @return whether it was successfully added
		 */
		public abstract bool add (string uri) throws GLib.DBusError, GLib.IOError;
		
		/**
		 * Remove an existing item for the given uri from the dock
		 *
		 * @param uri an URI
		 * @return whether it was successfully removed
		 */
		public abstract bool remove (string uri) throws GLib.DBusError, GLib.IOError;
		
		/**
		 * Returns the number of currently visible items on the dock
		 *
		 * @return the item-count
		 */
		public abstract int get_count () throws GLib.DBusError, GLib.IOError;
		
		/**
		 * Returns an array of uris of the persistent applications on the dock
		 *
		 * @return the array of uris
		 */
		public abstract string[] get_persistent_applications () throws GLib.DBusError, GLib.IOError;
		
		/**
		 * Returns an array of uris of the transient applications on the dock
		 *
		 * @return the array of uris
		 */
		public abstract string[] get_transient_applications () throws GLib.DBusError, GLib.IOError;

		/**
		 * Gets the x,y coords with the dock's position to display a hover window for an item.
		 *
		 * @param uri an URI
		 * @param x the resulting x position
		 * @param y the resulting y position
		 * @param dock_position the position of the dock
		 * @return whether it was successfully retrieved
		 */
		public abstract bool get_hover_position (string uri, out int x, out int y, out Gtk.PositionType dock_position) throws GLib.DBusError, GLib.IOError;
	}
}
