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
				Logger.debug<DockItems> ("Adding default dockitems");
				
				make_launcher ("firefox.dockitem", "/usr/share/applications/firefox.desktop", 0);
				make_launcher ("gnome-terminal.dockitem", "/usr/share/applications/gnome-terminal.desktop", 1);
				make_launcher ("pidgin.dockitem", "/usr/share/applications/pidgin.desktop", 2);
			}
			
			try {
				items_monitor = launchers_dir.monitor (0);
				items_monitor.set_rate_limit (500);
				items_monitor.changed.connect (handle_items_dir_changed);
			} catch {
				Logger.fatal<DockItems> ("Unable to watch the launchers directory.  Plank will not function properly.");
			}
			
			load_items ();
		}
		
		void load_items ()
		{
			Logger.debug<DockItems> ("Reloading items...");
			
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
							Logger.warn<DockItems> ("The launcher '%s' in '%s' does not exist".printf (item.Launcher, filename));
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
				DockItem left = a as DockItem;
				DockItem right = b as DockItem;
				if (left.get_sort () == right.get_sort ())
					return 0;
				if (left.get_sort () < right.get_sort ())
					return -1;
				return 1;
			});
			
			int pos = 0;
			foreach (DockItem i in Items)
				i.Position = pos++;
		}
		
		void make_launcher (string dockitem, string launcher, int sort)
		{
			KeyFile file = new KeyFile ();
			
			file.set_string (typeof (Items.DockItemPreferences).name (), "Launcher", launcher);
			file.set_integer (typeof (Items.DockItemPreferences).name (), "Sort", sort);
			
			try {
				var stream = new DataOutputStream (launchers_dir.get_child (dockitem).create (0));
				stream.put_string (file.to_data ());
			} catch { }
		}
	}
}
