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
	public class DockItems : GLib.Object
	{
		// triggered when the state of an item changes
		public signal void item_state_changed ();
		
		// triggered when a new item is added to the collection
		public signal void item_added (DockItem item);
		// triggered when an item is removed from the collection
		public signal void item_removed (DockItem item);
		
		public ArrayList<DockItem> Items = new ArrayList<DockItem> ();
		
		FileMonitor items_monitor;
		File launchers_dir;
		
		public DockItems ()
		{
			launchers_dir = Paths.UserConfigFolder.get_child ("launchers");
			
			// if we made the launcher directory, assume a first run and pre-populate with launchers
			if (Paths.ensure_directory_exists (launchers_dir)) {
				Logger.debug<DockItems> ("Adding default dock items...");
				
				if (!make_default_gnome_items ())
					make_default_items ();
				
				Logger.debug<DockItems> ("done.");
			}
			
			try {
				items_monitor = launchers_dir.monitor (0);
				items_monitor.set_rate_limit (500);
				items_monitor.changed.connect (handle_items_dir_changed);
			} catch {
				Logger.fatal<DockItems> ("Unable to watch the launchers directory.");
			}
			
			load_items ();
			add_running_apps ();
			set_item_positions ();
			
			Matcher.get_default ().app_opened.connect (app_opened);
		}
		
		~DockItems ()
		{
			Matcher.get_default ().app_opened.disconnect (app_opened);
			
			Set<DockItem> items = new HashSet<DockItem> ();
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
		
		public void add_item (DockItem item)
		{
			add_item_without_signaling (item);
			set_item_positions ();

			item_added (item);
		}
		
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
			foreach (DockItem item in Items) {
				unowned ApplicationDockItem appitem = (item as ApplicationDockItem);
				if (appitem == null)
					continue;
				if ((appitem.App != null && appitem.App == app) || (appitem.get_launcher () != null
					&& appitem.get_launcher () != "" && appitem.get_launcher () == app.get_desktop_file ()))
					return appitem;
			}
			
			return null;
		}
		
		void load_items ()
		{
			Logger.debug<DockItems> ("Reloading dock items...");
			
			try {
				var enumerator = launchers_dir.enumerate_children (FILE_ATTRIBUTE_STANDARD_NAME + "," + FILE_ATTRIBUTE_STANDARD_IS_HIDDEN, 0);
				FileInfo info;
				while ((info = enumerator.next_file ()) != null)
					if (file_is_dockitem (info)) {
						var filename = launchers_dir.get_path () + "/" + info.get_name ();
						DockItem item = Factory.item_factory.make_item (filename);
						
						if (item.ValidItem)
							add_item (item);
						else
							Logger.warn<DockItems> ("The launcher '%s' in dock item '%s' does not exist".printf (item.get_launcher (), filename));
					}
			} catch {
				Logger.fatal<DockItems> ("Error loading dock items");
			}
			
			ArrayList<string> favs = new ArrayList<string> ();
			
			foreach (DockItem item in Items)
				if ((item is ApplicationDockItem) && !(item is TransientDockItem))
					favs.add (item.get_launcher ());
			
			Matcher.get_default ().set_favorites (favs);
			
			Logger.debug<DockItems> ("done.");
		}
		
		void add_running_apps ()
		{
			// do this a better more efficient way
			foreach (Bamf.Application app in Matcher.get_default ().active_launchers ())
				app_opened (app);
		}
		
		void app_opened (Bamf.Application app)
		{
			var last_sort = 1000;
			
			foreach (DockItem item in Items)
				if (item is TransientDockItem)
					last_sort = item.get_sort ();
			
			var launcher = app.get_desktop_file ();
			if (launcher != "" && !File.new_for_path (launcher).query_exists ())
				return;
			
			var found = item_for_application (app);
			if (found != null) {
				found.set_app (app);
			} else if (app.user_visible () && WindowControl.get_num_windows (app) > 0) {
				var new_item = new TransientDockItem.with_application (app);
				new_item.set_sort (last_sort + 1);
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
			foreach (DockItem i in Items)
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
			ArrayList<DockItem> remove = new ArrayList<DockItem> ();
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
				var dockitem = make_dock_item (item.get_launcher (), item.get_sort ());
				if (dockitem == "")
					return;
				
				remove_item_without_signaling (item);
				var new_item = new ApplicationDockItem.with_dockitem (launchers_dir.get_child (dockitem).get_path ());
				new_item.Position = item.Position;
				add_item_without_signaling (new_item);
				
				item_state_changed ();
			} else {
				item.delete ();
			}
		}
		
		static int compare_items (DockItem left, DockItem right)
		{
			if (left.get_sort () == right.get_sort ())
				return 0;
			if (left.get_sort () < right.get_sort ())
				return -1;
			return 1;
		}
		
		bool make_default_gnome_items ()
		{
			var browser = AppInfo.get_default_for_type ("text/html", false);
			// TODO dont know how to get terminal...
			var terminal = AppInfo.get_default_for_uri_scheme ("ssh");
			var calendar = AppInfo.get_default_for_type ("text/calendar", false);
			var media = AppInfo.get_default_for_type ("video/mpeg", false);
			
			if (browser == null && terminal == null && calendar == null && media == null)
				return false;
			
			make_dock_item (Factory.main.build_data_dir + "/applications/plank.desktop", 0);
			if (browser != null)
				make_dock_item (new DesktopAppInfo (browser.get_id ()).get_filename (), 1);
			if (terminal != null)
				make_dock_item (new DesktopAppInfo (terminal.get_id ()).get_filename (), 2);
			if (calendar != null)
				make_dock_item (new DesktopAppInfo (calendar.get_id ()).get_filename (), 3);
			if (media != null)
				make_dock_item (new DesktopAppInfo (media.get_id ()).get_filename (), 4);
			
			return true;
		}
		
		void make_default_items ()
		{
			// add plank item!
			make_dock_item (Factory.main.build_data_dir + "/applications/plank.desktop", 0);
			
			// add browser
			if (make_dock_item ("/usr/share/applications/chromium-browser.desktop", 1) == "")
				if (make_dock_item ("/usr/local/share/applications/google-chrome.desktop", 1) == "")
					if (make_dock_item ("/usr/share/applications/firefox.desktop", 1) == "")
						if (make_dock_item ("/usr/share/applications/epiphany.desktop", 1) == "")
							make_dock_item ("/usr/share/applications/kde4/konqbrowser.desktop", 1);
			
			// add terminal
			if (make_dock_item ("/usr/share/applications/terminator.desktop", 2) == "")
				if (make_dock_item ("/usr/share/applications/gnome-terminal.desktop", 2) == "")
					make_dock_item ("/usr/share/applications/kde4/konsole.desktop", 2);
			
			// add music player
			if (make_dock_item ("/usr/share/applications/exaile.desktop", 3) == "")
				if (make_dock_item ("/usr/share/applications/songbird.desktop", 3) == "")
					if (make_dock_item ("/usr/share/applications/rhythmbox.desktop", 3) == "")
						if (make_dock_item ("/usr/share/applications/banshee-1.desktop", 3) == "")
							make_dock_item ("/usr/share/applications/kde4/amarok.desktop", 3);
			
			// add IM client
			if (make_dock_item ("/usr/share/applications/pidgin.desktop", 4) == "")
				make_dock_item ("/usr/share/applications/empathy.desktop", 4);
		}
		
		string make_dock_item (string launcher, int sort)
		{
			if (File.new_for_path (launcher).query_exists ()) {
				KeyFile file = new KeyFile ();
				
				file.set_string (typeof (Items.DockItemPreferences).name (), "Launcher", launcher);
				file.set_integer (typeof (Items.DockItemPreferences).name (), "Sort", sort);
				
				try {
					// find a unique file name, based on the name of the launcher
					var launcher_base = File.new_for_path (launcher).get_basename ().split (".") [0];
					var dockitem = launcher_base + ".dockitem";
					var counter = 1;
					
					while (launchers_dir.get_child (dockitem).query_exists ())
						dockitem = "%s-%d.dockitem".printf (launcher_base, counter++);
					
					// save the key file
					var stream = new DataOutputStream (launchers_dir.get_child (dockitem).create (0));
					stream.put_string (file.to_data ());
					
					Logger.debug<DockItems> ("Adding dock item '%s' for launcher '%s'".printf (dockitem, launcher));
					return dockitem;
				} catch { }
			}
			
			return "";
		}
	}
}
