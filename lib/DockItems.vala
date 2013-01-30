//  
//  Copyright (C) 2011-2012 Robert Dyer, Rico Tzschichholz
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
using Plank.Items;
using Plank.Widgets;

using Plank.Services;
using Plank.Services.Windows;

namespace Plank
{
	/**
	 * A container and controller class for managing dock items on a dock.
	 */
	public class DockItems : GLib.Object
	{
		/**
		 * Triggered when the items collection has changed.
		 *
		 * @param added the list of added items
		 * @param removed the list of removed items
		 */
		public signal void items_changed (Gee.List<DockItem> added, Gee.List<DockItem> removed);
		
		/**
		 * Triggered when the state of an item changes.
		 */
		public signal void item_state_changed ();
		/**
		 * Triggered anytime an item's Position changes.
		 */
		public signal void item_position_changed ();
		
		/**
		 * A list of the dock items.
		 */
		public unowned ArrayList<DockItem> Items {
			get {
				return visible_items;
			}
		}
		
		ArrayList<DockItem> visible_items = new ArrayList<DockItem> ();
		ArrayList<DockItem> internal_items = new ArrayList<DockItem> ();
		
		Gee.Map<DockItem, int> saved_item_positions = new HashMap<DockItem, int> ();
		
		FileMonitor? items_monitor = null;
		bool delay_items_monitor_handle = false;
		ArrayList<GLib.File> queued_files = new ArrayList<GLib.File> ();
		
		DockController controller;
		
		/**
		 * Creates a new container for dock items.
		 *
		 * @param controller the dock controller that owns these items
		 */
		public DockItems (DockController controller)
		{
			this.controller = controller;
			
			Factory.item_factory.launchers_dir = Paths.AppConfigFolder.get_child (Factories.AbstractMain.dock_path + "/launchers");
			
			// if we made the launcher directory, assume a first run and pre-populate with launchers
			if (Paths.ensure_directory_exists (Factory.item_factory.launchers_dir)) {
				debug ("Adding default dock items...");
				Factory.item_factory.make_default_items ();
				debug ("done.");
			}
			
			try {
				items_monitor = Factory.item_factory.launchers_dir.monitor (0);
				items_monitor.changed.connect (handle_items_dir_changed);
			} catch (Error e) {
				error ("Unable to watch the launchers directory. (%s)", e.message);
			}
			
			load_items ();
			add_running_apps ();
			update_visible_items ();
			serialize_item_positions ();
			
			controller.prefs.changed["CurrentWorkspaceOnly"].connect (handle_setting_changed);
			
			item_position_changed.connect (serialize_item_positions);
			items_changed.connect (serialize_item_positions);
			Matcher.get_default ().app_opened.connect (app_opened);
			
			var wnck_screen = Wnck.Screen.get_default ();
			wnck_screen.active_window_changed.connect (handle_window_changed);
			wnck_screen.active_workspace_changed.connect (handle_workspace_changed);
			wnck_screen.viewports_changed.connect (handle_viewports_changed);
		}
		
		~DockItems ()
		{
			item_position_changed.disconnect (serialize_item_positions);
			items_changed.disconnect (serialize_item_positions);
			controller.prefs.changed["CurrentWorkspaceOnly"].disconnect (handle_setting_changed);
			
			Matcher.get_default ().app_opened.disconnect (app_opened);
			
			var wnck_screen = Wnck.Screen.get_default ();
			wnck_screen.active_window_changed.disconnect (handle_window_changed);
			wnck_screen.active_workspace_changed.disconnect (handle_workspace_changed);
			wnck_screen.viewports_changed.disconnect (handle_viewports_changed);
			
			saved_item_positions.clear ();
			visible_items.clear ();
			
			var items = new HashSet<DockItem> ();
			items.add_all (internal_items);
			foreach (var item in items)
				remove_item_without_signaling (item);
			internal_items.clear ();
			
			if (items_monitor != null) {
				items_monitor.changed.disconnect (handle_items_dir_changed);
				items_monitor.cancel ();
				items_monitor = null;
			}
		}
		
		/**
		 * Adds a dock item to the collection.
		 *
		 * @param item the dock item to add
		 */
		public void add_item (DockItem item)
		{
			add_item_without_signaling (item);
			
			update_visible_items ();
		}
		
		/**
		 * Removes a dock item from the collection.
		 *
		 * @param item the dock item to remove
		 */
		public void remove_item (DockItem item)
		{
			remove_item_without_signaling (item);
			
			update_visible_items ();
		}
		
		void handle_item_state_changed ()
		{
			item_state_changed ();
		}
		
		ApplicationDockItem? item_for_application (Bamf.Application app)
		{
			foreach (var item in internal_items) {
				unowned ApplicationDockItem? appitem = (item as ApplicationDockItem);
				if (appitem == null)
					continue;
				if ((appitem.App != null && appitem.App == app) || (appitem.Launcher != null
					&& appitem.Launcher != "" && appitem.Launcher == app.get_desktop_file ()))
					return appitem;
			}
			
			return null;
		}
		
		public bool item_exists_for_uri (string uri)
		{
			var launcher = uri.replace ("file://", "");
			foreach (var item in internal_items)
				if (item.Launcher == launcher)
					return true;
			
			return false;
		}
		
		public void add_item_with_launcher (string launcher, DockItem? target = null)
		{
			if (launcher == null || launcher == "")
				return;
			
			// delay automatic add of new dockitems while creating this new one
			delay_items_monitor ();
			
			var dockitem_file = Factory.item_factory.make_dock_item (launcher);
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
				var enumerator = Factory.item_factory.launchers_dir.enumerate_children (FILE_ATTRIBUTE_STANDARD_NAME + "," + FILE_ATTRIBUTE_STANDARD_IS_HIDDEN, 0);
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
		
		void update_visible_items ()
		{
			Logger.verbose ("DockItems.update_visible_items ()");
			
			var old_items = new ArrayList<DockItem> ();
			old_items.add_all (visible_items);
			
			visible_items.clear ();
			
			if (controller.prefs.CurrentWorkspaceOnly) {
				var active_workspace = Wnck.Screen.get_default ().get_active_workspace ();
				foreach (var item in internal_items) {
					var transient = (item as TransientDockItem);
					if (transient != null
						&& !WindowControl.has_window_on_workspace (transient.App, active_workspace))
						continue;
					visible_items.add (item);
				}
			} else {
				visible_items.add_all (internal_items);
			}
			
			set_item_positions ();
			
			var added_items = new ArrayList<DockItem> ();
			added_items.add_all (visible_items);
			added_items.remove_all (old_items);
			
			var removed_items = old_items;
			removed_items.remove_all (visible_items);
			
			if (added_items.size > 0 || removed_items.size > 0)
				items_changed (added_items, removed_items);
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
		
		void set_item_positions ()
		{
			int pos = 0;
			foreach (var i in visible_items)
				i.Position = pos++;
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
				
				Logger.verbose ("DockItems.process_queued_files ('%s')", basename);
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
				if (!file_is_dockitem (f.query_info (FILE_ATTRIBUTE_STANDARD_NAME + "," + FILE_ATTRIBUTE_STANDARD_IS_HIDDEN, 0)))
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
			
			Logger.verbose ("DockItems.handle_items_dir_changed (processing '%s')", f.get_path ());
			
			queued_files.add (f);
			
			if (!delay_items_monitor_handle)
				process_queued_files ();
		}
		
		void handle_setting_changed ()
		{
			update_visible_items ();
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
		
		/**
		 * Save current item positions
		 */
		public void save_item_positions ()
		{
			saved_item_positions.clear ();
			
			foreach (var item in visible_items)
				saved_item_positions[item] = item.Position;
		}
		
		/**
		 * Restore previously saved item positions
		 */
		public void restore_item_positions ()
		{
			if (saved_item_positions.size == 0)
				return;
			
			foreach (var entry in saved_item_positions.entries)
				entry.key.Position = entry.value;
 			visible_items.sort ((CompareFunc) compare_items);
			
			saved_item_positions.clear ();
			
			set_item_positions ();
			item_position_changed ();
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
		
		/**
		 * Move an item to the position of another item.
		 * This shifts all items which are between these two items.
		 *
		 * @param move the item to move
		 * @param target the item of the new position
		 */
		public void move_item_to (DockItem move, DockItem target)
		{
			if (move == target)
				return;
			
			var index_target = internal_items.index_of (target);
			internal_items.remove (move);
			internal_items.insert (index_target, move);
			
			if (visible_items.contains (move) && (index_target = visible_items.index_of (target)) >= 0) {
				visible_items.remove (move);
				visible_items.insert (index_target, move);
				set_item_positions ();
			} else {
				update_visible_items ();
			}
			
			item_position_changed ();
		}
		
		void add_item_without_signaling (DockItem item)
		{
			if (item.Position > -1 && item.Position <= internal_items.size) {
				internal_items.insert (item.Position, item);
			} else {
				internal_items.add (item);
			}
			
			item.AddTime = new DateTime.now_utc ();
			item_signals_connect (item);
		}
		
		/**
		 * Replace an item with another item.
		 *
		 * @param new_item the new item
		 * @param old_item the item to be replaced
		 */
		public void replace_item (DockItem new_item, DockItem old_item)
		{
			if (new_item == old_item || !internal_items.contains (old_item))
				return;
			
			Logger.verbose ("DockItems.replace_item (%s[%s, %i] > %s[%s, %i])", old_item.Text, old_item.DockItemFilename, (int)old_item, new_item.Text, new_item.DockItemFilename, (int)new_item);
			
			item_signals_disconnect (old_item);
			
			var index = internal_items.index_of (old_item);
			internal_items.remove (old_item);
			internal_items.insert (index, new_item);
			
			new_item.AddTime = old_item.AddTime;
			new_item.Position = old_item.Position;
			item_signals_connect (new_item);
			
			if ((index = visible_items.index_of (old_item)) >= 0) {
				visible_items.remove (old_item);
				visible_items.insert (index, new_item);
			} else {
				update_visible_items ();
			}
			
			item_position_changed ();
		}
		
		void remove_item_without_signaling (DockItem item)
		{
			item.RemoveTime = new DateTime.now_utc ();
			item_signals_disconnect (item);
			
			internal_items.remove (item);
			controller.unity.remove_entry (item);
		}
		
		void item_signals_connect (DockItem item)
		{
			item.notify["Icon"].connect (handle_item_state_changed);
			item.notify["Indicator"].connect (handle_item_state_changed);
			item.notify["State"].connect (handle_item_state_changed);
			item.notify["LastClicked"].connect (handle_item_state_changed);
			item.needs_redraw.connect (handle_item_state_changed);
			item.deleted.connect (handle_item_deleted);
			
			unowned ApplicationDockItem? appitem = (item as ApplicationDockItem);
			if (appitem != null) {
				appitem.app_closed.connect (app_closed);
				appitem.app_window_added.connect (handle_item_app_window_added);
				appitem.pin_launcher.connect (pin_item);
			}
		}
		
		void item_signals_disconnect (DockItem item)
		{
			item.notify["Icon"].disconnect (handle_item_state_changed);
			item.notify["Indicator"].disconnect (handle_item_state_changed);
			item.notify["State"].disconnect (handle_item_state_changed);
			item.notify["LastClicked"].disconnect (handle_item_state_changed);
			item.needs_redraw.disconnect (handle_item_state_changed);
			item.deleted.disconnect (handle_item_deleted);
			
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
		
		void handle_item_deleted (DockItem item)
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
			Logger.verbose ("DockItems.pin_item ('%s[%s]')", item.Text, item.DockItemFilename);

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
		
		static int compare_items (DockItem left, DockItem right)
		{
			if (left.Position == right.Position)
				return 0;
			if (left.Position < right.Position)
				return -1;
			return 1;
		}
	}
}
