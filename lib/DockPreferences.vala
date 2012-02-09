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
using Gtk;

using Plank.Services;
using Plank.Widgets;

namespace Plank
{
	/**
	 * Contains all preferences for docks.
	 */
	public class DockPreferences : Preferences
	{
		const int MIN_ICON_SIZE = 24;
		const int MAX_ICON_SIZE = 128;
		
		[Description(nick = "icon-size", blurb = "The size of dock icons (in pixels).")]
		public int IconSize { get; set; }
		
		[Description(nick = "hide-mode", blurb = "If 0, the dock won't hide.  If 1, the dock intelligently hides.  If 2, the dock auto-hides.")]
		public HideType HideMode { get; set; }
		
		[Description(nick = "unhide-delay", blurb = "Time (in ms) to wait before unhiding the dock.")]
		public uint UnhideDelay { get; set; }
		
		[Description(nick = "monitor", blurb = "The monitor number for the dock.")]
		public int Monitor { get; set; }
		
		[Description(nick = "position", blurb = "The position for the dock on the monitor.")]
		public PositionType Position { get; set; }
		
		[Description(nick = "offset", blurb = "The dock's position offset from center (in percent).")]
		public double Offset { get; set; }
		
		/**
		 * {@inheritDoc}
		 */
		public DockPreferences ()
		{
			base ();
			Screen.get_default ().monitors_changed.connect (monitors_changed);
		}
		
		/**
		 * {@inheritDoc}
		 */
		public DockPreferences.with_file (string filename)
		{
			base.with_file (filename);
			Screen.get_default ().monitors_changed.connect (monitors_changed);
		}
		
		~DockPreferences ()
		{
			Screen.get_default ().monitors_changed.disconnect (monitors_changed);
		}
		
		/**
		 * {@inheritDoc}
		 */
		protected override void reset_properties ()
		{
			IconSize = 48;
			HideMode = HideType.INTELLIGENT;
			UnhideDelay = 0;
			Monitor = Screen.get_default ().get_primary_monitor ();
			Position = PositionType.BOTTOM;
			Offset = 0.0;
		}
		
		void monitors_changed ()
		{
			verify ("Monitor");
		}
		
		/**
		 * Increases the IconSize, if it is not already at its max.
		 */
		public void increase_icon_size ()
		{
			if (IconSize < MAX_ICON_SIZE)
				IconSize++;
		}
		
		/**
		 * Decreases the IconSize, if it is not already at its min.
		 */
		public void decrease_icon_size ()
		{
			if (IconSize > MIN_ICON_SIZE)
				IconSize--;
		}
		
		/**
		 * Return whether or not a dock is a horizontal dock.
		 *
		 * @return true if the dock's position indicates it is horizontal
		 */
		public bool is_horizontal_dock ()
		{
			return Position == PositionType.TOP || Position == PositionType.BOTTOM;
		}
		
		/**
		 * {@inheritDoc}
		 */
		protected override void verify (string prop)
		{
			switch (prop) {
			case "IconSize":
				if (IconSize < MIN_ICON_SIZE)
					IconSize = MIN_ICON_SIZE;
				else if (IconSize > MAX_ICON_SIZE)
					IconSize = MAX_ICON_SIZE;
				break;
			
			case "HideMode":
				break;
			
			case "UnhideDelay":
				break;
			
			case "Monitor":
				if (Monitor >= Screen.get_default ().get_n_monitors ())
					Monitor = Screen.get_default ().get_primary_monitor ();
				break;
			
			case "Position":
				break;
			
			case "Offset":
				if (Offset < -1)
					Offset = -1;
				else if (Offset > 1)
					Offset = 1;
				break;
			}
		}
	}
}
