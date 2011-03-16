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

using Cairo;
using Gdk;
using Gee;
using Gtk;

using Plank.Drawing;

namespace Plank.Items
{
	public class FileDockItem : DockItem
	{
		const string DEFAULT_ICON = "inode-directory;;gnome-mime-inode-directory;;inode-x-generic;;folder";
		
		File OwnedFile { get; set; }
		
		public FileDockItem.with_dockitem (string dockitem)
		{
			Prefs = new DockItemPreferences.with_file (dockitem);
			if (!ValidItem)
				return;
			
			Prefs.notify["Launcher"].connect (handle_launcher_changed);
			Prefs.deleted.connect (handle_deleted);
			OwnedFile = File.new_for_path (Prefs.Launcher);
			
			Icon = DrawingService.get_icon_from_file (OwnedFile) ?? DEFAULT_ICON;
			Text = OwnedFile.get_basename ();
			
			// pop up the dir contents on a left click too
			if (OwnedFile.query_file_type (0) == FileType.DIRECTORY)
				Button = PopupButton.RIGHT | PopupButton.LEFT;
		}
		
		~FileDockItem ()
		{
			Prefs.notify["Launcher"].disconnect (handle_launcher_changed);
			Prefs.deleted.disconnect (handle_deleted);
		}
		
		protected override void draw_icon (DockSurface surface)
		{
			if (Icon != DEFAULT_ICON) {
				base.draw_icon (surface);
				return;
			}
			
			var width = surface.Width;
			var height = surface.Height;
			var radius = 3 + 6 * height / (128 - 48);
			
			surface.Context.move_to (radius, 0.5);
			surface.Context.arc (width - radius - 0.5, radius + 0.5, radius, Math.PI * 1.5, Math.PI * 2.0);
			surface.Context.arc (width - radius - 0.5, height - radius - 0.5, radius, 0, Math.PI * 0.5);
			surface.Context.arc (radius + 0.5, height - radius - 0.5, radius, Math.PI * 0.5, Math.PI);
			surface.Context.arc (radius + 0.5, radius + 0.5, radius, Math.PI, Math.PI * 1.5);
			
			surface.Context.set_source_rgba (1, 1, 1, 0.6);
			surface.Context.set_line_width (1);
			surface.Context.stroke_preserve ();
			
			var rg = new Pattern.radial (width / 2, height, height / 8, width / 2, height, height);
			rg.add_color_stop_rgba (0, 0, 0, 0, 1);
			rg.add_color_stop_rgba (1, 0, 0, 0, 0.6);
			
			surface.Context.set_source (rg);
			surface.Context.fill ();
			
			HashMap<string, string> icons = new HashMap<string, string> (str_hash, str_equal);
			ArrayList<string> keys = new ArrayList<string> ();
			
			foreach (var file in get_files ()) {
				string icon, text;
				
				if (file.get_basename ().has_suffix (".desktop")) {
					ApplicationDockItem.parse_launcher (file.get_path (), out icon, out text);
				} else {
					icon = DrawingService.get_icon_from_file (file) ?? "";
					text = file.get_basename ();
				}
				
				icons.set (text, icon);
				keys.add (text);
			}
			
			var pos = 0;
			width = (width - 3 * radius) / 2;
			height = (height - 3 * radius) / 2;
			
			keys.sort ((CompareFunc) strcmp);
			foreach (string s in keys) {
				var x = pos % 2;
				int y = pos / 2;
				
				if (++pos > 4)
					break;
				
				var pbuf = DrawingService.load_icon (icons.get (s), width, height);
				cairo_set_source_pixbuf (surface.Context, pbuf, x * (width + radius) + radius, y * (height + radius) + radius);
				surface.Context.paint ();
			}
		}
		
		void handle_launcher_changed ()
		{
			OwnedFile = File.new_for_path (Prefs.Launcher);
			
			launcher_changed ();
		}
		
		public override void launch ()
		{
			Services.System.open (OwnedFile);
			ClickedAnimation = ClickAnimation.BOUNCE;
			LastClicked = new DateTime.now_utc ();
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
			if (OwnedFile.query_file_type (0) == FileType.DIRECTORY)
				return get_dir_menu_items ();
			
			return get_file_menu_items ();
		}
		
		ArrayList<MenuItem> get_dir_menu_items ()
		{
			ArrayList<MenuItem> items = new ArrayList<MenuItem> ();
		
			HashMap<string, MenuItem> menu_items = new HashMap<string, MenuItem> (str_hash, str_equal);
			ArrayList<string> keys = new ArrayList<string> ();
			
			foreach (var file in get_files ()) {
				if (file.get_basename ().has_suffix (".desktop")) {
					string icon, text;
					ApplicationDockItem.parse_launcher (file.get_path (), out icon, out text);
					
					var item = create_menu_item (text, icon);
					item.activate.connect (() => {
						Services.System.launch (file);
						ClickedAnimation = ClickAnimation.BOUNCE;
						LastClicked = new DateTime.now_utc ();
					});
					menu_items.set (text, item);
					keys.add (text);
				} else {
					var icon = DrawingService.get_icon_from_file (file) ?? "";
					
					var item = create_menu_item (file.get_basename (), icon);
					item.activate.connect (() => {
						Services.System.open (file);
						ClickedAnimation = ClickAnimation.BOUNCE;
						LastClicked = new DateTime.now_utc ();
					});
					menu_items.set (file.get_basename (), item);
					keys.add (file.get_basename ());
				}
			}
			
			keys.sort ((CompareFunc) strcmp);
			foreach (string s in keys)
				items.add (menu_items.get (s));
			
			items.add (new SeparatorMenuItem ());
			
			var item = create_menu_item (_("_Open in File Browser"), "gtk-open");
			item.activate.connect (() => {
				launch ();
			});
			items.add (item);
			
			return items;
		}
		
		ArrayList<MenuItem> get_file_menu_items ()
		{
			ArrayList<MenuItem> items = new ArrayList<MenuItem> ();
			
			var item = create_menu_item (_("_Open"), "gtk-open");
			item.activate.connect (launch);
			items.add (item);
			
			item = create_menu_item (_("Open Containing _Folder"), "folder");
			item.activate.connect (() => {
				Services.System.open (OwnedFile.get_parent ());
				ClickedAnimation = ClickAnimation.BOUNCE;
				LastClicked = new DateTime.now_utc ();
			});
			items.add (item);
			
			return items;
		}
		
		ArrayList<File> get_files ()
		{
			ArrayList<File> files = new ArrayList<File> ();
			
			try {
				var enumerator = OwnedFile.enumerate_children (FILE_ATTRIBUTE_STANDARD_NAME + ","
					+ FILE_ATTRIBUTE_STANDARD_IS_HIDDEN + ","
					+ FILE_ATTRIBUTE_ACCESS_CAN_READ, 0);
				
				FileInfo info;
				
				while ((info = enumerator.next_file ()) != null) {
					if (info.get_is_hidden ())
						continue;
				
					files.add (OwnedFile.get_child (info.get_name ()));
				}
			} catch { }
			
			return files;
		}
	}
}
