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
				var path = f.get_path ();
				if (path != null && path != "" && (f.is_native () || path_is_mounted (path))) {
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
			foreach (var m in VolumeMonitor.get ().get_mounts ()) {
				var m_root = m.get_root ();
				if (m_root == null)
					continue;
				
				var m_path = m_root.get_path ();
				if (m_path != null && path.contains (m_path))
					return true;
			}
			
			return false;
		}
		
		static void internal_launch (File? app, GLib.List<File> files)
		{
			if (app == null && files.length () == 0)
				return;
			
			AppInfo? info = null;
			
			if (app != null) {
				KeyFile keyfile;
				var launcher = app.get_path ();
				
				try {
					keyfile = new KeyFile ();
					keyfile.load_from_file (launcher, KeyFileFlags.NONE);
				} catch (Error e) {
					critical ("%s: %s", launcher, e.message);
					return;
				}
				
				try {
					var type = keyfile.get_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_TYPE);
					switch (type) {
					default:
					case KeyFileDesktop.TYPE_APPLICATION:
					case KeyFileDesktop.TYPE_DIRECTORY:
						break;
					case KeyFileDesktop.TYPE_LINK:
						try {
							var url = keyfile.get_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_URL);
							AppInfo.launch_default_for_uri (url, null);
						} catch (Error e) {
							critical ("%s: %s", launcher, e.message);
						}
						return;
					}
				} catch (KeyFileError e) {
					critical ("%s: %s", launcher, e.message);
					return;
				}
				
				info = new DesktopAppInfo.from_keyfile (keyfile);
			} else {
				try {
					info = files.first ().data.query_default_handler ();
				} catch (Error e) {
					critical (e.message);
				}
			}
			
			if (info == null) {
				critical ("Unable to use application/file '%s' for execution.",
					(app != null ? app.get_path () : files.first ().data.get_path ()));
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
					info.launch_uris (uris, null);
					return;
				}
				
				warning ("The application '%s' doesn't support files/URIs or wasn't found.", info.get_name ());
			} catch (Error e) {
				critical (e.message);
			}
		}
		
		public static bool is_desktop_session (string session)
		{
			unowned string? current_session = get_current_desktop_session ();
			if (current_session == null)
				return false;
			
			return (current_session.down () == session.down ());
		}
		
		static unowned string? get_current_desktop_session ()
		{
			unowned string? current_session;
			
			current_session = Environment.get_variable ("XDG_CURRENT_DESKTOP");
			if (current_session == null)
				current_session = Environment.get_variable ("DESKTOP_SESSION");
			
			return current_session;
		}
	}
}
