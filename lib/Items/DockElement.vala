//
//  Copyright (C) 2011-2012 Robert Dyer, Rico Tzschichholz
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
	 * The base class for all dock elements.
	 */
	public abstract class DockElement : GLib.Object
	{
		/**
		 * Signal fired when the dock element needs redrawn.
		 */
		public signal void needs_redraw ();
		
		/**
		 * The dock element's container which it is added too (if any).
		 */
		public DockContainer? Container { get; set; default = null; }
		
		/**
		 * The dock item's text.
		 */
		public string Text { get; set; default = ""; }
		
		/**
		 * Whether the item is currently hidden on the dock.
		 * If TRUE it will be drawn and does consume space.
		 * If FALSE it will not be drawn and does not consume space.
		 */
		public bool IsAttached { get; set; default = true; }
		
		/**
		 * Whether the item is currently visible on the dock.
		 * If TRUE it will be drawn and does consume space.
		 * If FALSE it will not be drawn and does consume space.
		 */
		public bool IsVisible { get; set; default = true; }
		
		/**
		 * The buttons this item shows popup menus for.
		 */
		public PopupButton Button { get; protected set; default = PopupButton.RIGHT; }
		
		/**
		 * The animation to show for the item's last click event.
		 */
		public AnimationType ClickedAnimation { get; protected set; default = AnimationType.NONE; }
		
		/**
		 * The animation to show for the item's last hover event.
		 */
		public AnimationType HoveredAnimation { get; protected set; default = AnimationType.NONE; }
		
		/**
		 * The animation to show for the item's last scroll event.
		 */
		public AnimationType ScrolledAnimation { get; protected set; default = AnimationType.NONE; }
		
		/**
		 * The time the item was added to the dock.
		 */
		public int64 AddTime { get; set; }
		
		/**
		 * The time the item was removed from the dock.
		 */
		public int64 RemoveTime { get; set; }
		
		/**
		 * The last time the item was clicked.
		 */
		public int64 LastClicked { get; protected set; }
		
		/**
		 * The last time the item was hovered.
		 */
		public int64 LastHovered { get; protected set; }
		
		/**
		 * The last time the item was scrolled.
		 */
		public int64 LastScrolled { get; protected set; }
		
		/**
		 * The last time the item changed its urgent status.
		 */
		public int64 LastUrgent { get; protected set; }
		
		/**
		 * The last time the item changed its active status.
		 */
		public int64 LastActive { get; protected set; }
		
		/**
		 * The last time the item changed its position.
		 */
		public int64 LastMove { get; protected set; }
		
		/**
		 * The last time the item was valid.
		 */
		public int64 LastValid { get; protected set; }
		
		/**
		 * Called when an item is clicked on.
		 *
		 * @param button the button clicked
		 * @param mod the modifiers
		 * @param event_time the timestamp of the event triggering this action
		 */
		public void clicked (PopupButton button, Gdk.ModifierType mod, uint32 event_time)
		{
			ClickedAnimation = on_clicked (button, mod, event_time);
			LastClicked = GLib.get_monotonic_time ();
		}
		
		/**
		 * Called when an item is clicked on.
		 *
		 * @param button the button clicked
		 * @param mod the modifiers
		 * @param event_time the timestamp of the event triggering this action
		 * @return which type of animation to trigger
		 */
		protected virtual AnimationType on_clicked (PopupButton button, Gdk.ModifierType mod, uint32 event_time)
		{
			return AnimationType.NONE;
		}
		
		/**
		 * Called when an item gets hovered.
		 */
		public void hovered ()
		{
			HoveredAnimation = on_hovered ();
			LastHovered = GLib.get_monotonic_time ();
		}
		
		/**
		 * Called when an item gets hovered.
		 *
		 * @return which type of animation to trigger
		 */
		protected virtual AnimationType on_hovered ()
		{
			return AnimationType.LIGHTEN;
 		}
		
		/**
		 * Called when an item is scrolled over.
		 *
		 * @param direction the scroll direction
		 * @param mod the modifiers
		 * @param event_time the timestamp of the event triggering this action
		 */
		public void scrolled (Gdk.ScrollDirection direction, Gdk.ModifierType mod, uint32 event_time)
		{
			ScrolledAnimation = on_scrolled (direction, mod, event_time);
		}
		
		/**
		 * Called when an item is scrolled over.
		 *
		 * @param direction the scroll direction
		 * @param mod the modifiers
		 * @param event_time the timestamp of the event triggering this action
		 * @return which type of animation to trigger
		 */
		protected virtual AnimationType on_scrolled (Gdk.ScrollDirection direction, Gdk.ModifierType mod, uint32 event_time)
		{
			LastScrolled = GLib.get_monotonic_time ();
			return AnimationType.NONE;
		}
		
		/**
		 * Get the dock which this element is part of
		 *
		 * @return the dock-controller of this element, or null
		 */
		public unowned DockController? get_dock ()
		{
			unowned DockContainer? container = Container;
			
			while (container != null) {
				if (container is DockController)
					return (DockController) container;
				
				container = container.Container;
			}
			
			return null;
		}
		
		/**
		 * Returns a list of the item's menu items.
		 *
		 * @return the item's menu items
		 */
		public virtual Gee.ArrayList<Gtk.MenuItem> get_menu_items ()
		{
			return new Gee.ArrayList<Gtk.MenuItem> ();
		}
		
		/**
		 * The item's text for drop actions.
		 *
		 * @return the item's drop-text
		 */
		public virtual string get_drop_text ()
		{
			return "";
		}
		
		/**
		 * Returns if this item can be removed from the dock.
		 *
		 * @return if this item can be removed from the dock
		 */
		public virtual bool can_be_removed ()
		{
			return true;
		}
		
		/**
		 * Returns if the item accepts a drop of the given URIs.
		 *
		 * @param uris the URIs to check
		 * @return if the item accepts a drop of the given URIs
		 */
		public virtual bool can_accept_drop (Gee.ArrayList<string> uris)
		{
			return false;
		}
		
		/**
		 * Accepts a drop of the given URIs.
		 *
		 * @param uris the URIs to accept
		 * @return if the item accepted a drop of the given URIs
		 */
		public virtual bool accept_drop (Gee.ArrayList<string> uris)
		{
			return false;
		}
		
		/**
		 * Returns a unique ID for this dock item.
		 *
		 * @return a unique ID for this dock element
		 */
		public virtual string unique_id ()
		{
			// TODO this is a unique ID, but it is not stable!
			// do we still need stable IDs?
			return "dockelement%p".printf (this);
		}
		
		/**
		 * Returns a unique URI for this dock element.
		 *
		 * @return a unique URI for this dock element
		 */
		public string as_uri ()
		{
			return "plank://%s".printf (unique_id ());
		}
		
		/**
		 * Resets the buffers for this element.
		 */
		public abstract void reset_buffers ();
		
		/**
		 * Creates a new menu item.
		 *
		 * @param title the title of the menu item
		 * @param icon the icon of the menu item
		 * @param force_show_icon whether to force showing the icon
		 * @return the new menu item
		 */
		protected static Gtk.MenuItem create_menu_item (string title, string? icon = null, bool force_show_icon = false)
		{
			if (icon == null || icon == "")
				return new Gtk.MenuItem.with_mnemonic (title);
			
			int width, height;
			Gtk.icon_size_lookup (Gtk.IconSize.MENU, out width, out height);
			
			var item = new Gtk.ImageMenuItem.with_mnemonic (title);
			item.set_image (new Gtk.Image.from_pixbuf (DrawingService.load_icon (icon, width, height)));
			if (force_show_icon)
				item.always_show_image = true;
			
			return item;
		}
		
		/**
		 * Creates a new menu item.
		 *
		 * @param title the title of the menu item
		 * @param pixbuf the icon of the menu item
		 * @param force_show_icon whether to force showing the icon
		 * @return the new menu item
		 */
		protected static Gtk.MenuItem create_menu_item_with_pixbuf (string title, owned Gdk.Pixbuf pixbuf, bool force_show_icon = false)
		{
			int width, height;
			Gtk.icon_size_lookup (Gtk.IconSize.MENU, out width, out height);
			
			if (width != pixbuf.width || height != pixbuf.height)
				pixbuf = DrawingService.ar_scale (pixbuf, width, height);
			
			var item = new Gtk.ImageMenuItem.with_mnemonic (title);
			item.set_image (new Gtk.Image.from_pixbuf (pixbuf));
			if (force_show_icon)
				item.always_show_image = true;
			
			return item;
		}
	}
}
