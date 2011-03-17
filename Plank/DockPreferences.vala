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

using Plank.Services;
using Plank.Widgets;

namespace Plank
{
	public class DockPreferences : Preferences
	{
		const int MIN_ICON_SIZE = 24;
		const int MAX_ICON_SIZE = 128;
		
		// FIXME zoom disabled
		//const double MIN_ZOOM = 1.0;
		//const double MAX_ZOOM = 4.0;
		
		//[Description(nick = "zoom", blurb = "How much to zoom dock icons when hovered (percentage).")]
		//public double Zoom { get; set; default = 2.0; }
		
		[Description(nick = "icon-size", blurb = "The size of dock icons (in pixels).")]
		public int IconSize { get; set; default = 48; }
		
		[Description(nick = "hide-mode", blurb = "If 0, the dock won't hide.  If 1, the dock intelligently hides.  If 2, the dock auto-hides.")]
		public HideType HideMode { get; set; default = HideType.INTELLIGENT; }
		
		public DockPreferences ()
		{
			base ();
		}
		
		public DockPreferences.with_file (string filename)
		{
			base.with_file (filename);
		}
		
		/*
		// FIXME zoom disabled
		public bool zoom_enabled ()
		{
			return Zoom > MIN_ZOOM;
		}
		*/
		
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
			/*
			// FIXME zoom disabled
			case "Zoom":
				if (Zoom < MIN_ZOOM)
					Zoom = MIN_ZOOM;
				else if (Zoom > MAX_ZOOM)
					Zoom = MAX_ZOOM;
				break;
			*/
			
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
