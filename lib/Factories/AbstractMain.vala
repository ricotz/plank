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

using Plank.Items;

using Plank.Services;
using Plank.Services.Windows;
using Plank.Widgets;

namespace Plank.Factories
{
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
		protected string dock_name = "dock1";
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
		 * The license of this program (to show in about dialog).
		 */
		protected Gtk.License about_license_type = Gtk.License.UNKNOWN;
		
		/**
		 * The Application for preserving uniqueness
		 */
		protected Gtk.Application application;
		
		/**
		 * Initializes the program, makes the dock and runs it.
		 *
		 * @param args the command-line arguments
		 * @return the exit status value
		 */
		public virtual int run (ref unowned string[] args)
		{
			initialize_program ();
			
			if (!parse_commandline (ref args))
				return Posix.EXIT_FAILURE;
			
			if (!initialize_libraries (ref args))
				return Posix.EXIT_FAILURE;
			
			set_options ();
			
			initialize_services ();
			
			initialized ();
			
			create_controller ();
			
			Gdk.threads_enter ();
			Gtk.main ();
			Gdk.threads_leave ();
			
			return Posix.EXIT_SUCCESS;
		}
		
		/**
		 * Sets the program executable's name, traps signals and intializes logging.
		 */
		protected virtual void initialize_program ()
		{
			// set program name
			prctl (15, exec_name);
			Environment.set_prgname (exec_name);
			
			Posix.signal(Posix.SIGINT, sig_handler);
			Posix.signal(Posix.SIGTERM, sig_handler);
			
			Logger.initialize (program_name);
			Logger.DisplayLevel = LogLevel.INFO;
			message ("%s version: %s", program_name, build_version);
			message ("Kernel version: %s", Posix.utsname ().release);
			message ("GLib version: %u.%u.%u", GLib.Version.major, GLib.Version.minor, GLib.Version.micro);
			message ("GTK+ version: %u.%u.%u", Gtk.get_major_version (), Gtk.get_minor_version () , Gtk.get_micro_version ());
#if HAVE_GTK_3_10
			message ("+ HiDPI support enabled");
#endif
			message ("Wnck version: %d.%d.%d", Wnck.Version.MAJOR_VERSION, Wnck.Version.MINOR_VERSION, Wnck.Version.MICRO_VERSION);
			message ("Cairo version: %s", Cairo.version_string ());
			message ("Pango version: %s", Pango.version_string ());
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
		 * If verbose mode is enabled.
		 */
		protected static bool VERBOSE = false;
		
		/**
		 * The given dock_name
		 */
		protected static string DOCK_NAME = "dock1";
		
		/**
		 * The default command-line options for the dock.
		 */
		protected const OptionEntry[] options = {
			{ "debug", 'd', 0, OptionArg.NONE, out DEBUG, "Enable debug logging", null },
			{ "verbose", 'v', 0, OptionArg.NONE, out VERBOSE, "Enable verbose logging", null },
			{ "name", 'n', 0, OptionArg.STRING, out DOCK_NAME, "The name of this dock", null },
			{ null }
		};
		
		/**
		 * Parses the command-line for options, but does not set them.
		 *
		 * @param args the command-line arguments
		 * @return whether the arguments were parsed successfully
		 */
		protected virtual bool parse_commandline (ref unowned string[] args)
		{
			// parse commandline options
			var context = new OptionContext ("");
			
			context.add_main_entries (options, null);
			context.add_group (Gtk.get_option_group (false));
			
			try {
				context.parse (ref args);
			} catch {
				return false;
			}
			
			dock_name = DOCK_NAME;
			
			return true;
		}
		
		/**
		 * Sets options based on the parsed command-line.
		 */
		protected virtual void set_options ()
		{
			if (DEBUG)
				Logger.DisplayLevel = LogLevel.DEBUG;
			if (VERBOSE)
				Logger.DisplayLevel = LogLevel.VERBOSE;
		}
		
		/**
		 * Initializes most libraries used (GTK, GDK, etc).
		 *
		 * @param args the command-line arguments
		 * @return whether the libraries were intialized successfully
		 */
		protected virtual bool initialize_libraries (ref unowned string[] args)
		{
			Intl.bindtextdomain (exec_name, build_data_dir + "/locale");
			
			if (!Thread.supported ()) {
				critical ("Problem initializing thread support.");
				return false;
			}
			
			Gdk.threads_init ();
			Gtk.init (ref args);
			
			// ensure only one instance per dock_name
			var path = app_dbus + "." + dock_name;
			
			application = new Gtk.Application (path, ApplicationFlags.FLAGS_NONE);
			try {
				if (application.register () && !application.get_is_remote ())
					return true;
			} catch (Error e) {
				critical ("Registering application as '%s' failed. (%s)", dock_name, e.message);
				return false;
			}
			
			warning ("Exiting because another instance of this application is already running with the name '%s'.", dock_name);
			return false;
		}
		
		/**
		 * Initializes the Plank services.
		 */
		protected virtual void initialize_services ()
		{
			Paths.initialize (exec_name, build_pkg_data_dir);
			Paths.ensure_directory_exists (Paths.AppConfigFolder.get_child (dock_name));
			WindowControl.initialize ();
		}
		
		/**
		 * Creates the dock controller.
		 */
		protected virtual void create_controller ()
		{
			var controller = new DockController (Paths.AppConfigFolder.get_child (dock_name));
			controller.initialize ();
		}
		
		/**
		 * Is true if the launcher given is the launcher for this dock.
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
				about_dlg.show_all ();
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
			about_dlg.set_license_type (about_license_type);
			
			about_dlg.response.connect (() => {
				about_dlg.hide ();
			});
			about_dlg.hide.connect (() => {
				about_dlg.destroy ();
				about_dlg = null;
			});
			
			about_dlg.show_all ();
		}
	}
}
