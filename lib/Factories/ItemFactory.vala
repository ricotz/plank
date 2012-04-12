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
using Plank.Services;

namespace Plank.Factories
{
	/**
	 * An item factory.  Creates {@link Items.DockItem}s based on .dockitem files.
	 */
	public class ItemFactory : GLib.Object
	{
		/**
		 * The directory containing .dockitem files.
		 */
		public File launchers_dir;
		
		/**
		 * Creates a new {@link Items.DockItem} from a .dockitem.
		 *
		 * @param dock_item_filename the .dockitem file to parse
		 * @return the new {@link Items.DockItem} created
		 */
		public virtual DockItem make_item (string dock_item_filename)
		{
			return default_make_item (dock_item_filename, get_launcher_from_dockitem (dock_item_filename));
		}
		
		/**
		 * Creates a new {@link Items.DockItem} for a launcher parsed from a .dockitem.
		 *
		 * @param dock_item_filename the .dockitem file that was parsed
		 * @param launcher the launcher name from the .dockitem
		 * @return the new {@link Items.DockItem} created
		 */
		protected DockItem default_make_item (string dock_item_filename, string launcher)
		{
			if (Factory.main.is_launcher_for_dock (launcher))
				return new PlankDockItem.with_dockitem (dock_item_filename);
			if (launcher.has_suffix (".desktop"))
				return new ApplicationDockItem.with_dockitem (dock_item_filename);
			return new FileDockItem.with_dockitem (dock_item_filename);
		}
		
		/**
		 * Parses a .dockitem to get the launcher from it.
		 *
		 * @param dockitem the .dockitem to parse
		 * @return the launcher from the .dockitem
		 */
		protected string get_launcher_from_dockitem (string dockitem)
		{
			try {
				var file = new KeyFile ();
				file.load_from_file (dockitem, 0);
				
				return file.get_string (typeof (Items.DockItemPreferences).name (), "Launcher");
			} catch {
				return "";
			}
		}
		
		bool make_default_gnome_items ()
		{
			var browser = AppInfo.get_default_for_type ("text/html", false);
			// FIXME dont know how to get terminal...
			var terminal = AppInfo.get_default_for_uri_scheme ("ssh");
			var calendar = AppInfo.get_default_for_type ("text/calendar", false);
			var media = AppInfo.get_default_for_type ("video/mpeg", false);
			
			if (browser == null && terminal == null && calendar == null && media == null)
				return false;
			
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
		
		/**
		 * Creates a bunch of default .dockitem's.
		 */
		public void make_default_items ()
		{
			// add plank item!
			make_dock_item ((Paths.DataFolder.get_parent ().get_path () ?? "") + "/applications/" + Factory.main.app_launcher, 0);
			
			if (make_default_gnome_items ())
				return;
			
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
		
		/**
		 * Creates a new .dockitem for a launcher.
		 *
		 * @param launcher the launcher to create a .dockitem for
		 * @param sort the Sort value in the new .dockitem
		 * @return the name of the new .dockitem created
		 */
		public string make_dock_item (string launcher, int sort)
		{
			if (File.new_for_path (launcher).query_exists ()) {
				var file = new KeyFile ();
				
				file.set_string (typeof (Items.DockItemPreferences).name (), "Launcher", launcher);
				file.set_integer (typeof (Items.DockItemPreferences).name (), "Sort", sort);
				
				try {
					// find a unique file name, based on the name of the launcher
					var launcher_base = (File.new_for_path (launcher).get_basename () ?? "").split (".") [0];
					var dockitem = launcher_base + ".dockitem";
					var counter = 1;
					
					while (launchers_dir.get_child (dockitem).query_exists ())
						dockitem = "%s-%d.dockitem".printf (launcher_base, counter++);
					
					// save the key file
					var stream = new DataOutputStream (launchers_dir.get_child (dockitem).create (0));
					stream.put_string (file.to_data ());
					stream.close ();
					
					debug ("Adding dock item '%s' for launcher '%s'", dockitem, launcher);
					return dockitem;
				} catch { }
			}
			
			return "";
		}
	}
}
