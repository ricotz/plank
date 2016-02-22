//
//  Copyright (C) 2011-2013 Robert Dyer, Rico Tzschichholz
//                2014 Rico Tzschichholz
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
		 * Triggered when the collection of elements has changed.
		 *
		 * @param added the list of added elements
		 * @param removed the list of removed elements
		 */
		public signal void elements_changed (Gee.List<DockElement> added, Gee.List<DockElement> removed);
		
		/**
		 * Triggered when the state of an element changes.
		 */
		public signal void states_changed ();
		
		/**
		 * Triggered anytime element-positions were changed.
		 *
		 * @param elements the list of moved elements
		 */
		public signal void positions_changed (Gee.List<unowned DockElement> elements);
		
		/**
		 * The ordered list of the visible dock elements.
		 */
		public Gee.ArrayList<DockElement> VisibleElements {
			get {
				return visible_elements;
			}
		}
		
		/**
		 * The list of the all containing dock elements.
		 */
		public Gee.ArrayList<DockElement> Elements {
			get {
				return internal_elements;
			}
		}
		
		protected Gee.ArrayList<DockElement> visible_elements;
		protected Gee.ArrayList<DockElement> internal_elements;
		
		/**
		 * Creates a new container for dock elements.
		 */
		public DockContainer ()
		{
			Object ();
		}
		
		construct
		{
			visible_elements = new Gee.ArrayList<DockElement> ();
			internal_elements = new Gee.ArrayList<DockElement> ();
			
			connect_element (placeholder_item);
		}
		
		~DockContainer ()
		{
			disconnect_element (placeholder_item);
			
			visible_elements.clear ();
			
			var elements = new Gee.HashSet<DockElement> ();
			elements.add_all (internal_elements);
			foreach (var element in elements) {
				remove_without_signaling (element);
				element.Container = null;
			}
			internal_elements.clear ();
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
		 * Adds a dock-element to the collection.
		 *
		 * @param element the dock-element to add
		 * @param target an existing item where to put this new one at
		 * @return whether adding the item was successful
		 */
		public bool add (DockElement element, DockElement? target = null)
		{
			if (internal_elements.contains (element)) {
				critical ("Element '%s' already exists in this DockContainer.", element.Text);
				return false;
			}
			
			if (element.Container != null) {
				critical ("Element '%s' should be removed from its old DockContainer first.", element.Text);
				return false;
			}
			
			add_without_signaling (element);
			
			if (target != null && target != placeholder_item)
				move_to (element, target);
			else
				update_visible_elements ();
			
			return true;
		}
		
		/**
		 * Prepends a dock-element to the collection.
		 * So the dock-element will appear at the first position.
		 *
		 * @param element the dock-element to add
		 */
		public void prepend (DockElement element)
		{
			if (internal_elements.contains (element)) {
				critical ("Element '%s' already exists in this DockContainer.", element.Text);
				return;
			}
			
			if (element.Container != null) {
				critical ("Element '%s' should be removed from its old DockContainer first.", element.Text);
				return;
			}
			
			unowned DockContainer? container = (element as DockContainer);
			if (container != null)
				container.prepare ();
			add_without_signaling (element);
			
			DockElement? target = null;
			if (internal_elements.size > 1)
				target = internal_elements[0];
			
			if (target != null && target != element)
				move_element (internal_elements, internal_elements.size - 1, 0);
			
			update_visible_elements ();
		}
		
		/**
		 * Adds a ordered list of dock-elements to the collection.
		 *
		 * @param elements the dock-elements to add
		 * @return whether all elements were added successfully
		 */
		public bool add_all (Gee.ArrayList<DockElement> elements)
		{
			bool result = true;
			
			foreach (var element in elements) {
				if (internal_elements.contains (element)) {
					critical ("Element '%s' already exists in this DockContainer.", element.Text);
					result = false;
					continue;
				}
				
				if (element.Container != null) {
					critical ("Element '%s' should be removed from its old DockContainer first.", element.Text);
					result = false;
					continue;
				}
				
				add_without_signaling (element);
			}
			
			update_visible_elements ();
			
			return result;
		}
		
		/**
		 * Removes a dock-element from the collection.
		 *
		 * @param element the dock-element to remove
		 * @return whether removing the element was successful
		 */
		public bool remove (DockElement element)
		{
			if (!internal_elements.contains (element)) {
				critical ("Element '%s' does not exist in this DockContainer.", element.Text);
				return false;
			}
			
			remove_without_signaling (element);
			
			update_visible_elements ();
			
			return true;
		}
		
		/**
		 * Removes all given dock-elements from the collection.
		 *
		 * @param elements the dock-elements to remove
		 * @return whether removing the elements was successful
		 */
		public bool remove_all (Gee.ArrayList<DockElement> elements)
		{
			bool result = true;
			
			foreach (var element in elements) {
				if (!internal_elements.contains (element)) {
					critical ("Element '%s' does not exist in this DockContainer.", element.Text);
					result = false;
					continue;
				}
				
				remove_without_signaling (element);
			}
			
			update_visible_elements ();
			
			return result;
		}
		
		/**
		 * Clears and therefore removes all dock-elements from the collection.
		 *
		 * @return whether removing the elements was successful
		 */
		public bool clear ()
		{
			var elements = new Gee.HashSet<DockElement> ();
			elements.add_all (internal_elements);
			foreach (var element in elements) {
				remove_without_signaling (element);
				element.Container = null;
			}
			internal_elements.clear ();
			
			update_visible_elements ();
			
			return true;
		}
		
		protected virtual void update_visible_elements ()
		{
			Logger.verbose ("DockContainer.update_visible_elements ()");
			
			var old_items = new Gee.ArrayList<DockElement> ();
			old_items.add_all (visible_elements);
			
			visible_elements.clear ();
			
			foreach (var item in internal_elements)
				if (item.IsAttached)
					visible_elements.add (item);
			
			var added_items = new Gee.ArrayList<DockElement> ();
			added_items.add_all (visible_elements);
			added_items.remove_all (old_items);
			
			var removed_items = old_items;
			removed_items.remove_all (visible_elements);
			
			if (visible_elements.size <= 0)
				visible_elements.add (placeholder_item);
			
			if (added_items.size > 0 || removed_items.size > 0)
				elements_changed (added_items, removed_items);
		}
		
		/**
		 * Move an element to the position of another element.
		 * This shifts all elements which are placed between these two elements.
		 *
		 * @param move the element to move
		 * @param target the element of the new position
		 * @return whether moving the element was successful
		 */
		public virtual bool move_to (DockElement move, DockElement target)
		{
			if (move == target)
				return true;
			
			int index_move, index_target;
			
			if ((index_move = internal_elements.index_of (move)) < 0) {
				critical ("Element '%s' does not exist in this DockContainer.", move.Text);
				return false;
			}
			
			if ((index_target = internal_elements.index_of (target)) < 0) {
				critical ("Element '%s' does not exist in this DockContainer.", target.Text);
				return false;
			}
			
			move_element (internal_elements, index_move, index_target);
			
			if ((index_move = visible_elements.index_of (move)) >= 0
				&& (index_target = visible_elements.index_of (target)) >= 0) {
				var moved_items = new Gee.ArrayList<unowned DockElement> ();
				move_element (visible_elements, index_move, index_target, moved_items);
				positions_changed (moved_items);
			} else {
				update_visible_elements ();
			}
			
			return true;
		}
		
		/**
		 * Reset internal buffers of all elements.
		 */
		public override void reset_buffers ()
		{
			foreach (var item in internal_elements)
				item.reset_buffers ();
		}
		
		void add_without_signaling (DockElement element)
		{
			var add_time = GLib.get_monotonic_time ();

			unowned DockContainer? container = (element as DockContainer);
			if (container != null) {
				container.prepare ();
				foreach (var e in container.Elements)
					e.AddTime = add_time;
			}
			
			internal_elements.add (element);
			
			element.Container = this;
			element.AddTime = add_time;
			element.RemoveTime = 0;
			connect_element (element);
		}
		
		/**
		 * Replace an element with another element.
		 *
		 * @param new_element the new element
		 * @param old_element the element to be replaced
		 * @return whether replacing the element was successful
		 */
		public virtual bool replace (DockElement new_element, DockElement old_element)
		{
			if (new_element == old_element)
				return true;
			
			int index;
			
			if ((index = internal_elements.index_of (old_element)) < 0) {
				critical ("Element '%s' does not exist in this DockContainer.", old_element.Text);
				return false;
			}
			
			if (internal_elements.contains (new_element)) {
				critical ("Element '%s' already exists in this DockContainer.", new_element.Text);
				return false;
			}
			
			if (new_element.Container != null) {
				critical ("Element '%s' should be removed from its old DockContainer first.", new_element.Text);
				return false;
			}
			
			//FIXME Logger.verbose ("DockContainer.replace_element (%s[%s, %i] > %s[%s, %i])", old_element.Text, old_element.DockItemFilename, (int)old_element, new_element.Text, new_element.DockItemFilename, (int)new_element);
			
			disconnect_element (old_element);
			
			internal_elements[index] = new_element;
			old_element.Container = null;
			new_element.Container = this;
			
			new_element.AddTime = old_element.AddTime;
			new_element.RemoveTime = old_element.RemoveTime;
			//FIXME new_element.Position = old_element.Position;
			connect_element (new_element);
			
			if (visible_elements.contains (old_element))
				update_visible_elements ();
			
			return true;
		}
		
		void remove_without_signaling (DockElement element)
		{
			var remove_time = GLib.get_monotonic_time ();
			
			unowned DockContainer? container = (element as DockContainer);
			if (container != null)
				foreach (var e in container.Elements)
					e.RemoveTime = remove_time;
			
			element.RemoveTime = remove_time;
			disconnect_element (element);
			
			internal_elements.remove (element);
			element.Container = null;
		}
		
		protected abstract void connect_element (DockElement element);
		
		protected abstract void disconnect_element (DockElement element);
		
		protected static void move_element (Gee.List<DockElement> elements, int from, int to, Gee.List<unowned DockElement>? moved = null)
		{
			assert (from >= 0);
			assert (to >= 0);
			assert (from != to);
			int size = elements.size;
			assert (from < size);
			assert (to < size);

			var item = elements[from];
			if (from < to) {
				for (int i = from; i < to; i++) {
					elements[i] = elements[i + 1];
					if (moved != null)
						moved.add (elements[i]);
				}
				if (moved != null)
					moved.add (item);
			} else {
				if (moved != null)
					moved.add (item);
				for (int i = from; i > to; i--) {
					elements[i] = elements[i - 1];
					if (moved != null)
						moved.add (elements[i]);
				}
			}
			elements[to] = item;
		}
	}
}
