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
					if (app.is_running () && app.is_user_visible ())
						app_window_added ();
				} else {
					reset_application_status ();
				}
				
				unity_update_application_uri ();
			}
		}
		
		Gee.ArrayList<string> supported_mime_types;
		Gee.ArrayList<string> actions;
		Gee.HashMap<string, string> actions_map;
		
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
			supported_mime_types = new Gee.ArrayList<string> ();
			actions = new Gee.ArrayList<string> ();
			actions_map = new Gee.HashMap<string, string> ();
			
			load_from_launcher ();
		}
		
		~ApplicationDockItem ()
		{
			supported_mime_types = null;
			actions = null;
			actions_map = null;
			
			App = null;
#if HAVE_DBUSMENU
			Quicklist = null;
#endif
		}
		
		void app_signals_connect (Bamf.Application app)
		{
			app.active_changed.connect_after (handle_active_changed);
			app.name_changed.connect_after (handle_name_changed);
			app.running_changed.connect_after (handle_running_changed);
			app.urgent_changed.connect_after (handle_urgent_changed);
			app.user_visible_changed.connect_after (handle_user_visible_changed);
			app.child_added.connect_after (handle_window_added);
			app.child_removed.connect_after (handle_window_removed);
			app.closed.connect_after (handle_closed);
		}
		
		void app_signals_disconnect (Bamf.Application app)
		{
			app.active_changed.disconnect (handle_active_changed);
			app.name_changed.disconnect (handle_name_changed);
			app.running_changed.disconnect (handle_running_changed);
			app.urgent_changed.disconnect (handle_urgent_changed);
			app.user_visible_changed.disconnect (handle_user_visible_changed);
			app.child_added.disconnect (handle_window_added);
			app.child_removed.disconnect (handle_window_removed);
			app.closed.disconnect (handle_closed);
		}
		
		void initialize_states ()
			requires (App != null)
		{
			handle_active_changed (App.is_active ());
			handle_urgent_changed (App.is_urgent ());
			
			update_indicator ();
		}
		
		public bool is_running ()
		{
			return (App != null && App.is_running ());
		}
		
		public bool is_window ()
		{
			if (App == null)
				return false;
			
			unowned string? desktop_file = App.get_desktop_file ();
			return (desktop_file == null || desktop_file == "");
		}
		
		void handle_user_visible_changed (bool user_visible)
		{
			if (user_visible)
				app_window_added ();
			else
				app_window_removed ();
		}
		
		void handle_closed ()
		{
			App = null;
			
			app_closed ();
		}
		
		void handle_active_changed (bool is_active)
		{
			var was_active = (State & ItemState.ACTIVE) == ItemState.ACTIVE;
			
			if (is_active && !was_active) {
				LastActive = GLib.get_monotonic_time ();
				State |= ItemState.ACTIVE;
			} else if (!is_active && was_active) {
				LastActive = GLib.get_monotonic_time ();
				State &= ~ItemState.ACTIVE;
			}
		}
		
		void handle_name_changed (string old_name, string new_name)
		{
			// do nothing if name and icon are coming from the desktop-file
			if (this is TransientDockItem)
				Text = new_name;
		}
		
		void handle_running_changed (bool is_running)
		{
			if (!is_running) {
				reset_application_status ();
				return;
			}
			
			update_indicator ();
			
			app_window_added ();
		}
		
		public void set_urgent (bool is_urgent)
		{
			handle_urgent_changed (is_urgent);
		}
		
		void handle_urgent_changed (bool is_urgent)
		{
			var was_urgent = (State & ItemState.URGENT) == ItemState.URGENT;
			
			if (is_urgent && !was_urgent) {
				LastUrgent = GLib.get_monotonic_time ();
				State |= ItemState.URGENT;
			} else if (!is_urgent && was_urgent) {
				State &= ~ItemState.URGENT;
			}
		}
		
		void handle_window_added (Bamf.View? child)
		{
			if (!(child is Bamf.Window))
				return;
			
			update_indicator ();
			
			app_window_added ();
		}
		
		void handle_window_removed (Bamf.View? child)
		{
			if (!(child is Bamf.Window))
				return;
			
			update_indicator ();
			
			app_window_removed ();
		}
		
		void update_indicator ()
		{
			//FIXME Do not be silly if the application is running
			//  we must indicate it, same goes for the opposite.
			
			var is_running = is_running ();
			
			if (!is_running) {
				if (Indicator != IndicatorState.NONE)
					Indicator = IndicatorState.NONE;
				return;
			}
			
			var window_count = App.get_windows ().length ();
			
			if (window_count <= 1) {
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
			
			if (Indicator != IndicatorState.NONE)
				Indicator = IndicatorState.NONE;
		}
		
		void launch ()
		{
			System.get_default ().launch (File.new_for_uri (Prefs.Launcher));
		}
		
		/**
		 * {@inheritDoc}
		 */
		protected override AnimationType on_clicked (PopupButton button, Gdk.ModifierType mod, uint32 event_time)
		{
			if (!is_window ())
				if (button == PopupButton.MIDDLE
					|| (button == PopupButton.LEFT && (App == null || App.get_windows ().length () == 0
					|| (mod & Gdk.ModifierType.CONTROL_MASK) == Gdk.ModifierType.CONTROL_MASK))) {
					launch ();
					return AnimationType.BOUNCE;
				}
			
			if (button == PopupButton.LEFT && App != null && App.get_windows ().length () > 0) {
				WindowControl.smart_focus (App, event_time);
				return AnimationType.DARKEN;
			}
			
			return AnimationType.NONE;
		}
		
		/**
		 * {@inheritDoc}
		 */
		protected override AnimationType on_scrolled (Gdk.ScrollDirection direction, Gdk.ModifierType mod, uint32 event_time)
		{
			if (App == null || App.get_windows ().length () == 0)
				return AnimationType.NONE;
			
			if (GLib.get_monotonic_time () - LastScrolled < ITEM_SCROLL_DURATION * 1000)
				return AnimationType.DARKEN;
			
			LastScrolled = GLib.get_monotonic_time ();
			
			if (direction == Gdk.ScrollDirection.UP || direction == Gdk.ScrollDirection.LEFT)
				WindowControl.focus_previous (App, event_time);
			else
				WindowControl.focus_next (App, event_time);
			
			return AnimationType.DARKEN;
		}
		
		string shorten_window_name (string window_name)
		{
			const string[] WINDOW_NAME_PATTERN = { "%s - (.+)", "(.+) - %s", "%s – (.+)", "(.+) – %s", "%s: (.+)" };
			const string[] APP_NAME_DELIMITER = { " ", "-", "–" };
			
			string[] app_strings = null;
			foreach (unowned string d in APP_NAME_DELIMITER) {
				app_strings = string_split_combine (Text, d);
				if (app_strings.length > 1)
					break;
			}
			
			MatchInfo? m;
			foreach (unowned string p in WINDOW_NAME_PATTERN) {
				foreach (unowned string s in app_strings) {
					if (s.char_count () < 3)
						continue;
					
					try {
						var r = new Regex ("^%s$".printf (p.printf (s)),
							RegexCompileFlags.CASELESS | RegexCompileFlags.ANCHORED | RegexCompileFlags.DOLLAR_ENDONLY,
							RegexMatchFlags.ANCHORED | RegexMatchFlags.NOTEMPTY);
						r.match (window_name, RegexMatchFlags.ANCHORED | RegexMatchFlags.NOTEMPTY, out m);
						if (m.matches ())
							return m.fetch (1);
					} catch (RegexError e) {
						warning (e.message);
					}
				}
			}
			
			return window_name;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override Gee.ArrayList<Gtk.MenuItem> get_menu_items ()
		{
			var items = new Gee.ArrayList<Gtk.MenuItem> ();
			
			GLib.List<unowned Bamf.View>? windows = null;
			if (App != null)
				windows = App.get_windows ();
			
			var window_count = 0U;
			if (windows != null)
				window_count = windows.length ();
			
			unowned DefaultApplicationDockItemProvider? default_provider = (Container as DefaultApplicationDockItemProvider);
			if (default_provider != null
				&& !default_provider.Prefs.LockItems
				&& !is_window ()) {
				var item = new Gtk.CheckMenuItem.with_mnemonic (_("_Keep in Dock"));
				item.active = !(this is TransientDockItem);
				item.activate.connect (() => pin_launcher ());
				items.add (item);
			}
			
			var event_time = Gtk.get_current_event_time ();
			if (is_running () && window_count > 0) {
				var item = create_menu_item ((window_count > 1 ? _("_Close All") : _("_Close")), "window-close-symbolic;;window-close");
				item.activate.connect (() => WindowControl.close_all (App, event_time));
				items.add (item);
			}
			
#if HAVE_DBUSMENU
			if (Quicklist != null) {
				if (items.size > 0)
					items.add (new Gtk.SeparatorMenuItem ());
				
				var dm_root = Quicklist.get_root ();
				if (dm_root != null) {
					Logger.verbose ("%i quicklist menuitems for %s", dm_root.get_children ().length (), Text);
					foreach (var menuitem in dm_root.get_children ())
						items.add (Quicklist.menuitem_get (menuitem));
				}
			}
#endif
			
			if (!is_window () && actions.size > 0) {
				if (items.size > 0)
					items.add (new Gtk.SeparatorMenuItem ());
				
				foreach (var s in actions) {
					var values = actions_map.get (s).split (";;");
					
					var item = create_menu_item (s, values[1], true);
					item.activate.connect (() => {
						try {
							AppInfo.create_from_commandline (values[0], null, AppInfoCreateFlags.NONE).launch (null, null);
						} catch { }
					});
					items.add (item);
				}
			}
			
			if (is_running () && window_count > 1) {
				if (items.size > 0)
					items.add (new Gtk.SeparatorMenuItem ());
				
				foreach (var view in windows) {
					unowned Bamf.Window? window = (view as Bamf.Window);
					if (window == null || window.get_transient () != null)
						continue;
					
					Gtk.MenuItem window_item;
					var pbuf = WindowControl.get_window_icon (window);
					var window_name = window.get_name ();
					window_name = shorten_window_name (window_name);
					
					if (pbuf != null)
						window_item = create_literal_menu_item_with_pixbuf (window_name, pbuf);
					else 
						window_item = create_literal_menu_item (window_name, Icon);
					
					if (window.is_active ())
						window_item.set_sensitive (false);
					else
						window_item.activate.connect (() => WindowControl.focus_window (window, event_time));
					
					items.add (window_item);
				}
			}
			
			return items;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override string get_drop_text ()
		{
			return _("Drop to open with %s").printf (Text);
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool can_accept_drop (Gee.ArrayList<string> uris)
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
					unowned string uri_content_type = info.get_content_type ();
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
		public override bool accept_drop (Gee.ArrayList<string> uris)
		{
			var files = new Gee.ArrayList<File> ();
			foreach (var uri in uris)
				files.add (File.new_for_uri (uri));
			
			System.get_default ().launch_with_files (File.new_for_uri (Prefs.Launcher), files.to_array ());
			
			return true;
		}
		
		/**
		 * {@inheritDoc}
		 */
		protected override void load_from_launcher ()
		{
			if (Prefs.Launcher == "")
				return;
			
			unity_update_application_uri ();
			
			string icon, text;
			parse_launcher (Prefs.Launcher, out icon, out text, actions, actions_map, supported_mime_types);
			Icon = icon;
			ForcePixbuf = null;
			Text = text;
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
		public static void parse_launcher (string launcher, out string icon, out string text, Gee.ArrayList<string>? actions = null, Gee.Map<string, string>? actions_map = null, Gee.ArrayList<string>? mimes = null)
		{
			icon = "";
			text = "";
			
			if (launcher == null || launcher == "")
				return;
			
			KeyFile file;
			
			try {
				file = new KeyFile ();
				file.load_from_file (Filename.from_uri (launcher), 0);
			} catch (Error e) {
				critical ("%s: %s", launcher, e.message);
				return;
			}
			
			try {
				text = file.get_locale_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_NAME);
				
				if (file.has_key (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_ICON))
					icon = file.get_locale_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_ICON);
				
				var type = file.get_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_TYPE);
				switch (type) {
				default:
				case KeyFileDesktop.TYPE_APPLICATION:
					break;
				case KeyFileDesktop.TYPE_DIRECTORY:
					if (icon == "")
						icon = "inode-directory";
					return;
				case KeyFileDesktop.TYPE_LINK:
					if (icon == "")
						icon = "document";
					return;	
				}
			} catch (KeyFileError e) {
				critical ("%s: %s", launcher, e.message);
				return;
			}
			
			try {
				if (mimes != null && file.has_key (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_MIME_TYPE)) {
					var mimestrings = file.get_string_list (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_MIME_TYPE);
					foreach (unowned string mime in mimestrings)
						mimes.add (ContentType.from_mime_type (mime));
				}
				
				string? textdomain = null;
				foreach (unowned string domain_key in SUPPORTED_GETTEXT_DOMAINS_KEYS)
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
					
					foreach (unowned string key in keys) {
						if (!file.has_key (KeyFileDesktop.GROUP, key))
							continue;
						
						foreach (unowned string action in file.get_string_list (KeyFileDesktop.GROUP, key)) {
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
								
								foreach (unowned string s in file.get_string_list (group, KeyFileDesktop.KEY_NOT_SHOW_IN))
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
								
								foreach (unowned string s in file.get_string_list (group, KeyFileDesktop.KEY_ONLY_SHOW_IN))
									if (s == UNITY_QUICKLISTS_TARGET_VALUE || s == "Plank") {
										found = true;
										break;
									}
								
								if (!found)
									continue;
							}
							
							var action_name = file.get_locale_string (group, KeyFileDesktop.KEY_NAME);
							
							var action_icon = "";
							if (file.has_key (group, KeyFileDesktop.KEY_ICON))
								action_icon = file.get_locale_string (group, KeyFileDesktop.KEY_ICON);
							
							var action_exec = "";
							if (file.has_key (group, KeyFileDesktop.KEY_EXEC))
								action_exec = file.get_string (group, KeyFileDesktop.KEY_EXEC);
							
							// apply given gettext-domain if available
							if (textdomain != null)
								action_name = GLib.dgettext (textdomain, action_name).dup ();
							
							actions.add (action_name);
							actions_map.set (action_name, "%s;;%s".printf (action_exec, action_icon));
						}
					}
				}
			} catch (KeyFileError e) {
				critical ("%s: %s", launcher, e.message);
				return;
			}
		}
		
		
		void unity_update_application_uri ()
		{
			unity_application_uri = null;
			
			unowned string? desktop_file = (App != null ? App.get_desktop_file () : Launcher);
			if (desktop_file == null || desktop_file == "")
				return;
			
			var p = desktop_file.split ("/");
			if (p.length == 0)
				return;
			
			unity_application_uri = "application://%s".printf (p[p.length - 1]);
		}
		
		/**
		 * Get libunity application URI
		 *
		 * @return the libunity application uri of this item, or NULL
		 */
		public unowned string? get_unity_application_uri ()
		{
			return unity_application_uri;
		}
		
		/**
		 * Get current libunity dbusname
		 *
		 * @return the dbusname which provides the LauncherEntry interface, or NULL
		 */
		public unowned string? get_unity_dbusname ()
		{
			return unity_dbusname;
		}
		
		/**
		 * Whether this item provides information worth showing
		 */
		public bool has_unity_info ()
		{
			return (ProgressVisible || CountVisible);
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
				if (prop_key == "count") {
					var val = prop_value.get_int64 ();
					if (Count != val)
						Count = val;
				} else if (prop_key == "count-visible") {
					var val = prop_value.get_boolean ();
					if (CountVisible != val)
						CountVisible = val;
				} else if (prop_key == "progress") {
					var val = nround (prop_value.get_double (), 3U);
					if (Progress != val)
						Progress = val;
				} else if (prop_key == "progress-visible") {
					var val = prop_value.get_boolean ();
					if (ProgressVisible != val)
						ProgressVisible = val;
				} else if (prop_key == "urgent") {
					set_urgent (prop_value.get_boolean ());
#if HAVE_DBUSMENU
				} else if (prop_key == "quicklist") {
					/* The value is the object path of the dbusmenu */
					unowned string dbus_path = prop_value.get_string ();
					// Make sure we don't update our Quicklist instance if isn't necessary
					if (Quicklist == null || Quicklist.dbus_object != dbus_path)
						if (dbus_path != "") {
							Logger.verbose ("Loading dynamic quicklists for %s (%s)", Text, sender_name);
							Quicklist = new DbusmenuGtk.Client (sender_name, dbus_path);
						} else {
							Quicklist = null;
						}
#endif
				}
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
