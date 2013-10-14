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

namespace Plank.Services
{
	/**
	 * A utility class for launching applications and opening files/URIs.
	 */
	public class System : GLib.Object
	{
		System ()
		{
		}
		
		/**
		 * Opens a file based on a URI.
		 *
		 * @param uri the URI to open
		 */
		public static void open_uri (string uri)
		{
			open (File.new_for_uri (uri));
		}
		
		/**
		 * Opens a file based on a {@link GLib.File}.
		 *
		 * @param file the {@link GLib.File} to open
		 */
		public static void open (File file)
		{
			launch_with_files (null, { file });
		}
		
		/**
		 * Opens multiple files based on {@link GLib.File}.
		 *
		 * @param files the {@link GLib.File}s to open
		 */
		public static void open_files (File[] files)
		{
			launch_with_files (null, files);
		}
		
		/**
		 * Launches an application.
		 *
		 * @param app the application to launch
		 */
		public static void launch (File app)
		{
			launch_with_files (app, new File[] {});
		}
		
		/**
		 * Launches an application and opens files.
		 *
		 * @param app the application to launch
		 * @param files the files to open with the application
		 */
		public static void launch_with_files (File? app, File[] files)
		{
			if (app != null && !app.query_exists ()) {
				warning ("Application '%s' doesn't exist", app.get_path () ?? "");
				return;
			}
			
			var mounted_files = new GLib.List<File> ();
			
			// make sure all files are mounted
			foreach (var f in files) {
				if (f.get_path () != null && f.get_path () != "" && (f.is_native () || path_is_mounted (f.get_path ()))) {
					mounted_files.append (f);
					continue;
				}
				
				try {
					AppInfo.launch_default_for_uri (f.get_uri (), null);
				} catch {
					f.mount_enclosing_volume.begin (0, null);
					mounted_files.append (f);
				}
			}
			
			if (mounted_files.length () > 0 || files.length == 0)
				internal_launch (app, mounted_files);
		}
		
		static bool path_is_mounted (string path)
		{
			foreach (var m in VolumeMonitor.get ().get_mounts ())
				if (m.get_root () != null && m.get_root ().get_path () != null && path.contains (m.get_root ().get_path ()))
					return true;
			
			return false;
		}
		
		static void internal_launch (File? app, GLib.List<File> files)
		{
			if (app == null && files.length () == 0)
				return;
			
			AppInfo info;
			if (app != null)
				info = new DesktopAppInfo.from_filename (app.get_path () ?? "");
			else
				try {
					info = files.first ().data.query_default_handler ();
				} catch {
					return;
				}
			
			try {
				if (files.length () == 0) {
					info.launch (null, null);
					return;
				}
				
				if (info.supports_files ()) {
					info.launch (files, null);
					return;
				}
				
				if (info.supports_uris ()) {
					var uris = new GLib.List<string> ();
					foreach (var f in files)
						uris.append (f.get_uri ());
					info.launch_uris (uris, new AppLaunchContext ());
					return;
				}
				
				warning ("The application '%s' doesn't support files/URIs or wasn't found.", info.get_name ());
			} catch (Error e) {
				critical (e.message);
			}
		}
	}
}
