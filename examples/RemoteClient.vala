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

using Plank;

namespace PlankExamples
{
	public class RemoteClient : GLib.Application
	{
		construct
		{
			application_id = "net.launchpad.plank.remote-client";
			flags = ApplicationFlags.FLAGS_NONE;
			
			Logger.initialize ("remote-client");
			Logger.DisplayLevel = LogLevel.DEBUG;
		}
		
		public override void activate ()
		{
			hold ();
			
			var client = Plank.DBusClient.get_instance ();
			client.proxy_changed.connect (handle_proxy_changed);
		}
		
		void handle_proxy_changed (DBusClient client)
		{
			if (!client.is_connected)
				return;
			
			print ("List all persistent applications:\n");
			foreach (unowned string s in client.get_persistent_applications ())
				print (" + %s\n", s);
			
			print ("List all transient applications:\n");
			foreach (unowned string s in client.get_transient_applications ())
				print (" + %s\n", s);
			
			print ("\n");
		}
		
		public static int main (string[] args)
		{
			var application = new RemoteClient ();
			return application.run (args);
		}
		
	}
}
