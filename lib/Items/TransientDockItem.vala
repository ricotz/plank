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

using Gee;
using Gtk;

using Plank.Drawing;
using Plank.Services.Windows;

namespace Plank.Items
{
	internal class TransientDockItem : ApplicationDockItem
	{
		public TransientDockItem.with_application (Bamf.Application app)
		{
			set_app (app);
			
			var launcher = app.get_desktop_file ();
			if (launcher == "") {
				Text = app.get_name ();
				ForcePixbuf = WindowControl.get_app_icon (app);
			} else {
				Prefs.Launcher = launcher;
				load_from_launcher ();
			}
		}
	}
}
