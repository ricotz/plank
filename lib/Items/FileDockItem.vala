//
//  Copyright (C) 2011 Robert Dyer, Rico Tzschichholz
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
	 * A dock item for files or folders on the dock.
	 *
	 * Folders act like stacks and display the contents of the folder in the
	 * popup menu. Files just open the associated file.
	 */
	public class FileDockItem : DockItem
	{
		const string DEFAULT_ICONS = "inode-directory;;folder";
		
		public File OwnedFile { get; protected construct set; }
		
		FileMonitor? dir_monitor;
		
		/**
		 * {@inheritDoc}
		 */
		public FileDockItem.with_file (GLib.File file)
		{
			var prefs = new DockItemPreferences ();
			prefs.Launcher = file.get_uri ();
			
			GLib.Object (Prefs: prefs, OwnedFile: file);
		}
		
		/**
		 * {@inheritDoc}
		 */
		public FileDockItem.with_dockitem_file (GLib.File file)
		{
			var prefs = new DockItemPreferences.with_file (file);
			
			GLib.Object (Prefs: prefs, OwnedFile: File.new_for_uri (prefs.Launcher));
		}

		/**
		 * {@inheritDoc}
		 */
		public FileDockItem.with_dockitem_filename (string filename)
		{
			var prefs = new DockItemPreferences.with_filename (filename);
			
			GLib.Object (Prefs: prefs, OwnedFile: File.new_for_uri (prefs.Launcher));
		}
		
		construct
		{
			load_from_launcher ();
		}
		
		~FileDockItem ()
		{
			stop_monitor ();
		}
		
		/**
		 * {@inheritDoc}
		 */
		protected override void load_from_launcher ()
		{
			stop_monitor ();
			
			if (Prefs.Launcher == "")
				return;
			
			OwnedFile = File.new_for_uri (Prefs.Launcher);
			Icon = DrawingService.get_icon_from_file (OwnedFile) ?? DEFAULT_ICONS;
			
			if (!OwnedFile.is_native ()) {
				Text = OwnedFile.get_uri ();
				return;
			}
			
			Text = get_display_name (OwnedFile);
			
			// pop up the dir contents on a left click too
			if (OwnedFile.query_file_type (0) == FileType.DIRECTORY) {
				Button = PopupButton.RIGHT | PopupButton.LEFT;
				
				try {
					dir_monitor = OwnedFile.monitor_directory (0);
					dir_monitor.changed.connect (handle_dir_changed);
				} catch {
					critical ("Unable to watch the stack directory '%s'.", OwnedFile.get_path () ?? "");
				}
			}
		}
		
		void stop_monitor ()
		{
			if (dir_monitor != null) {
				dir_monitor.changed.disconnect (handle_dir_changed);
				dir_monitor.cancel ();
				dir_monitor = null;
			}
		}
		
		[CCode (instance_pos = -1)]
		void handle_dir_changed (File f, File? other, FileMonitorEvent event)
		{
			reset_icon_buffer ();
		}
		
		bool has_default_icon_match ()
		{
			if (Icon == DEFAULT_ICONS)
				return true;
			
			var default_icons = DEFAULT_ICONS.split (";;");
			foreach (unowned string icon in Icon.split (";;"))
				if (icon in default_icons)
					return true;
			
			return false;
		}
		
		/**
		 * {@inheritDoc}
		 */
		protected override void draw_icon_fast (Surface surface)
		{
			unowned Cairo.Context cr = surface.Context;
			var width = surface.Width;
			var height = surface.Height;
			var radius = 3 + 6 * height / (128 - 48);
			double x_scale = 1.0, y_scale = 1.0;
#if HAVE_HIDPI
			surface.Internal.get_device_scale (out x_scale, out y_scale);
#endif
			var line_width_half = 0.5 * (int) double.max (x_scale, y_scale);
			
			cr.move_to (radius, line_width_half);
			cr.arc (width - radius - line_width_half, radius + line_width_half, radius, -Math.PI_2, 0);
			cr.arc (width - radius - line_width_half, height - radius - line_width_half, radius, 0, Math.PI_2);
			cr.arc (radius + line_width_half, height - radius - line_width_half, radius, Math.PI_2, Math.PI);
			cr.arc (radius + line_width_half, radius + line_width_half, radius, Math.PI, -Math.PI_2);
			cr.close_path ();
			
			cr.set_source_rgba (1, 1, 1, 0.6);
			cr.set_line_width (2 * line_width_half);
			cr.stroke_preserve ();
			
			var rg = new Cairo.Pattern.radial (width / 2, height, height / 8, width / 2, height, height);
			rg.add_color_stop_rgba (0, 0, 0, 0, 1);
			rg.add_color_stop_rgba (1, 0, 0, 0, 0.6);
			
			cr.set_source (rg);
			cr.fill ();
		}
		
		/**
		 * {@inheritDoc}
		 */
		protected override void draw_icon (Surface surface)
		{
			if (!is_valid () || !has_default_icon_match ()) {
				base.draw_icon (surface);
				return;
			}
			
			unowned Cairo.Context cr = surface.Context;
			var width = surface.Width;
			var height = surface.Height;
			var radius = 3 + 6 * height / (128 - 48);
			
			draw_icon_fast (surface);
			
			var icons = new Gee.HashMap<string, string> ();
			var keys = new Gee.ArrayList<string> ();
			
			get_files (OwnedFile).map_iterator ().foreach ((display_name, file) => {
				string icon, text;
				var uri = file.get_uri ();
				if (uri.has_suffix (".desktop")) {
					ApplicationDockItem.parse_launcher (uri, out icon, out text);
				} else {
					icon = DrawingService.get_icon_from_file (file) ?? "";
					text = display_name ?? "";
				}
				
				var key = "%s%s".printf (text, uri);
				icons.set (key, icon);
				keys.add (key);

				return true;
			});
			
			var pos = 0;
			var icon_width = (int) ((width - 80 * radius / 33.0) / 2.0);
			var icon_height = (int) ((height - 80 * radius / 33.0) / 2.0);
			var offset = (int) ((width - 2 * icon_width) / 3.0);
			
			keys.sort ();
			foreach (var s in keys) {
				var x = pos % 2;
				int y = pos / 2;
				
				if (++pos > 4)
					break;
				
				var pbuf = DrawingService.load_icon (icons.get (s), icon_width, icon_height);
				Gdk.cairo_set_source_pixbuf (cr, pbuf,
					x * (icon_width + offset) + offset + (icon_width - pbuf.width) / 2,
					y * (icon_height + offset) + offset + (icon_height - pbuf.height) / 2);
				cr.paint ();
			}
		}
		
		/**
		 * Launches the application associated with this item.
		 */
		public void launch ()
		{
			System.get_default ().open (OwnedFile);
			ClickedAnimation = AnimationType.BOUNCE;
			LastClicked = GLib.get_monotonic_time ();
		}
		
		/**
		 * {@inheritDoc}
		 */
		protected override AnimationType on_clicked (PopupButton button, Gdk.ModifierType mod, uint32 event_time)
		{
			if (button == PopupButton.MIDDLE) {
				launch ();
				return AnimationType.BOUNCE;
			}
			
			// this actually only happens if its a file, not a directory
			if (button == PopupButton.LEFT) {
				launch ();
				return AnimationType.BOUNCE;
			}
			
			return AnimationType.NONE;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override Gee.ArrayList<Gtk.MenuItem> get_menu_items ()
		{
			if (OwnedFile.query_file_type (0) == FileType.DIRECTORY)
				return get_dir_menu_items ();
			
			return get_file_menu_items ();
		}
		
		Gee.ArrayList<Gtk.MenuItem> get_dir_menu_items ()
		{
			var items = new Gee.ArrayList<Gtk.MenuItem> ();
		
			var menu_items = new Gee.HashMap<string, Gtk.MenuItem> ();
			var keys = new Gee.ArrayList<string> ();
			
			get_files (OwnedFile).map_iterator ().foreach ((display_name, file) => {
				Gtk.MenuItem item;
				string icon, text;
				var uri = file.get_uri ();
				if (uri.has_suffix (".desktop")) {
					ApplicationDockItem.parse_launcher (uri, out icon, out text);
					item = create_menu_item (text, icon, true);
					item.activate.connect (() => {
						System.get_default ().launch (file);
						ClickedAnimation = AnimationType.BOUNCE;
						LastClicked = GLib.get_monotonic_time ();
					});
				} else {
					icon = DrawingService.get_icon_from_file (file) ?? "";
					text = display_name ?? "";
					text = text.replace ("_", "__");
					item = create_menu_item (text, icon, true);
					item.activate.connect (() => {
						System.get_default ().open (file);
						ClickedAnimation = AnimationType.BOUNCE;
						LastClicked = GLib.get_monotonic_time ();
					});
				}
				
				var key = "%s%s".printf (text, uri);
				menu_items.set (key, item);
				keys.add (key);

				return true;
			});
			
			keys.sort ();
			foreach (var s in keys)
				items.add (menu_items.get (s));
			
			if (keys.size > 0)
				items.add (new Gtk.SeparatorMenuItem ());
			
			unowned DefaultApplicationDockItemProvider? default_provider = (Container as DefaultApplicationDockItemProvider);
			if (default_provider != null
				&& !default_provider.Prefs.LockItems) {
				var delete_item = new Gtk.CheckMenuItem.with_mnemonic (_("_Keep in Dock"));
				delete_item.active = true;
				delete_item.activate.connect (() => delete ());
				items.add (delete_item);
			}
			
			var item = create_menu_item (_("_Open in File Browser"), "gtk-open");
			item.activate.connect (() => {
				launch ();
			});
			items.add (item);
			
			return items;
		}
		
		Gee.ArrayList<Gtk.MenuItem> get_file_menu_items ()
		{
			var items = new Gee.ArrayList<Gtk.MenuItem> ();
			
			unowned DefaultApplicationDockItemProvider? default_provider = (Container as DefaultApplicationDockItemProvider);
			if (default_provider != null
				&& !default_provider.Prefs.LockItems) {
				var delete_item = new Gtk.CheckMenuItem.with_mnemonic (_("_Keep in Dock"));
				delete_item.active = true;
				delete_item.activate.connect (() => delete ());
				items.add (delete_item);
			}
			
			var item = create_menu_item (_("_Open"), "gtk-open");
			item.activate.connect (launch);
			items.add (item);
			
			item = create_menu_item (_("Open Containing _Folder"), "folder");
			item.activate.connect (() => {
				System.get_default ().open (OwnedFile.get_parent ());
				ClickedAnimation = AnimationType.BOUNCE;
				LastClicked = GLib.get_monotonic_time ();
			});
			items.add (item);
			
			return items;
		}
		
		static Gee.HashMap<string,File> get_files (File file)
		{
			var files = new Gee.HashMap<string,File> ();
			var count = 0U;
			
			try {
				var enumerator = file.enumerate_children (FileAttribute.STANDARD_NAME + ","
					+ FileAttribute.STANDARD_DISPLAY_NAME + ","
					+ FileAttribute.STANDARD_IS_HIDDEN + ","
					+ FileAttribute.ACCESS_CAN_READ, 0);
				
				FileInfo info;
				
				while ((info = enumerator.next_file ()) != null) {
					if (info.get_is_hidden ())
						continue;
					
					if (count++ >= FOLDER_MAX_FILE_COUNT) {
						critical ("There are way too many files (%u+) in '%s'.", FOLDER_MAX_FILE_COUNT, file.get_path ());
						break;
					}
					
					unowned string name = info.get_name ();
					files.set (info.get_display_name () ?? name, file.get_child (name));
				}
			} catch { }
			
			return files;
		}
		
		static string get_display_name (File file)
		{
			try {
				var info = file.query_info (FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_DISPLAY_NAME, 0);
				return info.get_display_name () ?? info.get_name ();
			} catch { }
			
			debug ("Could not get display-name for '%s'", file.get_path () ?? "");
			
			return "Unknown";
		}
	}
}
