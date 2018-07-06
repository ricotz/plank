//
//  Copyright (C) 2011-2012 Robert Dyer, Rico Tzschichholz
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
	 * This interface is used by objects that need to be serialized in a Preferences.
	 * The object must have a string representation and provide these methods to
	 * translate between the string and object representations.
	 */
	public interface Serializable : GLib.Object
	{
		/**
		 * Serializes the object into a string representation.
		 *
		 * @return the string representation of the object
		 */
		public abstract string serialize ();
		
		/**
		 * De-serializes the object from a string representation.
		 *
		 * @param s the string representation of the object
		 */
		public abstract void deserialize (string s);
	}
	
	/**
	 * The base class for all preferences in the system.  Preferences are serialized to files.
	 * The file is watched for changes and loads new values if the backing file changed.  When
	 * any public property of a sub-class is changed, the public properties are serialized to
	 * the backing file.
	 */
	public abstract class Preferences : GLib.Object
	{
		// Transition old group-names to new ones to preserve existing settings and keep themes working
		static string[,] TRANSITION_MAP = {
			// 0.10.1 > 0.10.9/0.11.x
			{"PlankItemsDockItemPreferences", "PlankDockItemPreferences"},
			{"PlankDrawingTheme", "PlankTheme"},
			{"PlankDrawingDockTheme", "PlankDockTheme"}
		};
		
		/**
		 * This signal indicates that the backing file for this preferences was deleted.
		 */
		public signal void deleted ();
		
		/**
		 * Creates a new preferences object with no backing file.
		 */
		public Preferences ()
		{
		}
		
		construct
		{
			reset_properties ();
			notify.connect (handle_notify);
		}
		
		~Preferences ()
		{
			notify.disconnect (handle_notify);
			apply ();
			stop_monitor ();
		}
		
		void handle_notify (Object sender, ParamSpec property)
		{
			if (read_only)
				return;
			
			notify.disconnect (handle_notify);
			freeze_notify ();
			
			Logger.verbose ("property changed: %s", property.name);
			
			is_delayed_internal = true;
			if (backing_file != null)
				save_prefs ();
			
			call_verify (property.name);
			
			is_delayed_internal = false;
			if (!is_delayed && is_changed && backing_file != null)
				save_prefs ();
			
			thaw_notify ();
			notify.connect (handle_notify);
		}
		
		void handle_verify_notify (Object sender, ParamSpec property)
		{
			save_prefs ();
			if (backing_file != null)
				warning ("Key '%s' failed verification in preferences file '%s', changing value", property.name, backing_file.get_path () ?? "");
			else
				warning ("Key '%s' failed verification, changing value", property.name);
		}
		
		void call_verify (string prop)
		{
			freeze_notify ();
			notify.connect (handle_verify_notify);
			verify (prop);
			notify.disconnect (handle_verify_notify);
			thaw_notify ();
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
		
		File? backing_file;
		FileMonitor backing_monitor;
		bool read_only = false;
		
		/**
		 * Creates a preferences object with a backing file.
		 *
		 * @param file the {@link GLib.File} of the backing file for this preferences
		 */
		public Preferences.with_file (GLib.File file)
		{
			init_from_file (file);
		}
		
		/**
		 * Creates a preferences object with a backing filename.
		 *
		 * @param filename of the backing file for this preferences
		 */
		public Preferences.with_filename (string filename)
		{
			init_from_file (Paths.AppConfigFolder.get_child (filename));
		}
		
		/**
		 * Initializes this preferences with a backing file.
		 *
		 * @param file the {@link GLib.File} of the backing file for this preferences
		 */
		protected void init_from_file (GLib.File file)
		{
			stop_monitor ();
			
			backing_file = file;
			var file_exists = backing_file.query_exists ();
			
			if (!read_only) {
				try {
					FileInfo info;
					if (file_exists)
						info = file.query_info (FileAttribute.ACCESS_CAN_WRITE, FileQueryInfoFlags.NONE, null);
					else
						info = file.get_parent ().query_info (FileAttribute.ACCESS_CAN_WRITE, FileQueryInfoFlags.NONE, null);
					
					read_only = (read_only || !info.get_attribute_boolean (FileAttribute.ACCESS_CAN_WRITE));
					
					if (read_only)
						warning ("'%s' is read-only!", file.get_path () ?? "");
				} catch (Error e) {
					warning (e.message);
					read_only = true;
				}
			}
			
			// ensure the preferences file exists
			if (!file_exists) {
				save_prefs ();
			} else {
				load_prefs ();
			}
			
			start_monitor ();
		}
		
		/**
		 * Initializes this preferences with a backing filename.
		 *
		 * @param filename of the backing file for this preferences
		 */
		protected void init_from_filename (string filename)
		{
			init_from_file (Paths.AppConfigFolder.get_child (filename));
		}
		
		bool is_delayed = false;
		bool is_delayed_internal = false;
		bool is_changed = false;
		
		/**
		 * Delays saving changes to the backing file until apply() is called.
		 */
		public void delay ()
		{
			if (read_only)
				return;
			
			if (is_delayed)
				return;
			
			if (backing_file != null && backing_file.get_path () != null)
				Logger.verbose ("Preferences.delay('%s')", backing_file.get_path ());
			else
				Logger.verbose ("Preferences.delay()");
			
			is_delayed = true;
		}
		
		/**
		 * If any settings were changed, apply them now.
		 */
		public void apply ()
		{
			if (read_only)
				return;
			
			if (!is_delayed)
				return;
			
			if (backing_file != null && backing_file.get_path () != null)
				Logger.verbose ("Preferences.apply('%s')", backing_file.get_path ());
			else
				Logger.verbose ("Preferences.apply()");
			
			is_delayed = false;
			if (is_changed && backing_file != null)
				save_prefs ();
		}
		
		/**
		 * Returns the filename of the backing file.
		 *
		 * @return the filename of the backing file
		 */
		public string get_filename ()
		{
			if (backing_file == null)
				return "";
			return backing_file.get_basename ();
		}
		
		/**
		 * Returns the backing file.
		 *
		 * @return the backing file
		 */
		public unowned File? get_backing_file ()
		{
			return backing_file;
		}
		
		/**
		 * This forces the deletion of the backing file for this preferences.
		 */
		public void delete ()
		{
			if (read_only)
				return;
			
			is_delayed = false;
			is_changed = false;
			
			try {
				Logger.verbose ("Preferences.delete ('%s')", backing_file.get_path () ?? "");
				backing_file.delete ();
			} catch (Error e) {
				warning ("Unable to delete the preferences file '%s'", backing_file.get_path () ?? "");
				debug (e.message);
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
				backing_monitor = backing_file.monitor_file (0);
				backing_monitor.changed.connect (backing_file_changed);
			} catch (Error e) {
				critical ("Unable to watch the preferences file '%s'", backing_file.get_path () ?? "");
				debug (e.message);
			}
		}
		
		[CCode (instance_pos = -1)]
		void backing_file_changed (File f, File? other, FileMonitorEvent event)
		{
			switch (event) {
			case FileMonitorEvent.CHANGES_DONE_HINT:
				load_prefs ();
				break;
			case FileMonitorEvent.DELETED:
				if (!f.query_exists ())
					deleted ();
				break;
			default:
				break;
			}
		}
		
		void load_prefs ()
		{
			string backing_file_path = (backing_file.get_path () ?? "");
			
			debug ("Loading preferences from file '%s'", backing_file_path);
			
			var missing_keys = false;
			
			notify.disconnect (handle_notify);
			freeze_notify ();
			
			is_delayed_internal = true;
			try {
				var file = new KeyFile ();
				file.load_from_file (backing_file_path, 0);
				
				(unowned ParamSpec)[] properties = get_class ().list_properties ();
				
				foreach (unowned ParamSpec prop in properties) {
					unowned string group_name = prop.owner_type.name ();
					unowned string prop_name = prop.get_name ();
					
					if (!file.has_group (group_name)) {
						// Accept and handle old preferences files
						for (var i = 0; i < 3; i++)
							if (TRANSITION_MAP[i,1] == group_name) {
								group_name = TRANSITION_MAP[i,0];
								missing_keys = true;
								break;
							}
					}
					
					if (!file.has_group (group_name) || !file.has_key (group_name, prop_name)) {
						warning ("Missing key '%s' for group '%s' in preferences file '%s' - using default value", prop_name, group_name, backing_file_path);
						missing_keys = true;
						continue;
					}
					
					var type = prop.value_type;
					
					try {
						if (type == typeof (int)) {
							int old_val;
							@get (prop_name, out old_val);
							var new_val = file.get_integer (group_name, prop_name);
							if (old_val == new_val)
								continue;
							@set (prop_name, new_val);
						} else if (type == typeof (uint)) {
							uint old_val;
							@get (prop_name, out old_val);
							var new_val = (uint) file.get_integer (group_name, prop_name);
							if (old_val == new_val)
								continue;
							@set (prop_name, new_val);
						} else if (type == typeof (double)) {
							double old_val;
							@get (prop_name, out old_val);
							var new_val = file.get_double (group_name, prop_name);
							if (old_val == new_val)
								continue;
							@set (prop_name, new_val);
						} else if (type == typeof (string)) {
							string old_val;
							@get (prop_name, out old_val);
							var new_val = file.get_string (group_name, prop_name);
							if (old_val == new_val)
								continue;
							@set (prop_name, new_val);
						} else if (type == typeof (bool)) {
							bool old_val;
							@get (prop_name, out old_val);
							var new_val = file.get_boolean (group_name, prop_name);
							if (old_val == new_val)
								continue;
							@set (prop_name, new_val);
						} else if (type.is_enum ()) {
							int old_val;
							@get (prop_name, out old_val);
							var new_val = file.get_integer (group_name, prop_name);
							if (old_val == new_val)
								continue;
							@set (prop_name, new_val);
						} else if (type.is_a (typeof (Color)) || type.is_a (typeof (Gdk.RGBA))) {
							var val = Value (type);
							get_property (prop_name, ref val);
							Color* old_val = val.get_boxed ();
							var old_val_string = old_val.to_prefs_string ();
							var new_val_string = file.get_string (group_name, prop_name);
							if (old_val_string == new_val_string)
								continue;
							var new_val = Color.from_prefs_string (new_val_string);
							val.set_boxed (&new_val);
							set_property (prop_name, val);
						} else if (type.is_a (typeof (Serializable))) {
							Serializable val;
							@get (prop_name, out val);
							val.deserialize (file.get_string (group_name, prop_name));
							continue;
						} else {
							debug ("Unsupported preferences type '%s' for property '%s' in file '%s'", type.name (), prop_name, backing_file_path);
							continue;
						}
						
						call_verify (prop_name);
					} catch (KeyFileError e) {
						warning ("Problem loading preferences from file '%s' for property '%s'", backing_file_path, prop_name);
						debug (e.message);
					}
				}
			} catch (Error e) {
				warning ("Unable to load preferences from file '%s'", backing_file_path);
				debug (e.message);
				deleted ();
			}
			
			thaw_notify ();
			notify.connect (handle_notify);
			
			is_delayed_internal = false;
			if (missing_keys
				|| (!is_delayed && is_changed && backing_file != null))
				save_prefs ();
		}
		
		void save_prefs ()
			requires (backing_file != null)
		{
			if (read_only)
				return;
			
			string backing_file_path = (backing_file.get_path () ?? "");
			
			if (is_delayed || is_delayed_internal) {
				Logger.verbose ("Preferences.save_prefs('%s') - delaying save", backing_file_path);
				is_changed = true;
				return;
			}
			
			stop_monitor ();
			freeze_notify ();
			
			var file = new KeyFile ();
			
			try {
				file.set_comment (null, null, "This file auto-generated by Plank.\n%s".printf (new DateTime.now_utc ().to_string ()));
			} catch { }
			
			(unowned ParamSpec)[] properties = get_class ().list_properties ();
			
			foreach (unowned ParamSpec prop in properties) {
				unowned string group_name = prop.owner_type.name ();
				unowned string prop_name = prop.get_name ();
				var type = prop.value_type;
				
				if (type == typeof (int)) {
					int new_val;
					@get (prop_name, out new_val);
					file.set_integer (group_name, prop_name, new_val);
				} else if (type == typeof (uint)) {
					uint new_val;
					@get (prop_name, out new_val);
					file.set_integer (group_name, prop_name, (int) new_val);
				} else if (type == typeof (double)) {
					double new_val;
					@get (prop_name, out new_val);
					file.set_double (group_name, prop_name, new_val);
				} else if (type == typeof (string)) {
					string new_val;
					@get (prop_name, out new_val);
					file.set_string (group_name, prop_name, new_val);
				} else if (type == typeof (bool)) {
					bool new_val;
					@get (prop_name, out new_val);
					file.set_boolean (group_name, prop_name, new_val);
				} else if (type.is_enum ()) {
					int new_val;
					@get (prop_name, out new_val);
					file.set_integer (group_name, prop_name, new_val);
				} else if (type.is_a (typeof (Color)) || type.is_a (typeof (Gdk.RGBA))) {
					var val = Value (type);
					get_property (prop_name, ref val);
					Color* color = val.get_boxed ();
					file.set_string (group_name, prop_name, (color.to_prefs_string ()));
				} else if (type.is_a (typeof (Serializable))) {
					var val = Value (type);
					get_property (prop_name, ref val);
					file.set_string (group_name, prop_name, ((Serializable) val.get_object ()).serialize ());
				} else {
					debug ("Unsupported preferences type '%s' for property '%s' in file '%s'", type.name (), prop_name, backing_file_path);
					continue;
				}
				
				unowned string prop_blurb = prop.get_blurb ();
				if (prop_blurb != null && prop_blurb != "" && prop_blurb != prop_name)
					try {
						file.set_comment (group_name, prop_name, prop_blurb);
					} catch { }
			}
			
			debug ("Saving preferences '%s'", backing_file_path);
			is_changed = false;
			
			try {
				var stream = new DataOutputStream (backing_file.replace (null, false, 0));
				stream.put_string (file.to_data ());
				stream.close ();
			} catch (Error e) {
				warning ("Unable to create the preferences file '%s'", backing_file_path);
				debug (e.message);
			}
			
			thaw_notify ();
			start_monitor ();
		}
	}
}
