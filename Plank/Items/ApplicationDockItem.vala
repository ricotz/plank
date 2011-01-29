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
			
			load_from_launcher ();
			update_app ();
			start_monitor ();
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
	}
}
