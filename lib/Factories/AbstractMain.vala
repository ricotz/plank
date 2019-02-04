//
//  Copyright (C) 2011-2012 Robert Dyer, Rico Tzschichholz
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
	 * The main class for all dock applications.  All docks should extend this class.
	 * In the constructor, the string fields should be initialized to customize the dock.
	 */
	public abstract class AbstractMain : Gtk.Application
	{
		/**
		 * The default command-line options for the dock.
		 */
		const OptionEntry[] options = {
			{ "debug", 'd', 0, OptionArg.NONE, null, "Enable debug logging", null },
			{ "verbose", 'v', 0, OptionArg.NONE, null, "Enable verbose logging", null },
			{ "name", 'n', 0, OptionArg.STRING, null, "The name of this dock. Defaults to \"dock1\".", null },
			{ "preferences", 0, 0, OptionArg.NONE, null, "Show preferences dialog of the just started or already running instance", null },
			{ "version", 'V', 0, OptionArg.NONE, null, "Show the application's version", null },
			{ null }
		};

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
		
		string dock_name = "";
		
		Gtk.AboutDialog? about_dlg;
		PreferencesWindow? preferences_dlg;
		DockController? primary_dock;
		Gee.ArrayList<DockController> docks;
		
		construct
		{
			flags = ApplicationFlags.HANDLES_COMMAND_LINE;
			docks = new Gee.ArrayList<DockController> ();
			
			// set program name
#if HAVE_SYS_PRCTL_H
			prctl (15, exec_name);
#else
			setproctitle (exec_name);
#endif
			Environment.set_prgname (exec_name);
			
			Intl.bindtextdomain (Build.GETTEXT_PACKAGE, Build.DATADIR + "/locale");
			Intl.bind_textdomain_codeset (Build.GETTEXT_PACKAGE, "UTF-8");
			
			add_main_option_entries (options);
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
		public override int handle_local_options (VariantDict options)
		{
			if (options.contains ("version")) {
				print ("%s\n", build_version);
				return 0;
			}
			
			Logger.initialize (program_name);
			
			if (options.contains ("verbose"))
				Logger.DisplayLevel = LogLevel.VERBOSE;
			else if (options.contains ("debug"))
				Logger.DisplayLevel = LogLevel.DEBUG;
			else
				Logger.DisplayLevel = LogLevel.WARN;
			
			if (options.lookup ("name", "&s", out dock_name)) {
				application_id = "%s.%s".printf (app_dbus, dock_name);
			} else {
				dock_name = "";
				application_id = app_dbus;
			}
			
			return -1;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override int command_line (ApplicationCommandLine command_line)
		{
			var options = command_line.get_options_dict ();
			
			if (options.contains ("preferences"))
				activate_action ("preferences", null);
			
			return 0;
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
			
			base.startup ();
			
			if (!Thread.supported ())
				critical ("Problem initializing thread support.");
			
			message ("%s version: %s", program_name, build_version);
			message ("Kernel version: %s", Posix.utsname ().release);
			message ("GLib version: %u.%u.%u (%u.%u.%u)",
				GLib.Version.major, GLib.Version.minor, GLib.Version.micro,
				GLib.Version.MAJOR, GLib.Version.MINOR, GLib.Version.MICRO);
			message ("GTK+ version: %u.%u.%u (%i.%i.%i)",
				Gtk.get_major_version (), Gtk.get_minor_version () , Gtk.get_micro_version (),
				Gtk.MAJOR_VERSION, Gtk.MINOR_VERSION, Gtk.MICRO_VERSION);
			message ("Wnck version: %d.%d.%d", Wnck.Version.MAJOR_VERSION, Wnck.Version.MINOR_VERSION, Wnck.Version.MICRO_VERSION);
			message ("Cairo version: %s", Cairo.version_string ());
			message ("Pango version: %s", Pango.version_string ());
			message ("+ Cairo/Gtk+ HiDPI support enabled");
#if HAVE_DBUSMENU
			message ("+ Dynamic Quicklists support enabled");
#endif
#if HAVE_BARRIERS
			message ("+ XInput Barriers support enabled");
#endif
			if (Gtk.Widget.get_default_direction () == Gtk.TextDirection.RTL)
				message ("+ RTL support enabled");
			
			internal_quarks_initialize ();
			environment_initialize ();
			
			// Make sure we are not doing silly things like trying to run in a wayland-session!
			if (!environment_is_session_type (XdgSessionType.X11)) {
				critical ("Only X11 environments are supported.");
				quit ();
				return;
			}
			
			Paths.initialize (exec_name, build_pkg_data_dir);
			WindowControl.initialize ();
			DockletManager.get_default ().load_docklets ();
			
			initialize ();
			create_docks ();
			create_actions ();
		}
		
		/**
		 * Additional initializations before the dock is created.
		 */
		protected virtual void initialize ()
		{
		}
		
		/**
		 * Creates the docks.
		 */
		protected virtual void create_docks ()
		{
			if (dock_name != null && dock_name != "") {
				message ("Running with 1 dock ('%s')", dock_name);
				add_dock (create_dock (dock_name));
				return;
			}
			
			var settings = create_settings ("net.launchpad.plank");
			var enabled_docks = settings.get_strv ("enabled-docks");
			
			// Allow up to 8 docks
			if (enabled_docks.length <= 0) {
				enabled_docks = { "dock1" };
				settings.set_strv ("enabled-docks", enabled_docks);
			} else if (enabled_docks.length > 8) {
				enabled_docks = enabled_docks[0:8];
				settings.set_strv ("enabled-docks", enabled_docks);
			}
			
			message ("Running with %i docks ('%s')", enabled_docks.length, string.joinv ("', '", enabled_docks));
			foreach (unowned string dock_name in enabled_docks)
				add_dock (create_dock (dock_name));
		}
		
		DockController create_dock (string dock_name)
		{
			var config_folder = Paths.AppConfigFolder.get_child (dock_name);
			// Make sure our config-directory exists
			Paths.ensure_directory_exists (config_folder);
			
			var dock = new DockController (dock_name, config_folder);
			dock.initialize ();
			
			return dock;
		}
		
		void add_dock (DockController dock)
		{
			// Make sure to populate our primary-dock field
			if (primary_dock == null
				|| (primary_dock.prefs.PinnedOnly && !dock.prefs.PinnedOnly))
				primary_dock = dock;
			
			docks.add (dock);
			add_window (dock.window);
		}
		
		void remove_dock (DockController dock)
		{
			if (docks.size == 1)
				return;
			
			remove_window (dock.window);
			docks.remove (dock);
			
			if (primary_dock == dock)
				primary_dock = docks[0];
		}
		
		/**
		 * Creates the actions and adds them to this {@link GLib.Application}.
		 */
		protected virtual void create_actions ()
		{
			SimpleAction action;
			
			action = new SimpleAction ("help", null);
			action.activate.connect (() => {
				System.get_default ().open_uri (help_url);
			});
			add_action (action);
			
			action = new SimpleAction ("translate", null);
			action.activate.connect (() => {
				System.get_default ().open_uri (translate_url);
			});
			add_action (action);
			
			action = new SimpleAction ("preferences", null);
			action.activate.connect (() => {
				show_preferences (primary_dock);
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
			about_dlg.set_transient_for (primary_dock.window);
			
			about_dlg.set_program_name (exec_name);
			about_dlg.set_version ("%s\n%s".printf (build_version, build_version_info));
			about_dlg.set_logo_icon_name (app_icon);
			
			about_dlg.set_comments ("%s. %s".printf (program_name, build_release_name));
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
			else
				about_dlg.set_translator_credits (_("translator-credits"));
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
		 *
		 * @param controller the dock to show preferences for
		 */
		void show_preferences (DockController controller)
		{
			if (preferences_dlg != null) {
				preferences_dlg.controller = controller;
				preferences_dlg.set_transient_for (controller.window);
				preferences_dlg.show ();
				return;
			}
			
			preferences_dlg = new PreferencesWindow (controller);
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
