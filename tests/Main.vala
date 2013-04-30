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

using Cairo;
using Gdk;

using Plank.Services;

namespace Plank.Tests
{
	public const string TEST_ICON = Config.DATA_DIR + "/test-icon.svg";
	
	public static int main (string[] args)
	{
		Test.init (ref args);
		
		Gtk.init (ref args);
		
		Log.set_always_fatal (LogLevelFlags.LEVEL_ERROR | LogLevelFlags.LEVEL_CRITICAL);
		
		Paths.initialize ("test", Config.DATA_DIR);
		
		register_drawing_tests ();
		register_items_tests ();
		register_preferences_tests ();
		
		return Test.run ();
	}
}
