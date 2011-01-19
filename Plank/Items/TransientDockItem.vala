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

using Plank.Services.Logging;

namespace Plank.Items
{
	public class TransientDockItem : ApplicationDockItem
	{
		public TransientDockItem (string launcher)
		{
			Prefs = new DockItemPreferences ();
			
			Prefs.Launcher = launcher;
			Prefs.Sort = int.MAX;
			
			load_from_launcher ();
			
			start_monitor ();
		}
	}
}
