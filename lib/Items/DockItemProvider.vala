//
//  Copyright (C) 2011-2013 Robert Dyer, Rico Tzschichholz
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

using Plank.Services;

namespace Plank.Items
{
	/**
	 * A container and controller class for managing dock items on a dock.
	 */
	public class DockItemProvider : DockElement
	{
		static PlaceholderDockItem placeholder_item;
		
		static construct
		{
			placeholder_item = new PlaceholderDockItem ();
		}
		
		/**
		 * Triggered when the items collection has changed.
		 *
		 * @param added the list of added items
		 * @param removed the list of removed items
		 */
		public signal void items_changed (Gee.List<DockItem> added, Gee.List<DockItem> removed);
		
		/**
		 * Triggered when the state of an item changes.
		 */
		public signal void item_state_changed ();
		
		/**
		 * Triggered anytime item-positions were changed.
		 */
		public signal void item_positions_changed (Gee.List<unowned DockItem> items);
		
		/**
		 * The ordered list of the visible dock items.
		 */
		public ArrayList<DockItem> Items {
			get {
				return visible_items;
			}
		}
		
		protected ArrayList<DockItem> visible_items;
		protected ArrayList<DockItem> internal_items;
		
		/**
		 * Creates a new container for dock items.
		 */
		public DockItemProvider ()
		{
			Object ();
		}
		
		construct
		{
			visible_items = new ArrayList<DockItem> ();
			internal_items = new ArrayList<DockItem> ();
			
			item_signals_connect (placeholder_item);
		}
		
		~DockItemProvider ()
		{
			item_signals_disconnect (placeholder_item);
			
			visible_items.clear ();
			
			var items = new HashSet<DockItem> ();
			items.add_all (internal_items);
			foreach (var item in items) {
				remove_item_without_signaling (item);
				item.Provider = null;
			}
			internal_items.clear ();
		}
		
		/**
		 * Do some special implementation specific preparation
		 *
		 * This is meant to called after the initial batch of items was added
		 * and the provider is about to be added to the dock.
		 */
		public virtual void prepare ()
		{
		}
		
		/**
		 * Adds a dock item to the collection.
		 *
		 * @param item the dock item to add
		 * @param target an existing item where to put this new one at
		 */
		public void add_item (DockItem item, DockItem? target = null)
		{
			if (internal_items.contains (item)) {
				critical ("Item '%s' already exists in this DockItemProvider.", item.Text);
				return;
			}
			
			if (item.Provider != null) {
				critical ("Item '%s' should be removed from its old DockItemProvider first.", item.Text);
				return;
			}
			
			add_item_without_signaling (item);
			
			if (target != null)
				move_item_to (item, target);
			else
				update_visible_items ();
		}
		
		/**
		 * Adds a ordered list of dock items to the collection.
		 *
		 * @param items the dock items to add
		 */
		public void add_items (ArrayList<DockItem> items)
		{
			foreach (var item in items) {
				if (internal_items.contains (item)) {
					critical ("Item '%s' already exists in this DockItemProvider.", item.Text);
					continue;
				}
				
				if (item.Provider != null) {
					critical ("Item '%s' should be removed from its old DockItemProvider first.", item.Text);
					continue;
				}
				
				add_item_without_signaling (item);
			}
			
			update_visible_items ();
		}
		
		/**
		 * Removes a dock item from the collection.
		 *
		 * @param item the dock item to remove
		 */
		public void remove_item (DockItem item)
		{
			if (!internal_items.contains (item)) {
				critical ("Item '%s' does not exist in this DockItemProvider.", item.Text);
				return;
			}
			
			remove_item_without_signaling (item);
			
			update_visible_items ();
		}
		
		protected void handle_item_state_changed ()
		{
			item_state_changed ();
		}
		
		protected virtual void update_visible_items ()
		{
			Logger.verbose ("DockItemProvider.update_visible_items ()");
			
			var old_items = new ArrayList<DockItem> ();
			old_items.add_all (visible_items);
			
			visible_items.clear ();
			
			foreach (var item in internal_items)
				if (item.IsVisible)
					visible_items.add (item);
			
			var added_items = new ArrayList<DockItem> ();
			added_items.add_all (visible_items);
			added_items.remove_all (old_items);
			
			var removed_items = old_items;
			removed_items.remove_all (visible_items);
			
			if (visible_items.size <= 0)
				visible_items.add (placeholder_item);
			
			if (added_items.size > 0 || removed_items.size > 0)
				items_changed (added_items, removed_items);
		}
		
		protected void handle_setting_changed ()
		{
			update_visible_items ();
		}
		
		/**
		 * Move an item to the position of another item.
		 * This shifts all items which are between these two items.
		 *
		 * @param move the item to move
		 * @param target the item of the new position
		 */
		public virtual void move_item_to (DockItem move, DockItem target)
		{
			if (move == target)
				return;
			
			int index_move, index_target;
			
			if ((index_move = internal_items.index_of (move)) < 0) {
				critical ("Item '%s' does not exist in this DockItemProvider.", move.Text);
				return;
			}
			
			if ((index_target = internal_items.index_of (target)) < 0) {
				critical ("Item '%s' does not exist in this DockItemProvider.", target.Text);
				return;
			}
			
			move_item (internal_items, index_move, index_target);
			
			if ((index_move = visible_items.index_of (move)) >= 0
				&& (index_target = visible_items.index_of (target)) >= 0) {
				var moved_items = new ArrayList<unowned DockItem> ();
				move_item (visible_items, index_move, index_target, moved_items);
				item_positions_changed (moved_items);
			} else {
				update_visible_items ();
			}
		}
		
		/**
		 * Reset internal buffers of all items.
		 */
		public void reset_item_buffers ()
		{
			foreach (var item in internal_items)
				item.reset_buffers ();
		}
		
		public virtual bool item_exists_for_uri (string uri)
		{
			foreach (var item in internal_items)
				if (item.Launcher == uri)
					return true;
			
			return false;
		}
		
		/**
		 * Adds a dock item with the given URI to the collection.
		 *
		 * @param uri the URI to add a dock item for
		 * @param target an existing item where to put this new one at
		 */
		public virtual void add_item_with_uri (string uri, DockItem? target = null)
		{
			warning ("Not implemented by default");
		}
		
		protected virtual void add_item_without_signaling (DockItem item)
		{
			internal_items.add (item);
			
			item.Provider = this;
			item.AddTime = GLib.get_monotonic_time ();
			item_signals_connect (item);
		}
		
		/**
		 * Replace an item with another item.
		 *
		 * @param new_item the new item
		 * @param old_item the item to be replaced
		 */
		public virtual void replace_item (DockItem new_item, DockItem old_item)
		{
			if (new_item == old_item)
				return;
			
			if (!internal_items.contains (old_item)) {
				critical ("Item '%s' does not exist in this DockItemProvider.", old_item.Text);
				return;
			}
			
			if (new_item.Provider != null) {
				critical ("Item '%s' should be removed from its old DockItemProvider first.", new_item.Text);
				return;
			}
			
			Logger.verbose ("DockItemProvider.replace_item (%s[%s, %i] > %s[%s, %i])", old_item.Text, old_item.DockItemFilename, (int)old_item, new_item.Text, new_item.DockItemFilename, (int)new_item);
			
			item_signals_disconnect (old_item);
			
			var index = internal_items.index_of (old_item);
			internal_items[index] = new_item;
			old_item.Provider = null;
			new_item.Provider = this;
			
			new_item.AddTime = old_item.AddTime;
			new_item.Position = old_item.Position;
			item_signals_connect (new_item);
			
			if (visible_items.index_of (old_item) >= 0)
				update_visible_items ();
		}
		
		protected virtual void remove_item_without_signaling (DockItem item)
		{
			item.RemoveTime = GLib.get_monotonic_time ();
			item_signals_disconnect (item);
			
			internal_items.remove (item);
			item.Provider = null;
		}
		
		protected virtual void item_signals_connect (DockItem item)
		{
			item.notify["Indicator"].connect (handle_item_state_changed);
			item.notify["State"].connect (handle_item_state_changed);
			item.notify["LastClicked"].connect (handle_item_state_changed);
			item.needs_redraw.connect (handle_item_state_changed);
			item.deleted.connect (handle_item_deleted);
		}
		
		protected virtual void item_signals_disconnect (DockItem item)
		{
			item.notify["Indicator"].disconnect (handle_item_state_changed);
			item.notify["State"].disconnect (handle_item_state_changed);
			item.notify["LastClicked"].disconnect (handle_item_state_changed);
			item.needs_redraw.disconnect (handle_item_state_changed);
			item.deleted.disconnect (handle_item_deleted);
		}
		
		protected virtual void handle_item_deleted (DockItem item)
		{
			remove_item (item);
		}
		
		static void move_item (Gee.List<DockItem> items, int from, int to, Gee.List<unowned DockItem>? moved = null)
		{
			assert (from >= 0);
			assert (to >= 0);
			assert (from != to);
			int size = items.size;
			assert (from < size);
			assert (to < size);

			var item = items[from];
			if (from < to) {
				for (int i = from; i < to; i++) {
					items[i] = items[i + 1];
					if (moved != null)
						moved.add (items[i]);
				}
				if (moved != null)
					moved.add (item);
			} else {
				if (moved != null)
					moved.add (item);
				for (int i = from; i > to; i--) {
					items[i] = items[i - 1];
					if (moved != null)
						moved.add (items[i]);
				}
			}
			items[to] = item;
		}
	}
}
