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
	public static int main (string[] argv)
	{
		Intl.setlocale (LocaleCategory.ALL, "");
		Intl.bindtextdomain (Build.GETTEXT_PACKAGE, Build.DATADIR + "/locale");
		Intl.bind_textdomain_codeset (Build.GETTEXT_PACKAGE, "UTF-8");
		Intl.textdomain (Build.GETTEXT_PACKAGE);
		
		var application = new Plank.Main ();
		Factory.init (application, new ItemFactory ());
		return application.run (argv);
	}
	
	public class Main : AbstractMain
	{
		public Main ()
		{
			var authors = new string[] {
					"Robert Dyer <psybers@gmail.com>",
					"Rico Tzschichholz <ricotz@ubuntu.com>",
					"Michal Hruby <michal.mhr@gmail.com>"
				};
			
			var documenters = new string[] {
					"Robert Dyer <psybers@gmail.com>",
					"Rico Tzschichholz <ricotz@ubuntu.com>"
				};
			
			var artists = new string[] {
					"Daniel Foré <daniel@elementaryos.org>"
				};
			
			Object (
				build_data_dir : Build.DATADIR,
				build_pkg_data_dir : Build.PKGDATADIR,
				build_release_name : Build.RELEASE_NAME,
				build_version : Build.VERSION,
				build_version_info : Build.VERSION_INFO,
			
				program_name : "Plank",
				exec_name : "plank",
			
				app_copyright : "2011-2016",
				app_dbus : "net.launchpad.plank",
				app_icon : "plank",
				app_launcher : "plank.desktop",
			
				main_url : "https://launchpad.net/plank",
				help_url : "https://answers.launchpad.net/plank",
				translate_url : "https://translations.launchpad.net/plank",
			
				about_authors : authors,
				about_documenters : documenters,
				about_artists : artists,
				about_translators : _("translator-credits"),
				about_license_type : Gtk.License.GPL_3_0
			);
		}
	}
}
