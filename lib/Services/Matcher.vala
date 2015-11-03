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
	 * Wrapper for Bamf.Matcher
	 */
	public class Matcher : GLib.Object
	{
		public signal void active_window_changed (Bamf.Window? old_win, Bamf.Window? new_win);
		public signal void window_opened (Bamf.Window w);
		public signal void window_closed (Bamf.Window w);
		
		public signal void active_application_changed (Bamf.Application? old_app, Bamf.Application? new_app);
		public signal void application_opened (Bamf.Application app);
		public signal void application_closed (Bamf.Application app);
		
		static Matcher? matcher = null;
		
		public static Matcher get_default ()
		{
			if (matcher == null)
				matcher = new Matcher ();
			return matcher;
		}
		
		Gee.HashSet<Bamf.View> pending_views;
		Bamf.Matcher? bamf_matcher;
		
		private Matcher ()
		{
		}
		
		construct
		{
			bamf_matcher = Bamf.Matcher.get_default ();
			bamf_matcher.active_application_changed.connect_after (handle_active_application_changed);
			bamf_matcher.active_window_changed.connect_after (handle_active_window_changed);
			bamf_matcher.view_opened.connect_after (handle_view_opened);
			bamf_matcher.view_closed.connect_after (handle_view_closed);
			
			pending_views = new Gee.HashSet<Bamf.View> ();
		}
		
		~Matcher ()
		{
			foreach (var view in pending_views)
				view.user_visible_changed.disconnect (handle_view_user_visible_changed);
			
			bamf_matcher.active_application_changed.disconnect (handle_active_application_changed);
			bamf_matcher.active_window_changed.disconnect (handle_active_window_changed);
			bamf_matcher.view_opened.disconnect (handle_view_opened);
			bamf_matcher.view_closed.disconnect (handle_view_closed);
			bamf_matcher = null;
		}
		
		void handle_active_application_changed (Bamf.Application? arg1, Bamf.Application? arg2)
		{
			active_application_changed (arg1, arg2);
		}
		
		void handle_active_window_changed (Bamf.Window? arg1, Bamf.Window? arg2)
		{
			active_window_changed (arg1, arg2);
		}
		
		void handle_view_user_visible_changed (Bamf.View view, bool user_visible)
		{
			if (!user_visible)
				return;
			
			handle_view_opened (view);
		}
		
		void handle_view_opened (Bamf.View arg1)
		{
			if (arg1 is Bamf.Application && !arg1.is_user_visible ()) {
				pending_views.add (arg1);
				arg1.user_visible_changed.connect_after (handle_view_user_visible_changed);
				return;
			}
			
			if (arg1 is Bamf.Window)
				window_opened ((Bamf.Window) arg1);
			else if (arg1 is Bamf.Application)
				application_opened ((Bamf.Application) arg1);
		}
		
		void handle_view_closed (Bamf.View arg1)
		{
			if (pending_views.remove (arg1)) {
				arg1.user_visible_changed.disconnect (handle_view_user_visible_changed);
				return;
			}
			
			if (arg1 is Bamf.Window)
				window_closed ((Bamf.Window) arg1);
			else if (arg1 is Bamf.Application)
				application_closed ((Bamf.Application) arg1);
		}
		
		public Gee.ArrayList<Bamf.Application> active_launchers ()
		{
			var apps = bamf_matcher.get_running_applications ();
			var list = new Gee.ArrayList<Bamf.Application> ();
			
			warn_if_fail (apps != null);
			if (apps == null)
				return list;
			
			foreach (var app in apps)
				list.add (app);
			
			return list;
		}
		
		public Bamf.Application? app_for_uri (string uri)
		{
			string launcher;
			try {
				launcher = Filename.from_uri (uri);
			} catch (ConvertError e) {
				warning (e.message);
				return null;
			}
			
			unowned Bamf.Application app = bamf_matcher.get_application_for_desktop_file (launcher, false);
			
			warn_if_fail (app != null);
			
			return app;
		}
		
		public void set_favorites (Gee.ArrayList<string> favs)
		{
			var paths = new string[favs.size];
			
			for (var i = 0; i < favs.size; i++)
				paths [i] = favs.get (i);
			
			bamf_matcher.register_favorites (paths);
		}
	}
}
