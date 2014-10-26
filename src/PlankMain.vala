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

using Plank.Factories;

namespace Plank
{
	public class PlankMain : AbstractMain
	{
		public static int main (string[] args)
		{
			var application = new PlankMain ();
			Factory.init (application, new ItemFactory ());
			return application.run (args);
		}
		
		public PlankMain ()
		{
			var authors = new string[] {
					"Robert Dyer <robert@go-docky.com>",
					"Rico Tzschichholz <rtz@go-docky.com>",
					"Michal Hruby <michal.mhr@gmail.com>"
				};
			
			var documenters = new string[] {
					"Robert Dyer <robert@go-docky.com>",
					"Rico Tzschichholz <rtz@go-docky.com>"
				};
			
			var artists = new string[] {
					"Daniel Foré <bunny@go-docky.com>"
				};
			
			Object (
				build_data_dir : Build.DATADIR,
				build_pkg_data_dir : Build.PKGDATADIR,
				build_release_name : Build.RELEASE_NAME,
				build_version : Build.VERSION,
				build_version_info : Build.VERSION_INFO,
			
				program_name : "Plank",
				exec_name : "plank",
			
				app_copyright : "2011-2014",
				app_dbus : "net.launchpad.plank",
				app_icon : "plank",
				app_launcher : "plank.desktop",
			
				main_url : "https://launchpad.net/plank",
				help_url : "https://answers.launchpad.net/plank",
				translate_url : "https://translations.launchpad.net/plank",
			
				about_authors : authors,
				about_documenters : documenters,
				about_artists : artists,
				about_translators : "",
				about_license_type : Gtk.License.GPL_3_0
			);
		}
	}
}
