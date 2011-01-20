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

using Plank.Services.Preferences;

namespace Plank
{
	public class DockPreferences : Preferences
	{
		const int MIN_ICON_SIZE = 24;
		const int MAX_ICON_SIZE = 128;
		
		const double MIN_ZOOM = 1.0;
		const double MAX_ZOOM = 4.0;
		
		public double Zoom { get; set; default = 2.0; }
		
		public int IconSize { get; set; default = 48; }
		
		public AutohideType Autohide { get; set; default = AutohideType.INTELLIHIDE; }
		
		public DockPreferences ()
		{
			base ();
		}
		
		public DockPreferences.with_file (string filename)
		{
			base.with_file (filename);
		}
		
		public bool zoom_enabled ()
		{
			return Zoom > MIN_ZOOM;
		}
		
		public void increase_icon_size ()
		{
			if (IconSize < MAX_ICON_SIZE)
				IconSize++;
		}
		
		public void decrease_icon_size ()
		{
			if (IconSize > MIN_ICON_SIZE)
				IconSize--;
		}
		
		protected override void verify (string prop)
		{
			switch (prop) {
			case "Zoom":
				if (Zoom < MIN_ZOOM)
					Zoom = MIN_ZOOM;
				else if (Zoom > MAX_ZOOM)
					Zoom = MAX_ZOOM;
				break;
			
			case "IconSize":
				if (IconSize < MIN_ICON_SIZE)
					IconSize = MIN_ICON_SIZE;
				else if (IconSize > MAX_ICON_SIZE)
					IconSize = MAX_ICON_SIZE;
				break;
			}
		}
	}
}
