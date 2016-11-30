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
	 * The interface to provide the LauncherEntry handling.
	 */
	public interface UnityClient : Object
	{
		/**
		 * The LauncherEntry corresponding to the sender_name requested an update
		 *
		 * @param sender_name the dbusname
		 * @param parameters the data in a standardize format '(sa{sv})' from libunity
		 * @param is_retry whether this data was already processed before and decided to give is another run
		 */
		public abstract void update_launcher_entry (string sender_name, Variant parameters, bool is_retry = false);

		/**
		 * The LauncherEntry corresponding to the sender_name vanished
		 *
		 * @param sender_name the dbusname
		 */
		public abstract void remove_launcher_entry (string sender_name);
	}

	/**
	 * Handle the LauncherEntry DBus interface implemented by applications.
	 */
	public class Unity : GLib.Object
	{
		class LauncherEntry
		{
			public uint fast_count = 0U;
			public int64 last_update = 0LL;
			public string? sender_name;
			public Variant? parameters;
			public uint timer_id = 0U;
			public bool warned = false;
		}

		const string DBUS_NAME = "com.canonical.Unity";
		const string INTERFACE_NAME = "com.canonical.Unity.LauncherEntry";
		const string SIGNAL_NAME = "Update";

		static Unity? instance = null;
		static DBusConnection connection = null;
		static uint unity_bus_id = 0U;
		static VariantType payload_variant_type;

		public static unowned Unity get_default ()
		{
			if (instance == null)
				instance = new Unity ();

			return instance;
		}

		static construct
		{
			acquire_unity_dbus ();
			payload_variant_type = new VariantType ("(sa{sv})");
		}

		/**
		 * Connect DBus connection and try to aquire unity busname
		 */
		static void acquire_unity_dbus ()
		{
			// Initialize Unity DBus
			try {
				if (connection == null)
					connection = Bus.get_sync (BusType.SESSION, null);
			} catch (Error e) {
				warning (e.message);
				return;
			}

			if (unity_bus_id == 0U) {
				// Acquire Unity bus-name to activate libunity clients since normally there shouldn't be a running Unity
				unity_bus_id = Bus.own_name (BusType.SESSION, DBUS_NAME, BusNameOwnerFlags.ALLOW_REPLACEMENT,
					(BusAcquiredCallback) handle_bus_acquired, (BusNameAcquiredCallback) handle_name_acquired,
					(BusNameLostCallback) handle_name_lost);
			}
		}

		/**
		 * Disconnect DBus connection and release unity busname
		 */
		static void release_unity_dbus ()
		{
			if (unity_bus_id > 0U) {
				Bus.unown_name (unity_bus_id);
				unity_bus_id = 0U;
			}

			if (connection != null) {
				try {
					connection.flush_sync ();
					connection.close_sync ();
				} catch (Error e) {
					warning (e.message);
				} finally {
					connection = null;
				}
			}
		}

		static void handle_bus_acquired (DBusConnection conn, string name)
		{
			// Nothing here since we just want to provide this bus without any functionality
		}

		static void handle_name_acquired (DBusConnection conn, string name)
		{
			debug ("%s acquired", name);
		}

		static void handle_name_lost (DBusConnection conn, string name)
		{
			if (conn == null)
				warning ("%s failed", name);
			else
				debug ("%s lost", name);
		}

		Gee.HashSet<UnityClient> clients;

		uint launcher_entry_dbus_signal_id = 0U;
		uint dbus_name_owner_changed_signal_id = 0U;
		Gee.HashMap<string, LauncherEntry> launcher_entries;
		uint launcher_entries_timer_id = 0U;

		Unity ()
		{
			Object ();
		}

		construct
		{
			clients = new Gee.HashSet<UnityClient> ();
			launcher_entries = new Gee.HashMap<string, LauncherEntry> ();

			acquire_unity_dbus ();

			if (connection != null) {
				debug ("Initializing LauncherEntry support");

				launcher_entry_dbus_signal_id = connection.signal_subscribe (null, INTERFACE_NAME,
					null, null, null, DBusSignalFlags.NONE, (DBusSignalCallback) handle_entry_signal);
				dbus_name_owner_changed_signal_id = connection.signal_subscribe ("org.freedesktop.DBus", "org.freedesktop.DBus",
					"NameOwnerChanged", "/org/freedesktop/DBus", null, DBusSignalFlags.NONE, (DBusSignalCallback) handle_name_owner_changed);
			}
		}

		~Unity ()
		{
			if (launcher_entries_timer_id > 0U)
				Source.remove (launcher_entries_timer_id);

			clients = null;
			launcher_entries = null;

			if (unity_bus_id > 0U)
				Bus.unown_name (unity_bus_id);

			if (connection != null) {
				if (launcher_entry_dbus_signal_id > 0U)
					connection.signal_unsubscribe (launcher_entry_dbus_signal_id);
				if (dbus_name_owner_changed_signal_id > 0U)
					connection.signal_unsubscribe (dbus_name_owner_changed_signal_id);
			}
		}

		/**
		 * Add a client which will receive all update requests of running LauncherEntry applications.
		 *
		 * @param client the client to add
		 */
		public void add_client (UnityClient client)
		{
			clients.add (client);
		}

		/**
		 * Remove a client.
		 *
		 * @param client the client to remove
		 */
		public void remove_client (UnityClient client)
		{
			clients.remove (client);
		}

		[CCode (instance_pos = -1)]
		void handle_entry_signal (DBusConnection connection, string sender_name, string object_path,
			string interface_name, string signal_name, Variant parameters)
		{
			if (parameters == null || signal_name == null || sender_name == null)
				return;

			if (signal_name == SIGNAL_NAME)
				handle_update_request (sender_name, parameters);
		}

		[CCode (instance_pos = -1)]
		void handle_name_owner_changed (DBusConnection connection, string sender_name, string object_path,
			string interface_name, string signal_name, Variant parameters)
		{
			string name, before, after;
			parameters.get ("(sss)", out name, out before, out after);

			if (after != null && after != "")
				return;

			clients.foreach ((client) => {
				client.remove_launcher_entry (name);
				return true;
			});
		}

		void handle_update_request (string sender_name, Variant parameters)
		{
			var current_time = GLib.get_monotonic_time ();
			LauncherEntry? entry;
			if ((entry = launcher_entries.get (sender_name)) != null) {
				entry.parameters = parameters;
				if (current_time - entry.last_update < UNITY_UPDATE_THRESHOLD_DURATION * 1000
					&& entry.fast_count > UNITY_UPDATE_THRESHOLD_FAST_COUNT) {
					if (entry.timer_id <= 0U) {
						if (!entry.warned) {
							warning ("LauncherEntry '%s' is behaving badly, skipping requests", sender_name);
							entry.warned = true;
						}
						entry.timer_id = Timeout.add (UNITY_UPDATE_THRESHOLD_DURATION, () => {
							entry.timer_id = 0U;
							entry.last_update = GLib.get_monotonic_time ();
							perform_update (entry.sender_name, entry.parameters);
							return false;
						});
					}
				} else {
					entry.fast_count++;
					entry.last_update = current_time;
					perform_update (entry.sender_name, entry.parameters);
				}
			} else {
				entry = new LauncherEntry ();
				entry.fast_count++;
				entry.last_update = current_time;
				entry.sender_name = sender_name;
				entry.parameters = parameters;
				launcher_entries.set (sender_name, entry);
				perform_update (sender_name, parameters);
			}

			if (launcher_entries_timer_id <= 0U)
				launcher_entries_timer_id = Timeout.add (60 * 1000, (SourceFunc) clean_up_launcher_entries);
		}

		bool clean_up_launcher_entries ()
		{
			var current_time = GLib.get_monotonic_time ();

			var launcher_entries_it = launcher_entries.map_iterator ();
			while (launcher_entries_it.next ()) {
				var entry = launcher_entries_it.get_value ();
				if (current_time - entry.last_update > 10 * UNITY_UPDATE_THRESHOLD_DURATION * 1000)
					launcher_entries_it.unset ();
			}

			var keep_running = (launcher_entries.size > 0);
			if (!keep_running)
				launcher_entries_timer_id = 0U;

			Logger.verbose ("[Unity] Keeping %i active LauncherEntries", launcher_entries.size);

			return keep_running;
		}

		void perform_update (string sender_name, Variant parameters)
		{
			if (!parameters.is_of_type (payload_variant_type)) {
				warning ("Illegal payload signature '%s' from %s. expected '(sa{sv})'", parameters.get_type_string (), sender_name);
				return;
			}

			clients.foreach ((client) => {
				client.update_launcher_entry (sender_name, parameters);
				return true;
			});
		}
	}
}
