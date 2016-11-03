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

// portions based on code from Rygel

/*
 * Copyright (C) 2008 Nokia Corporation.
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */

namespace Plank
{
	public const string DOCKLET_ENTRY_POINT = "docklet_init";
	
	public delegate void DockletInitFunc (DockletManager manager);
	
	/**
	 * A controller class for managing all available docklets.
	 */
	public class DockletManager : Object
	{
		static Regex docklet_filename_regex = /^libdocklet-.+.so$/;
		static DockletManager? instance;
		
		public static unowned DockletManager get_default ()
		{
			if (instance == null)
				instance = new DockletManager ();
			
			return instance;
		}
		
		public signal void docklet_added (Docklet docklet);
		
		Gee.HashMap<string, Docklet> docklets;
		
		DockletManager ()
		{
			Object ();
		}
		
		construct
		{
			docklets = new Gee.HashMap<string, Docklet> ();
		}
		
		/**
		 * Load docklet modules from known directories
		 */
		public void load_docklets ()
		{
			load_modules_from_dir (File.new_for_path (Build.DOCKLETSDIR));
			
			unowned string? docklet_dirs = Environment.get_variable ("PLANK_DOCKLET_DIRS");
			if (docklet_dirs != null)
				foreach (unowned string dir in docklet_dirs.split (":"))
					load_modules_from_dir (File.new_for_path (dir));
		}
		
		/**
		 * Register docklet with given name and type
		 *
		 * @param type a type
		 */
		public void register_docklet (Type type)
		{
			if (!type.is_a (typeof (Docklet))) {
				warning ("'%s' is not a Docklet", type.name ());
				return;
			}
			
			var docklet = (Docklet) Object.new (type);
			
			unowned string id = docklet.get_id ();
			message ("Docklet '%s' registered", id);
			docklets.set (id, docklet);
			
			docklet_added (docklet);
		}
		
		/**
		 * Find docklet for given id
		 *
		 * @param id a unique id
		 * @return a docklet or null
		 */
		public Docklet? get_docklet_by_id (string id)
		{
			return docklets.get (id);
		}
		
		/**
		 * Find docklet wich supports given uri
		 *
		 * @param uri an URI
		 * @return a docklet or null
		 */
		public Docklet? get_docklet_by_uri (string uri)
		{
			Docklet? docklet = null;
			
			var it = docklets.map_iterator ();
			it.foreach ((k, v) => {
				if (uri == "%s%s".printf (DOCKLET_URI_PREFIX, k)) {
					docklet = v;
					return false;
				}
				return true;
			});
			
			return docklet;
		}
		
		/**
		 * Get list of all registered docklets
		 *
		 * @return a list of all registered docklets
		 */
		public Gee.Collection<Docklet> list_docklets ()
		{
			return docklets.values;
		}
		
		void load_modules_from_dir (File dir)
		{
			if (!dir.query_exists ())
				return;
			
			Logger.verbose ("Searching for modules in folder '%s'", dir.get_path ());
			
			unowned string attributes = FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE + "," + FileAttribute.STANDARD_CONTENT_TYPE;
			
			try {
				var enumerator = dir.enumerate_children (attributes, 0);
				FileInfo info;
				
				while ((info = enumerator.next_file ()) != null) {
					unowned string name = info.get_name ();
					var file = dir.get_child (name);
					if (info.get_content_type () == "application/x-sharedlib"
						&& docklet_filename_regex.match (name))
						load_module_from_file (file.get_path ());
					else if (info.get_file_type () == FileType.DIRECTORY)
						load_modules_from_dir (file);
				}
			} catch (Error error) {
				critical ("Error listing contents of folder '%s': %s", dir.get_path (), error.message);
				return;
			}
			
			Logger.verbose ("Finished searching for modules in folder '%s'", dir.get_path ());
		}
		
		void load_module_from_file (string file_path)
		{
			var module = Module.open (file_path, ModuleFlags.BIND_LOCAL);
			if (module == null) {
				warning ("Failed to load module '%s': %s", file_path, Module.error ());
				return;
			}
			
			void* function;
			
			if (!module.symbol (DOCKLET_ENTRY_POINT, out function)) {
				warning ("Failed to find entry point function '%s' in '%s': %s", DOCKLET_ENTRY_POINT, file_path, Module.error ());
				return;
			}
			
			unowned DockletInitFunc module_init = (DockletInitFunc) function;
			assert (module_init != null);
			
			debug ("Loading module '%s'", module.name ());
			
			// We don't want our modules to ever unload
			module.make_resident ();
			
			module_init (this);
		}
	}
}
