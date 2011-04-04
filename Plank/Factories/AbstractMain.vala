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

using Plank.Services;

namespace Plank.Factories
{
	public struct utsname
	{
		char sysname [65];
		char nodename [65];
		char release [65];
		char version [65];
		char machine [65];
		char domainname [65];
	}
	
	public abstract class AbstractMain : GLib.Object
	{
		public abstract void quit ();
		
		public abstract void show_about ();
		
		[CCode (cheader_filename = "sys/prctl.h", cname = "prctl")]
		protected extern static int prctl (int option, string arg2, ulong arg3, ulong arg4, ulong arg5);
		
		[CCode (cheader_filename = "sys/utsname.h", cname = "uname")]
		protected extern static int uname (utsname buf);
		
		protected static bool DEBUG = false;

		protected const OptionEntry[] options = {
			{ "debug", 'd', 0, OptionArg.NONE, out DEBUG, "Enable debug logging", null },
			{ null }
		};
		
		protected static void sig_handler (int sig)
		{
			Logger.warn<AbstractMain> ("Caught signal (%d), exiting".printf (sig));
			Factory.main.quit ();
		}
		
		protected static void set_options ()
		{
			if (DEBUG)
				Logger.DisplayLevel = LogLevel.DEBUG;
		}
	}
}
