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
	public static void register_preferences_tests ()
	{
		Test.add_func ("/Preferences/basics", preferences_basics);
		Test.add_func ("/Preferences/signals", preferences_signals);
	}
	
	class TestPreferences : Preferences
	{
		public bool BoolSetting { get; set; }
		public double DoubleSetting { get; set; }
		public int IntSetting { get; set; }
		public string StringSetting { get; set; }
		
		public TestPreferences (string filename)
		{
			base.with_filename (filename);
		}
		
		public override void reset_properties ()
		{
			BoolSetting = true;
			DoubleSetting = 0.42;
			IntSetting = 42;
			StringSetting = "test";
		}
	}
	
	void preferences_basics ()
	{
		var prefs = new TestPreferences ("test_preferences_basics");
		assert (prefs.BoolSetting == true);
		assert (prefs.DoubleSetting == 0.42);
		assert (prefs.IntSetting == 42);
		assert (prefs.StringSetting == "test");
		
		prefs.BoolSetting = false;
		prefs.IntSetting = 4711;
		prefs.DoubleSetting = 0.4711;
		prefs.StringSetting = "test_changed";
		
		assert (prefs.BoolSetting == false);
		assert (prefs.DoubleSetting == 0.4711);
		assert (prefs.IntSetting == 4711);
		assert (prefs.StringSetting == "test_changed");

		var prefs2 = new TestPreferences ("test_preferences_basics");
		assert (prefs2.BoolSetting == false);
		assert (prefs2.DoubleSetting == 0.4711);
		assert (prefs2.IntSetting == 4711);
		assert (prefs2.StringSetting == "test_changed");
	}
	
	bool triggered;
	
	void preferences_signals ()
	{
		var prefs = new TestPreferences ("test_preferences_signals");
		
		triggered = false;
		prefs.changed.connect (preferences_triggered_cb);
		prefs.StringSetting = "test_changed";
		assert (triggered == true);
		
		triggered = false;
		prefs.changed.disconnect (preferences_triggered_cb);
		prefs.StringSetting = "test_changed";
		assert (triggered == false);
		
		triggered = false;
		prefs.deleted.connect (preferences_triggered_cb);
		var file = Paths.AppConfigFolder.get_child ("test_preferences_signals");
		file.delete ();
		//assert (triggered == true);
	}
	
	void preferences_triggered_cb (Preferences prefs)
	{
		triggered = true;
	}
}

