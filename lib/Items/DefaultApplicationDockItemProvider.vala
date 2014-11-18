//
//  Copyright (C) 2013 Rico Tzschichholz
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


using Plank.Factories;
using Plank.Services;
using Plank.Services.Windows;

namespace Plank.Items
{
	/**
	 * The default container and controller class for managing application dock items on a dock.
	 */
	public class DefaultApplicationDockItemProvider : ApplicationDockItemProvider
	{
		public DockPreferences Prefs { get; construct; }
		
		/**
		 * Creates the default container for dock items.
		 *
		 * @param prefs the preferences of the dock which owns this provider
		 */
		public DefaultApplicationDockItemProvider (DockPreferences prefs, File launchers_dir)
		{
			Object (Prefs : prefs, LaunchersDir : launchers_dir);
		}
		
		construct
		{
			Prefs.notify["CurrentWorkspaceOnly"].connect (handle_setting_changed);
			
			unowned Wnck.Screen wnck_screen = Wnck.Screen.get_default ();
			wnck_screen.active_window_changed.connect_after (handle_window_changed);
			wnck_screen.active_workspace_changed.connect_after (handle_workspace_changed);
			wnck_screen.viewports_changed.connect_after (handle_viewports_changed);
		}
		
		~DefaultApplicationDockItemProvider ()
		{
			Prefs.notify["CurrentWorkspaceOnly"].disconnect (handle_setting_changed);
			
			unowned Wnck.Screen wnck_screen = Wnck.Screen.get_default ();
			wnck_screen.active_window_changed.disconnect (handle_window_changed);
			wnck_screen.active_workspace_changed.disconnect (handle_workspace_changed);
			wnck_screen.viewports_changed.disconnect (handle_viewports_changed);
		}
		
		protected override void update_visible_items ()
		{
			Logger.verbose ("DefaultDockItemProvider.update_visible_items ()");
			
			if (Prefs.CurrentWorkspaceOnly) {
				unowned Wnck.Workspace? active_workspace = Wnck.Screen.get_default ().get_active_workspace ();
				foreach (var item in internal_items) {
					unowned TransientDockItem? transient = (item as TransientDockItem);
					item.IsVisible = (transient == null || transient.App == null || active_workspace == null
						|| WindowControl.has_window_on_workspace (transient.App, active_workspace));
				}
			} else {
				foreach (var item in internal_items)
					item.IsVisible = true;
			}
			
			base.update_visible_items ();
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override void prepare ()
		{
			// Make sure internal window-list of Wnck is most up to date
			Wnck.Screen.get_default ().force_update ();
			
			// Match running applications to their available dock-items
			foreach (var app in Matcher.get_default ().active_launchers ()) {
				var found = item_for_application (app);
				if (found != null) {
					found.App = app;
					continue;
				}
				
				if (!app.is_user_visible () || WindowControl.get_num_windows (app) <= 0)
					continue;
				
				var new_item = new TransientDockItem.with_application (app);
				
				add_item_without_signaling (new_item);
			}
			
			update_visible_items ();
			
			var favs = new Gee.ArrayList<string> ();
			
			foreach (var element in internal_items) {
				unowned ApplicationDockItem? item = (element as ApplicationDockItem);
				if (item != null && !(item is TransientDockItem))
					favs.add (item.Launcher);
			}
			
			Matcher.get_default ().set_favorites (favs);
		}
		
		protected override void app_opened (Bamf.Application app)
		{
			// Make sure internal window-list of Wnck is most up to date
			Wnck.Screen.get_default ().force_update ();
			
			var found = item_for_application (app);
			if (found != null) {
				found.App = app;
				return;
			}
			
			if (!app.is_user_visible () || WindowControl.get_num_windows (app) <= 0)
				return;
			
			var new_item = new TransientDockItem.with_application (app);
			
			add_item (new_item);
		}
		
		void app_closed (DockItem remove)
		{
			if (remove is TransientDockItem
				&& !(((TransientDockItem) remove).has_unity_info ()))
				remove_item (remove);
		}
		
		void handle_window_changed (Wnck.Screen screen, Wnck.Window? previous)
		{
			if (!Prefs.CurrentWorkspaceOnly)
				return;
			
			unowned Wnck.Workspace? active_workspace = screen.get_active_workspace ();
			if (previous == null || active_workspace == null
				|| previous.get_workspace () == active_workspace)
				return;
			
			update_visible_items ();
		}
		
		void handle_workspace_changed (Wnck.Screen screen, Wnck.Workspace? previous)
		{
			if (!Prefs.CurrentWorkspaceOnly)
				return;
			
			unowned Wnck.Workspace? active_workspace = screen.get_active_workspace ();
			if (active_workspace != null && active_workspace.is_virtual ())
				return;
			
			update_visible_items ();
		}
		
		void handle_viewports_changed (Wnck.Screen screen)
		{
			if (!Prefs.CurrentWorkspaceOnly)
				return;
			
			unowned Wnck.Workspace? active_workspace = screen.get_active_workspace ();
			if (active_workspace != null && !active_workspace.is_virtual ())
				return;
			
			update_visible_items ();
		}
		
		void handle_setting_changed ()
		{
			update_visible_items ();
		}
		
		protected override void connect_element (DockElement element)
		{
			base.connect_element (element);
			
			unowned ApplicationDockItem? appitem = (element as ApplicationDockItem);
			if (appitem != null) {
				appitem.app_closed.connect (app_closed);
				appitem.pin_launcher.connect (pin_item);
			}
		}
		
		protected override void disconnect_element (DockElement element)
		{
			base.disconnect_element (element);
			
			unowned ApplicationDockItem? appitem = (element as ApplicationDockItem);
			if (appitem != null) {
				appitem.app_closed.disconnect (app_closed);
				appitem.pin_launcher.disconnect (pin_item);
			}
		}
		
		protected override void handle_item_deleted (DockItem item)
		{
			unowned Bamf.Application? app = null;
			if (item is ApplicationDockItem)
				app = (item as ApplicationDockItem).App;
			
			if (app == null || !app.is_running ()) {
				remove_item (item);
				return;
			}
			
			var new_item = new TransientDockItem.with_application (app);
			item.copy_values_to (new_item);
			
			replace_item (new_item, item);
		}
		
		public void pin_item (DockItem item)
		{
			if (!internal_items.contains (item)) {
				critical ("Item '%s' does not exist in this DockItemProvider.", item.Text);
				return;
			}
			
			Logger.verbose ("DefaultDockItemProvider.pin_item ('%s[%s]')", item.Text, item.DockItemFilename);

			unowned ApplicationDockItem? app_item = (item as ApplicationDockItem);
			if (app_item == null)
				return;
			
			// delay automatic add of new dockitems while creating this new one
			delay_items_monitor ();
			
			if (item is TransientDockItem) {
				var dockitem_file = Factory.item_factory.make_dock_item (item.Launcher, LaunchersDir);
				if (dockitem_file == null)
					return;
				
				var new_item = new ApplicationDockItem.with_dockitem_file (dockitem_file);
				item.copy_values_to (new_item);
				
				replace_item (new_item, item);
			} else {
				item.delete ();
			}
			
			resume_items_monitor ();
		}
	}
}
