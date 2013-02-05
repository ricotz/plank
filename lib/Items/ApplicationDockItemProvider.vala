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
		FileMonitor? items_monitor = null;
		bool delay_items_monitor_handle = false;
		ArrayList<GLib.File> queued_files = new ArrayList<GLib.File> ();
		
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
			
			controller.prefs.changed["CurrentWorkspaceOnly"].connect (handle_setting_changed);
			
			Matcher.get_default ().app_opened.connect (app_opened);
			
			var wnck_screen = Wnck.Screen.get_default ();
			wnck_screen.active_window_changed.connect (handle_window_changed);
			wnck_screen.active_workspace_changed.connect (handle_workspace_changed);
			wnck_screen.viewports_changed.connect (handle_viewports_changed);
			
			try {
				items_monitor = Factory.item_factory.launchers_dir.monitor (0);
				items_monitor.changed.connect (handle_items_dir_changed);
			} catch (Error e) {
				error ("Unable to watch the launchers directory. (%s)", e.message);
			}
		}
		
		~ApplicationDockItemProvider ()
		{
			controller.prefs.changed["CurrentWorkspaceOnly"].disconnect (handle_setting_changed);
			
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
					var transient = (item as TransientDockItem);
					item.IsVisible = (transient == null
						|| WindowControl.has_window_on_workspace (transient.App, active_workspace));
				}
			} else {
				foreach (var item in internal_items)
					item.IsVisible = true;
			}
			
			base.update_visible_items ();
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
			if (remove is TransientDockItem)
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
			Bamf.Application? app = null;
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

			var app_item = (item as ApplicationDockItem);
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
	}
}
