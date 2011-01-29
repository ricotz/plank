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

using GConf;

using Plank.Items;

using Plank.Services;
using Plank.Services.Windows;

namespace Plank
{
	public class DockItems : GLib.Object
	{
		public signal void items_changed ();
		public signal void item_added (DockItem item);
		public signal void item_removed (DockItem item);
		
		public List<DockItem> Items = new List<DockItem> ();
		
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
			if (items_monitor != null) {
				items_monitor.cancel ();
				items_monitor = null;
			}
		}
		
		void signal_items_changed ()
		{
			items_changed ();
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

						// put this into a static method of DockItem?
						DockItem item;
						var launcher = DockItem.get_launcher_from_dockitem (filename);
						if (launcher.has_suffix ("plank.desktop"))
							item = new PlankDockItem.with_dockitem (filename);
						else if (launcher.has_suffix (".desktop"))
							item = new ApplicationDockItem.with_dockitem (filename);
						else
							item = new FileDockItem.with_dockitem (filename);
						
						if (item.ValidItem)
							add_item (item);
						else
							Logger.warn<DockItems> ("The launcher '%s' in dock item '%s' does not exist".printf (item.get_launcher (), filename));
					}
			} catch {
				Logger.fatal<DockItems> ("Error loading dock items");
			}
			
			List<string> favs = new List<string> ();
			
			foreach (DockItem item in Items)
				if ((item is ApplicationDockItem) && !(item is TransientDockItem))
					favs.append (item.get_launcher ());
			
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
			bool is_plank = launcher.has_suffix ("plank.desktop");
			if (!is_plank) {
				if (!app.user_visible ())
					return;
			
				if (launcher != "" && !File.new_for_path (launcher).query_exists ())
					return;
			
				if (WindowControl.get_num_windows (app) == 0)
					return;
			}
			
			var found = item_for_application (app);
			if (found != null) {
				found.set_app (app);
			} else if (!is_plank) {
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
			
			if ((event & (FileMonitorEvent.CREATED | FileMonitorEvent.DELETED)) == 0)
				return;
			
			// remove peristent and invalid items
			List<DockItem> remove = new List<DockItem> ();
			foreach (var item in Items)
				if (!(item is TransientDockItem) || !item.ValidItem)
					remove.append (item);
			foreach (var item in remove)
				remove_item_without_signaling (item);
			
			load_items ();
			add_running_apps ();
			set_item_positions ();
			
			items_changed ();
		}
		
		void add_item_without_signaling (DockItem item) {
			Items.insert_sorted (item, (CompareFunc) compare_items);
			
			item.notify["Icon"].connect (signal_items_changed);
			item.notify["Indicator"].connect (signal_items_changed);
			item.notify["State"].connect (signal_items_changed);
			item.notify["LastClicked"].connect (signal_items_changed);
			
			if (item is ApplicationDockItem)
				(item as ApplicationDockItem).app_closed.connect (app_closed);
			
			if (item is TransientDockItem)
				(item as TransientDockItem).pin_launcher.connect (pin_item);
		}
		
		public void add_item (DockItem item)
		{
			add_item_without_signaling (item);
			set_item_positions ();

			item_added (item);
		}
		
		void remove_item_without_signaling (DockItem item)
		{
			item.notify["Icon"].disconnect (signal_items_changed);
			item.notify["Indicator"].disconnect (signal_items_changed);
			item.notify["State"].disconnect (signal_items_changed);
			item.notify["LastClicked"].disconnect (signal_items_changed);
			
			if (item is ApplicationDockItem)
				(item as ApplicationDockItem).app_closed.disconnect (app_closed);
			
			if (item is TransientDockItem)
				(item as TransientDockItem).pin_launcher.disconnect (pin_item);
			
			Items.remove (item);
		}
			
		public void remove_item (DockItem item)
		{
			remove_item_without_signaling (item);
			set_item_positions ();
			
			item_removed (item);
		}
		
		void pin_item (DockItem item)
		{
			string launcher = item.get_launcher ();
			string dockitem = File.new_for_path (launcher).get_basename ().split (".") [0] + ".dockitem";
			
			if (!make_launcher (dockitem, launcher, item.get_sort ()))
				return;
			
			remove_item_without_signaling (item);
			var new_item = new ApplicationDockItem.with_dockitem (launchers_dir.get_path () + "/" + dockitem);
			new_item.Position = item.Position;
			add_item_without_signaling (new_item);
			
			items_changed ();
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
			try {
				// browser
				string browser = Client.get_default ().get_string ("/desktop/gnome/applications/browser/exec");
				// terminal
				string terminal = Client.get_default ().get_string ("/desktop/gnome/applications/terminal/exec");
				// calendar
				string calendar = Client.get_default ().get_string ("/desktop/gnome/applications/calendar/exec");
				// media
				string media = Client.get_default ().get_string ("/desktop/gnome/applications/media/exec");
				
				if (true)
					return false;
				
				if (browser == null && terminal == null && calendar == null && media == null)
					return false;
				
				// TODO - we need a way to map the exec's to launchers
				make_launcher ("plank.dockitem", Build.DATADIR + "/applications/plank.desktop", 0);
				make_launcher (browser + ".dockitem", browser, 1);
				make_launcher (terminal + ".dockitem", terminal, 2);
				make_launcher (calendar + ".dockitem", calendar, 3);
				make_launcher (media + ".dockitem", media, 4);
				
				return true;
			} catch {
				return false;
			}
		}
		
		void make_default_items ()
		{
			// add plank item!
			make_launcher ("plank.dockitem", Build.DATADIR + "/applications/plank.desktop", 0);
			
			// add browser
			if (!make_launcher ("chromium-browser.dockitem", "/usr/share/applications/chromium-browser.desktop", 1))
				if (!make_launcher ("google-chrome.dockitem", "/usr/local/share/applications/google-chrome.desktop", 1))
					if (!make_launcher ("firefox.dockitem", "/usr/share/applications/firefox.desktop", 1))
						if (!make_launcher ("epiphany.dockitem", "/usr/share/applications/epiphany.desktop", 1))
							make_launcher ("konqbrowser.dockitem", "/usr/share/applications/kde4/konqbrowser.desktop", 1);
			
			// add terminal
			if (!make_launcher ("terminator.dockitem", "/usr/share/applications/terminator.desktop", 2))
				if (!make_launcher ("gnome-terminal.dockitem", "/usr/share/applications/gnome-terminal.desktop", 2))
					make_launcher ("konsole.dockitem", "/usr/share/applications/kde4/konsole.desktop", 2);
			
			// add music player
			if (!make_launcher ("exaile.dockitem", "/usr/share/applications/exaile.desktop", 3))
				if (!make_launcher ("songbird.dockitem", "/usr/share/applications/songbird.desktop", 3))
					if (!make_launcher ("rhythmbox.dockitem", "/usr/share/applications/rhythmbox.desktop", 3))
						if (!make_launcher ("banshee-1.dockitem", "/usr/share/applications/banshee-1.desktop", 3))
							make_launcher ("amarok.dockitem", "/usr/share/applications/kde4/amarok.desktop", 3);
			
			// add IM client
			if (!make_launcher ("pidgin.dockitem", "/usr/share/applications/pidgin.desktop", 4))
				make_launcher ("empathy.dockitem", "/usr/share/applications/empathy.desktop", 4);
		}
		
		bool make_launcher (string dockitem, string launcher, int sort)
		{
			if (!File.new_for_path (launcher).query_exists ())
				return false;
			Logger.debug<DockItems> ("Adding default dock item for launcher '%s'".printf (launcher));
			
			KeyFile file = new KeyFile ();
			
			file.set_string (typeof (Items.DockItemPreferences).name (), "Launcher", launcher);
			file.set_integer (typeof (Items.DockItemPreferences).name (), "Sort", sort);
			
			try {
				var stream = new DataOutputStream (launchers_dir.get_child (dockitem).create (0));
				stream.put_string (file.to_data ());
			} catch {
				return false;
			}
			
			return true;
		}
	}
}
