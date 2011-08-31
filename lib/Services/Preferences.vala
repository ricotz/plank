//  
//  Copyright (C) 2011 Robert Dyer, Rico Tzschichholz
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
	 * This interface is used by objects that need to be serialized in a Preferences.
	 * The object must have a string representation and provide these methods to
	 * translate between the string and object representations.
	 */
	public interface PrefsSerializable : GLib.Object
	{
		/**
		 * Serializes the object into a string representation.
		 *
		 * @return the string representation of the object
		 */
		public abstract string prefs_serialize ();
		
		/**
		 * Un-serializes the object from a string representation.
		 *
		 * @param s the string representation of the object
		 */
		public abstract void prefs_deserialize (string s);
	}
	
	/**
	 * Clients of this class should not connect to the {@link GLib.Object.notify()} signal.
	 * Instead, they should connect to the {@link Plank.Services.Preferences.changed()} signal.
	 */
	public abstract class Preferences : GLib.Object
	{
		/**
		 * This signal is to be used in place of the standard {@link GLib.Object.notify()} signal.
		 *
		 * This signal ''only'' emits after a property's value was verified.
		 *
		 * Note that in the case where a property was set to an invalid value,
		 * (and thus, sanitized to a valid value), the {@link GLib.Object.notify()} signal will emit 
		 * twice: once with the invalid value and once with the sanitized value.
		 */
		[Signal (no_recurse = true, run = "first", action = true, no_hooks = true, detailed = true)]
		public signal void changed ();
		
		/**
		 * This signal indicates that the backing file for this preferences was deleted.
		 */
		public signal void deleted ();
		
		/**
		 * Creates a new preferences object with no backing file.
		 */
		public Preferences ()
		{
			reset_properties ();
			notify.connect (handle_notify);
		}
		
		~Preferences ()
		{
			stop_monitor ();
		}
		
		void handle_notify (Object sender, ParamSpec property)
		{
			notify.disconnect (handle_notify);
			call_verify (property.name);
			notify.connect (handle_notify);
			
			// FIXME save_prefs() might be called twice in this path (if verification failed)
			//       need to figure out a way to only call it once
			if (backing_file != null)
				save_prefs ();
		}
		
		void handle_verify_notify (Object sender, ParamSpec property)
		{
			if (backing_file != null) {
				warning ("Key '%s' failed verification in preferences file '%s', changing value", property.name, backing_file.get_path ());
				save_prefs ();
			} else {
				warning ("Key '%s' failed verification, changing value", property.name);
			}
		}
		
		void call_verify (string prop)
		{
			notify.connect (handle_verify_notify);
			verify (prop);
			changed[prop] ();
			notify.disconnect (handle_verify_notify);
		}
		
		/**
		 * This method will verify the value of a property.
		 * If the value is wrong, this method should replace it with a sanitized value.
		 *
		 * @param prop the name of the property that needs verified
		 */
		protected virtual void verify (string prop)
		{
			// do nothing, this isnt abstract because we dont
			// want to force subclasses to implement this
		}
		
		/**
		 * Resets all properties to their default values.  Called from construct and before
		 * loading from the backing file.
		 */
		protected abstract void reset_properties ();
		
		File backing_file;
		FileMonitor backing_monitor;
		
		/**
		 * Creates a preferences object with a backing file.
		 *
		 * @param filename the path to the backing file for this preferences
		 */
		public Preferences.with_file (string filename)
		{
			init_from_file (filename);
		}
		
		/**
		 * Initializes this preferences with a backing file.
		 *
		 * @param filename the path to the backing file for this preferences
		 */
		protected void init_from_file (string filename)
		{
			backing_file = Paths.AppConfigFolder.get_child (filename);
			
			// ensure the preferences file exists
			if (!backing_file.query_exists ())
				save_prefs ();
			
			load_prefs ();
			
			start_monitor ();
		}
		
		public string get_backing_path ()
		{
			if (backing_file == null)
				return "";
			return backing_file.get_basename ();
		}
		
		/**
		 * This forces the deletion of the backing file for this preferences.
		 */
		public void delete ()
		{
			try {
				backing_file.delete ();
			} catch {
				warning ("Unable to delete the preferences file '%s'", backing_file.get_path ());
			}
		}
		
		void stop_monitor ()
		{
			if (backing_monitor == null)
				return;
			
			backing_monitor.changed.disconnect (backing_file_changed);
			backing_monitor.cancel ();
			backing_monitor = null;
		}
		
		void start_monitor ()
		{
			if (backing_monitor != null)
				return;
			
			try {
				backing_monitor = backing_file.monitor (0);
				backing_monitor.changed.connect (backing_file_changed);
			} catch {
				error ("Unable to watch the preferences file '%s'", backing_file.get_path ());
			}
		}
		
		void backing_file_changed (File f, File? other, FileMonitorEvent event)
		{
			// only watch for change or delete events
			if ((event & FileMonitorEvent.CHANGES_DONE_HINT) != FileMonitorEvent.CHANGES_DONE_HINT &&
				(event & FileMonitorEvent.DELETED) != FileMonitorEvent.DELETED)
				return;
			
			if ((event & FileMonitorEvent.DELETED) == FileMonitorEvent.DELETED)
				deleted ();
			else
				load_prefs ();
		}
		
		void load_prefs ()
		{
			debug ("Loading preferences from file '%s'", backing_file.get_path ());
			
			var missing_keys = false;
			
			notify.disconnect (handle_notify);
			reset_properties ();
			try {
				var file = new KeyFile ();
				file.load_from_file (backing_file.get_path (), 0);
				
				var obj_class = (ObjectClass) get_type ().class_ref ();
				var properties = obj_class.list_properties ();
				foreach (var prop in properties) {
					var group_name = prop.owner_type.name ();
					
					if (!file.has_group (group_name) || !file.has_key (group_name, prop.name)) {
						warning ("Missing key '%s' for group '%s' in preferences file '%s' - using default value", prop.name, group_name, backing_file.get_path ());
						missing_keys = true;
						continue;
					}
					
					var type = prop.value_type;
					var val = Value (type);
					
					if (type == typeof (int))
						val.set_int (file.get_integer (group_name, prop.name));
					else if (type == typeof (double))
						val.set_double (file.get_double (group_name, prop.name));
					else if (type == typeof (string))
						val.set_string (file.get_string (group_name, prop.name));
					else if (type == typeof (bool))
						val.set_boolean (file.get_boolean (group_name, prop.name));
					else if (type.is_enum ())
						val.set_enum (file.get_integer (group_name, prop.name));
					else if (type.is_a (typeof (PrefsSerializable))) {
						get_property (prop.name, ref val);
						(val.get_object () as PrefsSerializable).prefs_deserialize (file.get_string (group_name, prop.name));
						continue;
					} else {
						debug ("Unsupported preferences type '%s' for property '%' in file '%s'", type.name (), prop.name, backing_file.get_path ());
						continue;
					}
					
					set_property (prop.name, val);
					call_verify (prop.name);
				}
			} catch {
				warning ("Unable to load preferences from file '%s'", backing_file.get_path ());
				deleted ();
			}
			notify.connect (handle_notify);
			
			if (missing_keys)
				save_prefs ();
		}
		
		void save_prefs ()
		{
			stop_monitor ();
			
			var file = new KeyFile ();
			
			try {
				file.set_comment (null, null, "This file auto-generated by Plank.\n" + new DateTime.now_utc ().to_string ());
			} catch { }
			
			var obj_class = (ObjectClass) get_type ().class_ref ();
			var properties = obj_class.list_properties ();
			foreach (var prop in properties) {
				var group_name = prop.owner_type.name ();
				
				var type = prop.value_type;
				var val = Value (type);
				get_property (prop.name, ref val);
				
				if (type == typeof (int))
					file.set_integer (group_name, prop.name, val.get_int ());
				else if (type == typeof (double))
					file.set_double (group_name, prop.name, val.get_double ());
				else if (type == typeof (string))
					file.set_string (group_name, prop.name, val.get_string ());
				else if (type == typeof (bool))
					file.set_boolean (group_name, prop.name, val.get_boolean ());
				else if (type.is_enum ())
					file.set_integer (group_name, prop.name, val.get_enum ());
				else if (type.is_a (typeof (PrefsSerializable)))
					file.set_string (group_name, prop.name, (val.get_object () as PrefsSerializable).prefs_serialize ());
				else {
					debug ("Unsupported preferences type '%s' for property '%' in file '%s'", type.name (), prop.name, backing_file.get_path ());
					continue;
				}
				
				var blurb = prop.get_blurb ();
				if (blurb != null && blurb != "" && blurb != prop.name)
					try {
						file.set_comment (group_name, prop.name, blurb);
					} catch { }
			}
			
			debug ("Saving preferences '%s'", backing_file.get_path ());
			
			try {
				DataOutputStream stream;
				if (backing_file.query_exists ())
					stream = new DataOutputStream (backing_file.replace (null, false, 0));
				else
					stream = new DataOutputStream (backing_file.create (0));
				
				stream.put_string (file.to_data ());
			} catch {
				warning ("Unable to create the preferences file '%s'", backing_file.get_path ());
			}
			
			start_monitor ();
		}
	}
}
