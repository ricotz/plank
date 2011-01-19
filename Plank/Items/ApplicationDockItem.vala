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

using Gdk;

using Plank.Services.Logging;

namespace Plank.Items
{
	public class ApplicationDockItem : DockItem
	{
		public bool ValidItem {
			get { return File.new_for_path (Prefs.Launcher).query_exists (); }
		}
		
		public ApplicationDockItem (string dockitem)
		{
			Prefs = new DockItemPreferences.with_file (dockitem);
			
			load_from_launcher ();
			
			try {
				monitor = File.new_for_path (Prefs.Launcher).monitor (0);
				monitor.set_rate_limit (500);
				monitor.changed.connect (launcher_changed);
			} catch {
				Logger.warn<ApplicationDockItem> ("Unable to watch the launcher file '%s'".printf (Prefs.Launcher));
			}
		}
		
		FileMonitor monitor;
		
		void launcher_changed (File f, File? other, FileMonitorEvent event)
		{
			if ((event & FileMonitorEvent.CHANGES_DONE_HINT) == 0 &&
				(event & FileMonitorEvent.DELETED) == 0)
				return;
			
			Logger.debug<ApplicationDockItem> ("Launcher file '%s' changed, reloading".printf (Prefs.Launcher));
			load_from_launcher ();
		}
		
		void load_from_launcher ()
		{
			try {
				KeyFile file = new KeyFile ();
				file.load_from_file (Prefs.Launcher, 0);
				
				Icon = file.get_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_ICON);
				Text = file.get_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_NAME);
			} catch { }
		}
	}
}
