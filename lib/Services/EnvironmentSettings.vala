//
//  Copyright (C) 2016 Rico Tzschichholz
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
	 * Summons settings of the currently running destop-session to use for improving
	 * integration like appearance and behaviour
	 */
	internal class EnvironmentSettings : Object
	{
		static EnvironmentSettings? instance = null;
		
		public static unowned EnvironmentSettings? get_instance ()
		{
			if (instance == null)
				instance = new EnvironmentSettings ();
			
			return instance;
		}
		
		/**
		 * Whether the environment allows an application to draw the user's attention
		 * e.g. "Do not disturb"-mode is disabled or not
		 */
		[Description(nick = "show-notifications")]
		public bool ShowNotifications { get; private set; default = true; }
		
		DesktopNofications? notifications;
		
		EnvironmentSettings ()
		{
			Object ();
		}
		
		construct
		{
			switch (get_xdg_session_desktop ()) {
			case XdgSessionDesktop.GNOME:
				notifications = GnomeDesktopNotifications.try_get_instance ();
				break;
			case XdgSessionDesktop.PANTHEON:
				notifications = PantheonDesktopNotifications.try_get_instance ();
				break;
			default:
				notifications = null;
				break;
			}
			
			if (notifications != null) {
				notifications_changed ();
				notifications.notify.connect (notifications_changed);
			}
		}
		
		~EnvironmentSettings ()
		{
			if (notifications != null)
				notifications.notify.disconnect (notifications_changed);
		}
		
		void notifications_changed ()
		{
			ShowNotifications = notifications.ShowNotifications;
		}
	}
	
	interface DesktopNofications : Object
	{
		public abstract bool ShowNotifications { get; set; }
	}
	
	class PantheonDesktopNotifications : Plank.Settings, DesktopNofications
	{
		static PantheonDesktopNotifications? instance = null;
		
		public static unowned PantheonDesktopNotifications? try_get_instance ()
		{
			if (instance == null) {
				var settings = try_create_settings ("org.pantheon.desktop.gala.notifications");
				if (settings != null && ("do-not-disturb" in settings.list_keys ()))
					instance = (PantheonDesktopNotifications) Object.new (typeof (PantheonDesktopNotifications),
						"settings", settings, "bind-flags", SettingsBindFlags.GET | SettingsBindFlags.INVERT_BOOLEAN, null);
			}
			
			return instance;
		}
		
		[Description(nick = "do-not-disturb")]
		public bool ShowNotifications { get; set; }
		
		public PantheonDesktopNotifications ()
		{
			Object ();
		}
	}
	
	class GnomeDesktopNotifications : Plank.Settings, DesktopNofications
	{
		static GnomeDesktopNotifications? instance = null;
		
		public static unowned GnomeDesktopNotifications? try_get_instance ()
		{
			if (instance == null) {
				var settings = try_create_settings ("org.gnome.desktop.notifications");
				if (settings != null && ("show-banners" in settings.list_keys ()))
					instance = (GnomeDesktopNotifications) Object.new (typeof (GnomeDesktopNotifications),
						"settings", settings, "bind-flags", SettingsBindFlags.GET, null);
			}
			
			return instance;
		}
		
		[Description(nick = "show-banners")]
		public bool ShowNotifications { get; set; }
		
		public GnomeDesktopNotifications ()
		{
			Object ();
		}
	}
}
