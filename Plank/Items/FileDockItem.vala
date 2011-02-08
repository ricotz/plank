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
		File OwnedFile { get; set; }
		
		public FileDockItem.with_dockitem (string dockitem)
		{
			Prefs = new DockItemPreferences.with_file (dockitem);
			if (!ValidItem)
				return;
			
			Prefs.notify["Launcher"].connect (() => {
				OwnedFile = File.new_for_path (Prefs.Launcher);
			});
			OwnedFile = File.new_for_path (Prefs.Launcher);
			
			Icon = DrawingService.get_icon_from_file (OwnedFile) ?? "folder";
			Text = OwnedFile.get_basename ();
			
			// pop up the dir contents on a left click too
			if (OwnedFile.query_file_type (0) == FileType.DIRECTORY)
				Button = PopupButton.RIGHT | PopupButton.LEFT;
		}
		
		public override void launch ()
		{
			Services.System.open (OwnedFile);
		}
		
		protected override ClickAnimation on_clicked (PopupButton button, ModifierType mod)
		{
			// this actually only happens if its a file, not a directory
			if (button == PopupButton.LEFT) {
				launch ();
				return ClickAnimation.BOUNCE;
			}
			
			return ClickAnimation.NONE;
		}
		
		public override ArrayList<MenuItem> get_menu_items ()
		{
			ArrayList<MenuItem> items = new ArrayList<MenuItem> ();
			
			if (OwnedFile.query_file_type (0) == FileType.DIRECTORY)
				get_dir_menu_items (items);
			else
				get_file_menu_items (items);
			
			return items;
		}
		
		void get_dir_menu_items (ArrayList<MenuItem> items)
		{
			try {
				var enumerator = OwnedFile.enumerate_children (FILE_ATTRIBUTE_STANDARD_NAME + ","
					+ FILE_ATTRIBUTE_STANDARD_IS_HIDDEN + ","
					+ FILE_ATTRIBUTE_ACCESS_CAN_READ, 0);
				
				FileInfo info;
				HashMap<string, MenuItem> files = new HashMap<string, MenuItem> (str_hash, str_equal);
				ArrayList<string> keys = new ArrayList<string> ();
				
				while ((info = enumerator.next_file ()) != null) {
					if (info.get_is_hidden ())
						continue;
				
					var file = OwnedFile.get_child (info.get_name ());
					
					if (info.get_name ().has_suffix (".desktop")) {
						string icon, text;
						ApplicationDockItem.parse_launcher (file.get_path (), out icon, out text);
						
						var item = create_menu_item (text, icon);
						item.activate.connect (() => {
							Services.System.launch (file);
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
		}
		
		void get_file_menu_items (ArrayList<MenuItem> items)
		{
			var item = create_menu_item (_("_Open"), "gtk-open");
			item.activate.connect (launch);
			items.add (item);
			
			item = create_menu_item (_("Open Containing _Folder"), "folder");
			item.activate.connect (() => {
				Services.System.open (OwnedFile.get_parent ());
			});
			items.add (item);
		}
	}
}
