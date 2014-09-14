//
//  Copyright (C) 2011-2012 Robert Dyer, Rico Tzschichholz
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

using Plank.Drawing;

namespace Plank.Items
{
	/**
	 * What type of animation to perform when an item is or was interacted with.
	 */
	public enum Animation
	{
		/**
		 * No animation.
		 */
		NONE,
		/**
		 * Bounce the icon.
		 */
		BOUNCE,
		/**
		 * Darken the icon, then restore it.
		 */
		DARKEN,
		/**
		 * Brighten the icon, then restore it.
		 */
		LIGHTEN
	}
	
	/**
	 * What mouse button pops up the context menu on an item.
	 * Can be multiple buttons.
	 */
	[Flags]
	public enum PopupButton
	{
		/**
		 * No button pops up the context.
		 */
		NONE = 1 << 0,
		/**
		 * Left button pops up the context.
		 */
		LEFT = 1 << 1,
		/**
		 * Middle button pops up the context.
		 */
		MIDDLE = 1 << 2,
		/**
		 * Right button pops up the context.
		 */
		RIGHT = 1 << 3;
		
		/**
		 * Convenience method to map {@link Gdk.EventButton} to this enum.
		 *
		 * @param event the event to map
		 * @return the PopupButton representation of the event
		 */
		public static PopupButton from_event_button (Gdk.EventButton event)
		{
			switch (event.button) {
			default:
			case 1:
				return PopupButton.LEFT;
			
			case 2:
				return PopupButton.MIDDLE;
			
			case 3:
				return PopupButton.RIGHT;
			}
		}
	}
	
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
		 * Whether the item is currently visible on the dock.
		 */
		public bool IsVisible { get; set; default = true; }
		
		/**
		 * The buttons this item shows popup menus for.
		 */
		public PopupButton Button { get; protected set; default = PopupButton.RIGHT; }
		
		/**
		 * The animation to show for the item's last click event.
		 */
		public Animation ClickedAnimation { get; protected set; default = Animation.NONE; }
		
		/**
		 * The animation to show for the item's last hover event.
		 */
		public Animation HoveredAnimation { get; protected set; default = Animation.NONE; }
		
		/**
		 * The animation to show for the item's last scroll event.
		 */
		public Animation ScrolledAnimation { get; protected set; default = Animation.NONE; }
		
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
		 * Called when an item is clicked on.
		 *
		 * @param button the button clicked
		 * @param mod the modifiers
		 */
		public void clicked (PopupButton button, Gdk.ModifierType mod)
		{
			ClickedAnimation = on_clicked (button, mod);
			LastClicked = GLib.get_monotonic_time ();
		}
		
		/**
		 * Called when an item is clicked on.
		 *
		 * @param button the button clicked
		 * @param mod the modifiers
		 * @return which type of animation to trigger
		 */
		protected virtual Animation on_clicked (PopupButton button, Gdk.ModifierType mod)
		{
			return Animation.NONE;
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
		 */
		protected virtual Animation on_hovered ()
		{
			return Animation.LIGHTEN;
 		}
		
		/**
		 * Called when an item is scrolled over.
		 *
		 * @param direction the scroll direction
		 * @param mod the modifiers
		 */
		public void scrolled (Gdk.ScrollDirection direction, Gdk.ModifierType mod)
		{
			ScrolledAnimation = on_scrolled (direction, mod);
		}
		
		/**
		 * Called when an item is scrolled over.
		 *
		 * @param direction the scroll direction
		 * @param mod the modifiers
		 * @return which type of animation to trigger
		 */
		protected virtual Animation on_scrolled (Gdk.ScrollDirection direction, Gdk.ModifierType mod)
		{
			LastScrolled = GLib.get_monotonic_time ();
			return Animation.NONE;
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
			return "dockelement%d".printf ((int) this);
		}
		
		/**
		 * Returns a unique URI for this dock element.
		 *
		 * @return a unique URI for this dock element
		 */
		public string as_uri ()
		{
			return "plank://" + unique_id ();
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
