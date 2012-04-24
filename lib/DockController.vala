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

using Plank.Factories;
using Plank.Widgets;

namespace Plank
{
	/**
	 * A controller class for managing a single dock.
	 */
	public class DockController : GLib.Object
	{
		public DockPreferences prefs;
		public DockItems items;
		public PositionManager position_manager;
		public DockRenderer renderer;
		public HideManager hide_manager;
		public HoverWindow hover;
		public DockWindow window;
		
		public DockController ()
		{
			prefs = new DockPreferences.with_filename (Factory.main.dock_path + "/settings");
			items = new DockItems ();
			position_manager = new PositionManager (this);
			renderer = new DockRenderer (this);
			hide_manager = new HideManager (this);
			hover = new HoverWindow (this);
			window = new DockWindow (this);
			
			renderer.initialize ();
			hide_manager.initialize ();
			position_manager.initialize ();
			
			window.show_all ();
		}
	}
}
