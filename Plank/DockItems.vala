//  
//  Copyright (C) 2011 Robert Dyer
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

using Plank.Services.Logging;
using Plank.Services.Paths;

namespace Plank
{
	public class DockItems : GLib.Object
	{
		public signal void items_changed ();
		
		public List<DockItem> Items = new List<DockItem> ();
		
		FileMonitor items_monitor;
		File launchers_dir;
		
		public DockItems ()
		{
			launchers_dir = Paths.UserConfigFolder.get_child ("launchers");
			
			// if we made the launcher directory, assume a first run and pre-populate with launchers
			if (Paths.ensure_directory_exists (launchers_dir)) {
				Logger.debug<DockItems> ("Adding default dock items...");
				
				if (!load_default_gnome_items ())
					load_default_items ();
				
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
		}
		
		bool load_default_gnome_items ()
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
				make_launcher (browser + ".dockitem", browser, 0);
				make_launcher (terminal + ".dockitem", terminal, 1);
				make_launcher (calendar + ".dockitem", calendar, 2);
				make_launcher (media + ".dockitem", media, 3);
			} catch {
				return false;
			}
			
			return true;
		}
		
		void load_default_items ()
		{
			// add browser
			if (!make_launcher ("chromium-browser.dockitem", "/usr/share/applications/chromium-browser.desktop", 0))
				if (!make_launcher ("google-chrome.dockitem", "/usr/local/share/applications/google-chrome.desktop", 0))
					if (!make_launcher ("firefox.dockitem", "/usr/share/applications/firefox.desktop", 0))
						if (!make_launcher ("epiphany.dockitem", "/usr/share/applications/epiphany.desktop", 0))
							make_launcher ("konqbrowser.dockitem", "/usr/share/applications/kde4/konqbrowser.desktop", 0);
			
			// add terminal
			if (!make_launcher ("terminator.dockitem", "/usr/share/applications/terminator.desktop", 1))
				if (!make_launcher ("gnome-terminal.dockitem", "/usr/share/applications/gnome-terminal.desktop", 1))
					make_launcher ("konsole.dockitem", "/usr/share/applications/kde4/konsole.desktop", 1);
			
			// add music player
			if (!make_launcher ("exaile.dockitem", "/usr/share/applications/exaile.desktop", 2))
				if (!make_launcher ("songbird.dockitem", "/usr/share/applications/songbird.desktop", 2))
					if (!make_launcher ("rhythmbox.dockitem", "/usr/share/applications/rhythmbox.desktop", 2))
						if (!make_launcher ("banshee-1.dockitem", "/usr/share/applications/banshee-1.desktop", 2))
							make_launcher ("amarok.dockitem", "/usr/share/applications/kde4/amarok.desktop", 2);
			
			// add IM client
			if (!make_launcher ("pidgin.dockitem", "/usr/share/applications/pidgin.desktop", 3))
				make_launcher ("empathy.dockitem", "/usr/share/applications/empathy.desktop", 3);
		}
		
		void load_items ()
		{
			Logger.debug<DockItems> ("Reloading dock items...");
			
			try {
				var enumerator = launchers_dir.enumerate_children (FILE_ATTRIBUTE_STANDARD_NAME + "," + FILE_ATTRIBUTE_ACCESS_CAN_READ, 0);
				FileInfo info;
				while ((info = enumerator.next_file ()) != null)
					if (file_is_dockitem (info)) {
						var filename = launchers_dir.get_path () + "/" + info.get_name ();
						var item = new ApplicationDockItem (filename);
						
						if (item.ValidItem)
							add_item (item);
						else
							Logger.warn<DockItems> ("The launcher '%s' in dock item '%s' does not exist".printf (item.Launcher, filename));
					}
			} catch { }
			
			Logger.debug<DockItems> ("done.");
			
			items_changed ();
		}
		
		bool file_is_dockitem (FileInfo info)
		{
			return !info.get_is_hidden () && info.get_name ().has_suffix (".dockitem");
		}
		
		void handle_items_dir_changed (File f, File? other, FileMonitorEvent event)
		{
			try {
				if (!file_is_dockitem (f.query_info (FILE_ATTRIBUTE_STANDARD_NAME + "," + FILE_ATTRIBUTE_ACCESS_CAN_READ, 0)))
					return;
			} catch {
				return;
			}
			
			if ((event & (FileMonitorEvent.CREATED | FileMonitorEvent.DELETED)) == 0)
				return;
			
			Items = new List<DockItem> ();
			load_items ();
		}
		
		void add_item (DockItem item)
		{
			Items.insert_sorted (item, (a, b) => {
				return compare_items (a as DockItem, b as DockItem);
			});
			
			item.notify["Icon"].connect (() => { items_changed (); });
			
			int pos = 0;
			foreach (DockItem i in Items)
				i.Position = pos++;
		}
		
		public static int compare_items (DockItem left, DockItem right)
		{
			if (left.get_sort () == right.get_sort ())
				return 0;
			if (left.get_sort () < right.get_sort ())
				return -1;
			return 1;
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
