//
//  Copyright (C) 2011-2013 Robert Dyer, Rico Tzschichholz
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

using Plank.Factories;
using Plank.Widgets;

using Plank.Services;
using Plank.Services.Windows;

namespace Plank.Items
{
	/**
	 * A container and controller class for managing application dock items on a dock.
	 */
	public class ApplicationDockItemProvider : DockItemProvider
	{
		static DBusConnection connection = null;
		static uint unity_bus_id = 0;
		
		public signal void item_window_added (ApplicationDockItem item);
		
		public File LaunchersDir { get; construct; }
		
		public bool HandlesTransients { get; construct; }
		
		FileMonitor? items_monitor = null;
		bool delay_items_monitor_handle = false;
		ArrayList<GLib.File> queued_files = new ArrayList<GLib.File> ();
		
		uint launcher_entry_dbus_signal_id = 0;
		uint dbus_name_owner_changed_signal_id = 0;
		
		/**
		 * Creates a new container for dock items.
		 *
		 * @param launchers_dir the directory where to load/save .dockitems files from/to
		 */
		public ApplicationDockItemProvider (File launchers_dir)
		{
			Object (LaunchersDir : launchers_dir, HandlesTransients : false);
		}
		
		construct
		{
			// Make sure our launchers-directory exists
			Paths.ensure_directory_exists (LaunchersDir);
			
			foreach (var item in load_items ())
				add_item_without_signaling (item);
			add_running_apps ();
			update_visible_items ();
			
			Matcher.get_default ().application_opened.connect (app_opened);
			
			try {
				items_monitor = LaunchersDir.monitor (0);
				items_monitor.changed.connect (handle_items_dir_changed);
			} catch (Error e) {
				critical ("Unable to watch the launchers directory. (%s)", e.message);
			}
			
			acquire_unity_dbus ();
			
			if (connection != null) {
				debug ("Unity: Initalizing LauncherEntry support");
				
				launcher_entry_dbus_signal_id = connection.signal_subscribe (null, "com.canonical.Unity.LauncherEntry",
					null, null, null, DBusSignalFlags.NONE, handle_entry_signal);
				dbus_name_owner_changed_signal_id = connection.signal_subscribe ("org.freedesktop.DBus", "org.freedesktop.DBus",
					"NameOwnerChanged", "/org/freedesktop/DBus", null, DBusSignalFlags.NONE, handle_name_owner_changed);
			}
		}
		
		~ApplicationDockItemProvider ()
		{
			Matcher.get_default ().application_opened.disconnect (app_opened);
			
			if (items_monitor != null) {
				items_monitor.changed.disconnect (handle_items_dir_changed);
				items_monitor.cancel ();
				items_monitor = null;
			}
			
			if (unity_bus_id > 0)
				Bus.unown_name (unity_bus_id);
			
			if (connection != null) {
				if (launcher_entry_dbus_signal_id > 0)
					connection.signal_unsubscribe (launcher_entry_dbus_signal_id);
				if (dbus_name_owner_changed_signal_id > 0)
					connection.signal_unsubscribe (dbus_name_owner_changed_signal_id);
			}
		}
		
		static construct
		{
			acquire_unity_dbus ();
		}
		
		/**
		 * Connect DBus connection and try to aquire unity busname
		 */
		public static void acquire_unity_dbus ()
		{
			// Initialize Unity DBus
			try {
				if (connection == null)
					connection = Bus.get_sync (BusType.SESSION, null);
			} catch (Error e) {
				warning (e.message);
				return;
			}
			
			if (unity_bus_id == 0) {
				// Acquire Unity bus-name to activate libunity clients since normally there shouldn't be a running Unity
				unity_bus_id = Bus.own_name (BusType.SESSION, "com.canonical.Unity", BusNameOwnerFlags.NONE,
					handle_bus_acquired, handle_name_acquired, handle_name_lost);
			}
		}
		
		/**
		 * Disconnect DBus connection and release unity busname
		 */
		public static void release_unity_dbus ()
		{
			if (unity_bus_id > 0) {
				Bus.unown_name (unity_bus_id);
				unity_bus_id = 0;
			}
			
			if (connection != null) {
				try {
					connection.flush ();
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
			Logger.verbose ("Unity: %s acquired", name);
		}

		static void handle_name_acquired (DBusConnection conn, string name)
		{
			Logger.verbose ("Unity: %s acquired", name);
		}

		static void handle_name_lost (DBusConnection conn, string name)
		{
			debug ("Unity: %s lost", name);
		}
		
		protected ApplicationDockItem? item_for_application (Bamf.Application app)
		{
			var app_desktop_file = app.get_desktop_file ();
			if (app_desktop_file != null && app_desktop_file.has_prefix ("/"))
				try {
					app_desktop_file = Filename.to_uri (app_desktop_file);
				} catch (ConvertError e) {
					warning (e.message);
				}
			
			foreach (var item in internal_items) {
				unowned ApplicationDockItem? appitem = (item as ApplicationDockItem);
				if (appitem == null)
					continue;
				
				var item_app = appitem.App;
				if (item_app != null && item_app == app)
					return appitem;
				
				var launcher = appitem.Launcher;
				if (launcher != "" && app_desktop_file != null && launcher == app_desktop_file)
					return appitem;
			}
			
			return null;
		}
		
		static File? desktop_file_for_application_uri (string app_uri)
		{
			foreach (var folder in Paths.DataDirFolders) {
				var applications_folder = folder.get_child ("applications");
				if (!applications_folder.query_exists ())
					continue;
				
				var desktop_file = applications_folder.get_child (app_uri.replace ("application://", ""));
				if (!desktop_file.query_exists ())
					continue;
				
				return desktop_file;
			}
			
			debug ("Matching application for '%s' not found or not installed!", app_uri);
			
			return null;
		}

		public override void add_item_with_uri (string uri, DockItem? target = null)
		{
			if (uri == null || uri == "")
				return;
			
			// delay automatic add of new dockitems while creating this new one
			delay_items_monitor ();
			
			var dockitem_file = Factory.item_factory.make_dock_item (uri, LaunchersDir);
			if (dockitem_file == null)
				return;
			
			var item = Factory.item_factory.make_item (dockitem_file);
			add_item (item);
			
			if (target != null)
				move_item_to (item, target);
			
			resume_items_monitor ();
		}
		
		protected virtual ArrayList<DockItem> load_items ()
		{
			Paths.ensure_directory_exists (LaunchersDir);
			
			debug ("Loading dock items from '%s'", LaunchersDir.get_path ());
			
			var result = new ArrayList<DockItem> ();
			
			try {
				var enumerator = LaunchersDir.enumerate_children (FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_IS_HIDDEN, 0);
				FileInfo info;
				while ((info = enumerator.next_file ()) != null)
					if (file_is_dockitem (info)) {
						var file = LaunchersDir.get_child (info.get_name ());
						var item = Factory.item_factory.make_item (file);
						
						if (!item.ValidItem) {
							warning ("The launcher '%s' in dock item '%s' does not exist", item.Launcher, file.get_path ());
							continue;
						}
						
						result.add (item);
					}
			} catch (Error e) {
				critical ("Error loading dock items from '%s'. (%s)", LaunchersDir.get_path () ?? "", e.message);
			}
			
			return result;
		}
		
		protected virtual void add_running_apps ()
		{
			foreach (var app in Matcher.get_default ().active_launchers ()) {
				var found = item_for_application (app);
				if (found != null)
					found.App = app;
			}
		}
		
		protected virtual void app_opened (Bamf.Application app)
		{
			var found = item_for_application (app);
			if (found != null)
				found.App = app;
		}
		
		bool file_is_dockitem (FileInfo info)
		{
			return !info.get_is_hidden () && info.get_name ().has_suffix (".dockitem");
		}
		
		protected void delay_items_monitor ()
		{
			delay_items_monitor_handle = true;
		}
		
		protected void resume_items_monitor ()
		{
			delay_items_monitor_handle = false;
			process_queued_files ();
		}
		
		void process_queued_files ()
		{
			foreach (var file in queued_files) {
				var basename = file.get_basename ();
				bool skip = false;
				foreach (var item in internal_items) {
					if (basename == item.DockItemFilename) {
						skip = true;
						break;
					}
				}
				
				if (skip)
					continue;
				
				Logger.verbose ("ApplicationDockItemProvider.process_queued_files ('%s')", basename);
				var item = Factory.item_factory.make_item (file);
				if (item.ValidItem)
					add_item (item);
				else
					warning ("The launcher '%s' in dock item '%s' does not exist", item.Launcher, file.get_path ());
			}
			
			queued_files.clear ();
		}
		
		void handle_items_dir_changed (File f, File? other, FileMonitorEvent event)
		{
			try {
				if (!file_is_dockitem (f.query_info (FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_IS_HIDDEN, 0)))
					return;
			} catch {
				return;
			}
			
			// only watch for new items
			// items watch themselves for updates or deletions
			if ((event & FileMonitorEvent.CREATED) != FileMonitorEvent.CREATED)
				return;
			
			// bail if an item already manages this dockitem-file
			foreach (var item in internal_items)
				if (f.get_basename () == item.DockItemFilename)
					return;
			
			Logger.verbose ("ApplicationDockItemProvider.handle_items_dir_changed (processing '%s')", f.get_path ());
			
			queued_files.add (f);
			
			if (!delay_items_monitor_handle)
				process_queued_files ();
		}
		
		protected override void item_signals_connect (DockItem item)
		{
			base.item_signals_connect (item);
			
			unowned ApplicationDockItem? appitem = (item as ApplicationDockItem);
			if (appitem != null) {
				appitem.app_window_added.connect (handle_item_app_window_added);
			}
		}
		
		protected override void item_signals_disconnect (DockItem item)
		{
			base.item_signals_disconnect (item);
			
			unowned ApplicationDockItem? appitem = (item as ApplicationDockItem);
			if (appitem != null) {
				appitem.app_window_added.disconnect (handle_item_app_window_added);
			}
		}
		
		void handle_item_app_window_added (ApplicationDockItem item)
		{
			item_window_added (item);
		}
		
		protected override void handle_item_deleted (DockItem item)
		{
			unowned Bamf.Application? app = null;
			if (item is ApplicationDockItem)
				app = (item as ApplicationDockItem).App;
			
			if (app == null || !app.is_running ()) {
				remove_item (item);
				return;
			}
			
			var new_item = new TransientDockItem.with_application (app);
			item.copy_values_to (new_item);
			
			replace_item (new_item, item);
		}
		
		public override bool can_accept_drop (ArrayList<string> uris)
		{
			return false;
		}
		
		public override bool accept_drop (ArrayList<string> uris)
		{
			return false;
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
			
			// Reset item since there is no new NameOwner
			unowned TransientDockItem? transient_item = null;
			foreach (var item in internal_items) {
				unowned ApplicationDockItem? app_item = item as ApplicationDockItem;
				if (app_item == null)
					continue;
				
				if (app_item.get_unity_dbusname () != name)
					continue;
				
				app_item.unity_reset ();
				transient_item = item as TransientDockItem;
				
				item_state_changed ();
				break;
			}
			
			// Remove item which only exists because of the presence of
			// this removed LauncherEntry interface
			if (transient_item != null && transient_item.App == null)
				remove_item (transient_item);
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
			
			ApplicationDockItem? current_item = null;
			foreach (var item in internal_items) {
				unowned ApplicationDockItem? app_item = item as ApplicationDockItem;
				if (app_item == null)
					continue;
				
				if (app_item.get_unity_dbusname () == sender_name
					|| app_item.get_unity_application_uri () == app_uri) {
					current_item = app_item;
					break;
				}
			}
			
			// Update our entry and trigger a redraw
			if (current_item != null) {
				current_item.unity_update (sender_name, prop_iter);
				
				// Remove item which progress-bar/badge is gone and only existed
				// because of the presence of this LauncherEntry interface
				unowned TransientDockItem? transient_item = current_item as TransientDockItem;
				if (transient_item != null && transient_item.App == null
					&& !(transient_item.has_unity_info ()))
					remove_item (transient_item);
				else
					item_state_changed ();
			} else if (HandlesTransients) {
				// Find a matching desktop-file and create new TransientDockItem for this LauncherEntry
				var desktop_file = desktop_file_for_application_uri (app_uri);
				if (desktop_file != null) {
					current_item = new TransientDockItem.with_launcher (desktop_file.get_uri ());
					current_item.unity_update (sender_name, prop_iter);
					
					// Only add item if there is actually a visible progress-bar or badge
					// or the backing application provides a quicklist-dbusmenu
					if (current_item.has_unity_info ())
						add_item (current_item);
				}
				
				if (current_item == null)
					warning ("Matching application for '%s' not found or not installed!", app_uri);
			}
		}
	}
}
