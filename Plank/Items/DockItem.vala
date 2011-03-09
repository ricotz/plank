//  
//  Copyright (C) 2011 Robert Dyer, Rico Tzschichholz
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
	public enum IndicatorState
	{
		NONE,
		SINGLE = 2,
		SINGLE_PLUS = 4
	}
	
	public enum ItemState
	{
		NORMAL,
		ACTIVE = 2,
		URGENT = 4
	}
	
	public enum ClickAnimation
	{
		NONE,
		BOUNCE = 2,
		DARKEN = 4,
		LIGHTEN = 8
	}
	
	public enum PopupButton
	{
		NONE,
		LEFT = 2,
		MIDDLE = 4,
		RIGHT = 8;
		
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
	
	public class DockItem : GLib.Object
	{
		public signal void deleted ();
		
		public signal void launcher_changed ();
		
		public signal void needs_redraw ();
		
		public string Icon { get; set; default = ""; }
		
		public string Text { get; set; default = ""; }
		
		public string BadgeText { get; set; default = ""; }
		
		public int Position { get; set; default = 0; }
		
		public PopupButton Button { get; protected set; default = PopupButton.RIGHT; }
		
		public ItemState State { get; protected set; default = ItemState.NORMAL; }
		
		public IndicatorState Indicator { get; protected set; default = IndicatorState.NONE; }
		
		public ClickAnimation ClickedAnimation { get; protected set; default = ClickAnimation.NONE; }
		
		public DateTime LastClicked { get; protected set; default = new DateTime.from_unix_utc (0); }
		
		public DateTime LastScrolled { get; protected set; default = new DateTime.from_unix_utc (0); }
		
		public DateTime LastUrgent { get; protected set; default = new DateTime.from_unix_utc (0); }
		
		public DateTime LastActive { get; protected set; default = new DateTime.from_unix_utc (0); }
		
		public bool ValidItem {
			get { return File.new_for_path (Prefs.Launcher).query_exists (); }
		}
		
		public Drawing.Color AverageIconColor { get; protected set; }
		
		protected DockItemPreferences Prefs { get; protected set; }
		
		private DockSurface surface;
		
		public DockItem ()
		{
			Prefs = new DockItemPreferences ();
			AverageIconColor = Drawing.Color (0, 0, 0, 0);
			
			Prefs.deleted.connect (handle_deleted);
			Gtk.IconTheme.get_default ().changed.connect (reset_buffer);
			Prefs.notify["Icon"].connect (reset_buffer);
		}
		
		~DockItem ()
		{
			Prefs.deleted.disconnect (handle_deleted);
			Gtk.IconTheme.get_default ().changed.disconnect (reset_buffer);
			Prefs.notify["Icon"].disconnect (reset_buffer);
		}
		
		protected void handle_deleted ()
		{
			deleted ();
		}
		
		public static string get_launcher_from_dockitem (string dockitem)
		{
			try {
				KeyFile file = new KeyFile ();
				file.load_from_file (dockitem, 0);
				
				return file.get_string (typeof (DockItemPreferences).name (), "Launcher");
			} catch {
				return "";
			}
		}
		
		public int get_sort ()
		{
			return Prefs.Sort;
		}
		
		public void set_sort (int pos)
		{
			if (Prefs.Sort != pos)
				Prefs.Sort = pos;
		}
		
		public string get_launcher ()
		{
			return Prefs.Launcher;
		}
		
		void reset_buffer ()
		{
			surface = null;
			
			needs_redraw ();
		}
		
		public DockSurface get_surface (DockSurface surface)
		{
			if (this.surface == null || surface.Width != this.surface.Width || surface.Height != this.surface.Height) {
				this.surface = new DockSurface.with_dock_surface (surface.Width, surface.Height, surface);
				draw_icon (this.surface);
				
				AverageIconColor = this.surface.average_color ();
			}
			return this.surface;
		}
		
		protected virtual void draw_icon (DockSurface surface)
		{
			var pbuf = DrawingService.load_icon (Icon, surface.Width, surface.Height);
			cairo_set_source_pixbuf (surface.Context, pbuf, 0, 0);
			surface.Context.paint ();
		}
		
		public virtual void launch ()
		{
		}
		
		public void clicked (PopupButton button, ModifierType mod)
		{
			ClickedAnimation = on_clicked (button, mod);
			LastClicked = new DateTime.now_utc ();
		}
		
		protected virtual ClickAnimation on_clicked (PopupButton button, ModifierType mod)
		{
			return ClickAnimation.NONE;
		}
		
		public void scrolled (ScrollDirection direction, ModifierType mod)
		{
			on_scrolled (direction, mod);
		}
		
		protected virtual void on_scrolled (ScrollDirection direction, ModifierType mod)
		{
		}
		
		public virtual ArrayList<MenuItem> get_menu_items ()
		{
			return new ArrayList<MenuItem> ();
		}
		
		public virtual string unique_id ()
		{
			return "dockitem%d".printf ((int) this);
		}
		
		public string as_uri ()
		{
			return "plank://" + unique_id ();
		}
		
		protected MenuItem create_menu_item (string title, string icon)
		{
			int width, height;
			var item = new ImageMenuItem.with_mnemonic (title);
			
			icon_size_lookup (IconSize.MENU, out width, out height);
			item.set_image (new Gtk.Image.from_pixbuf (DrawingService.load_icon (icon, width, height)));
			
			return item;
		}
	}
}
