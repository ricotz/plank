//
//  Copyright (C) 2017 Rico Tzschichholz
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

using Plank;

namespace Docky
{
	public class ApplicationsDockItem : DockletItem
	{
		GMenu.Tree apps_menu;
		Mutex apps_menu_mutex;
		bool apps_loaded;

		/**
		 * {@inheritDoc}
		 */
		public ApplicationsDockItem.with_dockitem_file (GLib.File file)
		{
			GLib.Object (Prefs: new DockItemPreferences.with_file (file));
		}

		construct
		{
			Icon = "gnome-applications;;gnome-main-menu";
			Text = _("Applications");

			apps_menu = new GMenu.Tree ("applications.menu", GMenu.TreeFlags.SORT_DISPLAY_NAME);
			apps_menu.changed.connect (update_menu);
			update_menu ();
		}

		~ApplicationsDockItem ()
		{
			if (apps_menu != null)
				apps_menu.changed.disconnect (update_menu);
		}

		void update_menu ()
		{
			Worker.get_default ().add_task_with_result.begin<void*> (() => {
				apps_menu_mutex.lock ();
				try {
					apps_menu.load_sync ();
					apps_loaded = true;
				} catch (Error e) {
					warning ("Failed to load applications (%s)", e.message);
					apps_loaded = false;
				}
				apps_menu_mutex.unlock ();
				return null;
			}, TaskPriority.HIGH);
		}

		protected override AnimationType on_scrolled (Gdk.ScrollDirection direction, Gdk.ModifierType mod, uint32 event_time)
		{
			return AnimationType.NONE;
		}

		protected override AnimationType on_clicked (PopupButton button, Gdk.ModifierType mod, uint32 event_time)
		{
			return AnimationType.NONE;
		}

		public override Gee.ArrayList<Gtk.MenuItem> get_menu_items ()
		{
			var items = new Gee.ArrayList<Gtk.MenuItem> ();

			if (!apps_loaded) {
				var item = create_menu_item (_("No applications available"), null, false);
				items.add (item);
				return items;
			}

			var iter = apps_menu.get_root_directory ().iter ();
			GMenu.TreeItemType type;
			while ((type = iter.next ()) != GMenu.TreeItemType.INVALID) {
				if (type != GMenu.TreeItemType.DIRECTORY)
					continue;
				items.add (get_submenu_item (iter.get_directory ()));
			}

			return items;
		}

		Gtk.MenuItem get_submenu_item (GMenu.TreeDirectory category)
		{
			var item = create_menu_item (category.get_name (), DrawingService.get_icon_from_gicon (category.get_icon ()) ?? "", true);
			var submenu = new Gtk.Menu ();
			item.submenu = submenu;
			submenu.show ();
			item.show ();

			ulong? item_activate_id = item.activate.connect (submenu_item_activate);
			item.set_data<ulong?> ("plank-applications-item-activate-id", item_activate_id);
			item.set_data<GMenu.TreeDirectory> ("plank-applications-category", category);

			return item;
		}

		void submenu_item_activate (Gtk.MenuItem item)
		{
			var item_activate_id = item.steal_data<ulong?> ("plank-applications-item-activate-id");
			SignalHandler.disconnect (item, item_activate_id);

			var category = item.steal_data<GMenu.TreeDirectory> ("plank-applications-category");
			add_menu_items (item.submenu, category);
		}

		void add_menu_items (Gtk.Menu menu, GMenu.TreeDirectory category)
		{
			var iter = category.iter ();
			GMenu.TreeItemType type;
			while ((type = iter.next ()) != GMenu.TreeItemType.INVALID) {
				switch (type) {
				case GMenu.TreeItemType.DIRECTORY:
					menu.add (get_submenu_item (iter.get_directory ()));
					break;
				case GMenu.TreeItemType.ENTRY:
					GMenu.TreeEntry entry = iter.get_entry ();
					unowned GLib.DesktopAppInfo info = entry.get_app_info ();
					unowned string desktop_path = entry.get_desktop_file_path ();
					var item = create_menu_item (info.get_display_name (), DrawingService.get_icon_from_gicon (info.get_icon ()) ?? "", true);
					item.activate.connect (() => {
						System.get_default ().launch (File.new_for_path (desktop_path));;
					});
					item.show ();
					menu.add (item);
					break;
				}
			}
		}
	}
}
