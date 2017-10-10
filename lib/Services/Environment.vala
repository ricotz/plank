//
//  Copyright (C) 2015 Rico Tzschichholz
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
	public enum XdgSessionClass
	{
		USER,
		GREETER,
		LOCK_SCREEN,
		BACKGROUND;
		
		public static XdgSessionClass from_string (string s)
		{
			XdgSessionClass result;
			
			switch (s.down ()) {
			default:
			case "user": result = XdgSessionClass.USER; break;
			case "greeter": result = XdgSessionClass.GREETER; break;
			case "lock-screen": result = XdgSessionClass.LOCK_SCREEN; break;
			case "background": result = XdgSessionClass.BACKGROUND; break;
			}
			
			return result;
		}
	}
	
	[Flags]
	public enum XdgSessionDesktop
	{
		GNOME = 1 << 0,
		KDE = 1 << 1,
		LXDE = 1 << 2,
		MATE = 1 << 3,
		RAZOR = 1 << 4,
		ROX = 1 << 5,
		TDE = 1 << 6,
		UNITY = 1 << 7,
		XFCE = 1 << 8,
		EDE = 1 << 9,
		CINNAMON = 1 << 10,
		PANTHEON = 1 << 11,
		OLD = 1 << 12,
		UBUNTU = 1 << 13;
		
		static XdgSessionDesktop from_single_string (string s)
		{
			XdgSessionDesktop result;
			
			switch (s.down ()) {
			case "gnome": result = XdgSessionDesktop.GNOME; break;
			case "gnome-xorg": result = XdgSessionDesktop.GNOME; break;
			case "ubuntu": result = XdgSessionDesktop.UBUNTU; break;
			case "ubuntu-xorg": result = XdgSessionDesktop.UBUNTU; break;
			case "kde": result = XdgSessionDesktop.KDE; break;
			case "lxde": result = XdgSessionDesktop.LXDE; break;
			case "mate": result = XdgSessionDesktop.MATE; break;
			case "razor": result = XdgSessionDesktop.RAZOR; break;
			case "rox": result = XdgSessionDesktop.ROX; break;
			case "tde": result = XdgSessionDesktop.TDE; break;
			case "unity": result = XdgSessionDesktop.UNITY; break;
			case "xfce": result = XdgSessionDesktop.XFCE; break;
			case "ede": result = XdgSessionDesktop.EDE; break;
			case "cinnamon": result = XdgSessionDesktop.CINNAMON; break;
			case "pantheon": result = XdgSessionDesktop.PANTHEON; break;
			case "old": result = XdgSessionDesktop.OLD; break;
			default: result = 0; break;
			}
			
			return result;
		}
		
		public static XdgSessionDesktop from_string (string s)
		{
			XdgSessionDesktop result = 0;
			
			if (s.contains (";")) {
				foreach (unowned string e in s.split (";"))
					if (e != null)
						result |= from_single_string (e);
			} else {
				result = from_single_string (s);
			}
			
			return result;
		}
	}
	
	public enum XdgSessionType
	{
		UNSPECIFIED,
		TTY,
		X11,
		WAYLAND,
		MIR;
		
		public static XdgSessionType from_string (string s)
		{
			XdgSessionType result;
			
			switch (s.down ()) {
			default:
			case "unspecified": result = XdgSessionType.UNSPECIFIED; break;
			case "tty": result = XdgSessionType.TTY; break;
			case "x11": result = XdgSessionType.X11; break;
			case "wayland": result = XdgSessionType.WAYLAND; break;
			case "mir": result = XdgSessionType.MIR; break;
			}
			
			return result;
		}
	}
	
	static XdgSessionClass session_class;
	static XdgSessionDesktop session_desktop;
	static XdgSessionType session_type;
	
	public static void environment_initialize ()
	{
		session_class = get_xdg_session_class ();
		session_desktop = get_xdg_session_desktop ();
		session_type = get_xdg_session_type ();
	}
	
	public static bool environment_is_session_class (XdgSessionClass type)
	{
		return (type == session_class);
	}
	
	public static bool environment_is_session_desktop (XdgSessionDesktop type)
	{
		return (type in session_desktop);
	}
	
	public static bool environment_is_session_type (XdgSessionType type)
	{
		return (type == session_type);
	}
	
	static XdgSessionClass get_xdg_session_class ()
	{
		unowned string? result;
		
		result = Environment.get_variable ("XDG_SESSION_CLASS");
		if (result != null)
			return XdgSessionClass.from_string (result);
		
		warning ("XDG_SESSION_CLASS not set in this environment!");
		
		return XdgSessionClass.USER;
	}
	
	static XdgSessionDesktop get_xdg_session_desktop ()
	{
		unowned string? result;
		
		result = Environment.get_variable ("XDG_SESSION_DESKTOP");
		if (result == null)
			result = Environment.get_variable ("XDG_CURRENT_DESKTOP");
		if (result == null)
			result = Environment.get_variable ("DESKTOP_SESSION");
		
		if (result != null)
			return XdgSessionDesktop.from_string (result);
		
		warning ("Neither of XDG_SESSION_DESKTOP, XDG_CURRENT_DESKTOP or DESKTOP_SESSION is set in this environment!");
		
		return XdgSessionDesktop.GNOME;
	}
	
	static XdgSessionType get_xdg_session_type ()
	{
		unowned string? result;
		
		result = Environment.get_variable ("XDG_SESSION_TYPE");
		if (result != null)
			return XdgSessionType.from_string (result);
		
		warning ("XDG_SESSION_TYPE not set in this environment!");
		
		if (Gdk.Screen.get_default () is Gdk.X11.Screen)
			return XdgSessionType.X11;
		
		error ("XdgSessionType could not be determined!");
	}
}
