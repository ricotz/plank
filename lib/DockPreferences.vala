//
//  Copyright (C) 2011-2012 Robert Dyer, Rico Tzschichholz
//
//  This file is part of Plank.
//
//  Plank is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Plank is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

namespace Plank
{
	/**
	 * Contains all preferences for docks.
	 */
	public class DockPreferences : Plank.Settings
	{
		public const int MIN_ICON_SIZE = 24;
		public const int MAX_ICON_SIZE = 128;
		
		public const int MIN_ICON_ZOOM = 100;
		public const int MAX_ICON_ZOOM = 200;
		
		[Description(nick = "current-workspace-only", blurb = "Whether to show only windows of the current workspace.")]
		public bool CurrentWorkspaceOnly { get; set; }
		
		[Description(nick = "icon-size", blurb = "The size of dock icons (in pixels).")]
		public int IconSize { get; set; }
		
		[Description(nick = "hide-mode", blurb = "If 0, the dock won't hide.  If 1, the dock intelligently hides.  If 2, the dock auto-hides. If 3, the dock dodges active maximized windows. If 4, the dock dodges every window.")]
		public HideType HideMode { get; set; }
		
		[Description(nick = "unhide-delay", blurb = "Time (in ms) to wait before unhiding the dock.")]
		public uint UnhideDelay { get; set; }
		
		[Description(nick = "hide-delay", blurb = "Time (in ms) to wait before hiding the dock.")]
		public uint HideDelay { get; set; }
		
		[Description(nick = "monitor", blurb = "The plug-name of the monitor for the dock to show on (e.g. DVI-I-1, HDMI1, LVDS1). Leave this empty to keep on the primary monitor.")]
		public string Monitor { get; set; }
		
		[Description(nick = "dock-items", blurb = "Array of the dockitem-files on this dock. DO NOT MODIFY")]
		public string[] DockItems { get; set; }
		
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
		
		[Description(nick = "show-dock-item", blurb = "Whether to show the item for the dock itself.")]
		public bool ShowDockItem { get; set; }
		
		[Description(nick = "zoom-enabled", blurb = "Whether the dock will zoom when hovered.")]
		public bool ZoomEnabled { get; set; }
		
		[Description(nick = "zoom-percent", blurb = "The dock's icon-zoom (in percent).")]
		public uint ZoomPercent { get; set; }
		
		[Description(nick = "tooltips-enabled", blurb = "Whether to show tooltips when items are hovered.")]
		public bool TooltipsEnabled { get; set; }
		
		/**
		 * {@inheritDoc}
		 */
		public DockPreferences (string name)
		{
			Object (settings: create_settings ("net.launchpad.plank.dock.settings", "/net/launchpad/plank/docks/%s/".printf (name)));
		}
		
		~DockPreferences ()
		{
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
			case "IconSize":
				if (IconSize < MIN_ICON_SIZE)
					IconSize = MIN_ICON_SIZE;
				else if (IconSize > MAX_ICON_SIZE)
					IconSize = MAX_ICON_SIZE;
				else if (IconSize % 2 == 1)
					IconSize -= 1;
				break;
			
			case "Theme":
				if (Theme == "")
					Theme = Plank.Theme.DEFAULT_NAME;
				else if (Theme.contains ("/"))
					Theme = Theme.replace ("/", "");
				break;
			}
		}
	}
}
