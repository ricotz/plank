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

using Gee;

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
		public File launchers_folder { get; construct; }
		
		public DockPreferences prefs { get; construct; }
		
		public DragManager drag_manager { get; protected set; }
		public HideManager hide_manager { get; protected set; }
		public HoverWindow hover { get; protected set; }
		public PositionManager position_manager { get; protected set; }
		public DockRenderer renderer { get; protected set; }
		public DockWindow window { get; protected set; }
		
		DefaultDockItemProvider? default_provider;
		ArrayList<DockItemProvider> item_providers;
		
		public ArrayList<DockItemProvider> Providers {
			get {
				return item_providers;
			}
		}
		
		public ArrayList<DockItem> Items {
			owned get {
				var all_items = new ArrayList<DockItem> ();
				foreach (var provider in item_providers) {
					var items = provider.Items;
					all_items.add_all (items);
				}
				return all_items;
			}
		}
		
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
			launchers_folder = config_folder.get_child ("launchers");
			Factory.item_factory.launchers_dir = launchers_folder;
			
			item_providers = new ArrayList<DockItemProvider> ();
			
			position_manager = new PositionManager (this);
			renderer = new DockRenderer (this);
			drag_manager = new DragManager (this);
			hide_manager = new HideManager (this);
			hover = new HoverWindow (this);
			window = new DockWindow (this);
		}
		
		~DockController ()
		{
			foreach (var provider in item_providers)
				disconnect_provider (provider);
			
			item_providers.clear ();
		}
		
		/**
		 * Initialize this controller.
		 * Call this when added at least one DockItemProvider otherwise the
		 * {@link DefaultDockItemProvider} will be added by default.
		 */
		public void initialize ()
		{
			if (item_providers.size <= 0)
				add_default_provider ();
			
			position_manager.initialize ();
			renderer.initialize ();
			drag_manager.initialize ();
			hide_manager.initialize ();
			
			window.show_all ();
		}
		
		/**
		 * Reset internal buffers of all providers.
		 */
		public void reset_provider_buffers ()
		{
			foreach (var provider in item_providers)
				provider.reset_item_buffers ();
		}
		
		public void add_default_provider ()
		{
			if (default_provider == null) {
				default_provider = new DefaultDockItemProvider (prefs, launchers_folder);
				add_provider (default_provider);
			}
		}
		
		public void add_provider (DockItemProvider provider)
		{
			if (item_providers.contains (provider)) {
				critical ("Provider already exists in this dock-controller.");
				return;
			}
			
			item_providers.add (provider);
			update_first_item_positions ();
			
			connect_provider (provider);
		}
		
		public void remove_provider (DockItemProvider provider)
		{
			if (!item_providers.contains (provider)) {
				critical ("Provider does not exist in this dock-controller.");
				return;
			}
			
			disconnect_provider (provider);
			
			item_providers.remove (provider);
			update_first_item_positions ();
		}
		
		void connect_provider (DockItemProvider provider)
		{
			provider.item_position_changed.connect (item_position_changed);
			provider.item_state_changed.connect (item_state_changed);
			provider.items_changed.connect (items_changed);
			
			unowned ApplicationDockItemProvider? app_provider = (provider as ApplicationDockItemProvider);
			if (app_provider != null)
				app_provider.item_window_added.connect (window.update_icon_region);
		}
		
		void disconnect_provider (DockItemProvider provider)
		{
			provider.item_position_changed.disconnect (item_position_changed);
			provider.item_state_changed.disconnect (item_state_changed);
			provider.items_changed.disconnect (items_changed);
			
			unowned ApplicationDockItemProvider? app_provider = (provider as ApplicationDockItemProvider);
			if (app_provider != null)
				app_provider.item_window_added.disconnect (window.update_icon_region);
		}
		
		void update_first_item_positions ()
		{
			var current_pos = 0;
			foreach (var provider in item_providers) {
				provider.FirstItemPosition = current_pos;
				current_pos += provider.Items.size;
			}
		}
		
		void items_changed (DockItemProvider provider, Gee.List<DockItem> added, Gee.List<DockItem> removed)
		{
			if (prefs.Alignment != Gtk.Align.FILL)
				position_manager.reset_caches (renderer.theme);
			position_manager.update_regions ();
			update_first_item_positions ();
		}
		
		void item_position_changed (DockItemProvider provider)
		{
			renderer.animated_draw ();
		}
		
		void item_state_changed (DockItemProvider provider)
		{
			renderer.animated_draw ();
		}
	}
}
