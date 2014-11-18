//
//  Copyright (C) 2011-2013 Robert Dyer, Rico Tzschichholz
//                2014 Rico Tzschichholz
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

using Plank.Services;

namespace Plank.Items
{
	/**
	 * A container and controller class for managing dock elements on a dock.
	 */
	public abstract class DockContainer : DockElement
	{
		protected static PlaceholderDockItem placeholder_item;
		
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
		public signal void items_changed (Gee.List<DockElement> added, Gee.List<DockElement> removed);
		
		/**
		 * Triggered when the state of an item changes.
		 */
		public signal void item_state_changed ();
		
		/**
		 * Triggered anytime item-positions were changed.
		 */
		public signal void item_positions_changed (Gee.List<unowned DockElement> items);
		
		/**
		 * The ordered list of the visible dock elements.
		 */
		public Gee.ArrayList<DockElement> Elements {
			get {
				return visible_items;
			}
		}
		
		protected Gee.ArrayList<DockElement> visible_items;
		protected Gee.ArrayList<DockElement> internal_items;
		
		/**
		 * Creates a new container for dock elements.
		 */
		public DockContainer ()
		{
			Object ();
		}
		
		construct
		{
			visible_items = new Gee.ArrayList<DockElement> ();
			internal_items = new Gee.ArrayList<DockElement> ();
			
			connect_element (placeholder_item);
		}
		
		~DockContainer ()
		{
			disconnect_element (placeholder_item);
			
			visible_items.clear ();
			
			var items = new Gee.HashSet<DockElement> ();
			items.add_all (internal_items);
			foreach (var item in items) {
				remove_item_without_signaling (item);
				item.Container = null;
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
		public void add_item (DockElement item, DockElement? target = null)
		{
			if (internal_items.contains (item)) {
				critical ("Item '%s' already exists in this DockItemProvider.", item.Text);
				return;
			}
			
			if (item.Container != null) {
				critical ("Item '%s' should be removed from its old DockItemProvider first.", item.Text);
				return;
			}
			
			unowned DockContainer? container = (item as DockContainer);
			if (container != null)
				container.prepare ();
			add_item_without_signaling (item);
			
			if (target != null && target != placeholder_item)
				move_item_to (item, target);
			else
				update_visible_items ();
		}
		
		/**
		 * Adds a ordered list of dock items to the collection.
		 *
		 * @param items the dock items to add
		 */
		public void add_items (Gee.ArrayList<DockElement> items)
		{
			foreach (var item in items) {
				if (internal_items.contains (item)) {
					critical ("Item '%s' already exists in this DockItemProvider.", item.Text);
					continue;
				}
				
				if (item.Container != null) {
					critical ("Item '%s' should be removed from its old DockItemProvider first.", item.Text);
					continue;
				}
				
				unowned DockContainer? container = (item as DockContainer);
				if (container != null)
					container.prepare ();
				add_item_without_signaling (item);
			}
			
			update_visible_items ();
		}
		
		/**
		 * Removes a dock item from the collection.
		 *
		 * @param item the dock item to remove
		 */
		public void remove_item (DockElement item)
		{
			if (!internal_items.contains (item)) {
				critical ("Item '%s' does not exist in this DockItemProvider.", item.Text);
				return;
			}
			
			remove_item_without_signaling (item);
			
			update_visible_items ();
		}
		
		protected virtual void update_visible_items ()
		{
			Logger.verbose ("DockItemProvider.update_visible_items ()");
			
			var old_items = new Gee.ArrayList<DockElement> ();
			old_items.add_all (visible_items);
			
			visible_items.clear ();
			
			foreach (var item in internal_items)
				if (item.IsVisible)
					visible_items.add (item);
			
			var added_items = new Gee.ArrayList<DockElement> ();
			added_items.add_all (visible_items);
			added_items.remove_all (old_items);
			
			var removed_items = old_items;
			removed_items.remove_all (visible_items);
			
			if (visible_items.size <= 0)
				visible_items.add (placeholder_item);
			
			if (added_items.size > 0 || removed_items.size > 0)
				items_changed (added_items, removed_items);
		}
		
		/**
		 * Move an item to the position of another item.
		 * This shifts all items which are between these two items.
		 *
		 * @param move the item to move
		 * @param target the item of the new position
		 */
		public virtual void move_item_to (DockElement move, DockElement target)
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
				var moved_items = new Gee.ArrayList<unowned DockElement> ();
				move_item (visible_items, index_move, index_target, moved_items);
				item_positions_changed (moved_items);
			} else {
				update_visible_items ();
			}
		}
		
		/**
		 * Reset internal buffers of all elements.
		 */
		public override void reset_buffers ()
		{
			foreach (var item in internal_items)
				item.reset_buffers ();
		}
		
		protected virtual void add_item_without_signaling (DockElement item)
		{
			internal_items.add (item);
			
			item.Container = this;
			item.AddTime = GLib.get_monotonic_time ();
			connect_element (item);
		}
		
		/**
		 * Replace an item with another item.
		 *
		 * @param new_item the new item
		 * @param old_item the item to be replaced
		 */
		public virtual void replace_item (DockElement new_item, DockElement old_item)
		{
			if (new_item == old_item)
				return;
			
			int index;
			
			if ((index = internal_items.index_of (old_item)) < 0) {
				critical ("Item '%s' does not exist in this DockItemProvider.", old_item.Text);
				return;
			}
			
			if (internal_items.contains (new_item)) {
				critical ("Item '%s' already exists in this DockItemProvider.", new_item.Text);
				return;
			}
			
			if (new_item.Container != null) {
				critical ("Item '%s' should be removed from its old DockItemProvider first.", new_item.Text);
				return;
			}
			
			//FIXME Logger.verbose ("DockItemProvider.replace_item (%s[%s, %i] > %s[%s, %i])", old_item.Text, old_item.DockItemFilename, (int)old_item, new_item.Text, new_item.DockItemFilename, (int)new_item);
			
			disconnect_element (old_item);
			
			internal_items[index] = new_item;
			old_item.Container = null;
			new_item.Container = this;
			
			new_item.AddTime = old_item.AddTime;
			//FIXME new_item.Position = old_item.Position;
			connect_element (new_item);
			
			if (visible_items.contains (old_item))
				update_visible_items ();
		}
		
		protected virtual void remove_item_without_signaling (DockElement item)
		{
			item.RemoveTime = GLib.get_monotonic_time ();
			disconnect_element (item);
			
			internal_items.remove (item);
			item.Container = null;
		}
		
		protected abstract void connect_element (DockElement element);
		
		protected abstract void disconnect_element (DockElement element);
		
		protected static void move_item (Gee.List<DockElement> items, int from, int to, Gee.List<unowned DockElement>? moved = null)
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
