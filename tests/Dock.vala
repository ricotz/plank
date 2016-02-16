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

using Plank;

namespace PlankTests
{
	public class Dock : AbstractMain
	{
		public static int main (string[] args)
		{
			var application = new Dock ();
			Factory.init (application, new ItemFactory ());
			Timeout.add (5000, (SourceFunc) application.quit);
			return application.run (args);
		}
		
		public Dock ()
		{
			var authors = new string[] {
					"Rico Tzschichholz <ricotz@ubuntu.com>",
				};
			
			var documenters = new string[] {
					"Rico Tzschichholz <ricotz@ubuntu.com>",
				};
			
			var artists = new string[] {
					"Daniel Foré <bunny@go-docky.com>"
				};
			
			Object (
				build_data_dir : Config.DATA_DIR,
				build_pkg_data_dir : Config.DATA_DIR + "/test",
				build_release_name : "testname",
				build_version : "0.0.0",
				build_version_info : "testing",
				
				program_name : "Test",
				exec_name : "test",
				
				app_copyright : "2015",
				app_dbus : "net.launchpad.planktest",
				app_icon : "test",
				app_launcher : "test.desktop",
				
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
