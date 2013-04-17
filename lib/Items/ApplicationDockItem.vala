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

using Gdk;
using Gee;
using Gtk;

using Plank.Drawing;
using Plank.Services;
using Plank.Services.Windows;

namespace Plank.Items
{
	/**
	 * A dock item for applications (with .desktop launchers).
	 */
	public class ApplicationDockItem : DockItem
	{
		// for FDO Desktop Actions
		// see http://standards.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html#extra-actions
		private const string DESKTOP_ACTION_KEY = "Actions";
		private const string DESKTOP_ACTION_GROUP_NAME = "Desktop Action %s";
		
		// for the Unity static quicklists
		// see https://wiki.edubuntu.org/Unity/LauncherAPI#Static_Quicklist_entries
		private const string UNITY_QUICKLISTS_KEY = "X-Ayatana-Desktop-Shortcuts";
		private const string UNITY_QUICKLISTS_SHORTCUT_GROUP_NAME = "%s Shortcut Group";
		private const string UNITY_QUICKLISTS_TARGET_KEY = "TargetEnvironment";
		private const string UNITY_QUICKLISTS_TARGET_VALUE = "Unity";
		
		private const string[] SUPPORTED_GETTEXT_DOMAINS_KEYS = {"X-Ubuntu-Gettext-Domain", "X-GNOME-Gettext-Domain"};
		
		/**
		 * Signal fired when the item's 'keep in dock' menu item is pressed.
		 */
		public signal void pin_launcher ();
		
		/**
		 * Signal fired when the application associated with this item closes.
		 */
		public signal void app_closed ();
		
		/**
		 * Signal fired when the application associated with this item opened a new window.
		 */
		public signal void app_window_added ();
		
		/**
		 * Signal fired when the application associated with this item closed a window.
		 */
		public signal void app_window_removed ();
		
#if HAVE_DBUSMENU
		/**
		 * The dock item's quicklist-dbusmenu.
		 */
		DbusmenuGtk.Client? Quicklist { get; set; default = null; }
#endif
		
		Bamf.Application? app = null;
		public Bamf.Application? App {
			internal get {
				// Nasty hack for libreoffice as workarround
				// closing libreoffice results in destroying its Bamf.Application object
				// and creating a new object which renders our reference useless
				// https://bugs.launchpad.net/bamf/+bug/1026426
				// https://bugs.launchpad.net/plank/+bug/1029555
				warn_if_fail (app == null || (app is Bamf.Application));
				if (app != null && !(app is Bamf.Application))
					app = null;
				
				return app;
			}
			internal construct set {
				if (app == value)
					return;
				
				if (app != null)
					app_signals_disconnect (app);
				
				app = value;
				
				if (app != null) {
					app_signals_connect (app);
					initialize_states ();
				} else {
					reset_application_status ();
				}
				
				unity_update_application_uri ();
			}
		}
		
		ArrayList<string> supported_mime_types = new ArrayList<string> ();
		
		ArrayList<string> actions = new ArrayList<string> ();
#if HAVE_GEE_0_8
		HashMap<string, string> actions_map = new HashMap<string, string> ();
#else
		HashMap<string, string> actions_map = new HashMap<string, string> (str_hash, str_equal);
#endif
		
		string? unity_application_uri = null;
		string? unity_dbusname = null;
		
		/**
		 * {@inheritDoc}
		 */
		public ApplicationDockItem.with_dockitem_file (GLib.File file)
		{
			GLib.Object (Prefs: new DockItemPreferences.with_file (file));
		}
		
		/**
		 * {@inheritDoc}
		 */
		public ApplicationDockItem.with_dockitem_filename (string filename)
		{
			GLib.Object (Prefs: new DockItemPreferences.with_filename (filename));
		}
		
		construct
		{
			Prefs.notify["Launcher"].connect (handle_launcher_changed);
			
			if (!ValidItem)
				return;
			
			load_from_launcher ();
		}
		
		~ApplicationDockItem ()
		{
			Prefs.notify["Launcher"].disconnect (handle_launcher_changed);
			
			App = null;
#if HAVE_DBUSMENU
			Quicklist = null;
#endif
			stop_monitor ();
		}
		
		void app_signals_connect (Bamf.Application app)
		{
			app.active_changed.connect (handle_active_changed);
			app.running_changed.connect (handle_running_changed);
			app.urgent_changed.connect (handle_urgent_changed);
			app.user_visible_changed.connect (handle_user_visible_changed);
			app.window_added.connect (handle_window_added);
			app.window_removed.connect (handle_window_removed);
			app.closed.connect (handle_closed);
		}
		
		void app_signals_disconnect (Bamf.Application app)
		{
			app.active_changed.disconnect (handle_active_changed);
			app.running_changed.disconnect (handle_running_changed);
			app.urgent_changed.disconnect (handle_urgent_changed);
			app.user_visible_changed.disconnect (handle_user_visible_changed);
			app.window_added.disconnect (handle_window_added);
			app.window_removed.disconnect (handle_window_removed);
			app.closed.disconnect (handle_closed);
		}
		
		void initialize_states ()
			requires (App != null)
		{
			handle_active_changed (App.is_active ());
			handle_urgent_changed (App.is_urgent ());
			
			update_indicator (WindowControl.get_num_windows (App));
		}
		
		public bool is_running ()
		{
			return (App != null && App.is_running ());
		}
		
		public bool is_window ()
		{
			return (App != null && (App.get_desktop_file () == null || App.get_desktop_file () == ""));
		}
		
		void handle_launcher_changed ()
		{
			if (this is TransientDockItem)
				return;
			
			App = Matcher.get_default ().app_for_uri (Prefs.Launcher);
			
			load_from_launcher ();
			
			launcher_changed ();
		}
		
		void handle_user_visible_changed (bool user_visible)
		{
			if (user_visible)
				return;
			
			if (this is TransientDockItem)
				App = null;
			
			app_closed ();
		}
		
		void handle_closed ()
		{
			if (this is TransientDockItem)
				App = null;
			
			reset_application_status ();
			
			app_closed ();
		}
		
		void handle_active_changed (bool is_active)
		{
			var was_active = (State & ItemState.ACTIVE) == ItemState.ACTIVE;
			
			if (is_active && !was_active) {
				LastActive = new DateTime.now_utc ();
				State |= ItemState.ACTIVE;
			} else if (!is_active && was_active) {
				LastActive = new DateTime.now_utc ();
				State &= ~ItemState.ACTIVE;
			}
		}
		
		void handle_running_changed (bool is_running)
		{
			if (is_running)
				return;
			
			reset_application_status ();
		}
		
		public void set_urgent (bool is_urgent)
		{
			handle_urgent_changed (is_urgent);
		}
		
		void handle_urgent_changed (bool is_urgent)
		{
			var was_urgent = (State & ItemState.URGENT) == ItemState.URGENT;
			
			if (is_urgent && !was_urgent) {
				LastUrgent = new DateTime.now_utc ();
				State |= ItemState.URGENT;
			} else if (!is_urgent && was_urgent) {
				State &= ~ItemState.URGENT;
			}
		}
		
		void handle_window_added (Bamf.View? child)
		{
			update_indicator (WindowControl.get_num_windows (App));
			
			app_window_added ();
		}
		
		void handle_window_removed (Bamf.View? child)
		{
			update_indicator (WindowControl.get_num_windows (App));
			
			app_window_removed ();
		}
		
		void update_indicator (uint window_count)
		{
			if (window_count == 0) {
				if (Indicator != IndicatorState.NONE)
					Indicator = IndicatorState.NONE;
			} else if (window_count == 1) {
				if (Indicator != IndicatorState.SINGLE)
					Indicator = IndicatorState.SINGLE;
			} else {
				if (Indicator != IndicatorState.SINGLE_PLUS)
					Indicator = IndicatorState.SINGLE_PLUS;
			}
		}
		
		inline void reset_application_status ()
		{
			handle_urgent_changed (false);
			handle_active_changed (false);
			update_indicator (0);
		}
		
		void launch ()
		{
			Services.System.launch (File.new_for_uri (Prefs.Launcher));
		}
		
		/**
		 * {@inheritDoc}
		 */
		protected override ClickAnimation on_clicked (PopupButton button, ModifierType mod)
		{
			if (!is_window ())
				if (button == PopupButton.MIDDLE
					|| (button == PopupButton.LEFT && (App == null || WindowControl.get_num_windows (App) == 0
					|| (mod & ModifierType.CONTROL_MASK) == ModifierType.CONTROL_MASK))) {
					launch ();
					return ClickAnimation.BOUNCE;
				}
			
			if (button == PopupButton.LEFT && App != null && WindowControl.get_num_windows (App) > 0) {
				WindowControl.smart_focus (App);
				return ClickAnimation.DARKEN;
			}
			
			return ClickAnimation.NONE;
		}
		
		/**
		 * {@inheritDoc}
		 */
		protected override void on_scrolled (ScrollDirection direction, ModifierType mod)
		{
			if (App == null || WindowControl.get_num_windows (App) == 0
				|| (new DateTime.now_utc ().difference (LastScrolled) < WindowControl.VIEWPORT_CHANGE_DELAY * 1000))
				return;
			
			LastScrolled = new DateTime.now_utc ();
			
			if (direction == ScrollDirection.UP || direction == ScrollDirection.LEFT)
				WindowControl.focus_previous (App);
			else
				WindowControl.focus_next (App);
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override ArrayList<Gtk.MenuItem> get_menu_items ()
		{
			var items = new ArrayList<Gtk.MenuItem> ();
			
			GLib.List<unowned Bamf.View>? windows = null;
			if (App != null)
				windows = App.get_windows ();
			
			if (!is_window ()) {
				var item = new CheckMenuItem.with_mnemonic (_("_Keep in Dock"));
				item.active = !(this is TransientDockItem);
				item.activate.connect (() => pin_launcher ());
				items.add (item);
			}
			
			if (is_running () && windows != null && windows.length () > 0) {
				Gtk.MenuItem item;
				
				if (WindowControl.has_maximized_window (App)) {
					item = create_menu_item (_("Unma_ximize"), "view-fullscreen");
					item.activate.connect (() => WindowControl.unmaximize (App));
					items.add (item);
				} else {
					item = create_menu_item (_("Ma_ximize"), "view-fullscreen");
					item.activate.connect (() => WindowControl.maximize (App));
					items.add (item);
				}
				
				item = create_menu_item (_("_Close All"), "window-close-symbolic;;window-close");
				item.activate.connect (() => WindowControl.close_all (App));
				items.add (item);
			}
			
#if HAVE_DBUSMENU
			if (Quicklist != null) {
				items.add (new SeparatorMenuItem ());
				
				var dm_root = Quicklist.get_root ();
				if (dm_root != null) {
					Logger.verbose ("%i quicklist menuitems for %s", dm_root.get_children ().length (), Text);
					foreach (var menuitem in dm_root.get_children ())
						items.add (Quicklist.menuitem_get (menuitem));
				}
			}
#endif
			
			if (!is_window () && actions.size > 0) {
				items.add (new SeparatorMenuItem ());
				
				foreach (var s in actions) {
					var values = actions_map.get (s).split (";;");
					
					Gtk.MenuItem item;
					if (values[1] != null && values[1] != "") {
						item = new Gtk.ImageMenuItem.with_mnemonic (s);
						(item as Gtk.ImageMenuItem).set_image (new Gtk.Image.from_icon_name (values[1], IconSize.MENU));
					 } else {
						item = new Gtk.MenuItem.with_mnemonic (s);
					 }
						
					item.activate.connect (() => {
						try {
							AppInfo.create_from_commandline (values[0], null, AppInfoCreateFlags.NONE).launch (null, null);
						} catch { }
					});
					items.add (item);
				}
			}
			
			if (is_running () && windows != null && windows.length () > 0) {
				items.add (new SeparatorMenuItem ());
				
				int width, height;
				icon_size_lookup (IconSize.MENU, out width, out height);
				
				foreach (var view in windows) {
					unowned Bamf.Window? window = (view as Bamf.Window);
					if (window == null)
						continue;
					
					var pbuf = WindowControl.get_window_icon (window);
					if (pbuf == null)
						pbuf = DrawingService.load_icon (Icon, width, height);
					else
						pbuf = DrawingService.ar_scale (pbuf, width, height);
					
					var window_item = new ImageMenuItem.with_mnemonic (window.get_name ());
					window_item.set_image (new Gtk.Image.from_pixbuf (pbuf));
					window_item.activate.connect (() => WindowControl.focus_window (window));
					items.add (window_item);
				}
			}
			
			return items;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool can_accept_drop (ArrayList<string> uris)
		{
			if (uris == null || is_window ())
				return false;
			
			// if they dont specify mimes but have '%F' etc in their Exec, assume any file allowed
			// FIXME also check if the Exec key has %F/%f/%U/%u in it
			if (supported_mime_types.size == 0 /* && .. */)
				return true;
			
			try {
				foreach (var uri in uris) {
					var info = File.new_for_uri (uri).query_info (FileAttribute.STANDARD_CONTENT_TYPE, FileQueryInfoFlags.NONE);
					var uri_content_type = info.get_content_type ();
					foreach (var content_type in supported_mime_types)
						if (ContentType.is_a (uri_content_type, content_type) || ContentType.equals (uri_content_type, content_type))
							return true;
				}
			} catch {}
			
			return false;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool accept_drop (ArrayList<string> uris)
		{
			var files = new ArrayList<File> ();
			foreach (var uri in uris)
				files.add (File.new_for_uri (uri));
			
			Services.System.launch_with_files (File.new_for_uri (Prefs.Launcher), files.to_array ());
			
			return true;
		}
		
		/**
		 * Parses the associated launcher and sets the icon and text from it.
		 */
		protected void load_from_launcher ()
		{
			unity_update_application_uri ();
			
			var launcher = Prefs.Launcher;
			if (launcher == null || launcher == "")
				return;
			
			stop_monitor ();
			
			string icon, text;
			parse_launcher (launcher, out icon, out text, actions, actions_map, supported_mime_types);
			Icon = icon;
			ForcePixbuf = null;
			Text = text;
			
			start_monitor ();
		}
		
		/**
		 * Parses a launcher to get the text, icon and actions.
		 *
		 * @param launcher the launcher file (.desktop file) to parse
		 * @param icon the icon key from the launcher
		 * @param text the text key from the launcher
		 * @param actions a list of all actions by name
		 * @param actions_map a map of actions from name to exec;;icon
		 * @param mimes a list of all supported mime types
		 */
		public static void parse_launcher (string launcher, out string icon, out string text, ArrayList<string>? actions = null, Map<string, string>? actions_map = null, ArrayList<string>? mimes = null)
		{
			icon = "";
			text = "";
			
			if (launcher == null || launcher == "")
				return;
			
			try {
				var file = new KeyFile ();
				file.load_from_file (Filename.from_uri (launcher), 0);
				
				icon = file.get_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_ICON);
				text = file.get_locale_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_NAME);
				
				if (mimes != null && file.has_key (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_MIME_TYPE)) {
					var mimestrings = file.get_string_list (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_MIME_TYPE);
					foreach (var mime in mimestrings)
						mimes.add (ContentType.from_mime_type (mime));
				}
				
				string? textdomain = null;
				foreach (var domain_key in SUPPORTED_GETTEXT_DOMAINS_KEYS)
					if (file.has_key (KeyFileDesktop.GROUP, domain_key)) {
						textdomain = file.get_string (KeyFileDesktop.GROUP, domain_key);
						break;
					}
				
				// get FDO Desktop Actions
				// see http://standards.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html#extra-actions
				// get the Unity static quicklists
				// see https://wiki.edubuntu.org/Unity/LauncherAPI#Static Quicklist entries
				if (actions != null && actions_map != null) {
					actions.clear ();
					actions_map.clear ();
					
					string[] keys = {DESKTOP_ACTION_KEY, UNITY_QUICKLISTS_KEY};
					
					foreach (var key in keys) {
						if (!file.has_key (KeyFileDesktop.GROUP, key))
							continue;
						
						foreach (var action in file.get_string_list (KeyFileDesktop.GROUP, key)) {
							var group = DESKTOP_ACTION_GROUP_NAME.printf (action);
							if (!file.has_group (group)) {
								group = UNITY_QUICKLISTS_SHORTCUT_GROUP_NAME.printf (action);
								if (!file.has_group (group))
									continue;
							}
							
							// check for TargetEnvironment
							if (file.has_key (group, UNITY_QUICKLISTS_TARGET_KEY)) {
								var target = file.get_string (group, UNITY_QUICKLISTS_TARGET_KEY);
								if (target != UNITY_QUICKLISTS_TARGET_VALUE && target != "Plank")
									continue;
							}
							
							// check for NotShowIn
							if (file.has_key (group, KeyFileDesktop.KEY_NOT_SHOW_IN)) {
								var found = false;
								
								foreach (var s in file.get_string_list (group, KeyFileDesktop.KEY_NOT_SHOW_IN))
									if (s == "Plank") {
										found = true;
										break;
									}
								
								if (found)
									continue;
							}
							
							// check for OnlyShowIn
							if (file.has_key (group, KeyFileDesktop.KEY_ONLY_SHOW_IN)) {
								var found = false;
								
								foreach (var s in file.get_string_list (group, KeyFileDesktop.KEY_ONLY_SHOW_IN))
									if (s == UNITY_QUICKLISTS_TARGET_VALUE || s == "Plank") {
										found = true;
										break;
									}
								
								if (!found)
									continue;
							}
							
							// check for Icon
							var action_icon = "";
							if (file.has_key (group, KeyFileDesktop.KEY_ICON))
								action_icon = file.get_string (group, KeyFileDesktop.KEY_ICON);
							
							var action_name = file.get_locale_string (group, KeyFileDesktop.KEY_NAME);
							var action_exec = file.get_string (group, KeyFileDesktop.KEY_EXEC);
							
							// apply given gettext-domain if available
							if (textdomain != null)
								action_name = GLib.dgettext (textdomain, action_name).dup ();
							
							actions.add (action_name);
							actions_map.set (action_name, "%s;;%s".printf (action_exec, action_icon));
						}
					}
				}
			} catch { }
		}
		
		FileMonitor? monitor = null;
		
		void start_monitor ()
		{
			if (monitor != null)
				return;
			
			try {
				monitor = File.new_for_uri (Prefs.Launcher).monitor (0);
				monitor.changed.connect (monitor_changed);
			} catch {
				warning ("Unable to watch the launcher file '%s'", Prefs.Launcher);
			}
		}
		
		void monitor_changed (File f, File? other, FileMonitorEvent event)
		{
			if ((event & FileMonitorEvent.CHANGES_DONE_HINT) != FileMonitorEvent.CHANGES_DONE_HINT
				&& (event & FileMonitorEvent.DELETED) != FileMonitorEvent.DELETED)
				return;
			
			// If the desktop-file for the corresponding application was deleted
			// request removal of this item from dock
			if (!f.query_exists ()) {
				debug ("Launcher file '%s' deleted, removing item '%s'", Prefs.Launcher, Text);
				deleted ();
				return;
			}
			
			debug ("Launcher file '%s' changed, reloading", Prefs.Launcher);
			load_from_launcher ();
		}
		
		void stop_monitor ()
		{
			if (monitor == null)
				return;
			
			monitor.changed.disconnect (monitor_changed);
			monitor.cancel ();
			monitor = null;
		}
		
		void unity_update_application_uri ()
		{
			unity_application_uri = null;
			
			var desktop_file = (App != null ? App.get_desktop_file () : Launcher);
			if (desktop_file == null || desktop_file == "")
				return;
			
			var p = desktop_file.split ("/");
			if (p.length == 0)
				return;
			
			unity_application_uri = "application://" + p[p.length - 1];
		}
		
		/**
		 * Get libunity application URI
		 *
		 * @return the libunity application uri of this item, or NULL
		 */
		public string? get_unity_application_uri ()
		{
			return unity_application_uri;
		}
		
		/**
		 * Get current libunity dbusname
		 *
		 * @return the dbusname which provides the LauncherEntry interface, or NULL
		 */
		public string? get_unity_dbusname ()
		{
			return unity_dbusname;
		}
		
		/**
		 * Update this item's remote libunity value based on the given data
		 *
		 * @param sender_name the corressponding dbusname
		 * @param prop_iter the data in a standardize format from libunity
		 */
		public void unity_update (string sender_name, VariantIter prop_iter)
		{
			unity_dbusname = sender_name;
			
			string prop_key;
			Variant prop_value;
			
			while (prop_iter.next ("{sv}", out prop_key, out prop_value)) {
				if (prop_key == "count")
					Count = prop_value.get_int64 ();
				else if (prop_key == "count-visible")
					CountVisible = prop_value.get_boolean ();
				else if (prop_key == "progress")
					Progress = prop_value.get_double ();
				else if (prop_key == "progress-visible")
					ProgressVisible = prop_value.get_boolean ();
				else if (prop_key == "urgent")
					set_urgent (prop_value.get_boolean ());
#if HAVE_DBUSMENU
				else if (prop_key == "quicklist") {
					/* The value is the object path of the dbusmenu */
					var dbus_path = prop_value.get_string ();
					// Make sure we don't update our Quicklist instance if isn't necessary
					if (Quicklist == null || Quicklist.dbus_object != dbus_path)
						if (dbus_path != "") {
							Logger.verbose ("Loading dynamic quicklists for %s (%s)", Text, sender_name);
							Quicklist = new DbusmenuGtk.Client (sender_name, dbus_path);
						} else {
							Quicklist = null;
						}
				}
#endif
			}
		}
		
		/**
		 * Reset this item's remote libunity values
		 */
		public void unity_reset ()
		{
			unity_dbusname = null;
			
			Count = 0;
			CountVisible = false;
			Progress = 0.0;
			ProgressVisible = false;
			set_urgent (false);
#if HAVE_DBUSMENU
			Quicklist = null;
#endif
		}

	}
}
