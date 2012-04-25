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
		 * Triggered when the state of an item changes.
		 */
		public signal void item_state_changed ();
		/**
		 * Triggered anytime an item's Position changes.
		 */
		public signal void item_position_changed ();
		
		/**
		 * Triggered when a new item is added to the collection.
		 */
		public signal void item_added (DockItem item);
		/**
		 * Triggered when an item is removed from the collection.
		 */
		public signal void item_removed (DockItem item);
		
		/**
		 * A list of the dock items.
		 */
		public ArrayList<DockItem> Items = new ArrayList<DockItem> ();

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
			
			Factory.item_factory.launchers_dir = Paths.AppConfigFolder.get_child (Factory.main.dock_path + "/launchers");
			
			// if we made the launcher directory, assume a first run and pre-populate with launchers
			if (Paths.ensure_directory_exists (Factory.item_factory.launchers_dir)) {
				debug ("Adding default dock items...");
				Factory.item_factory.make_default_items ();
				debug ("done.");
			}
			
			try {
				items_monitor = Factory.item_factory.launchers_dir.monitor (0);
				items_monitor.changed.connect (handle_items_dir_changed);
			} catch {
				error ("Unable to watch the launchers directory.");
			}
			
			load_items ();
			
			Matcher.get_default ().app_opened.connect (app_opened);
		}
		
		~DockItems ()
		{
			Matcher.get_default ().app_opened.disconnect (app_opened);
			
			var items = new HashSet<DockItem> ();
			items.add_all (Items);
			foreach (var item in items)
				remove_item_without_signaling (item);
			Items.clear ();
			
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
		 * @param is_initializing if the dock is initializing
		 */
		public void add_item (DockItem item)
		{
			add_item_without_signaling (item);
			
			item_added (item);
		}
		
		/**
		 * Removes a dock item from the collection.
		 *
		 * @param item the dock item to remove
		 */
		public void remove_item (DockItem item)
		{
			remove_item_without_signaling (item);
			
			item_removed (item);
		}
		
		void handle_item_state_changed ()
		{
			item_state_changed ();
		}
		
		ApplicationDockItem? item_for_application (Bamf.Application app)
		{
			foreach (var item in Items) {
				unowned ApplicationDockItem? appitem = (item as ApplicationDockItem);
				if (appitem == null)
					continue;
				if ((appitem.App != null && appitem.App == app) || (appitem.Launcher != null
					&& appitem.Launcher != "" && appitem.Launcher == app.get_desktop_file ()))
					return appitem;
			}
			
			return null;
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
			} catch {
				error ("Error loading dock items");
			}
			
			// add saved dockitems based on their serialized order
			var dockitems = controller.prefs.DockItems.split (";;");
			for (int pos = 0; pos < dockitems.length; pos++)
				foreach (var item in existing_items)
					if (dockitems[pos] == item.DockItemFilename) {
						item.Position = pos;
						add_item (item);
						break;
					}
			
			// add transient and new dockitems
			foreach (var item in new_items)
				add_item (item);
			
			Matcher.get_default ().set_favorites (favs);
			
			debug ("done.");
			
			add_running_apps ();
		}
		
		void add_running_apps ()
		{
			// do this a better more efficient way
			foreach (var app in Matcher.get_default ().active_launchers ())
				app_opened (app);
		}
		
		void app_opened (Bamf.Application app)
		{
			var last_sort = 1000;
			
			foreach (var item in Items)
				if (item is TransientDockItem)
					last_sort = item.Sort;
			
			var launcher = app.get_desktop_file ();
			if (launcher != "" && !File.new_for_path (launcher).query_exists ())
				return;
			
			var found = item_for_application (app);
			if (found != null) {
				found.set_app (app);
			} else if (app.is_user_visible () && WindowControl.get_num_windows (app) > 0) {
				var new_item = new TransientDockItem.with_application (app);
				new_item.Sort = last_sort + 1;
				add_item (new_item);
			}
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
				stdout.printf ("%s ->\n", basename);
				foreach (var item in Items) {
					stdout.printf ("%s[%s]\n", item.Text, item.DockItemFilename);
					if (basename == item.DockItemFilename) {
						skip = true;
						break;
					}
				}
				
				if (skip)
					continue;
				
				Logger.verbose ("DockItems.process_queued_files ('%s')", basename);
				var item = Factory.item_factory.make_item (file);
				add_item (item);
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
			foreach (var item in Items)
				if (f.get_basename () == item.DockItemFilename)
					return;
			
			Logger.verbose ("DockItems.handle_items_dir_changed (processing '%s')", f.get_path ());
			
			queued_files.add (f);
			
			if (!delay_items_monitor_handle)
				process_queued_files ();
		}
		
		/**
		 * Save current item positions
		 */
		public void save_item_positions ()
		{
			saved_item_positions.clear ();
			
			foreach (var item in Items)
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
 			Items.sort ((CompareFunc) compare_items);
			
			update_item_positions ();
			item_position_changed ();
 		}
		
		void update_item_positions ()
		{
			int pos = 0;
			foreach (var item in Items) {
				if (item.Position != pos)
					item.Position = pos;
				pos++;
			}
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
			
			var index_target = Items.index_of (target);
			Items.remove (move);
			Items.insert (index_target, move);
			
			update_item_positions ();
			item_position_changed ();
		}
		
		void add_item_without_signaling (DockItem item)
		{
			if (item.Position == -1) {
				// find a position based on Sort
				DockItem? pos_item = null;
				foreach (var i in Items) {
					pos_item = i;
					if (i.Sort >= item.Sort)
						break;
				}
				
				Items.insert ((pos_item == null ? Items.size : pos_item.Position + 1), item);
			} else {
				Items.add (item);
			}
			
			item.AddTime = new DateTime.now_utc ();
			item_signals_connect (item);
			
			update_item_positions ();
		}
		
		/**
		 * Replace an item with another item.
		 *
		 * @param new_item the new item
		 * @param old_item the item to be replaced
		 */
		public void replace_item (DockItem new_item, DockItem old_item)
		{
			if (new_item == old_item || !Items.contains (old_item))
				return;
			
			Logger.verbose ("DockItems.replace_item (%s[%s, %i] > %s[%s, %i])", old_item.Text, old_item.DockItemFilename, (int)old_item, new_item.Text, new_item.DockItemFilename, (int)new_item);
			
			item_signals_disconnect (old_item);
			
			var index = Items.index_of (old_item);
			Items.remove (old_item);
			Items.insert (index, new_item);
			
			new_item.AddTime = old_item.AddTime;
			item_signals_connect (new_item);
			
			update_item_positions ();
			item_position_changed ();
		}
		
		void remove_item_without_signaling (DockItem item)
		{
			item.RemoveTime = new DateTime.now_utc ();
			item_signals_disconnect (item);
			
			Items.remove (item);
			
			update_item_positions ();
		}
		
		void item_signals_connect (DockItem item)
		{
			item.notify["Icon"].connect (handle_item_state_changed);
			item.notify["Indicator"].connect (handle_item_state_changed);
			item.notify["State"].connect (handle_item_state_changed);
			item.notify["LastClicked"].connect (handle_item_state_changed);
			item.needs_redraw.connect (handle_item_state_changed);
			item.deleted.connect (handle_item_deleted);
			
			if (item is ApplicationDockItem) {
				(item as ApplicationDockItem).app_closed.connect (app_closed);
				(item as ApplicationDockItem).pin_launcher.connect (pin_item);
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
			
			if (item is ApplicationDockItem) {
				(item as ApplicationDockItem).app_closed.disconnect (app_closed);
				(item as ApplicationDockItem).pin_launcher.disconnect (pin_item);
			}
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
				var last_sort = 0;
				
				foreach (var i in Items) {
					if (i == item)
						break;
					if (!(i is TransientDockItem))
						last_sort = i.Sort;
				}
				
				var dockitem_file = Factory.item_factory.make_dock_item (item.Launcher, last_sort + 1);
				if (dockitem_file == null)
					return;
				
				var new_item = new ApplicationDockItem.with_dockitem_file (dockitem_file);
				if (app_item.App != null)
					new_item.set_app (app_item.App);
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
