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

using Plank.Factories;
using Plank.Items;
using Plank.Services;

namespace Plank
{
	/**
	 * Provide an interface to manage items of the dock
	 */
	class DBusItems : GLib.Object, Plank.DBus.ItemsIface
	{
		DockController controller;
		uint changed_timer = 0;		
		
		public DBusItems (DockController _controller)
		{
			controller = _controller;
			controller.elements_changed.connect (handle_elements_changed);
		}
		
		~DBusItems ()
		{
			controller.elements_changed.disconnect (handle_elements_changed);
			
			if (changed_timer > 0) {
				GLib.Source.remove (changed_timer);
				changed_timer = 0;
			}
		}
		
		void handle_elements_changed ()
		{
			if (changed_timer > 0)
				return;
			
			// Fire updates with a reasonable rate
			changed_timer = Timeout.add (500, () => {
				changed_timer = 0;
				changed ();
				return false;
			});
		}
		
		public bool add (string uri)
		{
			debug ("Try to remotely add '%s'", uri);
			
			unowned ApplicationDockItemProvider? provider = (controller.default_provider as ApplicationDockItemProvider);
			if (provider == null)
				return false;
			
			unowned DockItem? item = provider.item_for_uri (uri);
			if (item != null && item is TransientDockItem) {
				((TransientDockItem) item).pin_launcher ();
				return true;
			}
			
			return provider.add_item_with_uri (uri);
		}
		
		public bool remove (string uri)
		{
			debug ("Try to remotely remove '%s'", uri);
			
			unowned ApplicationDockItemProvider? provider = (controller.default_provider as ApplicationDockItemProvider);
			if (provider == null)
				return false;
			
			unowned DockItem? item = provider.item_for_uri (uri);
			if (item == null)
				return false;
			
			if (item is ApplicationDockItem) {
				if (!(item is TransientDockItem))
					((ApplicationDockItem) item).pin_launcher ();
				return true;
			}
			
			return provider.remove (item);
		}
		
		public int get_count ()
		{
			return controller.VisibleItems.size;
		}
		
		public string[] get_persistent_applications ()
		{
			Logger.verbose ("Remotely list persistent items");
			
			var items = controller.Items;
			
			string[] result = {};
			unowned string launcher;
			foreach (unowned DockItem item in items) {
				if (item is ApplicationDockItem && !(item is TransientDockItem)) {
					launcher = item.Launcher;
					if (launcher != null && launcher != "")
						result += launcher;
				}
			}
			
			return result;
		}
		
		public string[] get_transient_applications ()
		{
			Logger.verbose ("Remotely list transient items");
			
			var items = controller.Items;
			
			string[] result = {};
			unowned string launcher;
			foreach (unowned DockItem item in items) {
				if (item is TransientDockItem) {
					launcher = item.Launcher;
					if (launcher != null && launcher != "")
						result += launcher;
				}
			}
			
			return result;
		}
	}
	
	/**
	 * Handles all the exported DBus functions of the dock
	 */
	public class DBusManager : GLib.Object
	{
		public DockController controller { private get; construct; }
		
		DBusConnection? connection = null;
		string? dock_object_path;
		
		uint dbus_items_id = 0;
		uint dbus_client_ping_id = 0;
		
		public DBusManager (DockController controller)
		{
			Object (controller: controller);
		}
		
		construct
		{
			unowned Application application = Application.get_default ();
			string? object_path;
			
#if GLIB_2_34
			connection = application.get_dbus_connection ();
			object_path = application.get_dbus_object_path ();
#else
			try {
				connection = Bus.get_sync (BusType.SESSION);
			} catch {
				connection = null;
			}
			object_path = "/%s".printf (application.get_application_id ().replace (".", "/").replace ("-", "_"));
#endif
			
			if (connection == null || object_path == null) {
				critical ("Not able to register our interfaces");
				return;
			}
			
			// Listen for "Ping" signals coming from clients
			try {
				dbus_client_ping_id = connection.signal_subscribe (null, Plank.DBus.CLIENT_INTERFACE_NAME,
					Plank.DBus.PING_NAME, null, null, DBusSignalFlags.NONE, handle_client_ping);
			} catch (IOError e) {
				warning ("Could not subscribe for client signal (%s)", e.message);
			}
			
			try {
				var dbus_items = new DBusItems (controller);
				dbus_items_id = connection.register_object<Plank.DBus.ItemsIface> (object_path, dbus_items);
			} catch (IOError e) {
				warning ("Could not register service (%s)", e.message);
			}
			
			dock_object_path = object_path;
			
			try {
				// Broadcast to inform running clients
				connection.emit_signal (null, dock_object_path, Plank.DBus.DOCK_INTERFACE_NAME, Plank.DBus.PING_NAME, null);
			} catch (Error e) {
				warning ("Could not ping running clients (%s)", e.message);
			}
		}
		
		~DBusManager ()
		{
			if (connection != null) {
				if (dbus_items_id > 0)
					connection.unregister_object (dbus_items_id);
				if (dbus_client_ping_id > 0)
					connection.signal_unsubscribe (dbus_client_ping_id);
			}
		}
		
		void handle_client_ping (DBusConnection connection, string sender_name, string object_path,
			string interface_name, string signal_name, Variant parameters)
		{
			try {
				// Broadcast to inform running clients
				connection.emit_signal (null, dock_object_path, Plank.DBus.DOCK_INTERFACE_NAME, Plank.DBus.PING_NAME, null);
			} catch (Error e) {
				warning ("Could not ping running clients (%s)", e.message);
			}
		}
	}
}
