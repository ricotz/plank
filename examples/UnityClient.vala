//
//  Copyright (C) 2016 Rico Tzschichholz
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

using Plank;

namespace PlankExamples
{
	public class TestClient : Object, Plank.UnityClient
	{
		public void remove_launcher_entry (string sender_name)
		{
			print ("Client '%s' was terminated\n", sender_name);
		}

		public void update_launcher_entry (string sender_name, GLib.Variant parameters, bool is_retry = false)
		{
			print ("Client '%s' requests an update\n", sender_name);

			// Decode and process the given "paramaters" argument
			string app_uri;
			VariantIter prop_iter;
			parameters.get ("(sa{sv})", out app_uri, out prop_iter);

			print ("=> '%s'\n   %s\n", app_uri, decode_payload (prop_iter));
		}

		static string decode_payload (VariantIter prop_iter)
		{
			var result = new StringBuilder ();
			
			string prop_key;
			Variant prop_value;
			
			while (prop_iter.next ("{sv}", out prop_key, out prop_value)) {
				if (prop_key == "count") {
					var val = prop_value.get_int64 ();
					result.append ("count = %lld; ".printf (val));
				} else if (prop_key == "count-visible") {
					var val = prop_value.get_boolean ();
					result.append ("count-visible = %s; ".printf (val ? "true" : "false"));
				} else if (prop_key == "progress") {
					var val = prop_value.get_double ();
					result.append ("progress = %f; ".printf (val));
				} else if (prop_key == "progress-visible") {
					var val = prop_value.get_boolean ();
					result.append ("progress-visible = %s; ".printf (val ? "true" : "false"));
				} else if (prop_key == "urgent") {
					var val = prop_value.get_boolean ();
					result.append ("urgent = %s; ".printf (val ? "true" : "false"));
#if HAVE_DBUSMENU
				} else if (prop_key == "quicklist") {
					/* The value is the object path of the dbusmenu */
					unowned string dbus_path = prop_value.get_string ();
					result.append ("quicklist = %s; ".printf (dbus_path));
#endif
				}
			}

			return (owned) result.str;
		}
	}

	public class UnityExample : GLib.Application
	{
		construct
		{
			application_id = "net.launchpad.plank.unity-client";
			flags = ApplicationFlags.FLAGS_NONE;

			Logger.initialize ("unity-client");
			Logger.DisplayLevel = LogLevel.DEBUG;
		}

		public override void activate ()
		{
			hold ();

			unowned Unity unity = Unity.get_default ();

			var client = new TestClient ();
			unity.add_client (client);

			//unity.remove_client (client);
		}

		public static int main (string[] args)
		{
			var application = new UnityExample ();
			return application.run (args);
		}
	}
}
