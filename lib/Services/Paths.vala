//
//  Copyright (C) 2011 Robert Dyer, Rico Tzschichholz
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
	 * A wrapper class that gives static instances of {@link GLib.File}
	 * for commonly used paths.  Most paths are retrieved from
	 * {@link GLib.Environment}, which on Linux uses the XDG Base Directory
	 * specification (see [[http://standards.freedesktop.org/basedir-spec/basedir-spec-latest.html]]).
	 *
	 * Initializing this class also ensures any writable directories exist.
	 */
	public class Paths : GLib.Object
	{
		/**
		 * User's home folder - $HOME
		 */
		public static File HomeFolder { get; protected set; }
		
		/**
		 * Path passed in to initialize method
		 * should be Build.PKGDATADIR
		 */
		public static File DataFolder { get; protected set; }
		
		/**
		 * DataFolder/themes
		 */
		public static File ThemeFolder { get; protected set; }
		
		/**
		 * HomeFolder/.config
		 */
		public static File ConfigHomeFolder { get; protected set; }
		
		/**
		 * HomeFolder/.local/share
		 */
		public static File DataHomeFolder { get; protected set; }
		
		/**
		 * HomeFolder/.cache
		 */
		public static File CacheHomeFolder { get; protected set; }
		
		/**
		 * /usr/local/share/:/usr/share/
		 */
		public static Gee.ArrayList<File> DataDirFolders { get; protected set; }
		
		
		/**
		 * defaults to ConfigHomeFolder/app_name
		 */
		public static File AppConfigFolder { get; protected set; }
		
		/**
		 * defaults to DataHomeFolder/app_name
		 */
		public static File AppDataFolder { get; protected set; }
		
		/**
		 * defaults to AppDataFolder/themes
		 */
		public static File AppThemeFolder { get; protected set; }
		
		/**
		 * defaults to CacheHomeFolder/app_name
		 */
		public static File AppCacheFolder { get; protected set; }
		
		/**
		 * application name which got passed to initialize
		 */
		public static string AppName { get; protected set; }
		
		Paths ()
		{
		}
		
		/**
		 * Initialize the class, creating the {@link GLib.File} instances for all
		 * common paths.  Also ensure that any writable directory exists.
		 *
		 * @param app_name the name of the application
		 * @param data_folder the path to the application's data folder
		 */
		public static void initialize (string app_name, string data_folder)
		{
			AppName = app_name;
			
			// get environment-based settings
			HomeFolder = File.new_for_path (Environment.get_home_dir ());
			DataFolder = File.new_for_path (data_folder);
			ThemeFolder = DataFolder.get_child ("themes");
			
			
			// get standard directories
			ConfigHomeFolder = File.new_for_path (Environment.get_user_config_dir ());
			DataHomeFolder = File.new_for_path (Environment.get_user_data_dir ());
			CacheHomeFolder = File.new_for_path (Environment.get_user_cache_dir ());
			
			var dirs = new Gee.ArrayList<File> ();
			foreach (unowned string path in Environment.get_system_data_dirs ())
				dirs.add (File.new_for_path (path));
			DataDirFolders = dirs;
			
			
			// set the program-specific directories to use
			AppConfigFolder = ConfigHomeFolder.get_child (app_name);
			AppDataFolder   = DataHomeFolder.get_child (app_name);
			AppThemeFolder  = AppDataFolder.get_child ("themes");
			AppCacheFolder  = CacheHomeFolder.get_child (app_name);
			
			
			// ensure all writable directories exist
			ensure_directory_exists (AppConfigFolder);
			ensure_directory_exists (AppDataFolder);
			ensure_directory_exists (AppThemeFolder);
			ensure_directory_exists (AppCacheFolder);
		}
		
		/**
		 * Creates the directory if it does not already exist
		 *
		 * @param dir the directory to ensure exists
		 * @return true if a directory was created, false otherwise
		 */
		public static bool ensure_directory_exists (File dir)
		{
			if (!dir.query_exists ())
				try {
					dir.make_directory_with_parents ();
					return true;
				} catch (Error e) {
					critical ("Could not access or create the directory '%s'. (%s)", dir.get_path () ?? "", e.message);
				}
			
			return false;
		}
	}
}
