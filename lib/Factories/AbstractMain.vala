//  
//  Copyright (C) 2011-2012 Robert Dyer, Rico Tzschichholz
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
using Posix;

using Plank.Services;
using Plank.Services.Windows;
using Plank.Widgets;

namespace Plank.Factories
{
#if !VALA_0_12
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
		/**
		 * Signal fired when the program is fully initialized, before creating and showing the dock.
		 */
		protected signal void initialized ();
		
		/**
		 * Should be Build.DATADIR
		 */
		protected string build_data_dir = "";
		/**
		 * Should be Build.PKGDATADIR
		 */
		protected string build_pkg_data_dir = "";
		/**
		 * Should be Build.RELEASE_NAME
		 */
		protected string build_release_name = "";
		/**
		 * Should be Build.VERSION
		 */
		protected string build_version = "";
		/**
		 * Should be Build.VERSION_INFO
		 */
		protected string build_version_info = "";
		
		/**
		 * The displayed name of the program.
		 */
		protected string program_name = "";
		/**
		 * The executable name of the program.
		 */
		protected string exec_name = "";
		
		/**
		 * The copyright year(s).
		 */
		protected string app_copyright = "";
		/**
		 * The (unique) dbus path for this program.
		 */
		protected string app_dbus = "";
		/**
		 * The name of the path containing the dock's preferences.
		 */
		public static string dock_path = "dock1";
		/**
		 * The name of this program's icon.
		 */
		protected string app_icon = "";
		/**
		 * The name of the launcher (.desktop file) for this program.
		 */
		public string app_launcher = "";

		/**
		 * The URL for this program's website.
		 */
		protected string main_url = "";
		/**
		 * The URL for this program's help.
		 */
		protected string help_url = "";
		/**
		 * The URL for translating this program.
		 */
		protected string translate_url = "";
		
		/**
		 * The list of authors (to show in about dialog).
		 */
		protected string[] about_authors = {};
		/**
		 * The list of documenters (to show in about dialog).
		 */
		protected string[] about_documenters = {};
		/**
		 * The list of artists (to show in about dialog).
		 */
		protected string[] about_artists = {};
		/**
		 * The list of translators (to show in about dialog).
		 */
		protected string about_translators = "";
		
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
		
#if !VALA_0_12
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
			message ("GTK version: %d.%d.%d", Gtk.MAJOR_VERSION, Gtk.MINOR_VERSION, Gtk.MICRO_VERSION);
			message ("Cairo version: %s", Cairo.version_string ());
			message ("Pango version: %s", Pango.VERSION_STRING);
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
			{ "name", 'n', 0, OptionArg.STRING, out dock_path, "The name of this dock", null },
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
			
			// ensure only one instance per dock_path
			if (new App (app_dbus + "." + dock_path, null).is_running)
				error ("Exiting because another instance of this application is already running with the name '%s'.".printf (dock_path));
			
			return args;
		}
		
		/**
		 * Initializes the Plank services.
		 */
		protected virtual void initialize_services ()
		{
			Paths.initialize (exec_name, build_pkg_data_dir);
			Paths.ensure_directory_exists (Paths.AppConfigFolder.get_child (dock_path));
			WindowControl.initialize ();
		}
		
		/**
		 * Creates and displays the dock window.
		 */
		protected virtual void start_dock ()
		{
			var controller = new DockController ();
			controller.window.show_all ();
			
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
		 * Called when a {@link Items.PlankDockItem} is clicked.
		 */
		public virtual void on_item_clicked ()
		{
			show_about ();
		}
		
		/**
		 * The about dialog for the program.
		 */
		protected static AboutDialog? about_dlg;
		
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
