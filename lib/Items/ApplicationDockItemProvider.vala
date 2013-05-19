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
		public DockController controller { get; protected set construct; }
		
		FileMonitor? items_monitor = null;
		bool delay_items_monitor_handle = false;
		ArrayList<GLib.File> queued_files = new ArrayList<GLib.File> ();
		
		DBusConnection connection = null;
		uint unity_bus_id = 0;
		uint launcher_entry_dbus_signal_id = 0;
		uint dbus_name_owner_changed_signal_id = 0;
		
		/**
		 * Creates a new container for dock items.
		 *
		 * @param controller the dock controller that owns these items
		 */
		public ApplicationDockItemProvider (DockController controller)
		{
			Object (controller : controller);
		}
		
		construct
		{
			Factory.item_factory.launchers_dir = Paths.AppConfigFolder.get_child (Factories.AbstractMain.dock_path + "/launchers");
			
			// if we made the launcher directory, assume a first run and pre-populate with launchers
			if (Paths.ensure_directory_exists (Factory.item_factory.launchers_dir)) {
				debug ("Adding default dock items...");
				Factory.item_factory.make_default_items ();
				debug ("done.");
			}
			
			load_items ();
			add_running_apps ();
			update_visible_items ();
			serialize_item_positions ();
			
			controller.prefs.notify["CurrentWorkspaceOnly"].connect (handle_setting_changed);
			
			item_position_changed.connect (serialize_item_positions);
			items_changed.connect (serialize_item_positions);
			
			Matcher.get_default ().app_opened.connect (app_opened);
			
			var wnck_screen = Wnck.Screen.get_default ();
			wnck_screen.active_window_changed.connect (handle_window_changed);
			wnck_screen.active_workspace_changed.connect (handle_workspace_changed);
			wnck_screen.viewports_changed.connect (handle_viewports_changed);
			
			try {
				items_monitor = Factory.item_factory.launchers_dir.monitor (0);
				items_monitor.changed.connect (handle_items_dir_changed);
			} catch (Error e) {
				critical ("Unable to watch the launchers directory. (%s)", e.message);
			}
			
			// Initialize Unity DBus
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
		
		~ApplicationDockItemProvider ()
		{
			controller.prefs.notify["CurrentWorkspaceOnly"].disconnect (handle_setting_changed);
			
			item_position_changed.disconnect (serialize_item_positions);
			items_changed.disconnect (serialize_item_positions);
			
			Matcher.get_default ().app_opened.disconnect (app_opened);
			
			var wnck_screen = Wnck.Screen.get_default ();
			wnck_screen.active_window_changed.disconnect (handle_window_changed);
			wnck_screen.active_workspace_changed.disconnect (handle_workspace_changed);
			wnck_screen.viewports_changed.disconnect (handle_viewports_changed);
			
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
				
				connection.close_sync ();
			}
		}
		
		ApplicationDockItem? item_for_application (Bamf.Application app)
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

		public bool item_exists_for_uri (string uri)
		{
			foreach (var item in internal_items)
				if (item.Launcher == uri)
					return true;
			
			return false;
		}
		
		public void add_item_with_uri (string uri, DockItem? target = null)
		{
			if (uri == null || uri == "")
				return;
			
			// delay automatic add of new dockitems while creating this new one
			delay_items_monitor ();
			
			var dockitem_file = Factory.item_factory.make_dock_item (uri);
			if (dockitem_file == null)
				return;
			
			var item = Factory.item_factory.make_item (dockitem_file);
			add_item (item);
			
			if (target != null)
				move_item_to (item, target);
			
			resume_items_monitor ();
		}
		
		void load_items ()
		{
			debug ("Reloading dock items...");
			var existing_items = new ArrayList<DockItem> ();
			var new_items = new ArrayList<DockItem> ();
			var favs = new ArrayList<string> ();
			
			try {
				var enumerator = Factory.item_factory.launchers_dir.enumerate_children (FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_IS_HIDDEN, 0);
				FileInfo info;
				while ((info = enumerator.next_file ()) != null)
					if (file_is_dockitem (info)) {
						var file = Factory.item_factory.launchers_dir.get_child (info.get_name ());
						var item = Factory.item_factory.make_item (file);
						
						if (!item.ValidItem) {
							warning ("The launcher '%s' in dock item '%s' does not exist", item.Launcher, file.get_path ());
							continue;
						}
						
						if (controller.prefs.DockItems.contains (info.get_name ()))
							existing_items.add (item);
						else
							new_items.add (item);
						
						if ((item is ApplicationDockItem) && !(item is TransientDockItem))
							favs.add (item.Launcher);
					}
			} catch (Error e) {
				error ("Error loading dock items. (%s)", e.message);
			}
			
			// add saved dockitems based on their serialized order
			var dockitems = controller.prefs.DockItems.split (";;");
			var pos = 0;
			foreach (var dockitem in dockitems)
				foreach (var item in existing_items)
					if (dockitem == item.DockItemFilename) {
						item.Position = ++pos;
						add_item_without_signaling (item);
						break;
					}
			
			// add new dockitems
			foreach (var item in new_items)
				add_item_without_signaling (item);
			
			Matcher.get_default ().set_favorites (favs);
			
			debug ("done.");
		}
		
		protected override void update_visible_items ()
		{
			Logger.verbose ("ApplicationDockItemProvider.update_visible_items ()");
			
			if (controller.prefs.CurrentWorkspaceOnly) {
				var active_workspace = Wnck.Screen.get_default ().get_active_workspace ();
				foreach (var item in internal_items) {
					unowned TransientDockItem? transient = (item as TransientDockItem);
					item.IsVisible = (transient == null || transient.App == null
						|| WindowControl.has_window_on_workspace (transient.App, active_workspace));
				}
			} else {
				foreach (var item in internal_items)
					item.IsVisible = true;
			}
			
			base.update_visible_items ();
		}
		
		/**
		 * Serializes the item positions to the preferences.
		 */
		void serialize_item_positions ()
		{
			var item_list = "";
			foreach (var item in internal_items) {
				if (!(item is TransientDockItem) && item.DockItemFilename.length > 0) {
					if (item_list.length > 0)
						item_list += ";;";
					item_list += item.DockItemFilename;
				}
			}
			
			if (controller.prefs.DockItems != item_list)
				controller.prefs.DockItems = item_list;
		}
		
		void add_running_app (Bamf.Application app, bool without_signaling)
		{
			var found = item_for_application (app);
			if (found != null) {
				found.App = app;
				return;
			}
			
			if (!app.is_user_visible () || WindowControl.get_num_windows (app) <= 0)
				return;
			
			var new_item = new TransientDockItem.with_application (app);
			
			if (without_signaling)
				add_item_without_signaling (new_item);
			else
				add_item (new_item);
		}
		
		void add_running_apps ()
		{
			foreach (var app in Matcher.get_default ().active_launchers ())
				add_running_app (app, true);
		}
		
		void app_opened (Bamf.Application app)
		{
			add_running_app (app, false);
		}
		
		void app_closed (DockItem remove)
		{
			if (remove is TransientDockItem
				&& !(remove.ProgressVisible || remove.CountVisible))
				remove_item (remove);
		}
		
		bool file_is_dockitem (FileInfo info)
		{
			return !info.get_is_hidden () && info.get_name ().has_suffix (".dockitem");
		}
		
		void delay_items_monitor ()
		{
			delay_items_monitor_handle = true;
		}
		
		void resume_items_monitor ()
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
		
		void handle_window_changed (Wnck.Window? previous)
		{
			if (!controller.prefs.CurrentWorkspaceOnly)
				return;
			
			if (previous == null
				|| previous.get_workspace () == previous.get_screen ().get_active_workspace ())
				return;
			
			update_visible_items ();
		}
		
		void handle_workspace_changed (Wnck.Screen screen, Wnck.Workspace previously_active_space)
		{
			if (!controller.prefs.CurrentWorkspaceOnly
				|| screen.get_active_workspace ().is_virtual ())
				return;
			
			update_visible_items ();
		}
		
		void handle_viewports_changed (Wnck.Screen screen)
		{
			if (!controller.prefs.CurrentWorkspaceOnly
				|| !screen.get_active_workspace ().is_virtual ())
				return;
			
			update_visible_items ();
		}
		
		protected override void item_signals_connect (DockItem item)
		{
			base.item_signals_connect (item);
			
			unowned ApplicationDockItem? appitem = (item as ApplicationDockItem);
			if (appitem != null) {
				appitem.app_closed.connect (app_closed);
				appitem.app_window_added.connect (handle_item_app_window_added);
				appitem.pin_launcher.connect (pin_item);
			}
		}
		
		protected override void item_signals_disconnect (DockItem item)
		{
			base.item_signals_disconnect (item);
			
			unowned ApplicationDockItem? appitem = (item as ApplicationDockItem);
			if (appitem != null) {
				appitem.app_closed.disconnect (app_closed);
				appitem.app_window_added.disconnect (handle_item_app_window_added);
				appitem.pin_launcher.disconnect (pin_item);
			}
		}
		
		void handle_item_app_window_added ()
		{
			controller.window.update_icon_regions ();
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
		
		void pin_item (DockItem item)
		{
			Logger.verbose ("ApplicationDockItemProvider.pin_item ('%s[%s]')", item.Text, item.DockItemFilename);

			unowned ApplicationDockItem? app_item = (item as ApplicationDockItem);
			if (app_item == null)
				return;
			
			// delay automatic add of new dockitems while creating this new one
			delay_items_monitor ();
			
			if (item is TransientDockItem) {
				var dockitem_file = Factory.item_factory.make_dock_item (item.Launcher);
				if (dockitem_file == null)
					return;
				
				var new_item = new ApplicationDockItem.with_dockitem_file (dockitem_file);
				item.copy_values_to (new_item);
				
				replace_item (new_item, item);
			} else {
				item.delete ();
			}
			
			resume_items_monitor ();
		}
		
		void handle_bus_acquired (DBusConnection conn, string name)
		{
			Logger.verbose ("Unity: %s acquired", name);
		}

		void handle_name_acquired (DBusConnection conn, string name)
		{
			Logger.verbose ("Unity: %s acquired", name);
		}

		void handle_name_lost (DBusConnection conn, string name)
		{
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
				
				controller.renderer.animated_draw ();
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
					&& !(transient_item.ProgressVisible || transient_item.CountVisible))
					remove_item (transient_item);
				else
					controller.renderer.animated_draw ();
			} else {
				// Find a matching desktop-file and create new TransientDockItem for this LauncherEntry
				var desktop_file = desktop_file_for_application_uri (app_uri);
				if (desktop_file != null) {
					current_item = new TransientDockItem.with_launcher (desktop_file.get_uri ());
					current_item.unity_update (sender_name, prop_iter);
					
					// Only add item if there is actually a visible progress-bar or badge
					if (current_item.ProgressVisible || current_item.CountVisible)
						add_item (current_item);
				}
				
				if (current_item == null)
					warning ("Matching application for '%s' not found or not installed!", app_uri);
			}
		}
	}
}
