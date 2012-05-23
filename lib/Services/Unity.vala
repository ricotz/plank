//  
//  Copyright (C) 2012 Rico Tzschichholz
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

using Gee;

using Plank.Items;

namespace Plank.Services
{
	class RemoteEntry : GLib.Object
	{
		public ApplicationDockItem Item { get; construct; }
		public string DBusName { get; set; }
		
		public RemoteEntry (ApplicationDockItem item)
		{
			Object (Item: item);
		}
		
		public void update (string sender_name, VariantIter prop_iter)
		{
			DBusName = sender_name;
			
			string prop_key;
			Variant prop_value;
			
			// TODO emblem isn't part of libunity API anymore
			//      do we want to support this ?
			
			while (prop_iter.next ("{sv}", out prop_key, out prop_value)) {
				if (prop_key == "count")
					Item.Count = prop_value.get_int64 ();
				else if (prop_key == "count-visible")
					Item.CountVisible = prop_value.get_boolean ();
				//else if (prop_key == "emblem")
				//	Item.Emblem = prop_value.get_string ();
				//else if (prop_key == "emblem-visible")
				//	Item.EmblemVisible = prop_value.get_boolean ();
				else if (prop_key == "progress")
					Item.Progress = prop_value.get_double ();
				else if (prop_key == "progress-visible")
					Item.ProgressVisible = prop_value.get_boolean ();
				else if (prop_key == "urgent")
					Item.set_urgent (prop_value.get_boolean ());
				else if (prop_key == "quicklist")
					/* The value is the object path of the dbusmenu */
					Item.QuicklistPath = prop_value.get_string ();
			}
		}
		
		public void reset ()
		{
			Item.Count = 0;
			Item.CountVisible = false;
			//Item.Emblem = "";
			//Item.EmblemVisible = false;
			Item.Progress = 0.0;
			Item.ProgressVisible = false;
			Item.set_urgent (false);
			Item.QuicklistPath = "";
		}
	}
	
	/**
	 * Unity / Launcher API - https://wiki.edubuntu.org/Unity/LauncherAPI
	 */
	public class Unity : GLib.Object
	{
		/**
		 * The controller for this dock.
		 */
		public DockController controller { private get; construct; }

		DBusConnection connection = null;
		
		uint unity_bus_id = 0;
		uint launcher_entry_dbus_signal_id = 0;
		uint dbus_name_owner_changed_signal_id = 0;
		
		HashMap<string, RemoteEntry> remote_entries = new HashMap<string, RemoteEntry> ();
		
		public Unity (DockController controller)
		{
			GLib.Object (controller: controller);
		}
		
		construct
		{
			try {
				connection = Bus.get_sync (BusType.SESSION, null);
			} catch (Error e) {
				warning (e.message);
				return;
			}
			
			debug ("Unity: Initalizing LauncherEntry support");
			
			// Acquire Unity bus-name to activate libunity clients since normally there shouldn't be a running Unity
			unity_bus_id = Bus.own_name (BusType.SESSION, "com.canonical.Unity", BusNameOwnerFlags.NONE,
				handle_bus_acquired, handle_name_acquired, handle_name_lost);
			
			launcher_entry_dbus_signal_id = connection.signal_subscribe (null, "com.canonical.Unity.LauncherEntry",
				null, null, null, DBusSignalFlags.NONE, handle_entry_signal);
			dbus_name_owner_changed_signal_id = connection.signal_subscribe ("org.freedesktop.DBus", "org.freedesktop.DBus",
				"NameOwnerChanged", "/org/freedesktop/DBus", null, DBusSignalFlags.NONE, handle_name_owner_changed);
		}
		
		~Unity ()
		{
			if (unity_bus_id > 0)
				Bus.unown_name (unity_bus_id);
			
			if (connection != null) {
				if (launcher_entry_dbus_signal_id > 0)
					connection.signal_unsubscribe (launcher_entry_dbus_signal_id);
				if (dbus_name_owner_changed_signal_id > 0)
					connection.signal_unsubscribe (dbus_name_owner_changed_signal_id);
			}
		}
		
		void handle_bus_acquired (DBusConnection conn, string name) {
			Logger.verbose ("Unity: %s acquired", name);
		}

		void handle_name_acquired (DBusConnection conn, string name) {
			Logger.verbose ("Unity: %s acquired", name);
		}  

		void handle_name_lost (DBusConnection conn, string name) {
			debug ("Unity: %s lost", name);
		}
		
		
		void handle_entry_signal (DBusConnection connection, string sender_name, string object_path,
			string interface_name, string signal_name, Variant parameters)
		{
			if (parameters == null || signal_name == null || sender_name == null)
				return;
			
			if (signal_name == "Update")
				handle_update_request (sender_name, parameters);
		}
		
		void handle_name_owner_changed (DBusConnection connection, string sender_name, string object_path,
			string interface_name, string signal_name, Variant parameters)
		{
			string name, before, after;
			parameters.get ("(sss)", out name, out before, out after);
			
			if (after != null && after != "")
				return;
			
			// Remove connected entry since there is no new NameOwner
			foreach (var entry in remote_entries.entries) {
				if (entry.value.DBusName != name)
					continue;
				
				entry.value.reset ();
				remote_entries.unset (entry.key);
				controller.renderer.animated_draw ();
				break;
			}
		}
		
		
		void handle_update_request (string sender_name, Variant parameters)
		{
			if (parameters == null)
				return;
			
			if (!parameters.is_of_type (new VariantType ("(sa{sv})"))) {
				warning ("Unity.handle_update_request (illegal payload signature '%s' from %s. expected '(sa{sv})')", parameters.get_type_string (), sender_name);
				return;
			}
			
			string app_uri;
			VariantIter prop_iter;
			parameters.get ("(sa{sv})", out app_uri, out prop_iter);
			
			Logger.verbose ("Unity.handle_update_request (processing update for %s)", app_uri);
			
			var entry = remote_entries.get (app_uri);
			
			// If don't know this app yet create a new entry
			if (entry == null)
				foreach (var item in controller.items.Items) {
					var app_item = item as ApplicationDockItem;
					if (app_item == null || app_item.App == null)
						continue;
					
					var p = app_item.App.get_desktop_file ().split("/");
					if (p.length == 0)
						continue;
					
					var uri = "application://" + p[p.length - 1];
					
					if (app_uri == uri) {
						entry = new RemoteEntry (app_item);
						remote_entries.set (app_uri, entry);
						break;
					}
				}
			
			// Update our entry and trigger a redraw
			if (entry != null) {
				entry.update (sender_name, prop_iter);
				controller.renderer.animated_draw ();
			}
		}
	}
}
