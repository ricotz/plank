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
using Plank.Items;
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
		public File config_folder { get; construct; }
		public DockPreferences prefs { get; construct; }
		
		public DragManager drag_manager { get; protected set; }
		public HideManager hide_manager { get; protected set; }
		public HoverWindow hover { get; protected set; }
		public ApplicationDockItemProvider items { get; protected set; }
		public PositionManager position_manager { get; protected set; }
		public DockRenderer renderer { get; protected set; }
		public DockWindow window { get; protected set; }
		
		/**
		 * Create a new DockController which manages a single dock
		 *
		 * @param config_folder the base-folder to load settings from and save them to
		 */
		public DockController (File config_folder)
		{
			Logger.verbose ("DockController (config_folder = %s)", config_folder.get_path ());
			
			Object (config_folder : config_folder,
				prefs : new DockPreferences.with_file (config_folder.get_child ("settings")));
		}
		
		construct
		{
			items = new ApplicationDockItemProvider (this, config_folder.get_child ("launchers"));
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
			
			window.show_all ();
		}
	}
}
