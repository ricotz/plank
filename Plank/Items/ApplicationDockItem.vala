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
using Gtk;

using Plank.Drawing;
using Plank.Services;
using Plank.Services.Windows;

namespace Plank.Items
{
	public class ApplicationDockItem : DockItem
	{
		protected ApplicationDockItem ()
		{
		}
		
		public ApplicationDockItem.with_dockitem (string dockitem)
		{
			Prefs = new DockItemPreferences.with_file (dockitem);
			if (!ValidItem)
				return;
			
			if (is_launcher ()) {
				load_from_launcher ();
				update_app ();
				start_monitor ();
			} else {
				var file = File.new_for_path (Prefs.Launcher);
				Icon = DrawingService.get_icon_from_file (file) ?? "folder";
				Text = file.get_basename ();
				Button = PopupButton.RIGHT | PopupButton.LEFT;
			}
		}
		
		protected FileMonitor monitor;
		
		protected void start_monitor ()
		{
			try {
				monitor = File.new_for_path (Prefs.Launcher).monitor (0);
				monitor.set_rate_limit (500);
				monitor.changed.connect (monitor_changed);
			} catch {
				Logger.warn<ApplicationDockItem> ("Unable to watch the launcher file '%s'".printf (Prefs.Launcher));
			}
		}
		
		protected void monitor_changed (File f, File? other, FileMonitorEvent event)
		{
			if ((event & FileMonitorEvent.CHANGES_DONE_HINT) == 0 &&
				(event & FileMonitorEvent.DELETED) == 0)
				return;
			
			Logger.debug<ApplicationDockItem> ("Launcher file '%s' changed, reloading".printf (Prefs.Launcher));
			load_from_launcher ();
		}
		
		protected void load_from_launcher ()
		{
			string icon, text;
			parse_launcher (Prefs.Launcher, out icon, out text);
			Icon = icon;
			Text = text;
		}
		
		protected void parse_launcher (string launcher, out string icon, out string text)
		{
			try {
				KeyFile file = new KeyFile ();
				file.load_from_file (launcher, 0);
				
				icon = file.get_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_ICON);
				text = file.get_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_NAME);
			} catch {
				icon = "";
				text = "";
			}
		}
		
		public override List<MenuItem> get_menu_items ()
		{
			if (is_launcher () || is_window ())
				return base.get_menu_items ();
			
			List<MenuItem> items = new List<MenuItem> ();
			
			File dir = File.new_for_path (Prefs.Launcher);
			try {
				var enumerator = dir.enumerate_children (FILE_ATTRIBUTE_STANDARD_NAME + ","
					+ FILE_ATTRIBUTE_STANDARD_IS_HIDDEN + ","
					+ FILE_ATTRIBUTE_ACCESS_CAN_READ, 0);
				
				FileInfo info;
				HashTable<string, MenuItem> files = new HashTable<string, MenuItem> (str_hash, str_equal);
				List<string> keys = new List<string> ();
				
				while ((info = enumerator.next_file ()) != null) {
					if (info.get_is_hidden ())
						continue;
				
					var file = dir.get_child (info.get_name ());
					
					if (info.get_name ().has_suffix (".desktop")) {
						string icon, text;
						parse_launcher (file.get_path (), out icon, out text);
						
						var item = add_menu_item (items, text, icon);
						item.activate.connect (() => {
							Services.System.launch (file, {});
							ClickedAnimation = ClickAnimation.BOUNCE;
							LastClicked = new DateTime.now_utc ();
						});
						files.insert (text, item);
						keys.append (text);
					} else {
						var icon = DrawingService.get_icon_from_file (file) ?? "";
						
						var item = add_menu_item (items, info.get_name (), icon);
						item.activate.connect (() => {
							Services.System.open (file);
							ClickedAnimation = ClickAnimation.BOUNCE;
							LastClicked = new DateTime.now_utc ();
						});
						files.insert (info.get_name (), item);
						keys.append (info.get_name ());
					}
				}
				
				keys.sort (strcmp);
				foreach (string s in keys)
					items.append (files.lookup (s));
			} catch { }
			
			return items;
		}
	}
}
