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

using Plank.Widgets;
using Plank.Services;
using Plank.Services.Windows;

namespace Plank.Factories
{
	/**
	 * The main class for all dock applications.  All docks should extend this class.
	 * In the constructor, the string fields should be initialized to customize the dock.
	 */
	public abstract class AbstractMain : Gtk.Application
	{
		/**
		 * The default command-line options for the dock.
		 */
		const OptionEntry[] options = {
			{ "debug", 'd', 0, OptionArg.NONE, ref DEBUG, "Enable debug logging", null },
			{ "verbose", 'v', 0, OptionArg.NONE, ref VERBOSE, "Enable verbose logging", null },
			{ "name", 'n', 0, OptionArg.STRING, ref NAME, "The name of this dock", null },
			{ "preferences", 0, 0, OptionArg.NONE, ref PREFERENCES, "Show the application's preferences dialog", null },
			{ "version", 'V', 0, OptionArg.NONE, ref VERSION, "Show the application's version", null },
			{ null }
		};

		static bool DEBUG = false;
		static bool VERBOSE = false;
		static bool PREFERENCES = false;
		static bool VERSION = false;
		static string NAME = "dock1";
		
		static void sig_handler (int sig)
		{
			warning ("Caught signal (%d), exiting", sig);
			GLib.Application.get_default ().quit ();
		}
		
		static construct
		{
			Posix.signal(Posix.SIGINT, sig_handler);
			Posix.signal(Posix.SIGTERM, sig_handler);
		}
		
		/**
		 * Should be Build.DATADIR
		 */
		public string build_data_dir { get; construct; }
		/**
		 * Should be Build.PKGDATADIR
		 */
		public string build_pkg_data_dir { get; construct; }
		/**
		 * Should be Build.RELEASE_NAME
		 */
		public string build_release_name { get; construct; }
		/**
		 * Should be Build.VERSION
		 */
		public string build_version { get; construct; }
		/**
		 * Should be Build.VERSION_INFO
		 */
		public string build_version_info { get; construct; }
		
		/**
		 * The displayed name of the program.
		 */
		public string program_name { get; construct; }
		/**
		 * The executable name of the program.
		 */
		public string exec_name { get; construct; }
		
		/**
		 * The copyright year(s).
		 */
		public string app_copyright { get; construct; }
		/**
		 * The (unique) dbus path for this program.
		 */
		public string app_dbus { get; construct; }
		/**
		 * The name of the path containing the dock's preferences.
		 */
		public string dock_name { get; protected set; }
		/**
		 * The name of this program's icon.
		 */
		public string app_icon { get; construct; }
		/**
		 * The name of the launcher (.desktop file) for this program.
		 */
		public string app_launcher { get; construct; }

		/**
		 * The URL for this program's website.
		 */
		public string main_url { get; construct set; }
		/**
		 * The URL for this program's help.
		 */
		public string help_url { get; construct set; }
		/**
		 * The URL for translating this program.
		 */
		public string translate_url { get; construct set; }
		
		/**
		 * The list of authors (to show in about dialog).
		 */
		public string[] about_authors { get; construct set; }
		/**
		 * The list of documenters (to show in about dialog).
		 */
		public string[] about_documenters { get; construct set; }
		/**
		 * The list of artists (to show in about dialog).
		 */
		public string[] about_artists { get; construct set; }
		/**
		 * The list of translators (to show in about dialog).
		 */
		public string about_translators { get; construct set; }
		/**
		 * The license of this program (to show in about dialog).
		 */
		public Gtk.License about_license_type { get; construct set; default = Gtk.License.UNKNOWN; }
		
		Gtk.AboutDialog? about_dlg;
		PreferencesWindow? preferences_dlg;
		DockController? controller;
		
		construct
		{
			flags = ApplicationFlags.FLAGS_NONE;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override void activate ()
		{
			//TODO Maybe let the dock hide/show for a visible feedback
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool local_command_line (ref unowned string[] args, out int exit_status)
		{
			exit_status = 0;
			
			// set program name
			prctl (15, exec_name);
			Environment.set_prgname (exec_name);
			
			Intl.bindtextdomain (exec_name, build_data_dir + "/locale");
			
			var context = new OptionContext (null);
			context.add_main_entries (options, exec_name);
			context.add_group (Gtk.get_option_group (false));
			
			try {
				unowned string[] args2 = args;
				context.parse (ref args2);
			} catch (OptionError e) {
				printerr ("%s\n", e.message);
				exit_status = 1;
				return true;
			}
			
			if (VERSION) {
				print ("%s\n", build_version);
				return true;
			}
			
			if (VERBOSE)
				Logger.DisplayLevel = LogLevel.VERBOSE;
			else if (DEBUG)
				Logger.DisplayLevel = LogLevel.DEBUG;
			else
				Logger.DisplayLevel = LogLevel.WARN;
			
			dock_name = NAME;
			
			application_id = app_dbus + "." + dock_name;
			
			try {
				register ();
			} catch {
				exit_status = 1;
				return true;
			}
			
			if (get_is_registered () && PREFERENCES)
				activate_action ("preferences", null);
			
			return base.local_command_line (ref args, out exit_status);
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override void startup ()
		{
			// Make sure important properties are set
			assert (build_data_dir != null);
			assert (build_pkg_data_dir != null);
			assert (build_release_name != null);
			assert (build_version != null);
			assert (build_version_info != null);
			assert (program_name != null);
			assert (exec_name != null);
			assert (app_dbus != null);
			assert (dock_name != null);
			
			base.startup ();
			
			if (!Thread.supported ())
				critical ("Problem initializing thread support.");
			
			Logger.initialize (program_name);
			message ("%s version: %s", program_name, build_version);
			message ("Kernel version: %s", Posix.utsname ().release);
			message ("GLib version: %u.%u.%u", GLib.Version.major, GLib.Version.minor, GLib.Version.micro);
			message ("GTK+ version: %u.%u.%u", Gtk.get_major_version (), Gtk.get_minor_version () , Gtk.get_micro_version ());
#if HAVE_GTK_3_10
			message ("+ CSD support enabled");
#endif
#if HAVE_HIDPI
			message ("+ HiDPI support enabled");
#endif
			message ("Wnck version: %d.%d.%d", Wnck.Version.MAJOR_VERSION, Wnck.Version.MINOR_VERSION, Wnck.Version.MICRO_VERSION);
			message ("Cairo version: %s", Cairo.version_string ());
			message ("Pango version: %s", Pango.version_string ());
			
			Paths.initialize (exec_name, build_pkg_data_dir);
			WindowControl.initialize ();
			
			initialize ();
			create_controller ();
			create_actions ();
		}
		
		/**
		 * Additional initializations before the dock is created.
		 */
		protected virtual void initialize ()
		{
		}
		
		/**
		 * Creates the dock controller.
		 */
		protected virtual void create_controller ()
		{
			controller = new DockController (Paths.AppConfigFolder.get_child (dock_name));
			controller.initialize ();
			
			add_window (controller.window);
		}
		
		/**
		 * Creates the actions and adds them to this {@link GLib.Application}.
		 */
		protected virtual void create_actions ()
		{
			SimpleAction action;
			
			action = new SimpleAction ("help", null);
			action.activate.connect (() => {
				Services.System.open_uri (help_url);
			});
			add_action (action);
			
			action = new SimpleAction ("translate", null);
			action.activate.connect (() => {
				Services.System.open_uri (translate_url);
			});
			add_action (action);
			
			action = new SimpleAction ("preferences", null);
			action.activate.connect (() => {
				show_preferences ();
			});
			add_action (action);
			
			action = new SimpleAction ("about", null);
			action.activate.connect (() => {
				show_about ();
			});
			add_action (action);
			
			action = new SimpleAction ("quit", null);
			action.activate.connect (() => {
				quit ();
			});
			add_action (action);
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
		 * Displays the about dialog.
		 */
		void show_about ()
		{
			if (about_dlg != null) {
				about_dlg.show_all ();
				return;
			}
			
			about_dlg = new Gtk.AboutDialog ();
			about_dlg.window_position = Gtk.WindowPosition.CENTER;
			about_dlg.gravity = Gdk.Gravity.CENTER;
			about_dlg.set_transient_for (controller.window);
			
			about_dlg.set_program_name (exec_name);
			about_dlg.set_version (build_version + "\n" + build_version_info);
			about_dlg.set_logo_icon_name (app_icon);
			
			about_dlg.set_comments (program_name + ". " + build_release_name);
			about_dlg.set_copyright ("Copyright © %s %s Developers".printf (app_copyright, program_name));
			about_dlg.set_website (main_url);
			about_dlg.set_website_label ("Website");
			
			if (about_authors != null && about_authors.length > 0)
				about_dlg.set_authors (about_authors);
			if (about_documenters != null && about_documenters.length > 0)
				about_dlg.set_documenters (about_documenters);
			if (about_artists != null && about_artists.length > 0)
				about_dlg.set_artists (about_artists);
			if (about_translators != null && about_translators != "")
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
		
		/**
		 * Displays the preferences dialog.
		 */
		void show_preferences ()
			requires (controller != null)
		{
			if (preferences_dlg != null) {
				preferences_dlg.show ();
				return;
			}
			
			preferences_dlg = new PreferencesWindow (controller.prefs);
			preferences_dlg.set_transient_for (controller.window);
			
			preferences_dlg.destroy.connect (() => {
				preferences_dlg = null;
			});
			
			preferences_dlg.hide.connect (() => {
				preferences_dlg.destroy ();
				preferences_dlg = null;
			});
			
			preferences_dlg.show ();
		}
	}
}
