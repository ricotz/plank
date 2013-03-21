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

using Gdk;
using Gee;
using Gtk;

using Plank.Drawing;
using Plank.Services;
using Plank.Services.Windows;

namespace Plank.Items
{
	/**
	 * What item indicator to show.
	 */
	public enum IndicatorState
	{
		/**
		 * None - no windows for this item.
		 */
		NONE,
		/**
		 * Show a single indicator - there is 1 window for this item.
		 */
		SINGLE,
		/**
		 * Show multiple indicators - there are more than 1 window for this item.
		 */
		SINGLE_PLUS
	}
	
	/**
	 * The current activity state of an item.  The item has several
	 * states to track and can be in any combination of them.
	 */
	[Flags]
	public enum ItemState
	{
		/**
		 * The item is in a normal state.
		 */
		NORMAL = 1 << 0,
		/**
		 * The item is currently active (a window in the group is focused).
		 */
		ACTIVE = 1 << 1,
		/**
		 * The item is currently urgent (a window in the group has the urgent flag).
		 */
		URGENT = 1 << 2
	}
	
	/**
	 * What type of animation to perform when an item is clicked.
	 */
	public enum ClickAnimation
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
		public static PopupButton from_event_button (EventButton event)
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
	 * The base class for all dock items.
	 */
	public class DockItem : GLib.Object
	{
		/**
		 * Signal fired when the .dockitem for this item was deleted.
		 */
		public signal void deleted ();
		
		/**
		 * Signal fired when the launcher associated with the dock item changed.
		 */
		public signal void launcher_changed ();
		
		/**
		 * Signal fired when the dock item needs redrawn.
		 */
		public signal void needs_redraw ();
		
		/**
		 * The dock item's icon.
		 */
		public string Icon { get; set; default = ""; }
		
		protected Pixbuf? ForcePixbuf { get; set; default = null; }
		
		/**
		 * The dock item's text.
		 */
		public string Text { get; set; default = ""; }
		
		/**
		 * The count for the dock item.
		 */
		public int64 Count { get; set; default = 0; }
		
		/**
		 * Show the item's count or not.
		 */
		public bool CountVisible { get; set; default = false; }
		
		/**
		 * The progress for this dock item.
		 */
		public double Progress { get; set; default = 0; }
		
		/**
		 * Show the item's progress or not.
		 */
		public bool ProgressVisible { get; set; default = false; }
		
		/**
		 * The dock item's position on the dock.
		 */
		public int Position { get; set; default = -1; }
		
		/**
		 * Wether the item is currently visible on the dock.
		 */
		public bool IsVisible { get; set; default = true; }
		
		/**
		 * The buttons this item shows popup menus for.
		 */
		public PopupButton Button { get; protected set; default = PopupButton.RIGHT; }
		
		/**
		 * The item's current state.
		 */
		public ItemState State { get; protected set; default = ItemState.NORMAL; }
		
		/**
		 * The indicator shown for the item.
		 */
		public IndicatorState Indicator { get; protected set; default = IndicatorState.NONE; }
		
		/**
		 * The animation to show for the item's last click event.
		 */
		public ClickAnimation ClickedAnimation { get; protected set; default = ClickAnimation.NONE; }
		
		/**
		 * The time the item was added to the dock.
		 */
		public DateTime AddTime { get; set; default = new DateTime.from_unix_utc (0); }
		
		/**
		 * The time the item was removed from the dock.
		 */
		public DateTime RemoveTime { get; set; default = new DateTime.from_unix_utc (0); }
		
		/**
		 * The last time the item was clicked.
		 */
		public DateTime LastClicked { get; protected set; default = new DateTime.from_unix_utc (0); }
		
		/**
		 * The last time the item was scrolled.
		 */
		public DateTime LastScrolled { get; protected set; default = new DateTime.from_unix_utc (0); }
		
		/**
		 * The last time the item changed its urgent status.
		 */
		public DateTime LastUrgent { get; protected set; default = new DateTime.from_unix_utc (0); }
		
		/**
		 * The last time the item changed its active status.
		 */
		public DateTime LastActive { get; protected set; default = new DateTime.from_unix_utc (0); }
		
		/**
		 * Whether or not this item is valid for the .dockitem given.
		 */
		public virtual bool ValidItem {
			get { return File.new_for_uri (Prefs.Launcher).query_exists (); }
		}
		
		/**
		 * The average color of this item's icon.
		 */
		public Drawing.Color AverageIconColor { get; protected set; default = Drawing.Color () { R = 0.0, G = 0.0, B = 0.0, A = 0.0 }; }
		
		/**
		 * The filename of the preferences backing file.
		 */
		public string DockItemFilename {
			owned get { return Prefs.get_filename (); }
		}
		
		/**
		 * The launcher associated with this item.
		 */
		public string Launcher {
			get { return Prefs.Launcher; }
		}
		
		/**
		 * The underlying preferences for this item.
		 */
		public DockItemPreferences Prefs { get; construct; }
		
		DockSurface? surface = null;
		
		/**
		 * Creates a new dock item.
		 */
		public DockItem ()
		{
			GLib.Object (Prefs: new DockItemPreferences ());
		}
		
		construct
		{
			Prefs.deleted.connect (handle_deleted);
			Gtk.IconTheme.get_default ().changed.connect (icon_theme_changed);
			notify["Icon"].connect (reset_icon_buffer);
			notify["ForcePixbuf"].connect (reset_icon_buffer);
		}
		
		~DockItem ()
		{
			Prefs.deleted.disconnect (handle_deleted);
			Gtk.IconTheme.get_default ().changed.disconnect (icon_theme_changed);
			notify["Icon"].disconnect (reset_icon_buffer);
			notify["ForcePixbuf"].disconnect (reset_icon_buffer);
		}
		
		/**
		 * Signal handler called when the underlying preferences file is deleted.
		 */
		protected void handle_deleted ()
		{
			deleted ();
		}
		
		/**
		 * Deletes the underlying preferences file.
		 */
		public void delete ()
		{
			Prefs.delete ();
		}
		
		/**
		 * Resets the buffer for this item's icon and requests a redraw.
		 */
		protected void reset_icon_buffer ()
		{
			surface = null;
			
			needs_redraw ();
		}
		
		void icon_theme_changed ()
		{
			// Put Gtk.IconTheme.changed emmitted signals in idle queue to avoid 
			// race conditions with concurrent handles
			Idle.add (() => {
				reset_icon_buffer ();
				return false;
			});
		}
		
		DockSurface get_surface (int width, int height, DockSurface model)
		{
			if (surface == null || width != surface.Width || height != surface.Height) {
				surface = new DockSurface.with_dock_surface (width, height, model);
				
				Logger.verbose ("DockItem.draw_icon (width = %i, height = %i)", width, height);
				draw_icon (surface);
				
				AverageIconColor = surface.average_color ();
			}
			
			return surface;
		}
		
		/**
		 * Returns a copy of the dock surface for this item and triggers an
		 * internal redraw if the requested size isn't matching the cache.
		 *
		 * @param width width of the requested surface
		 * @param height height of the requested surface
		 * @param model existing surface to use as basis of new surface
		 * @return the copied dock surface for this item
		 */
		public DockSurface get_surface_copy (int width, int height, DockSurface model)
		{
			var surface_copy = new DockSurface.with_dock_surface (width, height, model);
			var cr = surface_copy.Context;
			
			cr.set_source_surface (get_surface (width, height, model).Internal, 0, 0);
			cr.paint ();
						
			return surface_copy;
		}

		/**
		 * Draws the item's icon onto a surface.
		 *
		 * @param surface the surface to draw on
		 */
		protected virtual void draw_icon (DockSurface surface)
		{
			Pixbuf? pbuf = ForcePixbuf;
			if (pbuf == null)
				pbuf = DrawingService.load_icon (Icon, surface.Width, surface.Height);
			else
				pbuf = DrawingService.ar_scale (pbuf, surface.Width, surface.Height);
			
			cairo_set_source_pixbuf (surface.Context, pbuf, 0, 0);
			surface.Context.paint ();
		}
		
		/**
		 * Called when an item is clicked on.
		 *
		 * @param button the button clicked
		 * @param mod the modifiers
		 */
		public void clicked (PopupButton button, ModifierType mod)
		{
			ClickedAnimation = on_clicked (button, mod);
			LastClicked = new DateTime.now_utc ();
		}
		
		/**
		 * Called when an item is clicked on.
		 *
		 * @param button the button clicked
		 * @param mod the modifiers
		 */
		protected virtual ClickAnimation on_clicked (PopupButton button, ModifierType mod)
		{
			return ClickAnimation.NONE;
		}
		
		/**
		 * Called when an item is scrolled over.
		 *
		 * @param direction the scroll direction
		 * @param mod the modifiers
		 */
		public void scrolled (ScrollDirection direction, ModifierType mod)
		{
			on_scrolled (direction, mod);
		}
		
		/**
		 * Called when an item is scrolled over.
		 *
		 * @param direction the scroll direction
		 * @param mod the modifiers
		 */
		protected virtual void on_scrolled (ScrollDirection direction, ModifierType mod)
		{
		}
		
		/**
		 * Returns a list of the item's menu items.
		 *
		 * @return the item's menu items
		 */
		public virtual ArrayList<Gtk.MenuItem> get_menu_items ()
		{
			return new ArrayList<Gtk.MenuItem> ();
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
		public virtual bool can_accept_drop (ArrayList<string> uris)
		{
			return false;
		}
		
		/**
		 * Accepts a drop of the given URIs.
		 *
		 * @param uris the URIs to accept
		 * @return if the item accepted a drop of the given URIs
		 */
		public virtual bool accept_drop (ArrayList<string> uris)
		{
			return false;
		}
		
		/**
		 * Returns a unique ID for this dock item.
		 *
		 * @return a unique ID for this dock item
		 */
		public virtual string unique_id ()
		{
			// TODO this is a unique ID, but it is not stable!
			// do we still need stable IDs?
			return "dockitem%d".printf ((int) this);
		}
		
		/**
		 * Returns a unique URI for this dock item.
		 *
		 * @return a unique URI for this dock item
		 */
		public string as_uri ()
		{
			return "plank://" + unique_id ();
		}
		
		/**
		 * Creates a new menu item.
		 *
		 * @param title the title of the menu item
		 * @param icon the icon of the menu item
		 * @return the new menu item
		 */
		protected static Gtk.MenuItem create_menu_item (string title, string icon)
		{
			int width, height;
			icon_size_lookup (IconSize.MENU, out width, out height);
			
			var item = new ImageMenuItem.with_mnemonic (title);
			item.set_image (new Gtk.Image.from_pixbuf (DrawingService.load_icon (icon, width, height)));
			
			return item;
		}
		
		/**
		 * Copy all property value of this dockitem instance to target instance.
		 *
		 * @param target the dockitem to copy the values to
		 */
		public void copy_values_to (DockItem target)
		{
			foreach (var prop in get_class ().list_properties ()) {
				// Skip non-copyable properties to avoid warnings
				if ((prop.flags & ParamFlags.WRITABLE) == 0
					|| (prop.flags & ParamFlags.CONSTRUCT_ONLY) != 0)
					continue;
				
				var name = prop.get_name ();
				var type = prop.value_type;
				var val = Value (type);
				get_property (name, ref val);
				target.set_property (name, val);
			}
		}
	}
}
