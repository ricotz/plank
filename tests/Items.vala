//
//  Copyright (C) 2013 Rico Tzschichholz
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
	public static void register_items_tests ()
	{
		Test.add_func ("/Items/DockItem/basics", items_dockitem);
		Test.add_func ("/Items/FileDockItem/basics", items_filedockitem);
		Test.add_func ("/Items/ApplicationDockItem/basics", items_applicationdockitem);
		Test.add_func ("/Items/TransientDockItem/basics", items_transientdockitem);
		
		Test.add_func ("/Items/DockItemProvider/basics", items_dockitemprovider);
		Test.add_func ("/Items/DockItemProvider/signals", items_dockitemprovider_signals);
	}
	
	void items_dockitem ()
	{
		DockItem item, item2;
		File file = File.new_for_path (Config.DATA_DIR + "/test.desktop");
		
		item = new TestDockItem ();
		item.Prefs.Launcher = file.get_uri ();
		item.Text = "Plank";
		item.Icon = TEST_ICON;
		item.Count = 42;
		item.CountVisible = true;
		item.Progress = 0.42;
		item.ProgressVisible = true;
		item.Position = 1;
		
		assert (item.is_valid () == true);
		assert (item.Text == "Plank");
		assert (item.Icon == TEST_ICON);
		assert (item.Count == 42);
		assert (item.CountVisible == true);
		assert (item.Progress == 0.42);
		assert (item.ProgressVisible == true);
		assert (item.Position == 1);
		
		item2 = new TestDockItem ();
		item.copy_values_to (item2);
		assert (item.Count == item2.Count);
		assert (item.CountVisible == item2.CountVisible);
		assert (item.Icon == item2.Icon);
		assert (item.Position == item2.Position);
		assert (item.Progress == item2.Progress);
		assert (item.ProgressVisible == item2.ProgressVisible);
		assert (item.Text == item2.Text);
		
		assert (item.unique_id () != null);
		assert (item.unique_id () != "");
		assert (item.unique_id () != item2.unique_id ());
		
		var icon = item.get_surface_copy (111, 111, new Surface (1, 1));
		assert (icon != null);
		assert (icon.Width == 111);
		assert (icon.Height == 111);
		
		var icon2 = item.get_surface_copy (111, 111, new Surface (1, 1));
		assert (icon != null);
		assert (icon2 != null);
		assert (icon != icon2);
		assert (icon.Width == icon2.Width);
		assert (icon.Height == icon2.Height);
	}
	
	void items_filedockitem ()
	{
		FileDockItem item;
		
		item = new FileDockItem.with_file (File.new_for_path (Config.DATA_DIR + "/test.desktop"));
		
		var icon = item.get_surface_copy (64, 64, new Surface (1, 1));
		assert (icon != null);
		assert (icon.Width == 64);
		assert (icon.Height == 64);
	}
	
	void items_applicationdockitem ()
	{
		ApplicationDockItem item;
		File file = File.new_for_path (Config.DATA_DIR + "/test.desktop");
		
		item = new ApplicationDockItem ();
		item.Prefs.Launcher = file.get_uri ();
		
		string icon, text;
		ApplicationDockItem.parse_launcher (file.get_uri (), out icon, out text, null, null);
		
		assert (item.is_valid () == true);
		assert (item.Icon != null && item.Icon != "");
		assert (item.Text != null && item.Text != "");
		assert (item.Icon == icon);
		assert (item.Text == text);
		assert (item.get_unity_application_uri () == "application://test.desktop");
	}
	
	void items_transientdockitem ()
	{
		TransientDockItem item;
		File file = File.new_for_path (Config.DATA_DIR + "/test.desktop");
		
		item = new TransientDockItem.with_launcher (file.get_uri ());
		
		string icon, text;
		ApplicationDockItem.parse_launcher (file.get_uri (), out icon, out text, null, null);
		
		assert (item.is_valid () == true);
		assert (item.Icon != null && item.Icon != "");
		assert (item.Text != null && item.Text != "");
		assert (item.Icon == icon);
		assert (item.Text == text);
		assert (item.get_unity_application_uri () == "application://test.desktop");
	}
	
	DockItem create_testitem ()
	{
		var file = File.new_for_path (Config.DATA_DIR + "/test.desktop");
		var item = new TestDockItem ();
		item.Prefs.Launcher = file.get_uri ();
		item.Text = "Plank";
		item.Icon = TEST_ICON;
		item.Count = 42;
		item.CountVisible = true;
		item.Progress = 0.42;
		item.ProgressVisible = true;
		item.Position = 1;
		
		return item;
	}
	
	void items_dockitemprovider ()
	{
		DockItemProvider provider;
		
		provider = new DockItemProvider ();
		var item = create_testitem ();
		
		provider.add (item);
		assert (item.ref_count > 1);
		
		provider.remove (item);
		assert (item.ref_count == 1);
	}
	
	DockItem? added_item;
	DockItem? removed_item;
	bool items_triggered;
	
	void items_dockitemprovider_signals ()
	{
		DockItemProvider provider;
		int64 now;
		
		provider = new DockItemProvider ();
		var item = create_testitem ();
		
		// add item
		provider.elements_changed.connect (itemprovider_added_cb);
		provider.add (item);
		wait (EVENT_WAIT_MS);
		now = GLib.get_monotonic_time ();
		provider.elements_changed.disconnect (itemprovider_added_cb);
		
		assert (item == added_item);
		added_item = null;
		assert (item.ref_count > 1);
		assert (item.AddTime - now < 100);
		
		// change item state
		items_triggered = false;
		provider.states_changed.connect (itemprovider_state_cb);
		item.clicked (0, 0, 0);
		wait (EVENT_WAIT_MS);
		provider.states_changed.disconnect (itemprovider_state_cb);
		
		assert (items_triggered = true);
		
		// remove item
		provider.elements_changed.connect (itemprovider_removed_cb);
		provider.remove (item);
		wait (EVENT_WAIT_MS);
		now = GLib.get_monotonic_time ();
		provider.elements_changed.disconnect (itemprovider_removed_cb);
		
		assert (item == removed_item);
		removed_item = null;
		assert (item.ref_count == 1);
		assert (item.RemoveTime - now < 100);
	}
	
	void itemprovider_added_cb (Gee.List<DockItem> added, Gee.List<DockItem> removed)
	{
		assert (added.size > 0);
		added_item = added.first ();
	}
	
	void itemprovider_removed_cb (Gee.List<DockItem> added, Gee.List<DockItem> removed)
	{
		assert (removed.size > 0);
		removed_item = removed.first ();
	}
	
	void itemprovider_state_cb ()
	{
		items_triggered = true;
	}
}
