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
		Test.add_func ("/Services/Preferences/basics", preferences_basics);
		Test.add_func ("/Services/Preferences/delay", preferences_delay);
		Test.add_func ("/Services/Preferences/signals", preferences_signals);
		Test.add_func ("/Services/Preferences/subclass", preferences_subclass);
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
	
	class SubTestPreferences : TestPreferences
	{
		public bool SubBoolSetting { get; set; }
		public double SubDoubleSetting { get; set; }
		public int SubIntSetting { get; set; }
		public string SubStringSetting { get; set; }
		
		public SubTestPreferences (string filename)
		{
			base (filename);
		}
		
		public override void reset_properties ()
		{
			base.reset_properties ();
			
			SubBoolSetting = false;
			SubDoubleSetting = 0.4242;
			SubIntSetting = 4242;
			SubStringSetting = "subtest";
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
	
	void preferences_delay ()
	{
		var prefs = new TestPreferences ("test_preferences_delay");
		var prefs2 = new TestPreferences ("test_preferences_delay");
		
		triggered = false;
		prefs2.changed.connect (preferences_triggered_cb);
		
		prefs.delay ();
		prefs.BoolSetting = false;
		prefs.IntSetting = 4711;
		prefs.DoubleSetting = 0.4711;
		prefs.StringSetting = "test_changed";
		
		wait (IO_WAIT_MS);
		assert (triggered == false);
		assert (prefs2.BoolSetting == true);
		assert (prefs2.DoubleSetting == 0.42);
		assert (prefs2.IntSetting == 42);
		assert (prefs2.StringSetting == "test");
		
		prefs.apply ();
		
		wait (IO_WAIT_MS);
		assert (triggered == true);
		assert (prefs2.BoolSetting == false);
		assert (prefs2.DoubleSetting == 0.4711);
		assert (prefs2.IntSetting == 4711);
		assert (prefs2.StringSetting == "test_changed");
	}
	
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
		try { file.delete (); } catch {};
		wait (IO_WAIT_MS);
		assert (triggered == true);
	}
	
	void preferences_triggered_cb (Preferences prefs)
	{
		triggered = true;
	}
	
	void preferences_subclass ()
	{
		var prefs = new SubTestPreferences ("test_preferences_subclass");
		var prefs2 = new SubTestPreferences ("test_preferences_subclass");
		
		assert (prefs.BoolSetting == true);
		assert (prefs.DoubleSetting == 0.42);
		assert (prefs.IntSetting == 42);
		assert (prefs.StringSetting == "test");
		assert (prefs.SubBoolSetting == false);
		assert (prefs.SubDoubleSetting == 0.4242);
		assert (prefs.SubIntSetting == 4242);
		assert (prefs.SubStringSetting == "subtest");
		
		prefs.delay ();
		prefs.BoolSetting = false;
		prefs.IntSetting = 4711;
		prefs.DoubleSetting = 0.4711;
		prefs.StringSetting = "test_changed";
		prefs.SubBoolSetting = true;
		prefs.SubIntSetting = 47114711;
		prefs.SubDoubleSetting = 0.47114711;
		prefs.SubStringSetting = "subtest_changed";
		prefs.apply ();
		
		wait (IO_WAIT_MS);
		assert (prefs2.BoolSetting == false);
		assert (prefs2.IntSetting == 4711);
		assert (prefs2.DoubleSetting == 0.4711);
		assert (prefs2.StringSetting == "test_changed");
		assert (prefs2.SubBoolSetting == true);
		assert (prefs2.SubIntSetting == 47114711);
		assert (prefs2.SubDoubleSetting == 0.47114711);
		assert (prefs2.SubStringSetting == "subtest_changed");
	}
}

