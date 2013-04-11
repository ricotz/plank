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

using Plank.Drawing;
using Plank.Items;

namespace Plank.Tests
{
	public static void register_items_tests ()
	{
		Test.add_func ("/Items/DockItem/basics", items_dockitem);
		Test.add_func ("/Items/FileDockItem/basics", items_filedockitem);
		Test.add_func ("/Items/ApplicationDockItem/basics", items_applicationdockitem);
		Test.add_func ("/Items/TransientDockItem/basics", items_transientdockitem);
	}
	
	void items_dockitem ()
	{
		DockItem item, item2;
		File file = File.new_for_path (Config.DATA_DIR + "/test.desktop");
		
		item = new DockItem ();
		item.Prefs.Launcher = file.get_uri ();
		item.Text = "Plank";
		item.Icon = TEST_ICON;
		item.Count = 42;
		item.CountVisible = true;
		item.Progress = 0.42;
		item.ProgressVisible = true;
		item.Position = 1;
		
		assert (item.ValidItem == true);
		assert (item.Text == "Plank");
		assert (item.Icon == TEST_ICON);
		assert (item.Count == 42);
		assert (item.CountVisible == true);
		assert (item.Progress == 0.42);
		assert (item.ProgressVisible == true);
		assert (item.Position == 1);
		
		item2 = new DockItem ();
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
		
		var icon = item.get_surface_copy (111, 111, new DockSurface (1, 1));
		assert (icon != null);
		assert (icon.Width == 111);
		assert (icon.Height == 111);
		
		var icon2 = item.get_surface_copy (111, 111, new DockSurface (1, 1));
		assert (icon != null);
		assert (icon2 != null);
		assert (icon != icon2);
		assert (icon.Width == icon2.Width);
		assert (icon.Height == icon2.Height);
	}
	
	void items_filedockitem ()
	{
		FileDockItem item;
		
		File file = File.new_for_path (Config.DATA_DIR + "/test.desktop");
		item = new FileDockItem ();
		item.Prefs.Launcher = file.get_uri ();
		
		var icon = item.get_surface_copy (64, 64, new DockSurface (1, 1));
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
		
		assert (item.ValidItem == true);
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
		
		assert (item.ValidItem == true);
		assert (item.Icon != null && item.Icon != "");
		assert (item.Text != null && item.Text != "");
		assert (item.Icon == icon);
		assert (item.Text == text);
		assert (item.get_unity_application_uri () == "application://test.desktop");
	}
}
