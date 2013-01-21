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
		 * @param file the {@link GLib.File} of .dockitem file to parse
		 * @return the new {@link Items.DockItem} created
		 */
		public virtual DockItem make_item (GLib.File file)
		{
			return default_make_item (file, get_launcher_from_dockitem (file));
		}
		
		/**
		 * Creates a new {@link Items.DockItem} for a launcher parsed from a .dockitem.
		 *
		 * @param file the {@link GLib.File} of .dockitem file that was parsed
		 * @param launcher the launcher name from the .dockitem
		 * @return the new {@link Items.DockItem} created
		 */
		protected DockItem default_make_item (GLib.File file, string launcher)
		{
			if (Factory.main.is_launcher_for_dock (launcher))
				return new PlankDockItem.with_dockitem_file (file);
			if (launcher.has_suffix (".desktop"))
				return new ApplicationDockItem.with_dockitem_file (file);
			return new FileDockItem.with_dockitem_file (file);
		}
		
		/**
		 * Parses a .dockitem to get the launcher from it.
		 *
		 * @param file the {@link GLib.File} of .dockitem to parse
		 * @return the launcher from the .dockitem
		 */
		protected string get_launcher_from_dockitem (GLib.File file)
		{
			try {
				var keyfile = new KeyFile ();
				keyfile.load_from_file (file.get_path (), KeyFileFlags.NONE);
				
				return keyfile.get_string (typeof (Items.DockItemPreferences).name (), "Launcher");
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
				make_dock_item (new DesktopAppInfo (browser.get_id ()).get_filename ());
			if (terminal != null)
				make_dock_item (new DesktopAppInfo (terminal.get_id ()).get_filename ());
			if (calendar != null)
				make_dock_item (new DesktopAppInfo (calendar.get_id ()).get_filename ());
			if (media != null)
				make_dock_item (new DesktopAppInfo (media.get_id ()).get_filename ());
			
			return true;
		}
		
		/**
		 * Creates a bunch of default .dockitem's.
		 */
		public void make_default_items ()
		{
			// add plank item!
			make_dock_item ((Paths.DataFolder.get_parent ().get_path () ?? "") + "/applications/" + Factory.main.app_launcher);
			
			if (make_default_gnome_items ())
				return;
			
			// add browser
			if (make_dock_item ("/usr/share/applications/chromium-browser.desktop") == null)
				if (make_dock_item ("/usr/local/share/applications/google-chrome.desktop") == null)
					if (make_dock_item ("/usr/share/applications/firefox.desktop") == null)
						if (make_dock_item ("/usr/share/applications/epiphany.desktop") == null)
							make_dock_item ("/usr/share/applications/kde4/konqbrowser.desktop");
			
			// add terminal
			if (make_dock_item ("/usr/share/applications/terminator.desktop") == null)
				if (make_dock_item ("/usr/share/applications/gnome-terminal.desktop") == null)
					make_dock_item ("/usr/share/applications/kde4/konsole.desktop");
			
			// add music player
			if (make_dock_item ("/usr/share/applications/exaile.desktop") == null)
				if (make_dock_item ("/usr/share/applications/songbird.desktop") == null)
					if (make_dock_item ("/usr/share/applications/rhythmbox.desktop") == null)
						if (make_dock_item ("/usr/share/applications/banshee-1.desktop") == null)
							make_dock_item ("/usr/share/applications/kde4/amarok.desktop");
			
			// add IM client
			if (make_dock_item ("/usr/share/applications/pidgin.desktop") == null)
				make_dock_item ("/usr/share/applications/empathy.desktop");
		}
		
		/**
		 * Creates a new .dockitem for a launcher.
		 *
		 * @param launcher the launcher to create a .dockitem for
		 * @param sort the Sort value in the new .dockitem
		 * @return the new {@link GLib.File} of the new .dockitem created
		 */
		public GLib.File? make_dock_item (string launcher)
		{
			var launcher_file = File.new_for_path (launcher);
			
			if (launcher_file.query_exists ()) {
				var file = new KeyFile ();
				
				file.set_string (typeof (Items.DockItemPreferences).name (), "Launcher", launcher);
				
				try {
					// find a unique file name, based on the name of the launcher
					var launcher_base = (launcher_file.get_basename () ?? "unknown").split (".") [0];
					var dockitem = launcher_base + ".dockitem";
					var dockitem_file = launchers_dir.get_child (dockitem);
					var counter = 1;
					
					while (dockitem_file.query_exists ()) {
						dockitem = "%s-%d.dockitem".printf (launcher_base, counter++);
						dockitem_file = launchers_dir.get_child (dockitem);
					}
					
					// save the key file
					var stream = new DataOutputStream (dockitem_file.create (FileCreateFlags.NONE));
					stream.put_string (file.to_data ());
					stream.close ();
					
					debug ("Created dock item '%s' for launcher '%s'", dockitem_file.get_path (), launcher);
					return dockitem_file;
				} catch { }
			}
			
			return null;
		}
	}
}
