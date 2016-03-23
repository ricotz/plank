//
//  Copyright (C) 2011 Robert Dyer
//
//  This file is part of Plank.
//
//  Plank is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Plank is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

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
		public string name { get; construct; }
		public File config_folder { get; construct; }
		public File launchers_folder { get; private set; }
		
		public DockPreferences prefs { get; construct; }
		
		public DragManager drag_manager { get; protected set; }
		public HideManager hide_manager { get; protected set; }
		public PositionManager position_manager { get; protected set; }
		public DockRenderer renderer { get; protected set; }
		public DockWindow window { get; protected set; }
		public HoverWindow hover { get; protected set; }
		
		public DockItemProvider? default_provider { get; private set; }
		
		DBusManager dbus_manager;
		Gee.ArrayList<unowned DockItem> visible_items;
		Gee.ArrayList<unowned DockItem> items;
		DockItem? dock_itself_item;
		
		/**
		 * List of all items on this dock
		 */
		public Gee.ArrayList<unowned DockItem> Items {
			get {
				return items;
			}
		}
		
		/**
		 * Ordered list of all visible items on this dock
		 */
		public Gee.ArrayList<unowned DockItem> VisibleItems {
			get {
				return visible_items;
			}
		}
		
		/**
		 * Create a new DockController which manages a single dock
		 *
		 * @param config_folder the base-folder to load settings from and save them to
		 */
		public DockController (string dock_name, File config_folder)
		{
			// Make sure our config-directory exists
			Paths.ensure_directory_exists (config_folder);
			
			debug ("Create dock '%s' (config_folder = %s)", dock_name, config_folder.get_path ());
			
			Object (name : dock_name, config_folder : config_folder, prefs : new DockPreferences (dock_name));
		}
		
		construct
		{
			launchers_folder = config_folder.get_child ("launchers");
			Factory.item_factory.launchers_dir = launchers_folder;
			
			items = new Gee.ArrayList<unowned DockItem> ();
			visible_items = new Gee.ArrayList<unowned DockItem> ();
			
			prefs.notify["Position"].connect (update_visible_elements);
			prefs.notify["ShowDockItem"].connect (update_show_dock_item);
			
			dbus_manager = new DBusManager (this);
			
			position_manager = new PositionManager (this);
			drag_manager = new DragManager (this);
			hide_manager = new HideManager (this);
			window = new DockWindow (this);
			hover = new HoverWindow ();
			renderer = new DockRenderer (this, window);
		}
		
		~DockController ()
		{
			prefs.notify["Position"].disconnect (update_visible_elements);
			prefs.notify["ShowDockItem"].disconnect (update_show_dock_item);
			
			positions_changed.disconnect (handle_positions_changed);
			states_changed.disconnect (handle_states_changed);
			elements_changed.disconnect (handle_elements_changed);
			
			items.clear ();
			visible_items.clear ();
		}
		
		/**
		 * Initialize this controller.
		 * Call this when added at least one DockItemProvider otherwise the
		 * {@link Plank.DefaultApplicationDockItemProvider} will be added by default.
		 */
		public void initialize ()
		{
			if (internal_elements.size <= 0)
				add_default_provider ();
			
			update_show_dock_item ();
			update_items ();
			
			AddTime = GLib.get_monotonic_time ();
			
			positions_changed.connect (handle_positions_changed);
			states_changed.connect (handle_states_changed);
			elements_changed.connect (handle_elements_changed);
			
			position_manager.initialize ();
			drag_manager.initialize ();
			hide_manager.initialize ();
			renderer.initialize ();
			
			window.show_all ();
		}
		
		/**
		 * Add the default provider which is an instance of
		 * {@link Plank.DefaultApplicationDockItemProvider}
		 */
		public void add_default_provider ()
		{
			if (default_provider != null)
				return;
			
			Logger.verbose ("DockController.add_default_provider ()");
			default_provider = create_default_provider ();
			
			add (default_provider);
		}
		
		DockItemProvider create_default_provider ()
		{
			DockItemProvider provider;
			
			// If we made the default-launcher-directory,
			// assume a first run and pre-populate with launchers
			if (Paths.ensure_directory_exists (launchers_folder)) {
				debug ("Adding default dock items...");
				Factory.item_factory.make_default_items ();
				debug ("done.");
			}
			
			provider = new DefaultApplicationDockItemProvider (prefs, launchers_folder);
			provider.add_all (Factory.item_factory.load_elements (launchers_folder, prefs.DockItems));
			serialize_item_positions (provider);
			
			return provider;
		}
		
		void update_show_dock_item ()
		{
			if (prefs.ShowDockItem) {
				if (dock_itself_item == null)
					dock_itself_item = Factory.item_factory.get_item_for_dock ();
				if (!internal_elements.contains (dock_itself_item))
					prepend (dock_itself_item);
			} else if (dock_itself_item != null) {
				if (internal_elements.contains (dock_itself_item))
					remove (dock_itself_item);
				dock_itself_item = null;
			}
		}
		
		protected override void connect_element (DockElement element)
		{
			unowned DockItemProvider? provider = (element as DockItemProvider);
			if (provider == null)
				return;
			
			provider.positions_changed.connect (handle_positions_changed);
			provider.states_changed.connect (handle_states_changed);
			provider.elements_changed.connect (handle_elements_changed);
			
			unowned ApplicationDockItemProvider? app_provider = (provider as ApplicationDockItemProvider);
			if (app_provider != null) {
				app_provider.item_window_added.connect (window.update_icon_region);
				Unity.get_default ().add_client (app_provider);
			}
		}
		
		protected override void disconnect_element (DockElement element)
		{
			unowned DockItemProvider? provider = (element as DockItemProvider);
			if (provider == null)
				return;
			
			provider.positions_changed.disconnect (handle_positions_changed);
			provider.states_changed.disconnect (handle_states_changed);
			provider.elements_changed.disconnect (handle_elements_changed);
			
			unowned ApplicationDockItemProvider? app_provider = (provider as ApplicationDockItemProvider);
			if (app_provider != null) {
				app_provider.item_window_added.disconnect (window.update_icon_region);
				Unity.get_default ().remove_client (app_provider);
			}
		}
		
		protected override void update_visible_elements ()
		{
			base.update_visible_elements ();
			
			Logger.verbose ("DockController.update_visible_items ()");
			
			visible_items.clear ();
			
			var current_position = 0;
			update_visible_items_recursive (this, ref current_position);
		}
		
		void update_visible_items_recursive (DockContainer container, ref int current_position)
		{
			var iterator = container.VisibleElements.bidir_list_iterator ();
			
			// Reverse dock-item-order for RTL environments if dock is placed horizontally
			if (Gtk.Widget.get_default_direction () == Gtk.TextDirection.RTL && prefs.is_horizontal_dock ()) {
				iterator.last ();
				do {
					update_visible_items_add_from_iterator (iterator, ref current_position);
				} while (iterator.previous ());
			} else {
				iterator.first ();
				do {
					update_visible_items_add_from_iterator (iterator, ref current_position);
				} while (iterator.next ());
			}
		}
		
		inline void update_visible_items_add_from_iterator (Gee.Iterator<DockElement> iterator, ref int current_position)
		{
			DockElement? element = iterator.get ();
			unowned DockItem? item = null;
			unowned DockContainer? container = null;
			
			container = (element as DockContainer);
			if (container != null) {
				update_visible_items_recursive (container, ref current_position);
				return;
			}

			item = (element as DockItem);
			if (item == null)
				return;
			
			if (item.Position != current_position)
				item.Position = current_position;
			current_position++;
			
			visible_items.add (item);
		}
		
		void update_items ()
		{
			Logger.verbose ("DockController.update_items ()");
			
			items.clear ();
			
			unowned DockItem? item = null;
			unowned DockContainer? container = null;
			
			foreach (var element in internal_elements) {
				item = (element as DockItem);
				if (item != null) {
					items.add (item);
					continue;
				}
				
				container = (element as DockContainer);
				if (container == null)
					continue;
				
				foreach (var element2 in container.Elements) {
					item = (element2 as DockItem);
					if (item == null)
						continue;
					items.add (item);
				}
			}
		}
		
		void handle_elements_changed (DockContainer container, Gee.List<DockElement> added, Gee.List<DockElement> removed)
		{
			if (container == default_provider)
				serialize_item_positions (container);
			
			// Schedule added/removed items for special animations
			renderer.animate_items (added);
			renderer.animate_items (removed);
			
			update_visible_elements ();
			update_items ();
			
			if (added.size != removed.size)
				position_manager.update (renderer.theme);
			
			window.update_icon_regions ();
			
			// FIXME Maybe add a dedicated signal
			if (container != this) {
				var empty = new Gee.ArrayList<DockElement> ();
				elements_changed (empty, empty);
			}
		}
		
		void handle_positions_changed (DockContainer container, Gee.List<unowned DockElement> moved_items)
		{
			if (container == default_provider)
				serialize_item_positions (container);
			
			update_visible_elements ();
			
			foreach (unowned DockElement item in moved_items) {
				unowned ApplicationDockItem? app_item = (item as ApplicationDockItem);
				if (app_item != null)
					window.update_icon_region (app_item);
			}
			renderer.animated_draw ();
		}
		
		void handle_states_changed (DockContainer container)
		{
			renderer.animated_draw ();
		}
		
		void serialize_item_positions (DockContainer container)
		{
			unowned ApplicationDockItemProvider? provider = (container as ApplicationDockItemProvider);
			if (provider == null)
				return;
			
			var item_list = provider.get_dockitem_filenames ();
			
			if (prefs.DockItems != item_list)
				prefs.DockItems = item_list;
		}
	}
}
