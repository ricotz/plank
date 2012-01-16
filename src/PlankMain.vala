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

using Plank.Factories;

namespace PlankMain
{
	public class PlankMain : AbstractMain
	{
		public static int main (string[] args)
		{
			var main_class = new PlankMain ();
			Factory.init (main_class, new ItemFactory ());
			return main_class.start (args);
		}
		
		public PlankMain ()
		{
			build_data_dir = Build.DATADIR;
			build_pkg_data_dir = Build.PKGDATADIR;
			build_release_name = Build.RELEASE_NAME;
			build_version = Build.VERSION;
			build_version_info = Build.VERSION_INFO;
			
			program_name = "Plank";
			exec_name = "plank";
			
			app_copyright = "2011-2012";
			app_dbus = "net.launchpad.plank";
			app_icon = "plank";
			app_launcher = "plank.desktop";
			
			main_url = "https://launchpad.net/plank";
			help_url = "https://answers.launchpad.net/plank";
			translate_url = "https://translations.launchpad.net/plank";
			
			about_authors = {
				"Robert Dyer <robert@go-docky.com>",
				"Rico Tzschichholz <rtz@go-docky.com>",
				"Michal Hruby <michal.mhr@gmail.com>"
			};
			about_documenters = {
				"Robert Dyer <robert@go-docky.com>"
			};
			about_artists = {
				"Daniel Foré <bunny@go-docky.com>"
			};
			about_translators = "";
		}
	}
}
