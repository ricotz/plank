//  
//  Copyright (C) 2011 Robert Dyer, Rico Tzschichholz
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

using Gdk;
using Gee;
using Gtk;

using Plank.Drawing;

namespace Plank.Items
{
	public class FileDockItem : DockItem
	{
		public FileDockItem.with_dockitem (string dockitem)
		{
			Prefs = new DockItemPreferences.with_file (dockitem);
			if (!ValidItem)
				return;
			
			var file = File.new_for_path (Prefs.Launcher);
			Icon = DrawingService.get_icon_from_file (file) ?? "folder";
			Text = file.get_basename ();
			Button = PopupButton.RIGHT | PopupButton.LEFT;
		}
		
		public override void launch ()
		{
			Services.System.open (File.new_for_path (Prefs.Launcher));
		}
		
		protected override ClickAnimation on_clicked (uint button, ModifierType mod)
		{
			if (button == 1) {
				launch ();
				return ClickAnimation.BOUNCE;
			}
			
			return ClickAnimation.NONE;
		}
		
		public override ArrayList<MenuItem> get_menu_items ()
		{
			ArrayList<MenuItem> items = new ArrayList<MenuItem> ();
			
			File dir = File.new_for_path (Prefs.Launcher);
			try {
				var enumerator = dir.enumerate_children (FILE_ATTRIBUTE_STANDARD_NAME + ","
					+ FILE_ATTRIBUTE_STANDARD_IS_HIDDEN + ","
					+ FILE_ATTRIBUTE_ACCESS_CAN_READ, 0);
				
				FileInfo info;
				HashMap<string, MenuItem> files = new HashMap<string, MenuItem> (str_hash, str_equal);
				ArrayList<string> keys = new ArrayList<string> ();
				
				while ((info = enumerator.next_file ()) != null) {
					if (info.get_is_hidden ())
						continue;
				
					var file = dir.get_child (info.get_name ());
					
					if (info.get_name ().has_suffix (".desktop")) {
						string icon, text;
						ApplicationDockItem.parse_launcher (file.get_path (), out icon, out text);
						
						var item = create_menu_item (text, icon);
						item.activate.connect (() => {
							Services.System.launch (file, {});
							ClickedAnimation = ClickAnimation.BOUNCE;
							LastClicked = new DateTime.now_utc ();
						});
						files.set (text, item);
						keys.add (text);
					} else {
						var icon = DrawingService.get_icon_from_file (file) ?? "";
						
						var item = create_menu_item (info.get_name (), icon);
						item.activate.connect (() => {
							Services.System.open (file);
							ClickedAnimation = ClickAnimation.BOUNCE;
							LastClicked = new DateTime.now_utc ();
						});
						files.set (info.get_name (), item);
						keys.add (info.get_name ());
					}
				}
				
				keys.sort (strcmp);
				foreach (string s in keys)
					items.add (files.get (s));
			} catch { }
			
			return items;
		}
	}
}
