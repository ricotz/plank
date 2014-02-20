//
//  Copyright (C) 2011 Robert Dyer, Rico Tzschichholz
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

using Cairo;
using Gdk;
using Gee;
using Gtk;

using Plank.Drawing;
using Plank.Services;

namespace Plank.Items
{
	/**
	 * A dock item for files or folders on the dock.
	 *
	 * Folders act like stacks and display the contents of the folder in the
	 * popup menu. Files just open the associated file.
	 */
	public class FileDockItem : DockItem
	{
		const string DEFAULT_ICON = "inode-directory";
		
		File OwnedFile { get; set; }
		FileMonitor? dir_monitor;
		
		/**
		 * {@inheritDoc}
		 */
		public FileDockItem.with_dockitem_file (GLib.File file)
		{
			GLib.Object (Prefs: new DockItemPreferences.with_file (file));
		}

		/**
		 * {@inheritDoc}
		 */
		public FileDockItem.with_dockitem_filename (string filename)
		{
			GLib.Object (Prefs: new DockItemPreferences.with_filename (filename));
		}
		
		construct
		{
			Prefs.notify["Launcher"].connect (handle_launcher_changed);
			
			if (!is_valid ())
				return;
			
			OwnedFile = File.new_for_uri (Prefs.Launcher);
			
			load_from_launcher ();
		}
		
		~FileDockItem ()
		{
			Prefs.notify["Launcher"].disconnect (handle_launcher_changed);
			
			stop_monitor ();
		}
		
		void load_from_launcher ()
		{
			stop_monitor ();
			
			Icon = DrawingService.get_icon_from_file (OwnedFile) ?? DEFAULT_ICON;
			
			if (!OwnedFile.is_native ()) {
				Text = OwnedFile.get_uri ();
				return;
			}
			
			Text = OwnedFile.get_basename () ?? "";
			
			// pop up the dir contents on a left click too
			if (OwnedFile.query_file_type (0) == FileType.DIRECTORY) {
				Button = PopupButton.RIGHT | PopupButton.LEFT;
				
				try {
					dir_monitor = OwnedFile.monitor (0);
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
		
		void handle_dir_changed (File f, File? other, FileMonitorEvent event)
		{
			reset_icon_buffer ();
		}
		
		/**
		 * {@inheritDoc}
		 */
		protected override void draw_icon (DockSurface surface)
		{
			if (!Icon.has_prefix (DEFAULT_ICON)) {
				base.draw_icon (surface);
				return;
			}
			
			unowned Context cr = surface.Context;
			var width = surface.Width;
			var height = surface.Height;
			var radius = 3 + 6 * height / (128 - 48);
			
			cr.move_to (radius, 0.5);
			cr.arc (width - radius - 0.5, radius + 0.5, radius, -Math.PI_2, 0);
			cr.arc (width - radius - 0.5, height - radius - 0.5, radius, 0, Math.PI_2);
			cr.arc (radius + 0.5, height - radius - 0.5, radius, Math.PI_2, Math.PI);
			cr.arc (radius + 0.5, radius + 0.5, radius, Math.PI, -Math.PI_2);
			
			cr.set_source_rgba (1, 1, 1, 0.6);
			cr.set_line_width (1);
			cr.stroke_preserve ();
			
			var rg = new Pattern.radial (width / 2, height, height / 8, width / 2, height, height);
			rg.add_color_stop_rgba (0, 0, 0, 0, 1);
			rg.add_color_stop_rgba (1, 0, 0, 0, 0.6);
			
			cr.set_source (rg);
			cr.fill ();
			
#if HAVE_GEE_0_8
			var icons = new HashMap<string, string> ();
#else
			var icons = new HashMap<string, string> (str_hash, str_equal);
#endif
			var keys = new ArrayList<string> ();
			
			foreach (var file in get_files ()) {
				string icon, text;
				var uri = file.get_uri ();
				if (uri.has_suffix (".desktop")) {
					ApplicationDockItem.parse_launcher (uri, out icon, out text);
				} else {
					icon = DrawingService.get_icon_from_file (file) ?? "";
					text = file.get_basename () ?? "";
				}
				
				icons.set (text + uri, icon);
				keys.add (text + uri);
			}
			
			var pos = 0;
			var icon_width = (int) ((width - 80 * radius / 33.0) / 2.0);
			var icon_height = (int) ((height - 80 * radius / 33.0) / 2.0);
			var offset = (int) ((width - 2 * icon_width) / 3.0);
			
#if HAVE_GEE_0_8
			keys.sort ();
#else
			keys.sort ((CompareFunc) strcmp);
#endif
			foreach (var s in keys) {
				var x = pos % 2;
				int y = pos / 2;
				
				if (++pos > 4)
					break;
				
				var pbuf = DrawingService.load_icon (icons.get (s), icon_width, icon_height);
				cairo_set_source_pixbuf (cr, pbuf,
					x * (icon_width + offset) + offset + (icon_width - pbuf.width) / 2,
					y * (icon_height + offset) + offset + (icon_height - pbuf.height) / 2);
				cr.paint ();
			}
		}
		
		void handle_launcher_changed ()
		{
			OwnedFile = File.new_for_uri (Prefs.Launcher);
			
			load_from_launcher ();
			
			launcher_changed ();
		}
		
		/**
		 * Launches the application associated with this item.
		 */
		public void launch ()
		{
			Services.System.open (OwnedFile);
			ClickedAnimation = Animation.BOUNCE;
			LastClicked = new DateTime.now_utc ();
		}
		
		/**
		 * {@inheritDoc}
		 */
		protected override Animation on_clicked (PopupButton button, ModifierType mod)
		{
			if (button == PopupButton.MIDDLE) {
				launch ();
				return Animation.BOUNCE;
			}
			
			// this actually only happens if its a file, not a directory
			if (button == PopupButton.LEFT) {
				launch ();
				return Animation.BOUNCE;
			}
			
			return Animation.NONE;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override ArrayList<Gtk.MenuItem> get_menu_items ()
		{
			if (OwnedFile.query_file_type (0) == FileType.DIRECTORY)
				return get_dir_menu_items ();
			
			return get_file_menu_items ();
		}
		
		ArrayList<Gtk.MenuItem> get_dir_menu_items ()
		{
			var items = new ArrayList<Gtk.MenuItem> ();
		
#if HAVE_GEE_0_8
			var menu_items = new HashMap<string, Gtk.MenuItem> ();
#else
			var menu_items = new HashMap<string, Gtk.MenuItem> (str_hash, str_equal);
#endif
			var keys = new ArrayList<string> ();
			
			foreach (var file in get_files ()) {
				Gtk.MenuItem item;
				string icon, text;
				var uri = file.get_uri ();
				if (uri.has_suffix (".desktop")) {
					ApplicationDockItem.parse_launcher (uri, out icon, out text);
					item = create_menu_item (text, icon, true);
					item.activate.connect (() => {
						Services.System.launch (file);
						ClickedAnimation = Animation.BOUNCE;
						LastClicked = new DateTime.now_utc ();
					});
				} else {
					icon = DrawingService.get_icon_from_file (file) ?? "";
					text = file.get_basename () ?? "";
					item = create_menu_item (text, icon, true);
					item.activate.connect (() => {
						Services.System.open (file);
						ClickedAnimation = Animation.BOUNCE;
						LastClicked = new DateTime.now_utc ();
					});
				}
				
				menu_items.set (text + uri, item);
				keys.add (text + uri);
			}
			
#if HAVE_GEE_0_8
			keys.sort ();
#else
			keys.sort ((CompareFunc) strcmp);
#endif
			foreach (var s in keys)
				items.add (menu_items.get (s));
			
			if (keys.size > 0)
				items.add (new SeparatorMenuItem ());
			
			var delete_item = new CheckMenuItem.with_mnemonic (_("_Keep in Dock"));
			delete_item.active = true;
			delete_item.activate.connect (() => delete ());
			items.add (delete_item);
			
			var item = create_menu_item (_("_Open in File Browser"), "gtk-open");
			item.activate.connect (() => {
				launch ();
			});
			items.add (item);
			
			return items;
		}
		
		ArrayList<Gtk.MenuItem> get_file_menu_items ()
		{
			var items = new ArrayList<Gtk.MenuItem> ();
			
			var delete_item = new CheckMenuItem.with_mnemonic (_("_Keep in Dock"));
			delete_item.active = true;
			delete_item.activate.connect (() => delete ());
			items.add (delete_item);
			
			var item = create_menu_item (_("_Open"), "gtk-open");
			item.activate.connect (launch);
			items.add (item);
			
			item = create_menu_item (_("Open Containing _Folder"), "folder");
			item.activate.connect (() => {
				Services.System.open (OwnedFile.get_parent ());
				ClickedAnimation = Animation.BOUNCE;
				LastClicked = new DateTime.now_utc ();
			});
			items.add (item);
			
			return items;
		}
		
		ArrayList<File> get_files ()
		{
			var files = new ArrayList<File> ();
			
			try {
				var enumerator = OwnedFile.enumerate_children (FileAttribute.STANDARD_NAME + ","
					+ FileAttribute.STANDARD_IS_HIDDEN + ","
					+ FileAttribute.ACCESS_CAN_READ, 0);
				
				FileInfo info;
				
				while ((info = enumerator.next_file ()) != null) {
					if (info.get_is_hidden ())
						continue;
				
					files.add (OwnedFile.get_child (info.get_name ()));
				}
			} catch { }
			
			return files;
		}
	}
}
