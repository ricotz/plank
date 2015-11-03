//
//  Copyright (C) 2015 Rico Tzschichholz
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

using Plank;

namespace Docky
{
	public class DesktopDockItem : DockletItem
	{
		/**
		 * {@inheritDoc}
		 */
		public DesktopDockItem.with_dockitem_file (GLib.File file)
		{
			GLib.Object (Prefs: new DockItemPreferences.with_file (file));
		}
		
		construct
		{
			Icon = "resource://" + Docky.G_RESOURCE_PATH + "/icons/show-desktop.svg";
			Text = _("Show Desktop");
		}
		
		~DesktopDockItem ()
		{
		}
		
		protected override AnimationType on_clicked (PopupButton button, Gdk.ModifierType mod, uint32 event_time)
		{
			if (button == PopupButton.LEFT) {
				unowned Wnck.Screen screen = Wnck.Screen.get_default ();
				screen.toggle_showing_desktop (!screen.get_showing_desktop ());
				return AnimationType.BOUNCE;
			}
			
			return AnimationType.NONE;
		}
	}
}
