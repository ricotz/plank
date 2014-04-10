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
	 *
	 * All needed controlling parts will be created and initialized.
	 */
	public class DockController : GLib.Object
	{
		public File config_folder { get; construct; }
		public File launchers_folder { get; construct; }
		
		public DockPreferences prefs { get; construct; }
		
		public DragManager drag_manager { get; protected set; }
		public HideManager hide_manager { get; protected set; }
		public PositionManager position_manager { get; protected set; }
		public DockRenderer renderer { get; protected set; }
		public DockWindow window { get; protected set; }
		
		DefaultApplicationDockItemProvider? default_provider;
		ArrayList<DockItemProvider> item_providers;
		ArrayList<unowned DockItem> items;
		
		/**
		 * Ordered list of all providers on this dock
		 */
		public ArrayList<DockItemProvider> Providers {
			get {
				return item_providers;
			}
		}
		
		/**
		 * Ordered list of all visible items on this dock
		 */
		public ArrayList<unowned DockItem> Items {
			get {
				return items;
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
			items = new ArrayList<unowned DockItem> ();
			
			position_manager = new PositionManager (this);
			drag_manager = new DragManager (this);
			hide_manager = new HideManager (this);
			window = new DockWindow (this);
			renderer = new DockRenderer (this, window);
		}
		
		~DockController ()
		{
			foreach (var provider in item_providers)
				disconnect_provider (provider);
			
			item_providers.clear ();
			items.clear ();
		}
		
		/**
		 * Initialize this controller.
		 * Call this when added at least one DockItemProvider otherwise the
		 * {@link Plank.Items.DefaultApplicationDockItemProvider} will be added by default.
		 */
		public void initialize ()
		{
			if (item_providers.size <= 0)
				add_default_provider ();
			
			position_manager.initialize ();
			drag_manager.initialize ();
			hide_manager.initialize ();
			renderer.initialize ();
			
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
		
		/**
		 * Add the default provider which is an instance of
		 * {@link Plank.Items.DefaultApplicationDockItemProvider} 
		 */
		public void add_default_provider ()
		{
			if (default_provider == null) {
				default_provider = new DefaultApplicationDockItemProvider (prefs, launchers_folder);
				add_provider (default_provider);
			}
		}
		
		/**
		 * Add the given provider to this dock.
		 *
		 * @param provider the dock-provider to add
		 */
		public void add_provider (DockItemProvider provider)
		{
			if (item_providers.contains (provider)) {
				critical ("Provider already exists in this dock-controller.");
				return;
			}
			
			item_providers.add (provider);
			
			connect_provider (provider);
			
			update_items ();
		}
		
		/**
		 * Remove the given provider from this dock.
		 *
		 * @param provider the dock-provider to remove
		 */
		public void remove_provider (DockItemProvider provider)
		{
			if (!item_providers.contains (provider)) {
				critical ("Provider does not exist in this dock-controller.");
				return;
			}
			
			disconnect_provider (provider);
			
			item_providers.remove (provider);
			
			update_items ();
		}
		
		void connect_provider (DockItemProvider provider)
		{
			provider.item_positions_changed.connect (item_positions_changed);
			provider.item_state_changed.connect (item_state_changed);
			provider.items_changed.connect (items_changed);
			
			unowned ApplicationDockItemProvider? app_provider = (provider as ApplicationDockItemProvider);
			if (app_provider != null)
				app_provider.item_window_added.connect (window.update_icon_region);
		}
		
		void disconnect_provider (DockItemProvider provider)
		{
			provider.item_positions_changed.disconnect (item_positions_changed);
			provider.item_state_changed.disconnect (item_state_changed);
			provider.items_changed.disconnect (items_changed);
			
			unowned ApplicationDockItemProvider? app_provider = (provider as ApplicationDockItemProvider);
			if (app_provider != null)
				app_provider.item_window_added.disconnect (window.update_icon_region);
		}
		
		void update_items ()
		{
			Logger.verbose ("DockController.update_items ()");
			
			items.clear ();
			
			var current_pos = 0;
			foreach (var provider in item_providers) {
				foreach (var item in provider.Items) {
					if (item.Position != current_pos)
						item.Position = current_pos;
					items.add (item);
					current_pos++;
				}
			}
		}
		
		void items_changed (DockItemProvider provider, Gee.List<DockItem> added, Gee.List<DockItem> removed)
		{
			update_items ();
			
			if (prefs.Alignment != Gtk.Align.FILL
				&& added.size != removed.size)
				position_manager.reset_caches (renderer.theme);
			position_manager.update_regions ();
			window.update_icon_regions ();
		}
		
		void item_positions_changed (DockItemProvider provider, Gee.List<unowned DockItem> moved_items)
		{
			update_items ();
			
			foreach (unowned DockItem item in moved_items) {
				position_manager.reset_item_caches (item);
				unowned ApplicationDockItem? app_item = (item as ApplicationDockItem);
				if (app_item != null)
					window.update_icon_region (app_item);
			}
			renderer.animated_draw ();
		}
		
		void item_state_changed (DockItemProvider provider)
		{
			renderer.animated_draw ();
		}
	}
}
