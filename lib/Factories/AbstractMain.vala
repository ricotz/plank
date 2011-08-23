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
		protected signal void initialized ();
		
		public string build_data_dir;
		public string build_pkg_data_dir;
		public string build_release_name;
		public string build_version;
		public string build_version_info;
		
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
			Environment.set_prgname (exec_name);
			
			Posix.signal(Posix.SIGINT, sig_handler);
			Posix.signal(Posix.SIGTERM, sig_handler);
			
			Logger.initialize (program_name);
			Logger.DisplayLevel = LogLevel.INFO;
			message ("%s version: %s", program_name, build_version);
			var un = utsname ();
			uname (un);
			message ("Kernel version: %s", (string) un.release);
			Logger.DisplayLevel = LogLevel.WARN;
			
			// parse commandline options
			var context = new OptionContext ("");
			
			context.add_main_entries (options, null);
			context.add_group (Gtk.get_option_group (false));
			
			try {
				context.parse (ref args);
			} catch { }
			
			Intl.bindtextdomain (exec_name, build_data_dir + "/locale");
			
			if (!Thread.supported ())
				error ("Problem initializing thread support.");
			Gdk.threads_init ();
			
			Gtk.init (ref args);
			
			// ensure only one instance
			if (new App (app_dbus, null).is_running)
				error ("Exiting because another instance is already running.");
			
			set_options ();
			
			Paths.initialize (exec_name, build_pkg_data_dir);
			WindowControl.initialize ();
			
			initialized ();
			
			new DockWindow ().show_all ();
			
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
			warning ("Caught signal (%d), exiting", sig);
			Factory.main.quit ();
		}
		
		protected virtual void set_options ()
		{
			if (DEBUG)
				Logger.DisplayLevel = LogLevel.DEBUG;
		}
		
		protected AboutDialog about_dlg;
		
		public virtual void show_about ()
		{
			if (about_dlg != null) {
				about_dlg.window.raise ();
				return;
			}
			
			about_dlg = new AboutDialog ();
			
			about_dlg.set_program_name (exec_name);
			about_dlg.set_version (build_version + "\n" + build_version_info);
			about_dlg.set_logo_icon_name (app_icon);
			
			about_dlg.set_comments (program_name + ". " + build_release_name);
			about_dlg.set_copyright ("Copyright © %s %s Developers".printf (app_copyright, program_name));
			about_dlg.set_website (main_url);
			about_dlg.set_website_label ("Website");
			
			about_dlg.set_authors (about_authors);
			about_dlg.set_documenters (about_documenters);
			about_dlg.set_artists (about_artists);
			about_dlg.set_translator_credits (about_translators);
			
			about_dlg.response.connect (() => {
				about_dlg.hide_all ();
			});
			about_dlg.hide.connect (() => {
				about_dlg.destroy ();
				about_dlg = null;
			});
			
			about_dlg.show_all ();
		}
	}
}
