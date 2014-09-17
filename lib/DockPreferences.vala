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

using Plank.Services;

namespace Plank
{
	/**
	 * Contains all preferences for docks.
	 */
	public class DockPreferences : Preferences
	{
		public const int MIN_ICON_SIZE = 24;
		public const int MAX_ICON_SIZE = 128;
		
		[Description(nick = "current-workspace-only", blurb = "Whether to show only windows of the current workspace.")]
		public bool CurrentWorkspaceOnly { get; set; }
		
		[Description(nick = "icon-size", blurb = "The size of dock icons (in pixels).")]
		public int IconSize { get; set; }
		
		[Description(nick = "hide-mode", blurb = "If 0, the dock won't hide.  If 1, the dock intelligently hides.  If 2, the dock auto-hides. If 3, the dock dodges active maximized windows.")]
		public HideType HideMode { get; set; }
		
		[Description(nick = "unhide-delay", blurb = "Time (in ms) to wait before unhiding the dock.")]
		public uint UnhideDelay { get; set; }
		
		[Description(nick = "monitor", blurb = "The monitor number for the dock. Use -1 to keep on the primary monitor.")]
		public int Monitor { get; set; }
		
		[Description(nick = "dock-items", blurb = "List of *.dockitem files on this dock. DO NOT MODIFY")]
		public string DockItems { get; set; }
		
		[Description(nick = "position", blurb = "The position for the dock on the monitor.  If 0, left.  If 1, right.  If 2, top.  If 3, bottom.")]
		public Gtk.PositionType Position { get; set; }
		
		[Description(nick = "offset", blurb = "The dock's position offset from center (in percent).")]
		public int Offset { get; set; }
		
		[Description(nick = "theme", blurb = "The name of the dock's theme to use.")]
		public string Theme { get; set; }
		
		[Description(nick = "alignment", blurb = "The alignment for the dock on the monitor's edge.  If 0, panel-mode.  If 1, left-aligned.  If 2, right-aligned.  If 3, centered.")]
		public Gtk.Align Alignment { get; set; }
		
		[Description(nick = "items-alignment", blurb = "The alignment of the items in this dock if panel-mode is used.  If 1, left-aligned.  If 2, right-aligned.  If 3, centered.")]
		public Gtk.Align ItemsAlignment { get; set; }
		
		[Description(nick = "lock-items", blurb = "Whether to prevent drag'n'drop actions and lock items on the dock.")]
		public bool LockItems { get; set; }
		
		[Description(nick = "pressure-reveal", blurb = "Whether to use pressure-based revealing of the dock if the support is available.")]
		public bool PressureReveal { get; set; }
		
		[Description(nick = "pinned-only", blurb = "Whether to show only pinned applications. Useful for running more then one dock.")]
		public bool PinnedOnly { get; set; }
		
		[Description(nick = "auto-pinning", blurb = "Whether to automatically pin an application if it seems useful to do.")]
		public bool AutoPinning { get; set; }
		
		/**
		 * {@inheritDoc}
		 */
		public DockPreferences ()
		{
			base ();
		}
		
		/**
		 * {@inheritDoc}
		 */
		public DockPreferences.with_file (File file)
		{
			base.with_file (file);
		}
		
		/**
		 * {@inheritDoc}
		 */
		public DockPreferences.with_filename (string filename)
		{
			base.with_filename (filename);
		}
		
		~DockPreferences ()
		{
		}
		
		/**
		 * {@inheritDoc}
		 */
		protected override void reset_properties ()
		{
			Logger.verbose ("DockPreferences.reset_properties ()");
			
			CurrentWorkspaceOnly = false;
			IconSize = 48;
			HideMode = HideType.INTELLIGENT;
			UnhideDelay = 0;
			Monitor = -1;
			DockItems = "";
			Position = Gtk.PositionType.BOTTOM;
			Offset = 0;
			Theme = Plank.Drawing.Theme.DEFAULT_NAME;
			Alignment = Gtk.Align.CENTER;
			ItemsAlignment = Gtk.Align.CENTER;
			LockItems = false;
			PressureReveal = false;
			PinnedOnly = false;
			AutoPinning = true;
		}
		
		/**
		 * Get the actual monitor to place the dock on
		 *
		 * @return the number of the monitor
		 */
		public int get_monitor ()
		{
			unowned Gdk.Screen screen = Gdk.Screen.get_default ();
			if (Monitor <= -1 || Monitor >= screen.get_n_monitors ())
				return screen.get_primary_monitor ();
			return Monitor;
		}
		
		/**
		 * Increases the IconSize, if it is not already at its max.
		 */
		public void increase_icon_size ()
		{
			if (IconSize < MAX_ICON_SIZE - 1)
				IconSize += 2;
		}
		
		/**
		 * Decreases the IconSize, if it is not already at its min.
		 */
		public void decrease_icon_size ()
		{
			if (IconSize > MIN_ICON_SIZE + 1)
				IconSize -= 2;
		}
		
		/**
		 * Return whether or not a dock is a horizontal dock.
		 *
		 * @return true if the dock's position indicates it is horizontal
		 */
		public bool is_horizontal_dock ()
		{
			return (Position == Gtk.PositionType.TOP || Position == Gtk.PositionType.BOTTOM);
		}
		
		/**
		 * {@inheritDoc}
		 */
		protected override void verify (string prop)
		{
			switch (prop) {
			case "CurrentWorkspaceOnly":
				break;
			
			case "IconSize":
				if (IconSize < MIN_ICON_SIZE)
					IconSize = MIN_ICON_SIZE;
				else if (IconSize > MAX_ICON_SIZE)
					IconSize = MAX_ICON_SIZE;
				else if (IconSize % 2 == 1)
					IconSize -= 1;
				break;
			
			case "HideMode":
				break;
			
			case "UnhideDelay":
				break;
			
			case "Monitor":
				if (Monitor < -1)
					Monitor = -1;
				else if (Monitor != -1 && Monitor >= Gdk.Screen.get_default ().get_n_monitors ())
					Monitor = Gdk.Screen.get_default ().get_primary_monitor ();
				break;
			
			case "DockItems":
				break;
			
			case "Position":
				break;
			
			case "Offset":
				if (Offset < -100)
					Offset = -100;
				else if (Offset > 100)
					Offset = 100;
				break;
			
			case "Theme":
				if (Theme == "")
					Theme = Plank.Drawing.Theme.DEFAULT_NAME;
				else if (Theme.contains ("/"))
					Theme = Theme.replace ("/", "");
				break;
			
			case "Alignment":
				break;
			
			case "ItemsAlignment":
				break;
			
			case "LockItems":
				break;
			
			case "PressureReveal":
				break;
			
			case "PinnedOnly":
				break;
			
			case "AutoPinning":
				break;
			}
		}
	}
}
