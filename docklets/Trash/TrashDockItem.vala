//
//  Copyright (C) 2011 Robert Dyer
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
	[DBus (name = "org.gnome.Nautilus.FileOperations")]
	interface NautilusFileOperations : Object {
		public abstract void empty_trash () throws IOError;
	}
	
	public class TrashDockItem : DockletItem
	{
		static GLib.Settings? create_settings (string schema_id, string? path = null)
		{
			var schema = GLib.SettingsSchemaSource.get_default ().lookup (schema_id, true);
			if (schema == null) {
				warning ("GSettingsSchema '%s' not found", schema_id);
				return null;
			}
			
			return new GLib.Settings.full (schema, null, path);
		}
		
		FileMonitor trash_monitor;
		File owned_file;
		bool confirm_trash_delete = true;
		
		/**
		 * {@inheritDoc}
		 */
		public TrashDockItem.with_dockitem_file (GLib.File file)
		{
			GLib.Object (Prefs: new DockItemPreferences.with_file (file));
		}
		
		construct
		{
			owned_file = File.new_for_uri ("trash://");
			update ();
			
			try {
				trash_monitor = owned_file.monitor (0);
				trash_monitor.changed.connect (trash_changed);
			} catch (Error e) {
				warning ("Could not start file monitor for trash.");
			}
			
			//FIXME Add support for more environments besides GNOME
			var nautilus_settings = create_settings ("org.gnome.nautilus.preferences", "/org/gnome/nautilus/preferences/");
			if (nautilus_settings != null && ("confirm-trash" in nautilus_settings.list_keys ()))
				confirm_trash_delete = nautilus_settings.get_boolean ("confirm-trash");
		}
		
		~TrashDockItem ()
		{
			if (trash_monitor != null) {
				trash_monitor.changed.disconnect (trash_changed);
				trash_monitor.cancel ();
				trash_monitor = null;
			}
		}
		
		[CCode (instance_pos = -1)]
		void trash_changed (File f, File? other, FileMonitorEvent event)
		{
			update ();
		}
		
		void update ()
		{
			// this can be a little costly, let's just call it once and store locally
			var item_count = get_trash_item_count ();
			if (item_count == 0U)
				Text = _("No items in Trash");
			else
				Text = ngettext ("%u item in Trash", "%u items in Trash", item_count).printf (item_count);
			
			Icon = DrawingService.get_icon_from_file (owned_file);
		}
		
		uint32 get_trash_item_count ()
		{
			try {
				return owned_file.query_info (FileAttribute.TRASH_ITEM_COUNT, 0, null).get_attribute_uint32 (FileAttribute.TRASH_ITEM_COUNT);
			} catch (GLib.Error e) {
				warning ("Could not get item count from trash::item-count.");
			}
			
			return 0U;
		}
		
		protected override AnimationType on_clicked (PopupButton button, Gdk.ModifierType mod, uint32 event_time)
		{
			if (button == PopupButton.LEFT) {
				open_trash ();
				return AnimationType.BOUNCE;
			}
			
			return AnimationType.NONE;
		}
		
		public override string get_drop_text ()
		{
			return _("Drop to move to Trash");
		}
		
		protected override bool can_accept_drop (Gee.ArrayList<string> uris)
		{
			bool accepted = false;
			
			foreach (string uri in uris)
				accepted |= File.new_for_uri (uri).query_exists ();
			
			return accepted;
		}
		
		protected override bool accept_drop (Gee.ArrayList<string> uris)
		{
			bool accepted = false;
			
			foreach (string uri in uris)
				accepted |= receive_item (uri);
			
			if (accepted)
				update ();
			
			return accepted;
		}
		
		static inline bool receive_item (string uri)
		{
			bool trashed = false;
			
			try {
				trashed = File.new_for_uri (uri).trash (null);
			} catch { }
			
			if (!trashed)
				warning ("Could not move '%s' to trash.'", uri);
			
			return trashed;
		}
		
		public override Gee.ArrayList<Gtk.MenuItem> get_menu_items ()
		{
			var items = new Gee.ArrayList<Gtk.MenuItem> ();
			
			try {
				var enumerator = owned_file.enumerate_children (FileAttribute.STANDARD_TYPE + ","
					+ FileAttribute.STANDARD_NAME, FileQueryInfoFlags.NOFOLLOW_SYMLINKS, null);
				var files = new Gee.ArrayList<File> ();
				
				if (enumerator != null) {
					FileInfo info;
					
					while ((info = enumerator.next_file ()) != null)
						files.add (owned_file.get_child (info.get_name ()));
					
					enumerator.close (null);
				}
				
				if (files.size > 0)
					items.add (new TitledSeparatorMenuItem.no_line (_("Restore Files")));
				
				files.sort ((CompareDataFunc) compare_files);
				
				var count = 0;
				foreach (File _f in files) {
					var f = _f;
					var item = create_menu_item (f.get_basename (), DrawingService.get_icon_from_file (f));
					item.activate.connect (() => restore_file (f));
					items.add (item);
					
					if (++count == 5)
						break;
				}
				
				if (files.size > 0)
					items.add (new Gtk.SeparatorMenuItem ());
			} catch (GLib.Error e) {
				warning ("Could not enumerate items in the trash.");
			}
			
			var item = create_menu_item (_("_Open Trash"), Icon);
			item.activate.connect (open_trash);
			items.add (item);
			
			item = create_menu_item (_("Empty _Trash"), "gtk-clear");
			item.activate.connect (empty_trash);
			if (get_trash_item_count () == 0U)
				item.set_sensitive (false);
			items.add (item);
			
			return items;
		}
		
		static int compare_files (File left, File right)
		{
			try {
				unowned string? left_info = left.query_info (FileAttribute.TRASH_DELETION_DATE, 0, null).get_attribute_string (FileAttribute.TRASH_DELETION_DATE);
				unowned string? right_info = right.query_info (FileAttribute.TRASH_DELETION_DATE, 0, null).get_attribute_string (FileAttribute.TRASH_DELETION_DATE);
				return strcmp (right_info, left_info);
			} catch (GLib.Error e) {
				warning ("Could not enumerate items in the trash.");
				return 0;
			}
		}
		
		void restore_file (File f)
		{
			try {
				unowned string? orig_path = f.query_info (FileAttribute.TRASH_ORIG_PATH, 0, null).get_attribute_string (FileAttribute.TRASH_ORIG_PATH);
				if (orig_path != null) {
					var destFile = File.new_for_path (orig_path);
					f.move (destFile, FileCopyFlags.NOFOLLOW_SYMLINKS | FileCopyFlags.ALL_METADATA | FileCopyFlags.NO_FALLBACK_FOR_MOVE, null, null);
				}
			} catch (GLib.Error e) {
				warning ("Could not restore file from the trash.");
			}
		}
		
		void open_trash ()
		{
			System.get_default ().open (owned_file);
		}
		
		void empty_trash ()
		{
			if (environment_is_session_desktop (XdgSessionDesktop.GNOME | XdgSessionDesktop.UNITY)) {
				// Try using corresponding DBus-interface of Nautilus if available (GNOME, Unity)
				try {
					NautilusFileOperations nautilus_file_operations = Bus.get_proxy_sync (BusType.SESSION,
						"org.gnome.Nautilus", "/org/gnome/Nautilus");
					nautilus_file_operations.empty_trash ();
				} catch {
					empty_trash_internal ();
				}
			} else {
				empty_trash_internal ();
			}
		}
		
		void empty_trash_internal ()
		{
			if (!confirm_trash_delete) {
				perform_empty_trash ();
				return;
			}
			
			var md = new Gtk.MessageDialog (null, 0, Gtk.MessageType.WARNING, Gtk.ButtonsType.NONE,
				"%s", _("Empty all items from Trash?"));
			md.secondary_text = _("All items in the Trash will be permanently deleted.");
			md.add_button (_("_Cancel"), Gtk.ResponseType.CANCEL);
			md.add_button (_("Empty _Trash"), Gtk.ResponseType.OK);
			md.set_default_response (Gtk.ResponseType.OK);
			
			md.response.connect ((response_id) => {
				if (response_id != Gtk.ResponseType.CANCEL)
					perform_empty_trash ();
				md.destroy ();
			});
			
			md.show ();
		}
		
		void perform_empty_trash ()
		{
			// disable events for a minute
			if (trash_monitor != null)
				trash_monitor.changed.disconnect (trash_changed);
			
			Worker.get_default ().add_task_with_result.begin<void*> (() => {
				delete_children_recursive (owned_file);
				return null;
			}, TaskPriority.HIGH, () => {
				// enable events again
				if (trash_monitor != null)
					trash_monitor.changed.connect (trash_changed);
				update ();
			});
		}
		
		static void delete_children_recursive (GLib.File file)
		{
			FileEnumerator? enumerator = null;
			
			try {
				enumerator = file.enumerate_children (FileAttribute.STANDARD_TYPE + ","	+ FileAttribute.STANDARD_NAME + ","
					+ FileAttribute.ACCESS_CAN_DELETE, FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
			} catch (Error e) {
				critical (e.message);
			}
			
			if (enumerator == null)
				return;
			
			try {
				FileInfo info;
				while ((info = enumerator.next_file ()) != null) {
					File child = file.get_child (info.get_name ());
					if (info.get_file_type () == FileType.DIRECTORY)
						delete_children_recursive (child);
					try {
						if (info.get_attribute_boolean (FileAttribute.ACCESS_CAN_DELETE))
							child.delete (null);
					} catch {
						// if it fails to delete, not much we can do!
					}
				}
				enumerator.close (null);
			} catch (Error e) {
				critical (e.message);
			}
		}
	}
}
