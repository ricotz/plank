//
//  Copyright (C) 2011 Robert Dyer
//
//  This file is part of Plank.
//
//  Plank is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Plank is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

namespace Plank
{
	/**
	 * An item factory.  Creates {@link DockItem}s based on .dockitem files.
	 */
	public class ItemFactory : GLib.Object
	{
		const string[] DEFAULT_APP_WEB = {
			"file:///usr/share/applications/chromium-browser.desktop",
			"file:///usr/share/applications/google-chrome.desktop",
			"file:///usr/share/applications/firefox.desktop",
			"file:///usr/share/applications/epiphany.desktop",
			"file:///usr/share/applications/midori.desktop",
			"file:///usr/share/applications/kde4/konqbrowser.desktop"
		};
		
		const string[] DEFAULT_APP_MAIL = {
			"file:///usr/share/applications/thunderbird.desktop",
			"file:///usr/share/applications/evolution.desktop",
			"file:///usr/share/applications/geary.desktop",
			"file:///usr/share/applications/kde4/KMail2.desktop"
		};
		
		const string[] DEFAULT_APP_CALENDAR = {
			"file:///usr/share/applications/thunderbird.desktop",
			"file:///usr/share/applications/evolution.desktop",
			"file:///usr/share/applications/maya-calendar.desktop",
			"file:///usr/share/applications/kde4/korganizer.desktop"
		};
		
		const string[] DEFAULT_APP_TERMINAL = {
			"file:///usr/share/applications/terminator.desktop",
			"file:///usr/share/applications/gnome-terminal.desktop",
			"file:///usr/share/applications/pantheon-terminal.desktop",
			"file:///usr/share/applications/kde4/konsole.desktop"
		};
		
		const string[] DEFAULT_APP_AUDIO = {
			"file:///usr/share/applications/exaile.desktop",
			"file:///usr/share/applications/songbird.desktop",
			"file:///usr/share/applications/rhythmbox.desktop",
			"file:///usr/share/applications/noise.desktop",
			"file:///usr/share/applications/banshee-1.desktop",
			"file:///usr/share/applications/kde4/amarok.desktop"
		};
		
		const string[] DEFAULT_APP_VIDEO = {
			"file:///usr/share/applications/vlc.desktop",
			"file:///usr/share/applications/totem.desktop",
			"file:///usr/share/applications/audience.desktop",
			"file:///usr/share/applications/kde4/amarok.desktop"
		};
		
		const string[] DEFAULT_APP_PHOTO = {
			"file:///usr/share/applications/eog.desktop",
			"file:///usr/share/applications/gnome-photos.desktop",
			"file:///usr/share/applications/org.gnome.Photos.desktop",
			"file:///usr/share/applications/shotwell.desktop",
			"file:///usr/share/applications/kde4/digikam.desktop"
		};
		
		const string[] DEFAULT_APP_MESSENGER = {
			"file:///usr/share/applications/pidgin.desktop",
			"file:///usr/share/applications/empathy.desktop",
			"file:///usr/share/applications/birdie.desktop",
			"file:///usr/share/applications/kde4/kopete.desktop"
		};
		
		/**
		 * The directory containing .dockitem files.
		 */
		public File launchers_dir;
		
		/**
		 * Creates a new {@link DockElement} from a .dockitem.
		 *
		 * @param file the {@link GLib.File} of .dockitem file to parse
		 * @return the new {@link DockElement} created
		 */
		public virtual DockElement make_element (GLib.File file)
		{
			var launcher = get_launcher_from_dockitem (file);
			
			Docklet? docklet;
			if ((docklet = DockletManager.get_default ().get_docklet_by_uri (launcher)) != null)
				return docklet.make_element (launcher, file);
			
			return default_make_element (file, launcher);
		}
		
		/**
		 * Creates a new {@link PlankDockItem} for the dock itself.
		 *
		 * @return the new {@link PlankDockItem} created
		 */
		public virtual DockItem get_item_for_dock ()
		{
			return PlankDockItem.get_instance ();
		}
		
		/**
		 * Creates a new {@link DockElement} for a launcher parsed from a .dockitem.
		 *
		 * @param file the {@link GLib.File} of .dockitem file that was parsed
		 * @param launcher the launcher name from the .dockitem
		 * @return the new {@link DockElement} created
		 */
		protected DockElement default_make_element (GLib.File file, string launcher)
		{
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
				
				unowned string group_name = typeof (DockItemPreferences).name ();
				if (keyfile.has_group (group_name))
					return keyfile.get_string (group_name, "Launcher");
				
				// 0.10.1 > 0.10.9/0.11.x
				if (keyfile.has_group ("PlankItemsDockItemPreferences"))
					return keyfile.get_string ("PlankItemsDockItemPreferences", "Launcher");
			} catch (Error e) {
				warning ("%s (%s)", e.message, file.get_basename ());
			}
			
			return "";
		}
			
		/**
		 * Creates a list of Dockitems based on .dockitem files found in the given source_dir.
		 *
		 * @param source_dir the folder where to load .dockitem from
		 * @param ordering a ";;"-separated string to be used to order the loaded DockItems
		 * @return the new List of DockItems
		 */
		public Gee.ArrayList<DockElement> load_elements (GLib.File source_dir, string[]? ordering = null)
		{
			var result = new Gee.ArrayList<DockElement> ();
			
			if (!source_dir.query_exists ()) {
				critical ("Given folder '%s' does not exist.", source_dir.get_path ());
				return result;
			}

			debug ("Loading dock elements from '%s'", source_dir.get_path ());
			
			var elements = new Gee.HashMap<string,DockElement> ();
			var count = 0U;
			
			try {
				var enumerator = source_dir.enumerate_children (FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_IS_HIDDEN, 0);
				FileInfo info;
				while ((info = enumerator.next_file ()) != null) {
					var filename = info.get_name ();
					if (info.get_is_hidden () || !filename.has_suffix (".dockitem"))
						continue;
					
					if (count++ >= LAUNCHER_DIR_MAX_FILE_COUNT) {
						critical ("There are way too many files (%u+) in '%s'.", LAUNCHER_DIR_MAX_FILE_COUNT, source_dir.get_path ());
						break;
					}
					
					var file = source_dir.get_child (filename);
					var element = make_element (file);
					
					unowned DockItemProvider? provider = (element as DockItemProvider);
					if (provider != null) {
						elements.set (filename, element);
						continue;
					}
					
					unowned DockItem? item = (element as DockItem);
					if (item == null)
						continue;
					
					unowned DockItem? dupe;
					if ((dupe = find_item_for_uri (result, item.Launcher)) != null) {
						warning ("The launcher '%s' in dock item '%s' is already managed by dock item '%s'. Removing '%s'.",
							item.Launcher, file.get_path (), dupe.DockItemFilename, item.DockItemFilename);
						item.delete ();
					} else if (!item.is_valid ()) {
						warning ("The launcher '%s' in dock item '%s' does not exist. Removing '%s'.", item.Launcher, file.get_path (), item.DockItemFilename);
						item.delete ();
					} else {
						elements.set (filename, element);
					}
				}
			} catch (Error e) {
				critical ("Error loading dock elements from '%s'. (%s)", source_dir.get_path () ?? "", e.message);
			}
			
			if (ordering != null)
				foreach (unowned string dockitem in ordering) {
					DockElement? element;
					elements.unset (dockitem, out element);
					if (element != null)
						result.add (element);
				}
			
			result.add_all (elements.values);
			elements.clear ();
			
			return result;
		}
		
		unowned DockItem? find_item_for_uri (Gee.ArrayList<DockElement> elements, string uri)
		{
			foreach (var element in elements) {
				unowned DockItem? item = (element as DockItem);
				if (item != null && item.Launcher == uri)
					return item;
			}
			
			return null;
		}

		void make_dock_item_for_desktop_id (string id)
		{
			var app_info = new DesktopAppInfo (id);
			if (app_info == null) {
				warning ("Failed to create dock item for '%s'", id);
				return;
			}
			
			unowned string filename = app_info.get_filename ();
			if (filename == null) {
				warning ("Failed to create dock item for '%s'", id);
				return;
			}
			
			try {
				var uri = Filename.to_uri (filename);
				if (make_dock_item (uri) == null)
					warning ("Failed to create dock item for '%s' ('%s')", id, uri);
			} catch (ConvertError e) {
				warning ("Failed to create dock item for '%s'", id);
				warning (e.message);
			}
		}

		bool make_default_gnome_items ()
		{
			var browser = AppInfo.get_default_for_type ("x-scheme-handler/http", false);
			var mail = AppInfo.get_default_for_type ("x-scheme-handler/mailto", false);
			// FIXME dont know how to get terminal...
			var terminal = AppInfo.get_default_for_uri_scheme ("ssh");
			var calendar = AppInfo.get_default_for_type ("text/calendar", false);
			var audio = AppInfo.get_default_for_type ("audio/x-vorbis+ogg", false);
			var video = AppInfo.get_default_for_type ("video/x-ogm+ogg", false);
			var photo = AppInfo.get_default_for_type ("image/jpeg", false);

			if (browser == null && mail == null && calendar == null && terminal == null
				&& audio == null && video == null && photo == null)
				return false;
			
			if (browser != null)
				make_dock_item_for_desktop_id (browser.get_id ());
			if (mail != null)
				make_dock_item_for_desktop_id (mail.get_id ());
			if (terminal != null)
				make_dock_item_for_desktop_id (terminal.get_id ());
			if (calendar != null)
				make_dock_item_for_desktop_id (calendar.get_id ());
			if (audio != null)
				make_dock_item_for_desktop_id (audio.get_id ());
			if (video != null)
				make_dock_item_for_desktop_id (video.get_id ());
			if (photo != null)
				make_dock_item_for_desktop_id (photo.get_id ());
			
			return true;
		}
		
		/**
		 * Creates a bunch of default .dockitem's.
		 */
		public void make_default_items ()
		{
			if (make_default_gnome_items ())
				return;
			
			// add browser
			foreach (unowned string uri in DEFAULT_APP_WEB)
				if (make_dock_item (uri) != null)
					break;
			
			// add mail-client
			foreach (unowned string uri in DEFAULT_APP_MAIL)
				if (make_dock_item (uri) != null)
					break;
			
			// add terminal
			foreach (unowned string uri in DEFAULT_APP_TERMINAL)
				if (make_dock_item (uri) != null)
					break;
			
			// add audio player
			foreach (unowned string uri in DEFAULT_APP_AUDIO)
				if (make_dock_item (uri) != null)
					break;
			
			// add video player
			foreach (unowned string uri in DEFAULT_APP_VIDEO)
				if (make_dock_item (uri) != null)
					break;
			
			// add photo viewer
			foreach (unowned string uri in DEFAULT_APP_PHOTO)
				if (make_dock_item (uri) != null)
					break;
			
			// add IM client
			foreach (unowned string uri in DEFAULT_APP_MESSENGER)
				if (make_dock_item (uri) != null)
					break;
		}
		
		/**
		 * Creates a new .dockitem for a uri.
		 *
		 * @param uri the uri or path to create a .dockitem for
		 * @param target_dir the folder where to put the newly created .dockitem (defaults to launchers_dir)
		 * @return the new {@link GLib.File} of the new .dockitem created
		 */
		public GLib.File? make_dock_item (string uri, File? target_dir = null)
		{
			if (target_dir == null)
				target_dir = launchers_dir;
			
			bool is_valid = false;
			string basename;
			if (uri.has_prefix (DOCKLET_URI_PREFIX)) {
				is_valid = true;
				basename = uri.substring (10);
			} else {
				var launcher_file = File.new_for_uri (uri);
				is_valid = launcher_file.query_exists ();
				basename = (launcher_file.get_basename () ?? "unknown");
			}
			
			if (is_valid) {
				var file = new KeyFile ();
				
				file.set_string (typeof (DockItemPreferences).name (), "Launcher", uri);
				
				try {
					// find a unique file name, based on the name of the launcher
					var index_of_last_dot = basename.last_index_of (".");
					var launcher_base = (index_of_last_dot >= 0 ? basename.slice (0, index_of_last_dot) : basename);
					var dockitem = "%s.dockitem".printf (launcher_base);
					var dockitem_file = target_dir.get_child (dockitem);
					var counter = 1;
					
					while (dockitem_file.query_exists ()) {
						dockitem = "%s-%d.dockitem".printf (launcher_base, counter++);
						dockitem_file = target_dir.get_child (dockitem);
					}
					
					// save the key file
					var stream = new DataOutputStream (dockitem_file.create (FileCreateFlags.NONE));
					stream.put_string (file.to_data ());
					stream.close ();
					
					debug ("Created dock item '%s' for launcher '%s'", dockitem_file.get_path (), uri);
					return dockitem_file;
				} catch { }
			}
			
			return null;
		}
	}
}
