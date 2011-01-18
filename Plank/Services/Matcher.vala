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

using Bamf;

namespace Plank.Services.Windows
{
	public class Matcher : GLib.Object
	{
		public signal void window_changed (Window w);
		
		public static Matcher Default { get; protected set; default = new Matcher (); }
		
		public Matcher ()
		{
			Bamf.Matcher matcher = Bamf.Matcher.get_default ();
			
			matcher.view_opened.connect ((matcher, arg1) => {
				if (arg1 is Window)
					window_changed (arg1 as Window);
			});
			
			matcher.view_closed.connect ((matcher, arg1) => {
				if (arg1 is Window)
					window_changed (arg1 as Window);
			});
		}
		
		public void active_launchers ()
		{
			Bamf.Matcher matcher = Bamf.Matcher.get_default ();
			
			unowned GLib.List<Application> apps = Bamf.Matcher.get_running_applications (matcher);
			foreach (Application a in apps)
				if (View.is_user_visible (a))
					stdout.printf("%s\n", Application.get_desktop_file (a));
		}
	}
}
