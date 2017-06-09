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
	 * Provide an interface to manage items of the dock
	 */
	class DBusItems : GLib.Object, Plank.DBusItemsIface
	{
		DockController controller;
		uint changed_timer_id = 0U;
		
		public DBusItems (DockController _controller)
		{
			controller = _controller;
			controller.elements_changed.connect (handle_elements_changed);
		}
		
		~DBusItems ()
		{
			controller.elements_changed.disconnect (handle_elements_changed);
			
			if (changed_timer_id > 0U) {
				GLib.Source.remove (changed_timer_id);
				changed_timer_id = 0U;
			}
		}
		
		void handle_elements_changed ()
		{
			if (changed_timer_id > 0U)
				return;
			
			// Fire updates with a reasonable rate
			changed_timer_id = Timeout.add (500, () => {
				changed_timer_id = 0U;
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

		public bool get_hover_position (string uri, out int x, out int y, out Gtk.PositionType dock_position)
		{
			var items = controller.Items;
			
			unowned DockItem? found = null;
			foreach (unowned DockItem item in items) {
				if (uri == item.Launcher) {
					found = item;
					break;
				}
			}
			
			if (found == null) {
				x = y = -1;
				dock_position = 0;
				return false;
			}
			
			unowned PositionManager position_manager = controller.position_manager;
			position_manager.get_hover_position (found, out x, out y);
			dock_position = position_manager.Position;
			return true;
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
		
		uint dbus_items_signal_id = 0U;
		uint dbus_client_ping_signal_id = 0U;
		
		public DBusManager (DockController controller)
		{
			Object (controller: controller);
		}
		
		construct
		{
			unowned Application application = Application.get_default ();
			string? object_path;
			
			connection = application.get_dbus_connection ();
			object_path = application.get_dbus_object_path ();
			
			if (connection == null || object_path == null) {
				critical ("Not able to register our interfaces");
				return;
			}
			
			if (!object_path.has_suffix (controller.name))
				object_path = "%s/%s".printf (object_path, controller.name);
			
			// Listen for "Ping" signals coming from clients
			try {
				dbus_client_ping_signal_id = connection.signal_subscribe (null, Plank.DBUS_CLIENT_INTERFACE_NAME,
					Plank.DBUS_PING_NAME, null, null, DBusSignalFlags.NONE, (DBusSignalCallback) handle_client_ping);
			} catch (IOError e) {
				warning ("Could not subscribe for client signal (%s)", e.message);
			}
			
			try {
				var dbus_items = new DBusItems (controller);
				dbus_items_signal_id = connection.register_object<Plank.DBusItemsIface> (object_path, dbus_items);
			} catch (IOError e) {
				warning ("Could not register service (%s)", e.message);
			}
			
			dock_object_path = (owned) object_path;
			
			try {
				// Broadcast to inform running clients
				connection.emit_signal (null, dock_object_path, Plank.DBUS_DOCK_INTERFACE_NAME, Plank.DBUS_PING_NAME, null);
			} catch (Error e) {
				warning ("Could not ping running clients (%s)", e.message);
			}
		}
		
		~DBusManager ()
		{
			if (connection != null) {
				if (dbus_items_signal_id > 0U)
					connection.unregister_object (dbus_items_signal_id);
				if (dbus_client_ping_signal_id > 0U)
					connection.signal_unsubscribe (dbus_client_ping_signal_id);
			}
		}
		
		[CCode (instance_pos = -1)]
		void handle_client_ping (DBusConnection connection, string sender_name, string object_path,
			string interface_name, string signal_name, Variant parameters)
		{
			try {
				// Broadcast to inform running clients
				connection.emit_signal (null, dock_object_path, Plank.DBUS_DOCK_INTERFACE_NAME, Plank.DBUS_PING_NAME, null);
			} catch (Error e) {
				warning ("Could not ping running clients (%s)", e.message);
			}
		}
	}
}
