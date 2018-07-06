//
//  Copyright (C) 2014 Rico Tzschichholz
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

namespace Plank
{
	/**
	 * The base class for gsettings-based configuration classes. Defined properties will be bound
	 * to the corresponing schema-key of the given schema-path. The property's nick-name must match
	 * the schema-key.
	 */
	public abstract class Settings : GLib.Object
	{
		[CCode (notify = false)]
		public GLib.Settings settings { get; construct; }
		
		[CCode (notify = false)]
		public GLib.SettingsBindFlags bind_flags { get; construct; default = SettingsBindFlags.DEFAULT; }
		
		/**
		 * {@inheritDoc}
		 */
		public Settings (string schema)
		{
			Object (settings: new GLib.Settings (schema));
		}
		
		/**
		 * {@inheritDoc}
		 */
		public Settings.with_path (string schema, string path)
		{
			Object (settings: new GLib.Settings.with_path (schema, path));
		}
		
		construct
		{
			unowned string class_type_name = get_type ().name ();
			
			debug ("Bind '%s' to '%s'", class_type_name, settings.path);
			
			(unowned ParamSpec)[] properties = get_class ().list_properties ();
			
			// Bind available gsettings-keys to their class-properties
			foreach (unowned string key in settings.list_keys ()) {
				//Not taking a references of matched ParamSpec results in undefined behaviour
				ParamSpec? property = null;
				foreach (unowned ParamSpec p in properties)
					if (p.get_nick () == key) {
						property = p;
						break;
					}
				if (property == null)
					continue;
				
				unowned string name = property.get_name ();
				unowned string nick = property.get_nick ();
				var type = property.value_type;
				
				Logger.verbose ("Bind '%s%s' to '%s.%s'", settings.path, nick, class_type_name, name);
				if (type.is_fundamental () || type.is_enum () || type.is_flags () || type == typeof(string[])) {
					settings.bind (nick, this, name, bind_flags);
				} else {
					warning ("Binding of '%s' from type '%s' not supported yet!", name, type.name ());
				}
				
				verify (name);
			}
		}
		
		/**
		 * Verify the property given by its name and change the property if necessary.
		 *
		 * @param name the name of the property
		 */
		protected virtual void verify (string name)
		{
			// do nothing, this isnt abstract because we dont
			// want to force subclasses to implement this
		}
		
		/**
		 * Resets all properties to their default values.
		 */
		protected void reset_all ()
		{
			foreach (unowned string key in settings.list_keys ())
				settings.reset (key);
		}
		
		/**
		 * Delays saving changes until apply() is called.
		 */
		public void delay ()
		{
			if (settings.delay_apply)
				return;
			
			Logger.verbose ("Settings.delay()");
			
			settings.delay ();
		}
		
		/**
		 * If any settings were changed, apply them now.
		 */
		public void apply ()
		{
			if (!settings.delay_apply)
				return;
			
			Logger.verbose ("Settings.apply()");
			
			settings.apply ();
		}
	}
}
