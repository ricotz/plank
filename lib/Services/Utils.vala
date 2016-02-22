//
//  Copyright (C) 2015 Rico Tzschichholz
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
	 * Creates a new {@link GLib.Settings} object with a given schema and path.
	 *
	 * It is fatal if no schema to the given schema_id is found!
	 *
	 * If path is NULL then the path from the schema is used. It is an error if
	 * path is NULL and the schema has no path of its own or if path is non-NULL
	 * and not equal to the path that the schema does have.
	 *
	 * @param schema_id a schema ID
	 * @param path the path to use
	 * @return a new GLib.Settings object
	 */
	public static GLib.Settings create_settings (string schema_id, string? path = null)
	{
		//FIXME Only to make it run/work uninstalled from top_builddir
		Environment.set_variable ("GSETTINGS_SCHEMA_DIR", Environment.get_current_dir () + "/data", false);
		
		var schema = GLib.SettingsSchemaSource.get_default ().lookup (schema_id, true);
		if (schema == null)
			error ("GSettingsSchema '%s' not found", schema_id);
		
		return new GLib.Settings.full (schema, null, path);
	}
	
	/**
	 * Tries to create a new {@link GLib.Settings} object with a given schema and path.
	 *
	 * If path is NULL then the path from the schema is used. It is an error if
	 * path is NULL and the schema has no path of its own or if path is non-NULL
	 * and not equal to the path that the schema does have.
	 *
	 * @param schema_id a schema ID
	 * @param path the path to use
	 * @return a new GLib.Settings object or NULL
	 */
	public static GLib.Settings? try_create_settings (string schema_id, string? path = null)
	{
		var schema = GLib.SettingsSchemaSource.get_default ().lookup (schema_id, true);
		if (schema == null) {
			warning ("GSettingsSchema '%s' not found", schema_id);
			return null;
		}
		
		return new GLib.Settings.full (schema, null, path);
	}
	
	/**
	 * Generates an array containing all combinations of a splitted strings parts
	 * while preserving the given order of them.
	 *
	 * @param s a string
	 * @param delimiter a delimiter string
	 * @return an array of concated strings
	 */
	public static string[] string_split_combine (string s, string delimiter = " ")
	{
		var parts = s.split (delimiter);
		var count = parts.length;
		var result = new string[count * (count + 1) / 2];
		
		// Initialize array with the elementary parts
		int pos = 0;
		for (int i = 0; i < count; i++) {
			result[pos] = parts[i];
			pos += (count - i);
		}
		
		// Recursively filling up the result array
		combine_strings (ref result, delimiter, 0, count);
		
		return result;
	}
	
	static void combine_strings (ref string[] result, string delimiter, int n, int i)
	{
		if (i <= 1)
			return;
		
		int pos = n;
		for (int j = 0; j < i - 1; j++) {
			pos += (i - j);
			result[n + j + 1] = "%s%s%s".printf (result[n + j], delimiter, result[pos]);
		}
		
		combine_strings (ref result, delimiter, n + i, i - 1);
	}
	
	/**
	 * Whether the given file looks like a valid .dockitem file
	 */
	public inline bool file_is_dockitem (File file)
	{
		try {
			var info = file.query_info (FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_IS_HIDDEN, 0);
			return !info.get_is_hidden () && info.get_name ().has_suffix (".dockitem");
		} catch (Error e) {
			warning (e.message);
		}
		
		return false;
	}
	
	public inline double nround (double d, uint n)
	{
		double result;
		
		if (n > 0U) {
			var fac = Math.pow (10.0, n);
			result = Math.round (d * fac) / fac;
		} else {
			result = Math.round (d);
		}
		
		return result;
	}
}
