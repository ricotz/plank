//  
//  Copyright (C) 2011 Robert Dyer
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

using Plank.Items;

namespace Plank.Factories
{
	public class ItemFactory : GLib.Object
	{
		public virtual DockItem make_item (string dock_item_filename)
		{
			var launcher = get_launcher_from_dockitem (dock_item_filename);
			
			if (launcher.has_suffix ("plank.desktop"))
				return new PlankDockItem.with_dockitem (dock_item_filename);
			return default_make_item (dock_item_filename, launcher);
		}
		
		protected DockItem default_make_item (string dock_item_filename, string launcher)
		{
			if (launcher.has_suffix (".desktop"))
				return new ApplicationDockItem.with_dockitem (dock_item_filename);
			return new FileDockItem.with_dockitem (dock_item_filename);
		}
		
		protected string get_launcher_from_dockitem (string dockitem)
		{
			try {
				KeyFile file = new KeyFile ();
				file.load_from_file (dockitem, 0);
				
				return file.get_string (typeof (Items.DockItemPreferences).name (), "Launcher");
			} catch {
				return "";
			}
		}
	}
}
