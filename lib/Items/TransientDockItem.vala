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
	 * A dock item for applications which aren't pinned or doesn't have a matched desktop-files.
	 *
	 * Usually this represents a running application while it is possible it is a virtual item
	 * added through e.g. libunity-support to show specific application information.
	 */
	public class TransientDockItem : ApplicationDockItem
	{
		const uint ICON_UPDATE_DELAY = 200U;
		
		uint delayed_update_timer_id = 0U;
		
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
					update_forced_pixbuf ();
				} else {
					Prefs.Launcher = launcher;
					load_from_launcher ();
				}
			} else if (Prefs.Launcher != "") {
				load_from_launcher ();
			} else {
				critical ("No source of information for this item available");
			}
		}
		
		~TransientDockItem ()
		{
			if (delayed_update_timer_id > 0U) {
				Source.remove (delayed_update_timer_id);
				delayed_update_timer_id = 0U;
			}
		}
		
		void update_forced_pixbuf ()
		{
			if (delayed_update_timer_id > 0U)
				return;
			
			ForcePixbuf = WindowControl.get_app_icon (App);
			if (ForcePixbuf != null)
				return;
			
			// if there is no window-icon available yet then schedule a 2nd try
			delayed_update_timer_id = Gdk.threads_add_timeout (ICON_UPDATE_DELAY, () => {
				delayed_update_timer_id = 0U;
				
				if (App != null)
					ForcePixbuf = WindowControl.get_app_icon (App);
				
				return false;
			});
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool can_be_removed ()
		{
			return false;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool is_valid ()
		{
			return true;
		}
	}
}
