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

namespace Plank.Services.Preferences
{
	public abstract class Preferences : GLib.Object
	{
		public Preferences ()
		{
			notify.connect (handle_notify);
		}
		
		void handle_notify (Object sender, ParamSpec property)
		{
			notify.disconnect (handle_notify);
			verify (property.name);
			notify.connect (handle_notify);
			
			if (backing_file != null)
				save_prefs ();
		}
		
		protected virtual void verify (string prop)
		{
			// do nothing, this isnt abstract because we dont
			// want to force subclasses to implement this
		}
		
		File backing_file;
		FileMonitor backing_monitor;
		string group_name;
		
		public Preferences.with_file (string filename)
		{
			group_name = get_type ().name ();
			
			backing_file = Paths.Paths.UserConfigFolder.get_child (filename);
			
			// ensure the preferences file exists
			Paths.Paths.ensure_directory_exists (backing_file.get_parent ());
			try {
				if (!backing_file.query_exists ())
						backing_file.create (0);
			} catch {
				backing_error ("Unable to create the preferences file '%s'");
			}
			
			load_prefs ();
			
			start_monitor ();
		}
		
		public Preferences.with_file_and_group (string filename, string group)
		{
			this.with_file (filename);
			group_name = group;
		}
		
		void start_monitor ()
		{
			try {
				backing_monitor = backing_file.monitor (0);
				backing_monitor.set_rate_limit (500);
				backing_monitor.changed.connect (backing_file_changed);
			} catch {
				backing_error ("Unable to watch the preferences file '%s'");
			}
		}
		
		void backing_file_changed (File f, File? other, FileMonitorEvent event)
		{
			if ((event & FileMonitorEvent.CHANGES_DONE_HINT) == 0 &&
				(event & FileMonitorEvent.DELETED) == 0)
				return;
			
			load_prefs ();
		}
		
		void load_prefs ()
		{
			Logging.Logger.debug<Preferences> ("Loading preferences from file '%s'".printf (backing_file.get_path ()));
			
			notify.disconnect (handle_notify);
			try {
				KeyFile file = new KeyFile ();
				file.load_from_file (backing_file.get_path (), 0);
				
				var obj_class = (ObjectClass) get_type ().class_ref ();
				var properties = obj_class.list_properties ();
				foreach (var prop in properties) {
					if (!file.has_key (group_name, prop.name))
						continue;
					
					var type = prop.value_type;
					var val = Value (type);
					
					if (type == typeof (int))
						val.set_int (file.get_integer (group_name, prop.name));
					else if (type == typeof (double))
						val.set_double (file.get_double (group_name, prop.name));
					else if (type == typeof (string))
						val.set_string (file.get_string (group_name, prop.name));
					else
						backing_error ("Unsupported preferences type '%s'");
					
					set_property (prop.name, val);
					verify (prop.name);
				}
			} catch {
				Logging.Logger.warn<Preferences> ("Unable to load preferences from file '%s'".printf (backing_file.get_path ()));
			}
			notify.connect (handle_notify);
		}
		
		void save_prefs ()
		{
			backing_monitor.cancel ();
			
			KeyFile file = new KeyFile ();
			
			var obj_class = (ObjectClass) get_type ().class_ref ();
			var properties = obj_class.list_properties ();
			foreach (var prop in properties) {
				var type = prop.value_type;
				var val = Value (type);
				get_property (prop.name, ref val);
				
				if (type == typeof (int))
					file.set_integer (group_name, prop.name, val.get_int ());
				else if (type == typeof (double))
					file.set_double (group_name, prop.name, val.get_double ());
				else if (type == typeof (string))
					file.set_string (group_name, prop.name, val.get_string ());
				else
					backing_error ("Unsupported preferences type '%s'");
			}
			
			try {
				DataOutputStream stream;
				if (backing_file.query_exists ())
					stream = new DataOutputStream (backing_file.replace (null, false, 0));
				else
					stream = new DataOutputStream (backing_file.create (0));
				
				stream.put_string (file.to_data ());
			} catch {
				backing_error ("Unable to create the preferences file '%s'");
			}
			
			start_monitor ();
		}
		
		void backing_error (string err)
		{
			Logging.Logger.fatal<Preferences> (err.printf (backing_file.get_path ()));
		}
	}
}
