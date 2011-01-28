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

using Gtk;

using Plank.Drawing;
using Plank.Services;

namespace Plank.Items
{
	public class TransientDockItem : ApplicationDockItem
	{
		public signal void pin_launcher (TransientDockItem item);
		
		public TransientDockItem.with_launcher (string launcher)
		{
			Prefs = new DockItemPreferences ();
			
			Prefs.Launcher = launcher;
			
			load_from_launcher ();
			
			start_monitor ();
		}
		
		public override List<MenuItem> get_menu_items ()
		{
			List<MenuItem> items = base.get_menu_items ();
			
			var item = new ImageMenuItem.with_mnemonic ("_Keep in Dock");
			int width, height;
			icon_size_lookup (IconSize.MENU, out width, out height);
			item.set_image (new Gtk.Image.from_pixbuf (DrawingService.load_icon ("add", width, height)));
			item.activate.connect (() => pin_launcher (this));
			items.prepend (item);
			
			return items;
		}
	}
}
