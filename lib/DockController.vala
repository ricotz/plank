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
using Plank.Services;

namespace Plank
{
	public const string G_RESOURCE_PATH = "/net/launchpad/plank";
	
	/**
	 * A controller class for managing a single dock.
	 */
	public class DockController : GLib.Object
	{
		public DockPreferences prefs;
		public DockItems items;
		public PositionManager position_manager;
		public DockRenderer renderer;
		public DragManager drag_manager;
		public HideManager hide_manager;
		public HoverWindow hover;
		public DockWindow window;
		public Unity unity;
		
		public DockController ()
		{
			prefs = new DockPreferences.with_filename (Factories.AbstractMain.dock_path + "/settings");
			items = new DockItems (this);
			position_manager = new PositionManager (this);
			renderer = new DockRenderer (this);
			drag_manager = new DragManager (this);
			hide_manager = new HideManager (this);
			hover = new HoverWindow (this);
			window = new DockWindow (this);
			
			position_manager.initialize ();
			renderer.initialize ();
			drag_manager.initialize ();
			hide_manager.initialize ();
			
			unity = new Unity (this);
			
			window.show_all ();
		}
	}
}
