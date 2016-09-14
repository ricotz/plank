//
//  Copyright (C) 2014 Rico Tzschichholz
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
	public static void register_controller_tests ()
	{
		Test.add_func ("/Controller/construct_default", controller_construct_default);
		Test.add_func ("/Controller/construct_custom", controller_construct_custom);
	}
	
	DockItem create_controller_testitem ()
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
	
	void controller_construct_custom ()
	{
		DockController controller;
		ApplicationDockItemProvider provider;
		DockItem item, item2, item3;
		
		File config_folder = Paths.AppConfigFolder.get_child (TEST_DOCK_NAME);
		File launchers_folder = config_folder.get_child ("launchers-custom");
		
		provider = new ApplicationDockItemProvider (launchers_folder);
		item = create_controller_testitem ();
		provider.add (item);
		assert (item.ref_count > 1);

		controller = new DockController (TEST_DOCK_NAME, config_folder);
		controller.add (provider);
		controller.initialize ();
		
		wait (1000);
				
		provider.remove (item);
		assert (item.ref_count == 1);
		
		wait (1000);

		item2 = create_controller_testitem ();
		provider.add (item2);
		wait (500);
		
		controller_items_match (controller);
		
		item3 = create_controller_testitem ();
		provider.replace (item3, item2);
		wait (500);
		
		controller_items_match (controller);
	}
	
	void controller_construct_default ()
	{
		DockController controller;
		
		File config_folder = Paths.AppConfigFolder.get_child (TEST_DOCK_NAME);
		controller = new DockController (TEST_DOCK_NAME, config_folder);
		controller.initialize ();
	}
	
	void controller_items_match (DockController controller)
	{
		var controller_items = controller.VisibleItems;
		var items = new Gee.ArrayList<DockElement> ();
		
		foreach (var element in controller.VisibleElements) {
			unowned DockContainer? container = (element as DockContainer);
			if (container != null)
				items.add_all (container.VisibleElements);
		}
		
		assert (items.size == controller_items.size);
		for (var i = 0; i < items.size; i++)
			assert (items[i] == controller_items[i]);
	}
}
