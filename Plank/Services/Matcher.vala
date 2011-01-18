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

using bamf;

namespace Plank.Services.Windows
{
	public class Matcher : GLib.Object
	{
		static construct {
			BamfMatcher matcher = BamfMatcher.get_default ();
			matcher.view_opened.connect ((matcher, arg1) => {
				BamfView view = arg1 as BamfView;
				stdout.printf("view type: %s", view.get_name ());
				stdout.printf("new view\n");
			});
			matcher.view_closed.connect (() => {
				stdout.printf("lost view\n");
			});
		}
		
		public static void active_launchers ()
		{
			BamfMatcher matcher = BamfMatcher.get_default ();
			unowned GLib.List<BamfApplication> apps = BamfMatcher.get_running_applications (matcher);
			foreach (BamfApplication a in apps)
				if (BamfView.is_user_visible (a))
					stdout.printf("%s\n", BamfApplication.get_desktop_file (a));
		}
	}
}
