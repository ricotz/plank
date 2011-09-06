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
#if VALA_0_12
using Posix;
#endif

using Plank.Services;
using Plank.Services.Windows;
using Plank.Widgets;

namespace Plank.Factories
{
#if VALA_0_12
#else
	struct utsname
	{
		char sysname [65];
		char nodename [65];
		char release [65];
		char version [65];
		char machine [65];
		char domainname [65];
	}
#endif
	
	/**
	 * The main class for all dock applications.  All docks should extend this class.
	 * In the constructor, the string fields should be initialized to customize the dock.
	 */
	public abstract class AbstractMain : GLib.Object
	{
		protected signal void initialized ();
		
		protected string build_data_dir;
		protected string build_pkg_data_dir;
		protected string build_release_name;
		protected string build_version;
		protected string build_version_info;
		
		protected string program_name;
		protected string exec_name;
		
		protected string app_copyright;
		protected string app_dbus;
		protected string app_icon;
		protected string app_launcher;

		protected string main_url;
		protected string help_url;
		protected string translate_url;
		
		protected string[] about_authors;
		protected string[] about_documenters;
		protected string[] about_artists;
		protected string about_translators;
		
		/**
		 * Initializes the program, makes the dock and starts it.
		 *
		 * @param args the command-line arguments
		 */
		public virtual int start (string[] args)
		{
			initialize_program ();
			
			args = parse_commandline (args);
			
			args = initialize_libraries (args);
			
			set_options ();
			
			initialize_services ();
			
			initialized ();
			
			start_dock ();
			
			return 0;
		}
		
		[CCode (cheader_filename = "sys/prctl.h", cname = "prctl")]
		extern static int prctl (int option, string arg2, ulong arg3, ulong arg4, ulong arg5);
		
#if VALA_0_12
#else
		[CCode (cheader_filename = "sys/utsname.h", cname = "uname")]
		extern static int uname (utsname buf);
#endif
		
		/**
		 * Sets the program executable's name, traps signals and intializes logging.
		 */
		protected virtual void initialize_program ()
		{
			// set program name
			prctl (15, exec_name, 0, 0, 0);
			Environment.set_prgname (exec_name);
			
			Posix.signal(Posix.SIGINT, sig_handler);
			Posix.signal(Posix.SIGTERM, sig_handler);
			
			Logger.initialize (program_name);
			Logger.DisplayLevel = LogLevel.INFO;
			message ("%s version: %s", program_name, build_version);
#if VALA_0_12
			var un = Posix.utsname ();
#else
			var un = utsname ();
			uname (un);
#endif
			message ("Kernel version: %s", (string) un.release);
			Logger.DisplayLevel = LogLevel.WARN;
		}
		
		static void sig_handler (int sig)
		{
			warning ("Caught signal (%d), exiting", sig);
			Factory.main.quit ();
		}
		
		/**
		 * If debug mode is enabled.
		 */
		protected static bool DEBUG = false;
		
		/**
		 * The default command-line options for the dock.
		 */
		protected const OptionEntry[] options = {
			{ "debug", 'd', 0, OptionArg.NONE, out DEBUG, "Enable debug logging", null },
			{ null }
		};
		
		/**
		 * Parses the command-line for options, but does not set them.
		 *
		 * @param args the command-line arguments
		 */
		protected virtual unowned string[] parse_commandline (string[] args)
		{
			// parse commandline options
			var context = new OptionContext ("");
			
			context.add_main_entries (options, null);
			context.add_group (Gtk.get_option_group (false));
			
			try {
				context.parse (ref args);
			} catch { }
			
			return args;
		}
		
		/**
		 * Sets options based on the parsed command-line.
		 */
		protected virtual void set_options ()
		{
			if (DEBUG)
				Logger.DisplayLevel = LogLevel.DEBUG;
		}
		
		/**
		 * Initializes most libraries used (GTK, GDK, etc).
		 *
		 * @param args the command-line arguments
		 */
		protected virtual unowned string[] initialize_libraries (string[] args)
		{
			Intl.bindtextdomain (exec_name, build_data_dir + "/locale");
			
			if (!Thread.supported ())
				error ("Problem initializing thread support.");
			Gdk.threads_init ();
			
			Gtk.init (ref args);
			
			// ensure only one instance
			if (new App (app_dbus, null).is_running)
				error ("Exiting because another instance is already running.");
			
			return args;
		}
		
		/**
		 * Initializes the Plank services.
		 */
		protected virtual void initialize_services ()
		{
			Paths.initialize (exec_name, build_pkg_data_dir);
			WindowControl.initialize ();
		}
		
		/**
		 * Creates and displays the dock window.
		 */
		protected virtual void start_dock ()
		{
			new DockWindow ().show_all ();
			
			Gdk.threads_enter ();
			Gtk.main ();
			Gdk.threads_leave ();
		}
		
		/**
		 * Returns true if the launcher given is the launcher for this dock.
		 *
		 * @param launcher the launcher to test
		 */
		public bool is_launcher_for_dock (string launcher)
		{
			return launcher.has_suffix (app_launcher);
		}
		
		/**
		 * Displays the help page.
		 */
		public virtual void help ()
		{
			Services.System.open_uri (help_url);
		}
		
		/**
		 * Displays the translate page.
		 */
		public virtual void translate ()
		{
			Services.System.open_uri (translate_url);
		}
		
		/**
		 * Quits the program.
		 */
		public virtual void quit ()
		{
			Gtk.main_quit ();
		}
		
		/**
		 * Called when a {@link Plank.Items.PlankDockItem} is clicked.
		 */
		public virtual void on_item_clicked ()
		{
			show_about ();
		}
		
		/**
		 * The about dialog for the program.
		 */
		protected static AboutDialog about_dlg;
		
		/**
		 * Displays the about dialog.
		 */
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
