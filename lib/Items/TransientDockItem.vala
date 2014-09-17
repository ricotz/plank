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

using Plank.Services.Windows;

namespace Plank.Items
{
	/**
	 * A dock item for applications which aren't pinned or doesn't have a matched desktop-files.
	 *
	 * Usually this represents a running application while it is possible it is a virtual item
	 * added through e.g. libunity-support to show specific application information.
	 */
	public class TransientDockItem : ApplicationDockItem
	{
		internal TransientDockItem.with_application (Bamf.Application app)
		{
			GLib.Object (Prefs: new DockItemPreferences (), App: app);
		}
		
		public TransientDockItem.with_launcher (string launcher_uri)
		{
			GLib.Object (Prefs: new DockItemPreferences.with_launcher (launcher_uri), App: null);
		}
		
		construct
		{
			if (App != null) {
				unowned string? launcher = App.get_desktop_file ();
				if (launcher == null || launcher == "") {
					Text = App.get_name ();
					ForcePixbuf = WindowControl.get_app_icon (App);
				} else {
					Prefs.Launcher = launcher;
					load_from_launcher ();
				}
			} else if (Prefs.Launcher != null) {
				load_from_launcher ();
			} else {
				critical ("No source of information for this item available");
			}
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool can_be_removed ()
		{
			return false;
		}
	}
}
