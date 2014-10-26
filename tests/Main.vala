//
//  Copyright (C) 2013 Rico Tzschichholz
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

using Plank.Drawing;
using Plank.Factories;
using Plank.Services;

using Plank.Services.Windows;

namespace Plank.Tests
{
	public const string TEST_ICON = Config.DATA_DIR + "/test-icon.svg";
	public const string TEST_DOCK_NAME = "dock1";
	public const uint IO_WAIT_MS = 1500;
	public const uint EVENT_WAIT_MS = 100;
	public const uint X_WAIT_MS = 200;
	
	public static int main (string[] args)
	{
		Test.init (ref args);
		
		Gtk.init (ref args);
		
		Log.set_always_fatal (LogLevelFlags.LEVEL_ERROR | LogLevelFlags.LEVEL_CRITICAL);
		
		Paths.initialize ("test", Config.DATA_DIR);
		
		// static tests
		register_drawing_tests ();
		register_items_tests ();
		register_preferences_tests ();
		register_widgets_tests ();

		// further preparations needed for runtime tests
		Factory.init (new TestMain (), new ItemFactory ());
		Logger.initialize ("test");
		Paths.ensure_directory_exists (Paths.AppConfigFolder.get_child (TEST_DOCK_NAME));
		WindowControl.initialize ();
		
		// runtime tests
		register_controller_tests ();
		
		return Test.run ();
	}
	
	void wait (uint milliseconds)
	{
		var main_loop = new MainLoop ();
		
		Gdk.threads_add_timeout (milliseconds, () => {
			main_loop.quit ();
			return false;
		});
		
		main_loop.run ();
	}
	
	public class TestMain : AbstractMain
	{
		public TestMain ()
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
				build_data_dir : Config.DATA_DIR,
				build_pkg_data_dir : Config.DATA_DIR + "/test",
				build_release_name : "testname",
				build_version : "0.0.0",
				build_version_info : "testing",
			
				program_name : "Test",
				exec_name : "test",
			
				app_copyright : "2014",
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
