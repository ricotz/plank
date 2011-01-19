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
	
	public class DockItem : GLib.Object
	{
		public Bamf.Application? App { get; set; }
		
		public string Icon { get; set; default = "folder"; }
		
		public string Text { get; set; default = ""; }
		
		public int Position { get; set; default = 0; }
		
		public ItemState State { get; set; default = ItemState.NORMAL; }
		
		public IndicatorState Indicator { get; set; default = IndicatorState.NONE; }
		
		public bool ValidItem {
			get { return File.new_for_path (Prefs.Launcher).query_exists (); }
		}
		
		protected DockItemPreferences Prefs { get; protected set; }
		
		public DockItem ()
		{
			Prefs = new DockItemPreferences ();
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
			App = app;
			
			if (app != null) {
				app.active_changed.connect (() => update_states ());
				app.running_changed.connect (() => update_states ());
				app.urgent_changed.connect (() => update_states ());
			}
			
			update_states ();
		}
		
		public void update_states ()
		{
			if (App == null) {
				State = ItemState.NORMAL;
				Indicator = IndicatorState.NONE;
			} else {
				State = ItemState.NORMAL;
				if (App.is_active ())
					State |= ItemState.ACTIVE;
				if (App.is_urgent ())
					State |= ItemState.URGENT;
				if (App.get_children ().length () == 1)
					Indicator = IndicatorState.SINGLE;
				else
					Indicator = IndicatorState.SINGLE_PLUS;
			}
			
		}
		
		public virtual List<MenuItem> get_menu_items ()
		{
			List<MenuItem> items = new List<MenuItem> ();
			
			var item = new ImageMenuItem.with_mnemonic ("_Open");
			int width, height;
			icon_size_lookup (IconSize.MENU, out width, out height);
			item.set_image (new Gtk.Image.from_pixbuf (Drawing.load_icon ("document-open-symbolic;;document-open", width, height)));
			item.activate.connect (() => launch ());
			items.append (item);
			
			return items;
		}
	}
}
