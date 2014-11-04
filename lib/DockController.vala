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
	 *
	 * All needed controlling parts will be created and initialized.
	 */
	public class DockController : DockContainer
	{
		public File config_folder { get; construct; }
		public File launchers_folder { get; construct; }
		
		public DockPreferences prefs { get; construct; }
		
		public DragManager drag_manager { get; protected set; }
		public HideManager hide_manager { get; protected set; }
		public PositionManager position_manager { get; protected set; }
		public DockRenderer renderer { get; protected set; }
		public DockWindow window { get; protected set; }
		
		ApplicationDockItemProvider? default_provider;
		Gee.ArrayList<unowned DockItem> items;
		
		/**
		 * Ordered list of all visible items on this dock
		 */
		public Gee.ArrayList<unowned DockItem> Items {
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
			// Make sure our config-directory exists
			Paths.ensure_directory_exists (config_folder);
			
			Logger.verbose ("DockController (config_folder = %s)", config_folder.get_path ());
			
			Object (config_folder : config_folder,
				prefs : new DockPreferences.with_file (config_folder.get_child ("settings")));
		}
		
		construct
		{
			launchers_folder = config_folder.get_child ("launchers");
			Factory.item_factory.launchers_dir = launchers_folder;
			
			items = new Gee.ArrayList<unowned DockItem> ();
			
			prefs.notify["PinnedOnly"].connect (update_default_provider);
			
			position_manager = new PositionManager (this);
			drag_manager = new DragManager (this);
			hide_manager = new HideManager (this);
			window = new DockWindow (this);
			renderer = new DockRenderer (this, window);
		}
		
		~DockController ()
		{
			prefs.notify["PinnedOnly"].disconnect (update_default_provider);
			
			items.clear ();
		}
		
		/**
		 * Initialize this controller.
		 * Call this when added at least one DockItemProvider otherwise the
		 * {@link Plank.Items.DefaultApplicationDockItemProvider} will be added by default.
		 */
		public void initialize ()
		{
			if (internal_items.size <= 0)
				add_default_provider ();
			
			position_manager.initialize ();
			drag_manager.initialize ();
			hide_manager.initialize ();
			renderer.initialize ();
			
			window.show_all ();
		}
		
		/**
		 * Add the default provider which is an instance of
		 * {@link Plank.Items.DefaultApplicationDockItemProvider} 
		 */
		public void add_default_provider ()
		{
			if (default_provider != null)
				return;
			
			Logger.verbose ("DockController.add_default_provider ()");
			default_provider = get_default_provider ();
			
			add_item (default_provider);
		}
		
		ApplicationDockItemProvider get_default_provider ()
		{
			ApplicationDockItemProvider provider;
			
			// If we made the default-launcher-directory,
			// assume a first run and pre-populate with launchers
			if (Paths.ensure_directory_exists (launchers_folder)) {
				debug ("Adding default dock items...");
				Factory.item_factory.make_default_items ();
				debug ("done.");
			}
			
			if (prefs.PinnedOnly)
				provider = new ApplicationDockItemProvider (launchers_folder);
			else
				provider = new DefaultApplicationDockItemProvider (prefs, launchers_folder);
			
			provider.add_items (Factory.item_factory.load_items (launchers_folder, prefs.DockItems));
			
			return provider;
		}
		
		void update_default_provider ()
		{
			// If there is no default-provider we must not try to update it
			if (default_provider == null)
				return;
			
			var old_default_provider = default_provider;
			default_provider = get_default_provider ();
			default_provider.prepare ();
			replace_item (default_provider, old_default_provider);
			
			// Do a thorough update since we actually dropped all previous items
			// of the default-provider
			position_manager.update (renderer.theme);
			window.update_icon_regions ();
		}
		
		protected override void connect_element (DockElement element)
		{
			unowned DockItemProvider? provider = (element as DockItemProvider);
			if (provider == null)
				return;
			
			provider.item_positions_changed.connect (handle_item_positions_changed);
			provider.item_state_changed.connect (handle_item_state_changed);
			provider.items_changed.connect (handle_items_changed);
			
			unowned ApplicationDockItemProvider? app_provider = (provider as ApplicationDockItemProvider);
			if (app_provider != null)
				app_provider.item_window_added.connect (window.update_icon_region);
		}
		
		protected override void disconnect_element (DockElement element)
		{
			unowned DockItemProvider? provider = (element as DockItemProvider);
			if (provider == null)
				return;
			
			provider.item_positions_changed.disconnect (handle_item_positions_changed);
			provider.item_state_changed.disconnect (handle_item_state_changed);
			provider.items_changed.disconnect (handle_items_changed);
			
			unowned ApplicationDockItemProvider? app_provider = (provider as ApplicationDockItemProvider);
			if (app_provider != null)
				app_provider.item_window_added.disconnect (window.update_icon_region);
		}
		
		protected override void update_visible_items ()
		{
			base.update_visible_items ();
			
			Logger.verbose ("DockController.update_visible_items ()");
			
			items.clear ();
			
			var current_pos = 0;
			foreach (var element in visible_items) {
				unowned DockContainer? container = (element as DockContainer);
				if (container == null)
					continue;
				foreach (var element2 in container.Elements) {
					unowned DockItem? item = (element2 as DockItem);
					if (item == null)
						continue;
					if (item.Position != current_pos)
						item.Position = current_pos;
					items.add (item);
					current_pos++;
				}
			}
		}
		
		void handle_items_changed (DockContainer provider, Gee.List<DockElement> added, Gee.List<DockElement> removed)
		{
			if (provider == default_provider)
				serialize_item_positions ();
			
			update_visible_items ();
			
			if (prefs.Alignment != Gtk.Align.FILL
				&& added.size != removed.size) {
				position_manager.update (renderer.theme);
			} else {
				position_manager.reset_item_caches ();
				position_manager.update_regions ();
			}
			window.update_icon_regions ();
		}
		
		void handle_item_positions_changed (DockContainer provider, Gee.List<unowned DockElement> moved_items)
		{
			if (provider == default_provider)
				serialize_item_positions ();
			
			update_visible_items ();
			
			foreach (unowned DockElement item in moved_items) {
				position_manager.reset_item_cache (item);
				unowned ApplicationDockItem? app_item = (item as ApplicationDockItem);
				if (app_item != null)
					window.update_icon_region (app_item);
			}
			renderer.animated_draw ();
		}
		
		void handle_item_state_changed (DockContainer provider)
		{
			renderer.animated_draw ();
		}
		
		void serialize_item_positions ()
		{
			if (default_provider == null)
				return;
			
			var item_list = default_provider.get_item_list_string ();
			
			if (prefs.DockItems != item_list)
				prefs.DockItems = item_list;
		}
	}
}
