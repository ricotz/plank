//
//  Copyright (C) 2011-2013 Robert Dyer, Rico Tzschichholz
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
	 * A container and controller class for managing application dock items on a dock.
	 */
	public class ApplicationDockItemProvider : DockItemProvider, UnityClient
	{
		public signal void item_window_added (ApplicationDockItem item);
		
		public File LaunchersDir { get; construct; }
		
		FileMonitor? items_monitor = null;
		bool delay_items_monitor_handle = false;
		Gee.ArrayList<GLib.File> queued_files;
		
		/**
		 * Creates a new container for dock items.
		 *
		 * @param launchers_dir the directory where to load/save .dockitems files from/to
		 */
		public ApplicationDockItemProvider (File launchers_dir)
		{
			Object (LaunchersDir : launchers_dir);
		}
		
		construct
		{
			queued_files = new Gee.ArrayList<GLib.File> ();
			
			// Make sure our launchers-directory exists
			Paths.ensure_directory_exists (LaunchersDir);
			
			Matcher.get_default ().application_opened.connect (app_opened);
			
			try {
				items_monitor = LaunchersDir.monitor_directory (0);
				items_monitor.changed.connect (handle_items_dir_changed);
			} catch (Error e) {
				critical ("Unable to watch the launchers directory. (%s)", e.message);
			}
		}
		
		~ApplicationDockItemProvider ()
		{
			queued_files = null;
			
			Matcher.get_default ().application_opened.disconnect (app_opened);
			
			if (items_monitor != null) {
				items_monitor.changed.disconnect (handle_items_dir_changed);
				items_monitor.cancel ();
				items_monitor = null;
			}
		}
		
		protected unowned ApplicationDockItem? item_for_application (Bamf.Application app)
		{
			var app_desktop_file = app.get_desktop_file ();
			if (app_desktop_file != null && app_desktop_file.has_prefix ("/"))
				try {
					app_desktop_file = Filename.to_uri (app_desktop_file);
				} catch (ConvertError e) {
					warning (e.message);
				}
			
			foreach (var item in internal_elements) {
				unowned ApplicationDockItem? appitem = (item as ApplicationDockItem);
				if (appitem == null)
					continue;
				
				unowned Bamf.Application? item_app = appitem.App;
				if (item_app != null && item_app == app)
					return appitem;
				
				unowned string launcher = appitem.Launcher;
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

		/**
		 * {@inheritDoc}
		 */
		public override bool add_item_with_uri (string uri, DockItem? target = null)
		{
			if (uri == null || uri == "")
				return false;
			
			if (target != null && target != placeholder_item && !internal_elements.contains (target)) {
				critical ("Item '%s' does not exist in this DockItemProvider.", target.Text);
				return false;
			}
			
			if (item_exists_for_uri (uri)) {
				warning ("Item for '%s' already exists in this DockItemProvider.", uri);
				return false;
			}
			
			// delay automatic add of new dockitems while creating this new one
			delay_items_monitor ();
			
			var dockitem_file = Factory.item_factory.make_dock_item (uri, LaunchersDir);
			if (dockitem_file == null) {
				resume_items_monitor ();
				return false;
			}
			
			var element = Factory.item_factory.make_element (dockitem_file);
			unowned DockItem? item = (element as DockItem);
			if (item == null) {
				resume_items_monitor ();
				return false;
			}
			
			add (item, target);
			
			resume_items_monitor ();
			
			return true;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override void prepare ()
		{
			// Match running applications to their available dock-items
			foreach (var app in Matcher.get_default ().active_launchers ()) {
				unowned ApplicationDockItem? found = item_for_application (app);
				if (found != null)
					found.App = app;
			}
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override string[] get_dockitem_filenames ()
		{
			var item_list = new Gee.ArrayList<string> ();
			
			foreach (var element in internal_elements) {
				unowned DockItem? item = (element as DockItem);
				if (item == null || (item is TransientDockItem))
					continue;
				
				var dock_item_filename = item.DockItemFilename;
				if (dock_item_filename.length > 0) {
					item_list.add ((owned) dock_item_filename);
				}
			}
			
			return item_list.to_array ();
		}
		
		protected virtual void app_opened (Bamf.Application app)
		{
			// Make sure internal window-list of Wnck is most up to date
			Wnck.Screen.get_default ().force_update ();
			
			unowned ApplicationDockItem? found = item_for_application (app);
			if (found != null)
				found.App = app;
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
				foreach (var element in internal_elements) {
					unowned DockItem? item = (element as DockItem);
					if (item != null && basename == item.DockItemFilename) {
						skip = true;
						break;
					}
				}
				
				if (skip)
					continue;
				
				Logger.verbose ("ApplicationDockItemProvider.process_queued_files ('%s')", basename);
				var element = Factory.item_factory.make_element (file);
				unowned DockItem? item = (element as DockItem);
				if (item == null)
					continue;
				
				unowned DockItem? dupe;
				if ((dupe = item_for_uri (item.Launcher)) != null) {
					warning ("The launcher '%s' in dock item '%s' is already managed by dock item '%s'. Removing '%s'.",
						item.Launcher, file.get_path (), dupe.DockItemFilename, item.DockItemFilename);
					item.delete ();
				} else if (!item.is_valid ()) {
					warning ("The launcher '%s' in dock item '%s' does not exist. Removing '%s'.", item.Launcher, file.get_path (), item.DockItemFilename);
					item.delete ();
				} else {
					add (item);
				}
			}
			
			queued_files.clear ();
		}
		
		[CCode (instance_pos = -1)]
		void handle_items_dir_changed (File f, File? other, FileMonitorEvent event)
		{
			// only watch for new items, existing ones watch themselves for updates or deletions
			if (event != FileMonitorEvent.CREATED)
				return;
			
			if (!file_is_dockitem (f))
				return;
			
			// bail if an item already manages this dockitem-file
			foreach (var element in internal_elements) {
				unowned DockItem? item = (element as DockItem);
				if (item != null && f.get_basename () == item.DockItemFilename)
					return;
			}
			
			Logger.verbose ("ApplicationDockItemProvider.handle_items_dir_changed (processing '%s')", f.get_path ());
			
			queued_files.add (f);
			
			if (!delay_items_monitor_handle)
				process_queued_files ();
		}
		
		protected override void connect_element (DockElement element)
		{
			base.connect_element (element);
			
			unowned ApplicationDockItem? appitem = (element as ApplicationDockItem);
			if (appitem != null) {
				appitem.app_window_added.connect (handle_item_app_window_added);
			}
		}
		
		protected override void disconnect_element (DockElement element)
		{
			base.disconnect_element (element);
			
			unowned ApplicationDockItem? appitem = (element as ApplicationDockItem);
			if (appitem != null) {
				appitem.app_window_added.disconnect (handle_item_app_window_added);
			}
		}
		
		void handle_item_app_window_added (ApplicationDockItem item)
		{
			item_window_added (item);
		}
		
		public void remove_launcher_entry (string sender_name)
		{
			// Reset item since there is no new NameOwner
			foreach (var item in internal_elements) {
				unowned ApplicationDockItem? app_item = item as ApplicationDockItem;
				if (app_item == null)
					continue;
				
				if (app_item.get_unity_dbusname () != sender_name)
					continue;
				
				app_item.unity_reset ();
				
				// Remove item which only exists because of the presence of
				// this removed LauncherEntry interface
				unowned TransientDockItem? transient_item = item as TransientDockItem;
				if (transient_item != null && transient_item.App == null)
					remove (transient_item);
				
				break;
			}
		}
		
		public void update_launcher_entry (string sender_name, Variant parameters, bool is_retry = false)
		{
			string app_uri;
			VariantIter prop_iter;
			parameters.get ("(sa{sv})", out app_uri, out prop_iter);
			
			Logger.verbose ("Unity.handle_update_request (processing update for %s)", app_uri);
			
			ApplicationDockItem? current_item = null, alternate_item = null;
			foreach (var item in internal_elements) {
				unowned ApplicationDockItem? app_item = item as ApplicationDockItem;
				if (app_item == null)
					continue;
				
				// Prefer matching application-uri of available items
				if (app_item.get_unity_application_uri () == app_uri) {
					current_item = app_item;
					break;
				}
				
				if (app_item.get_unity_dbusname () == sender_name)
					alternate_item = app_item;
			}
			
			// Fallback to matching dbus-sender-name
			if (current_item == null)
				current_item = alternate_item;
			
			// Update our entry and trigger a redraw
			if (current_item != null) {
				current_item.unity_update (sender_name, prop_iter);
				
				// Remove item which progress-bar/badge is gone and only existed
				// because of the presence of this LauncherEntry interface
				unowned TransientDockItem? transient_item = current_item as TransientDockItem;
				if (transient_item != null && transient_item.App == null
					&& !(transient_item.has_unity_info ()))
					remove (transient_item);
				
				return;
			}
			
			if (!is_retry) {
				// Wait to let further update requests come in to catch the case where one application
				// sends out multiple LauncherEntry-updates with different application-uris, e.g. Nautilus
				Idle.add (() => {
					update_launcher_entry (sender_name, parameters, true);
					return false;
				});
				
				return;
			}
			
			unowned DefaultApplicationDockItemProvider? provider = (this as DefaultApplicationDockItemProvider);
			if (provider != null && !provider.Prefs.PinnedOnly) {
				// Find a matching desktop-file and create new TransientDockItem for this LauncherEntry
				var desktop_file = desktop_file_for_application_uri (app_uri);
				if (desktop_file != null) {
					current_item = new TransientDockItem.with_launcher (desktop_file.get_uri ());
					current_item.unity_update (sender_name, prop_iter);
					
					// Only add item if there is actually a visible progress-bar or badge
					// or the backing application provides a quicklist-dbusmenu
					if (current_item.has_unity_info ())
						add (current_item);
				}
				
				if (current_item == null)
					warning ("Matching application for '%s' not found or not installed!", app_uri);
			}
		}
	}
}
