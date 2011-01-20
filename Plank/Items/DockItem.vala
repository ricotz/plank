//  
//  Copyright (C) 2011 Robert Dyer
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

using Plank.Services.Drawing;
using Plank.Services.Logging;
using Plank.Services.Windows;

namespace Plank.Items
{
	public enum IndicatorState
	{
		NONE,
		SINGLE,
		SINGLE_PLUS,
	}
	
	public enum ItemState
	{
		NORMAL,
		ACTIVE,
		URGENT,
	}
	
	public enum ClickAnimation
	{
		NONE,
		BOUNCE,
		DARKEN,
		LIGHTEN
	}
	
	public class DockItem : GLib.Object
	{
		public signal void launcher_changed (DockItem item);
		
		public Bamf.Application? App { get; set; }
		
		public string Icon { get; set; default = "folder"; }
		
		public string Text { get; set; default = ""; }
		
		public int Position { get; set; default = 0; }
		
		public ItemState State { get; protected set; default = ItemState.NORMAL; }
		
		public IndicatorState Indicator { get; protected set; default = IndicatorState.NONE; }
		
		public ClickAnimation ClickedAnimation { get; protected set; default = ClickAnimation.NONE; }
		
		public DateTime LastClicked { get; protected set; default = new DateTime.from_unix_utc (0); }
		
		public DateTime LastUrgent { get; protected set; default = new DateTime.from_unix_utc (0); }
		
		public DateTime LastActive { get; protected set; default = new DateTime.from_unix_utc (0); }
		
		public bool ValidItem {
			get { return File.new_for_path (Prefs.Launcher).query_exists (); }
		}
		
		protected DockItemPreferences Prefs { get; protected set; }
		
		public DockItem ()
		{
			Prefs = new DockItemPreferences ();
			
			Prefs.notify["Launcher"].connect (() => launcher_changed (this));
		}
		
		public int get_sort ()
		{
			return Prefs.Sort;
		}
		
		public void set_sort (int pos)
		{
			if (Prefs.Sort!= pos)
				Prefs.Sort = pos;
		}
		
		public string get_launcher ()
		{
			return Prefs.Launcher;
		}
		
		public void launch ()
		{
			Services.System.launch (File.new_for_path (get_launcher ()), {});
		}
		
		public void set_app (Bamf.Application? app)
		{
			if (app != null) {
				app.active_changed.disconnect (update_needed);
				app.running_changed.disconnect (update_needed);
				app.urgent_changed.disconnect (update_needed);
			}
			
			App = app;
			
			if (app != null) {
				app.active_changed.connect (update_needed);
				app.running_changed.connect (update_needed);
				app.urgent_changed.connect (update_needed);
			}
			
			update_states ();
		}
		
		public void update_needed ()
		{
			update_states ();
		}
		
		public void update_states ()
		{
			var was_active = (State & ItemState.ACTIVE) != 0;
			
			if (App == null) {
				if (was_active)
					LastActive = new DateTime.now_utc ();
				State = ItemState.NORMAL;
				Indicator = IndicatorState.NONE;
			} else {
				// set active
				State = ItemState.NORMAL;
				if (App.is_active ())
					State |= ItemState.ACTIVE;
				if (was_active != ((State & ItemState.ACTIVE) != 0))
					LastActive = new DateTime.now_utc ();
				
				// set urgent
				if (App.is_urgent ()) {
					State |= ItemState.URGENT;
					LastUrgent = new DateTime.now_utc ();
				}
				
				// set running
				if (!App.is_running ())
					Indicator = IndicatorState.NONE;
				else if (App.get_children ().length () == 1)
					Indicator = IndicatorState.SINGLE;
				else
					Indicator = IndicatorState.SINGLE_PLUS;
			}
		}
		
		public void clicked (uint button, ModifierType mod)
		{
			try {
				ClickedAnimation = on_clicked (button, mod);
			} catch (Error e) {
				Logger.error<DockItem> (e.message);
				ClickedAnimation = ClickAnimation.DARKEN;
			}
			
			LastClicked = new DateTime.now_utc ();
		}
		
		protected virtual ClickAnimation on_clicked (uint button, ModifierType mod)
		{
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
		
		public virtual List<MenuItem> get_menu_items ()
		{
			if (get_launcher ().has_suffix ("plank.desktop"))
				return get_plank_items ();
			
			List<MenuItem> items = new List<MenuItem> ();
			
			if (App == null || App.get_children ().length () == 0) {
				var item = new ImageMenuItem.from_stock (STOCK_OPEN, null);
				item.activate.connect (() => launch ());
				items.append (item);
			} else {
				int width, height;
				var item = new ImageMenuItem.with_mnemonic ("New _Window");
				icon_size_lookup (IconSize.MENU, out width, out height);
				item.set_image (new Gtk.Image.from_pixbuf (Drawing.load_icon ("document-open-symbolic;;document-open", width, height)));
				item.activate.connect (() => launch ());
				items.append (item);
				
				item = new ImageMenuItem.with_mnemonic ("Ma_ximize");
				icon_size_lookup (IconSize.MENU, out width, out height);
				item.set_image (new Gtk.Image.from_pixbuf (Drawing.load_icon ("view-fullscreen", width, height)));
				item.activate.connect (() => {
					WindowControl.maximize (App);
				});
				items.append (item);
				
				item = new ImageMenuItem.with_mnemonic ("Mi_nimize");
				icon_size_lookup (IconSize.MENU, out width, out height);
				item.set_image (new Gtk.Image.from_pixbuf (Drawing.load_icon ("view-restore", width, height)));
				item.activate.connect (() => {
					WindowControl.minimize (App);
				});
				items.append (item);
				
				item = new ImageMenuItem.with_mnemonic ("_Close All");
				icon_size_lookup (IconSize.MENU, out width, out height);
				item.set_image (new Gtk.Image.from_pixbuf (Drawing.load_icon ("window-close-symbolic;;window-close", width, height)));
				item.activate.connect (() => {
					WindowControl.close_all (App);
				});
				items.append (item);
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
