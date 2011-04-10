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

using Gtk;
using Unique;

using Plank.Services;
using Plank.Services.Windows;
using Plank.Widgets;

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
		public string program_name;
		public string exec_name;
		
		public string app_copyright;
		public string app_dbus;
		public string app_icon;
		public string app_launcher;

		public string main_url;
		public string help_url;
		public string translate_url;
		
		public string[] about_authors;
		public string[] about_documenters;
		public string[] about_artists;
		public string about_translators;
		
		protected virtual int start (string[] args)
		{
			// set program name
			prctl (15, exec_name, 0, 0, 0);
			
			Posix.signal(Posix.SIGINT, sig_handler);
			Posix.signal(Posix.SIGTERM, sig_handler);
			
			Logger.initialize (program_name);
			Logger.DisplayLevel = LogLevel.INFO;
			Logger.info<AbstractMain> ("%s version: %s".printf (program_name, Build.VERSION));
			utsname un = utsname ();
			uname (un);
			Logger.info<AbstractMain> ("Kernel version: %s".printf ((string) un.release));
			Logger.DisplayLevel = LogLevel.WARN;
			
			// parse commandline options
			var context = new OptionContext ("");
			
			context.add_main_entries (options, null);
			context.add_group (Gtk.get_option_group (false));
			
			try {
				context.parse (ref args);
			} catch { }
			
			Intl.bindtextdomain (exec_name, Build.DATADIR + "/locale");
			
			if (!Thread.supported ()) {
				Logger.fatal<AbstractMain> ("Problem initializing thread support.");
				return -1;
			}
			Gdk.threads_init ();
			Gtk.init (ref args);
			
			// ensure only one instance
			if (new App (app_dbus, null).is_running) {
				Logger.fatal<AbstractMain> ("Exiting because another instance is already running.");
				return -2;
			}
			
			set_options ();
			
			Paths.initialize (exec_name);
			WindowControl.initialize ();
			
			var app = new DockWindow ();
			app.show_all ();
			
			Gdk.threads_enter ();
			Gtk.main ();
			Gdk.threads_leave ();
			
			return 0;
		}
		
		public virtual void quit ()
		{
			Gtk.main_quit ();
		}
		
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
		
		protected virtual void set_options ()
		{
			if (DEBUG)
				Logger.DisplayLevel = LogLevel.DEBUG;
		}
		
		public virtual void show_about ()
		{
			var dlg = new AboutDialog ();
			
			dlg.set_program_name (exec_name);
			dlg.set_version (Build.VERSION + "\n" + Build.VERSION_INFO);
			dlg.set_logo_icon_name (app_icon);
			
			dlg.set_comments (program_name + ". " + Build.RELEASE_NAME);
			dlg.set_copyright ("Copyright © %s %s Developers".printf (app_copyright, program_name));
			dlg.set_website (main_url);
			dlg.set_website_label ("Website");
			
			dlg.set_authors (about_authors);
			dlg.set_documenters (about_documenters);
			dlg.set_artists (about_artists);
			dlg.set_translator_credits (about_translators);
			
			dlg.show_all ();
			dlg.response.connect (() => {
				dlg.hide_all ();
				dlg.destroy ();
			});
		}
	}
}
