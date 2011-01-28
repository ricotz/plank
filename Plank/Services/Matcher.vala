//  
//  Copyright (C) 2011 Robert Dyer, Rico Tzschichholz
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

namespace Plank.Services.Windows
{
	public class Matcher : GLib.Object
	{
		public signal void window_changed (Bamf.Window? old_win, Bamf.Window? new_win);
		public signal void window_opened (Bamf.Window w);
		public signal void window_closed (Bamf.Window w);
		
		public signal void app_changed (Bamf.Application? old_app, Bamf.Application? new_app);
		public signal void app_opened (Bamf.Application app);
		public signal void app_closed (Bamf.Application app);
		
		static Matcher matcher;
		
		public static Matcher get_default ()
		{
			if (matcher == null)
				matcher = new Matcher ();
			return matcher;
		}
		
		public Matcher ()
		{
			Bamf.Matcher.get_default ().active_application_changed.connect (handle_app_changed);
			Bamf.Matcher.get_default ().active_window_changed.connect (handle_window_changed);
			Bamf.Matcher.get_default ().view_opened.connect (view_opened);
			Bamf.Matcher.get_default ().view_closed.connect (view_closed);
		}
		
		void handle_app_changed (Object? arg1, Object? arg2)
		{
			app_changed (arg1 as Bamf.Application, arg2 as Bamf.Application);
		}
		
		void handle_window_changed (Object? arg1, Object? arg2)
		{
			window_changed (arg1 as Bamf.Window, arg2 as Bamf.Window);
		}
		
		void view_opened (Object? arg1)
		{
			if (arg1 == null)
				return;
			if (arg1 is Bamf.Window)
				window_opened (arg1 as Bamf.Window);
			else if (arg1 is Bamf.Application)
				app_opened (arg1 as Bamf.Application);		
		}
		
		void view_closed (Object? arg1)
		{
			if (arg1 == null)
				return;
			if (arg1 is Bamf.Window)
				window_closed (arg1 as Bamf.Window);
			else if (arg1 is Bamf.Application)
				app_closed (arg1 as Bamf.Application);
		}
		
		public unowned List<Bamf.Application> active_launchers ()
		{
			return Bamf.Matcher.get_default ().get_applications ();
		}
		
		public Bamf.Application? app_for_launcher (string launcher)
		{
			unowned List<Bamf.Application> apps = Bamf.Matcher.get_default ().get_applications ();
			foreach (Bamf.Application app in apps)
				if (app.get_desktop_file () == launcher)
					return app;
			
			return null;
		}
		
		public void set_favorites (List<string> favs)
		{
			string[] paths = new string[favs.length ()];
			
			for (int i = 0; i < favs.length (); i++)
				paths [i] = favs.nth_data (i);
			
			Bamf.Matcher.get_default ().register_favorites (paths);
		}
	}
}
