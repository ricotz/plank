//  
//  Copyright (C) 2011 Robert Dyer, Rico Tzschichholz
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
		
		FileMonitor? items_monitor = null;
		
		/**
		 * Creates a new container for dock items.
		 */
		public DockItems ()
		{
			Factory.item_factory.launchers_dir = Paths.AppConfigFolder.get_child ("launchers");
			
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
			add_running_apps ();
			set_item_positions ();
			
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
		 */
		public void add_item (DockItem item)
		{
			add_item_without_signaling (item);
			set_item_positions ();

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
			set_item_positions ();
			
			item_removed (item);
		}
		
		void signal_item_state_changed ()
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
			
			try {
				var enumerator = Factory.item_factory.launchers_dir.enumerate_children (FILE_ATTRIBUTE_STANDARD_NAME + "," + FILE_ATTRIBUTE_STANDARD_IS_HIDDEN, 0);
				FileInfo info;
				while ((info = enumerator.next_file ()) != null)
					if (file_is_dockitem (info)) {
						var filename = Factory.item_factory.launchers_dir.get_path () + "/" + info.get_name ();
						var item = Factory.item_factory.make_item (filename);
						
						if (item.ValidItem)
							add_item (item);
						else
							warning ("The launcher '%s' in dock item '%s' does not exist", item.Launcher, filename);
					}
			} catch {
				error ("Error loading dock items");
			}
			
			var favs = new ArrayList<string> ();
			
			foreach (var item in Items)
				if ((item is ApplicationDockItem) && !(item is TransientDockItem))
					favs.add (item.Launcher);
			
			Matcher.get_default ().set_favorites (favs);
			
			debug ("done.");
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
			else if (remove is ApplicationDockItem)
				(remove as ApplicationDockItem).set_app (null);
		}
		
		void set_item_positions ()
		{
			int pos = 0;
			foreach (var i in Items)
				i.Position = pos++;
		}
		
		bool file_is_dockitem (FileInfo info)
		{
			return !info.get_is_hidden () && info.get_name ().has_suffix (".dockitem");
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
			
			// remove peristent and invalid items
			var remove = new ArrayList<DockItem> ();
			foreach (var item in Items)
				if (!(item is TransientDockItem) || !item.ValidItem)
					remove.add (item);
			foreach (var item in remove)
				remove_item_without_signaling (item);
			
			load_items ();
			add_running_apps ();
			set_item_positions ();
			
			item_state_changed ();
		}
		
		void add_item_without_signaling (DockItem item)
		{
			Items.add (item);
			Items.sort ((CompareFunc) compare_items);
			
			item.AddTime = new DateTime.now_utc ();
			item.notify["Icon"].connect (signal_item_state_changed);
			item.notify["Indicator"].connect (signal_item_state_changed);
			item.notify["State"].connect (signal_item_state_changed);
			item.notify["LastClicked"].connect (signal_item_state_changed);
			item.needs_redraw.connect (signal_item_state_changed);
			item.deleted.connect (handle_item_deleted);
			
			if (item is ApplicationDockItem) {
				(item as ApplicationDockItem).app_closed.connect (app_closed);
				(item as ApplicationDockItem).pin_launcher.connect (pin_item);
			}
		}
		
		void remove_item_without_signaling (DockItem item)
		{
			item.RemoveTime = new DateTime.now_utc ();
			item.notify["Icon"].disconnect (signal_item_state_changed);
			item.notify["Indicator"].disconnect (signal_item_state_changed);
			item.notify["State"].disconnect (signal_item_state_changed);
			item.notify["LastClicked"].disconnect (signal_item_state_changed);
			item.needs_redraw.disconnect (signal_item_state_changed);
			item.deleted.disconnect (handle_item_deleted);
			
			if (item is ApplicationDockItem) {
				(item as ApplicationDockItem).app_closed.disconnect (app_closed);
				(item as ApplicationDockItem).pin_launcher.disconnect (pin_item);
			}
			
			Items.remove (item);
		}
		
		void handle_item_deleted (DockItem item)
		{
			Bamf.Application? app = null;
			if (item is ApplicationDockItem)
				app = (item as ApplicationDockItem).App;
			
			remove_item_without_signaling (item);
			
			if (app != null) {
				var new_item = new TransientDockItem.with_application (app);
				new_item.Position = item.Position;
				add_item_without_signaling (new_item);
			}
			
			set_item_positions ();
			item_state_changed ();
		}
		
		void pin_item (DockItem item)
		{
			if (item is TransientDockItem) {
				var dockitem = Factory.item_factory.make_dock_item (item.Launcher, item.Sort);
				if (dockitem == "")
					return;
				
				remove_item_without_signaling (item);
				var new_item = new ApplicationDockItem.with_dockitem (Factory.item_factory.launchers_dir.get_child (dockitem).get_path () ?? "");
				new_item.Position = item.Position;
				add_item_without_signaling (new_item);
				
				item_state_changed ();
			} else {
				item.delete ();
			}
		}
		
		static int compare_items (DockItem left, DockItem right)
		{
			if (left.Sort == right.Sort)
				return 0;
			if (left.Sort < right.Sort)
				return -1;
			return 1;
		}
	}
}
