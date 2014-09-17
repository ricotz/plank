//
//  Copyright (C) 2014 Rico Tzschichholz
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
	 * A container and controller class for managing dock items.
	 */
	public class DockItemProvider : DockContainer
	{
		/**
		 * Creates a new container for dock items.
		 */
		public DockItemProvider ()
		{
			Object ();
		}
		
		public virtual bool item_exists_for_uri (string uri)
		{
			foreach (var element in internal_items) {
				unowned DockItem? item = (element as DockItem);
				if (item != null && item.Launcher == uri)
					return true;
			}
			
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
		
		protected override void connect_element (DockElement element)
		{
			unowned DockItem? item = (element as DockItem);
			if (item == null)
				return;
			
			item.notify["Indicator"].connect (handle_item_state_changed);
			item.notify["State"].connect (handle_item_state_changed);
			item.notify["LastClicked"].connect (handle_item_state_changed);
			item.needs_redraw.connect (handle_item_state_changed);
			item.deleted.connect (handle_item_deleted);
		}
		
		protected override void disconnect_element (DockElement element)
		{
			unowned DockItem? item = (element as DockItem);
			if (item == null)
				return;
			
			item.notify["Indicator"].disconnect (handle_item_state_changed);
			item.notify["State"].disconnect (handle_item_state_changed);
			item.notify["LastClicked"].disconnect (handle_item_state_changed);
			item.needs_redraw.disconnect (handle_item_state_changed);
			item.deleted.disconnect (handle_item_deleted);
		}
		
		protected void handle_item_state_changed ()
		{
			item_state_changed ();
		}
		
		protected virtual void handle_item_deleted (DockItem item)
		{
			remove_item (item);
		}
	}
}
