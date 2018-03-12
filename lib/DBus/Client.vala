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
	/**
	 * Connects to a running instance of plank via DBus and
	 * provides remote interface to a currently runnning dock.
	 */
	public class DBusClient : GLib.Object
	{
		static DBusClient? instance;
		
		/**
		 * Get the singleton instance of {@link Plank.DBusClient}
		 */
		public static unowned DBusClient get_instance ()
		{
			if (instance == null)
				instance = new DBusClient ();
			
			return instance;
		}
		
		/**
		 * If the proxy interfaces for the dock are ready to be used
		 * or were changed on runtime this signal will be emitted.
		 */
		public signal void proxy_changed ();
		
		/**
		 * Whether the client is in an operatable state and connected to
		 * a running dock
		 */
		public bool is_connected {
			get {
				return (items_proxy != null);
			}
		}
		
		DBusConnection? connection = null;
		string? client_object_path;
		
		string? dock_bus_owner;
		string? dock_bus_name;
		string? dock_object_path;
		
		uint dbus_dock_ping_id = 0;
		uint dbus_name_owner_changed_signal_id = 0;
		
		DBusItemsIface? items_proxy = null;
		int items_count = int.MIN;
		string[]? persistent_apps_list = null;
		string[]? transient_apps_list = null;
		
		DBusClient ()
		{
			Object ();
		}
		
		construct
		{
			unowned Application? application = GLib.Application.get_default ();
			string? object_path = null;
			
			if (application != null) {
				connection = application.get_dbus_connection ();
				object_path = application.get_dbus_object_path ();
			}
			
			if (connection == null || object_path == null) {
				critical ("Initializing client failed");
				return;
			}
			
			try {
				// Listen for "Ping" signals coming from docks
				dbus_dock_ping_id = connection.signal_subscribe (null, Plank.DBUS_DOCK_INTERFACE_NAME,
					Plank.DBUS_PING_NAME, null, null, DBusSignalFlags.NONE, (DBusSignalCallback) handle_dock_ping);
			} catch (Error e) {
				warning ("Could not subscribe for dock signal (%s)", e.message);
			}
			
			dbus_name_owner_changed_signal_id = connection.signal_subscribe ("org.freedesktop.DBus", "org.freedesktop.DBus",
				"NameOwnerChanged", "/org/freedesktop/DBus", null, DBusSignalFlags.NONE, (DBusSignalCallback) handle_name_owner_changed);
			
			client_object_path = (owned) object_path;
			
			try {
				// Broadcast to inform running docks
				connection.emit_signal (null, client_object_path, Plank.DBUS_CLIENT_INTERFACE_NAME, Plank.DBUS_PING_NAME, null);
			} catch (Error e) {
				warning ("Could not ping running docks (%s)", e.message);
			}
		}
		
		~DBusClient ()
		{
			if (connection != null) {
				if (dbus_dock_ping_id > 0)
					connection.signal_unsubscribe (dbus_dock_ping_id);
				if (dbus_name_owner_changed_signal_id > 0)
					connection.signal_unsubscribe (dbus_name_owner_changed_signal_id);
			}
		}
		
		[CCode (instance_pos = -1)]
		void handle_dock_ping (DBusConnection connection, string sender_name, string object_path,
			string interface_name, string signal_name, Variant parameters)
		{
			if (dock_bus_name == null && dock_bus_name != sender_name)
				connect_proxies (connection, sender_name, object_path);
		}
		
		[CCode (instance_pos = -1)]
		void handle_name_owner_changed (DBusConnection connection, string sender_name, string object_path,
			string interface_name, string signal_name, Variant parameters)
		{
			string name, before, after;
			parameters.get ("(sss)", out name, out before, out after);
			
			if (dock_bus_owner != null && dock_bus_owner == after)
				return;
			
			if (name != null && name != "" && name != dock_bus_name)
				return;
			
			if (after == null || after == "") {
				disconnect_proxies ();
				return;
			}
			
			connect_proxies (connection, name, object_path);
		}
		
		void connect_proxies (DBusConnection connection, string sender_name, string object_path)
		{	
			debug ("Connecting and create proxies for '%s' (%s)", sender_name, object_path);
			
			try {
				items_proxy = connection.get_proxy_sync<Plank.DBusItemsIface> (sender_name, object_path, DBusProxyFlags.NONE);
				items_proxy.changed.connect (invalidate_items_cache);
				dock_bus_owner = ((DBusProxy) items_proxy).get_name_owner ();
				dock_bus_name = sender_name;
				dock_object_path = object_path;
			} catch (Error e) {
				dock_bus_owner = null;
				dock_bus_name = null;
				dock_object_path = null;
				
				items_proxy = null;
				critical ("Failed to create items proxy for '%s' (%s)", sender_name, object_path);
			}
			
			proxy_changed ();
		}
		
		void disconnect_proxies ()
		{
			debug ("Disconnecting from '%s' (%s)", dock_bus_name, dock_object_path);
			
			dock_bus_owner = null;
			dock_bus_name = null;
			dock_object_path = null;
			
			items_proxy.changed.disconnect (invalidate_items_cache);
			items_proxy = null;
		}
		
		
		void invalidate_items_cache ()
		{
			items_count = int.MIN;
			persistent_apps_list = null;
			transient_apps_list = null;
		}
		
		/**
		 * Add a new item for the given uri to the dock
		 *
		 * @param uri an URI
		 * @return whether it was successfully added
		 */
		public bool add_item (string uri)
		{
			if (items_proxy == null) {
				warning ("No proxy connected");
				return false;
			}
			
			try {
				return items_proxy.add (uri);
			} catch (Error e) {
				warning (e.message);
				return false;
			}
		}
		
		/**
		 * Remove an existing item for the given uri from the dock
		 *
		 * @param uri an URI
		 * @return whether it was successfully removed
		 */
		public bool remove_item (string uri)
		{
			if (items_proxy == null) {
				warning ("No proxy connected");
				return false;
			}
			
			try {
				return items_proxy.remove (uri);
			} catch (Error e) {
				warning (e.message);
				return false;
			}
		}
		
		/**
		 * Returns the number of currently visible items on the dock
		 *
		 * @return the item-count
		 */
		public int get_items_count ()
		{
			if (items_proxy == null) {
				warning ("No proxy connected");
				return -1;
			}
			
			try {
				if (items_count == int.MIN)
					items_count = items_proxy.get_count ();
			} catch (Error e) {
				warning (e.message);
				return -1;
			}
			
			return items_count;
		}
		
		/**
		 * Returns an array of uris of the persistent applications on the dock
		 *
		 * @return the array of uris
		 */
		public unowned string[]? get_persistent_applications ()
		{
			if (items_proxy == null) {
				warning ("No proxy connected");
				return null;
			}
			
			if (persistent_apps_list != null)
				return persistent_apps_list;
			
			try {
				if (persistent_apps_list == null)
					persistent_apps_list = items_proxy.get_persistent_applications ();
				return persistent_apps_list;
			} catch (Error e) {
				warning (e.message);
			}
			
			return null;
		}
		
		/**
		 * Returns an array of uris of the transient applications on the dock
		 *
		 * @return the array of uris
		 */
		public unowned string[]? get_transient_applications ()
		{
			if (items_proxy == null) {
				warning ("No proxy connected");
				return null;
			}
			
			if (transient_apps_list != null)
				return transient_apps_list;
			
			try {
				if (transient_apps_list == null)
					transient_apps_list = items_proxy.get_transient_applications ();
				return transient_apps_list;
			} catch (Error e) {
				warning (e.message);
			}
			
			return null;
		}

		/**
		 * Gets the x,y coords with the dock's position to display a hover window for an item.
		 *
		 * @param uri an URI
		 * @param x the resulting x position
		 * @param y the resulting y position
		 * @param dock_position the position of the dock
		 * @return whether it was successfully retrieved
		 */
		public bool get_hover_position (string uri, out int x, out int y, out Gtk.PositionType dock_position)
		{
			if (items_proxy == null) {
				warning ("No proxy connected");
				x = y = -1;
				dock_position = 0;
				return false;
			}
			
			try {
				return items_proxy.get_hover_position (uri, out x, out y, out dock_position);
			} catch (Error e) {
				warning (e.message);
			}
			
			return false;
		}
	}
}
