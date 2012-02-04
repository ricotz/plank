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

using Gee;

namespace Plank.Services.Windows
{
	internal class Matcher : GLib.Object
	{
		public signal void window_changed (Bamf.Window? old_win, Bamf.Window? new_win);
		public signal void window_opened (Bamf.Window w);
		public signal void window_closed (Bamf.Window w);
		
		public signal void app_changed (Bamf.Application? old_app, Bamf.Application? new_app);
		public signal void app_opened (Bamf.Application app);
		public signal void app_closed (Bamf.Application app);
		
		static Matcher? matcher = null;
		
		public static Matcher get_default ()
		{
			if (matcher == null)
				matcher = new Matcher ();
			return matcher;
		}
		
		Bamf.Matcher? bamf_matcher;
		
		private Matcher ()
		{
			bamf_matcher = Bamf.Matcher.get_default ();
			bamf_matcher.active_application_changed.connect (handle_app_changed);
			bamf_matcher.active_window_changed.connect (handle_window_changed);
			bamf_matcher.view_opened.connect (view_opened);
			bamf_matcher.view_closed.connect (view_closed);
		}
		
		~Matcher ()
		{
			bamf_matcher.active_application_changed.disconnect (handle_app_changed);
			bamf_matcher.active_window_changed.disconnect (handle_window_changed);
			bamf_matcher.view_opened.disconnect (view_opened);
			bamf_matcher.view_closed.disconnect (view_closed);
			bamf_matcher = null;
		}
		
		void handle_app_changed (Bamf.View? arg1, Bamf.View? arg2)
		{
			app_changed (arg1 as Bamf.Application, arg2 as Bamf.Application);
		}
		
		void handle_window_changed (Bamf.View? arg1, Bamf.View? arg2)
		{
			window_changed (arg1 as Bamf.Window, arg2 as Bamf.Window);
		}
		
		void view_opened (Bamf.View arg1)
		{
			if (arg1 is Bamf.Window)
				window_opened (arg1 as Bamf.Window);
			else if (arg1 is Bamf.Application)
				app_opened (arg1 as Bamf.Application);		
		}
		
		void view_closed (Bamf.View arg1)
		{
			if (arg1 is Bamf.Window)
				window_closed (arg1 as Bamf.Window);
			else if (arg1 is Bamf.Application)
				app_closed (arg1 as Bamf.Application);
		}
		
		public ArrayList<Bamf.Application> active_launchers ()
		{
			GLib.List<unowned Bamf.View>? apps = bamf_matcher.get_running_applications ();
			var list = new ArrayList<Bamf.Application> ();
			
			warn_if_fail (apps != null);
			if (apps == null)
				return list;
			
			foreach (var app in apps)
				if (app is Bamf.Application)
					list.add (app as Bamf.Application);
			
			return list;
		}
		
		public Bamf.Application? app_for_launcher (string launcher)
		{
			GLib.List<unowned Bamf.View>? apps = bamf_matcher.get_applications ();
			
			warn_if_fail (apps != null);
			if (apps == null)
				return null;
			
			foreach (var app in apps)
				if (app is Bamf.Application && (app as Bamf.Application).get_desktop_file () == launcher)
					return app as Bamf.Application;
			
			return null;
		}
		
		public void set_favorites (ArrayList<string> favs)
		{
			var paths = new string[favs.size];
			
			for (var i = 0; i < favs.size; i++)
				paths [i] = favs.get (i);
			
			bamf_matcher.register_favorites (paths);
		}
	}
}
