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
		RIGHT = 8
	}
	
	public class DockItem : GLib.Object
	{
		const int SCROLL_RATE = 200 * 1000;
		
		public signal void launcher_changed (DockItem item);
		
		public signal void app_closed (DockItem item);
		
		public Bamf.Application? App { get; set; }
		
		public string Icon { get; set; default = ""; }
		
		public string Text { get; set; default = ""; }
		
		public int Position { get; set; default = 0; }
		
		public PopupButton Button { get; protected set; default = PopupButton.RIGHT; }
		
		public Drawing.Color AverageIconColor { get; protected set; }
		
		public ItemState State { get; protected set; default = ItemState.NORMAL; }
		
		public IndicatorState Indicator { get; protected set; default = IndicatorState.NONE; }
		
		public ClickAnimation ClickedAnimation { get; protected set; default = ClickAnimation.NONE; }
		
		public DateTime LastClicked { get; protected set; default = new DateTime.from_unix_utc (0); }
		
		public DateTime LastScrolled { get; protected set; default = new DateTime.from_unix_utc (0); }
		
		public DateTime LastUrgent { get; protected set; default = new DateTime.from_unix_utc (0); }
		
		public DateTime LastActive { get; protected set; default = new DateTime.from_unix_utc (0); }
		
		private DockSurface Surface { get; set; }
		
		public bool ValidItem {
			get { return File.new_for_path (Prefs.Launcher).query_exists (); }
		}
		
		protected DockItemPreferences Prefs { get; protected set; }
		
		public DockItem ()
		{
			Prefs = new DockItemPreferences ();
			
			Prefs.notify["Launcher"].connect (() => launcher_changed (this));
			Prefs.notify["Icon"].connect (() => {
				Surface = null;
			});
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
		
		public void launch ()
		{
			if (is_launcher ())
				Services.System.launch (File.new_for_path (Prefs.Launcher), {});
			else
				Services.System.open (File.new_for_path (Prefs.Launcher));
			
			ClickedAnimation = ClickAnimation.BOUNCE;
			LastClicked = new DateTime.now_utc ();
		}
		
		public DockSurface get_surface (DockSurface surface)
		{
			if (Surface == null || Surface.Width != surface.Width || Surface.Height != surface.Height) {
				Surface = new DockSurface.with_dock_surface (surface.Width, surface.Height, surface);
				draw_icon ();
			}
			return Surface;
		}
		
		protected virtual void draw_icon ()
		{
			var pbuf = DrawingService.load_icon (Icon, Surface.Width, Surface.Height);
			cairo_set_source_pixbuf (Surface.Context, pbuf, 0, 0);
			Surface.Context.paint ();
			
			AverageIconColor = DrawingService.average_color (pbuf);
		}
		
		public void set_app (Bamf.Application? app)
		{
			if (App != null) {
				App.active_changed.disconnect (update_active);
				App.child_added.disconnect (update_states);
				App.child_removed.disconnect (update_states);
				App.urgent_changed.disconnect (update_urgent);
				App.closed.disconnect (signal_app_closed);
			}
			
			App = app;
			
			update_states ();
			
			if (app != null) {
				app.active_changed.connect (update_active);
				app.urgent_changed.connect (update_urgent);
				app.child_added.connect (update_states);
				app.child_removed.connect (update_states);
				app.closed.connect (signal_app_closed);
			}
		}
		
		public void signal_app_closed ()
		{
			app_closed (this);
		}
		
		public void update_app ()
		{
			set_app (Matcher.get_default ().app_for_launcher (Prefs.Launcher));
		}
		
		public void update_urgent ()
		{
			var was_urgent = (State & ItemState.URGENT) == ItemState.URGENT;
			
			if (App == null || App.is_closed () || !App.is_running ()) {
				if ((State & ItemState.URGENT) == ItemState.URGENT)
					State &= ~ItemState.URGENT;
			} else {
				if (App.is_urgent ())
					State |= ItemState.URGENT;
				else
					State &= ~ItemState.URGENT;
			}
			
			if (was_urgent != ((State & ItemState.URGENT) == ItemState.URGENT))
				LastUrgent = new DateTime.now_utc ();
		}
		
		public void update_indicator ()
		{
			if (App == null || App.is_closed () || !App.is_running ()) {
				Indicator = IndicatorState.NONE;
				return;
			}
			
			// set running
			if (WindowControl.get_num_windows (App) > 1)
				Indicator = IndicatorState.SINGLE_PLUS;
			else
				Indicator = IndicatorState.SINGLE;
		}
		
		public void update_active ()
		{
			var was_active = (State & ItemState.ACTIVE) == ItemState.ACTIVE;
			
			if (App == null || App.is_closed () || !App.is_running ()) {
				if (was_active)
					LastActive = new DateTime.now_utc ();
				State = ItemState.NORMAL;
			} else {
				// set active
				if (App.is_active ())
					State |= ItemState.ACTIVE;
				else
					State &= ~ItemState.ACTIVE;
			}
			
			if (was_active != ((State & ItemState.ACTIVE) == ItemState.ACTIVE))
				LastActive = new DateTime.now_utc ();
		}
		
		public void update_states ()
		{
			update_urgent ();
			update_indicator ();
			update_active ();
		}
		
		public void clicked (uint button, ModifierType mod)
		{
			ClickedAnimation = on_clicked (button, mod);
			LastClicked = new DateTime.now_utc ();
		}
		
		protected virtual ClickAnimation on_clicked (uint button, ModifierType mod)
		{
			if (is_plank_item ()) {
				Plank.show_about ();
				return ClickAnimation.DARKEN;
			}
			
			if (((App == null || App.get_children ().length () == 0) && button == 1) ||
				button == 2 || 
				(button == 1 && (mod & ModifierType.CONTROL_MASK) == ModifierType.CONTROL_MASK)) {
				launch ();
				return ClickAnimation.BOUNCE;
			}
			
			if ((App == null || App.get_children ().length () == 0) || button != 1)
				return ClickAnimation.NONE;
			
			WindowControl.smart_focus (App);
			
			return ClickAnimation.DARKEN;
		}
		
		public void scrolled (ScrollDirection direction, ModifierType mod)
		{
			on_scrolled (direction, mod);
		}
		
		protected virtual void on_scrolled (ScrollDirection direction, ModifierType mod)
		{
			if (WindowControl.get_num_windows (App) == 0 ||
				(new DateTime.now_utc ().difference (LastScrolled) < SCROLL_RATE))
				return;
			
			LastScrolled = new DateTime.now_utc ();
			
			if ((direction & ScrollDirection.UP) == ScrollDirection.UP ||
				(direction & ScrollDirection.LEFT) == ScrollDirection.LEFT)
				WindowControl.focus_previous (App);
			else
				WindowControl.focus_next (App);
		}
		
		protected bool is_launcher ()
		{
			return Prefs.Launcher.has_suffix (".desktop");
		}
		
		protected bool is_window ()
		{
			return (App != null && App.get_desktop_file () == "");
		}
		
		bool is_plank_item ()
		{
			return Prefs.Launcher.has_suffix ("plank.desktop");
		}
		
		public virtual List<MenuItem> get_menu_items ()
		{
			if (is_plank_item ())
				return get_plank_items ();
			
			List<MenuItem> items = new List<MenuItem> ();
			
			if (App == null || App.get_children ().length () == 0) {
				var item = new ImageMenuItem.from_stock (STOCK_OPEN, null);
				item.activate.connect (() => launch ());
				items.append (item);
			} else {
				MenuItem item;
				
				if (is_launcher ()) {
					item = add_menu_item (items, _("_Open New Window"), "document-open-symbolic;;document-open");
					item.activate.connect (() => launch ());
					items.append (item);
				}
				
				if (WindowControl.has_maximized_window (App)) {
					item = add_menu_item (items, _("Unma_ximize"), "view-fullscreen");
					item.activate.connect (() => WindowControl.unmaximize (App));
					items.append (item);
				} else {
					item = add_menu_item (items, _("Ma_ximize"), "view-fullscreen");
					item.activate.connect (() => WindowControl.maximize (App));
					items.append (item);
				}
				
				if (WindowControl.has_minimized_window (App)) {
					item = add_menu_item (items, _("_Restore"), "view-restore");
					item.activate.connect (() => WindowControl.restore (App));
					items.append (item);
				} else {
					item = add_menu_item (items, _("Mi_nimize"), "view-restore");
					item.activate.connect (() => WindowControl.minimize (App));
					items.append (item);
				}
				
				item = add_menu_item (items, _("_Close All"), "window-close-symbolic;;window-close");
				item.activate.connect (() => WindowControl.close_all (App));
				items.append (item);
				
				List<Bamf.Window> windows = WindowControl.get_windows (App);
				if (windows.length () > 0) {
					items.append (new SeparatorMenuItem ());
					
					int width, height;
					icon_size_lookup (IconSize.MENU, out width, out height);
					
					for (int i = 0; i < windows.length (); i++) {
						var window = windows.nth_data (i);
						
						var pbuf = WindowControl.get_window_icon (window);
						if (pbuf == null)
							DrawingService.load_icon (Icon, width, height);
						else
							pbuf = DrawingService.ar_scale (pbuf, width, height);
						
						var window_item = new ImageMenuItem.with_mnemonic (window.get_name ());
						window_item.set_image (new Gtk.Image.from_pixbuf (pbuf));
						window_item.activate.connect (() => WindowControl.focus_window (window));
						items.append (window_item);
					}
				}
			}
			
			return items;
		}
		
		public virtual string unique_id ()
		{
			return "dockitem%d".printf ((int) this);
		}
		
		public string as_uri ()
		{
			return "plank://" + unique_id ();
		}
		
		protected MenuItem add_menu_item (List<MenuItem> items, string title, string icon)
		{
			int width, height;
			var item = new ImageMenuItem.with_mnemonic (title);
			
			icon_size_lookup (IconSize.MENU, out width, out height);
			item.set_image (new Gtk.Image.from_pixbuf (DrawingService.load_icon (icon, width, height)));
			
			return item;
		}
		
		List<MenuItem> get_plank_items ()
		{
			List<MenuItem> items = new List<MenuItem> ();
			
			var item = new ImageMenuItem.from_stock (STOCK_ABOUT, null);
			item.activate.connect (() => Plank.show_about ());
			items.append (item);
			
			item = new ImageMenuItem.from_stock (STOCK_QUIT, null);
			item.activate.connect (() => Plank.quit ());
			items.append (item);
			
			return items;
		}
	}
}
