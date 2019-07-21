//
//  Copyright (C) 2011 Robert Dyer
//  
//  Calendar docklet by Kuravi Hewawasam 2019.
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
	public class CalendarDockItem : DockletItem
	{
		File owned_file;

		const string THEME_BASE_URI = "resource://" + Docky.G_RESOURCE_PATH + "/themes/";
		
		Pango.Layout layout;
		uint timer_id = 0U;
		int minute;
		string current_theme;


		/**
		 * {@inheritDoc}
		 */
		public CalendarDockItem.with_dockitem_file (GLib.File file)
		{
			GLib.Object (Prefs: new CalendarPreferences.with_file (file));
		}
		
		construct
		{
			owned_file = File.new_for_path ("/usr/share/applications/io.elementary.calendar.desktop");

			// shared by all text
			layout = new Pango.Layout (Gdk.pango_context_get ());
			var font_description = new Gtk.Style ().font_desc;
			font_description.set_weight (Pango.Weight.BOLD);
			layout.set_font_description (font_description);
			layout.set_ellipsize (Pango.EllipsizeMode.NONE);
			
			Text = "time";
			
			unowned CalendarPreferences prefs = (CalendarPreferences) Prefs;
			prefs.notify["ShowMonth"].connect (handle_prefs_changed);
			prefs.notify["ShowDay"].connect (handle_prefs_changed);

			timer_id = Gdk.threads_add_timeout (1000, (SourceFunc) update_timer);
			current_theme = THEME_BASE_URI + "Default";
		}
		
		~CalendarDockItem ()
		{
			if (timer_id > 0U)
				GLib.Source.remove (timer_id);
			
			unowned CalendarPreferences prefs = (CalendarPreferences) Prefs;
			prefs.notify["ShowMonth"].disconnect (handle_prefs_changed);
			prefs.notify["ShowDay"].disconnect (handle_prefs_changed);
		}
		
		bool update_timer ()
		{
			var now = new DateTime.now_local ();
			if (minute != now.get_minute ()) {
				reset_icon_buffer ();
				minute = now.get_minute ();
			}
			return true;
		}
		
		protected override AnimationType on_clicked (PopupButton button, Gdk.ModifierType mod, uint32 event_time)
		{
			if (button == PopupButton.LEFT) {
				System.get_default ().launch (owned_file);
				return AnimationType.BOUNCE;
			}
			return AnimationType.NONE;
		}
		
		void handle_prefs_changed ()
		{
			reset_icon_buffer ();
		}
		
		protected override void draw_icon (Surface surface)
		{
			var now = new DateTime.now_local ();
			Text = now.format ("%a, %b %d %I:%M %p");
			var size = int.max (surface.Width, surface.Height);
			render_calendar (surface, now, size);
		}
		
		void render_file_onto_context (Cairo.Context cr, string uri, int size)
		{
			var pbuf = DrawingService.load_icon (uri, size, size);
			Gdk.cairo_set_source_pixbuf (cr, pbuf, 0, 0);
			cr.paint ();
		}
		
		void render_calendar (Surface surface, DateTime now, int size)
		{
			unowned CalendarPreferences prefs = (CalendarPreferences) Prefs;
			unowned Cairo.Context cr = surface.Context;

			render_file_onto_context (cr, current_theme + "/calendar.svg", surface.Height );

			layout.set_width ((int) (surface.Width * Pango.SCALE));

			Pango.Rectangle ink_rect, logical_rect;
			
			layout.set_alignment (Pango.Alignment.CENTER);

			//  month
			if (prefs.ShowMonth) {
				layout.get_font_description ().set_absolute_size ((int) (12 * surface.Height / 100 * Pango.SCALE));
				layout.set_text (now.format ("%B"), -1);
				layout.get_pixel_extents (out ink_rect, out logical_rect);

				cr.move_to (0, 10 * surface.Height / 100);
				
				Pango.cairo_layout_path (cr, layout);
				cr.set_source_rgba (19/255, 100/255, 0, 0.4);
				cr.fill ();
			}

			//  day
			if (prefs.ShowDay) {
				layout.get_font_description ().set_absolute_size ((int) (9 * surface.Height / 100 * Pango.SCALE));
				layout.set_text (now.format ("%A"), -1);
				layout.get_pixel_extents (out ink_rect, out logical_rect);

				cr.move_to (0, 31.5 * surface.Height / 100);
				
				Pango.cairo_layout_path (cr, layout);
				cr.set_source_rgba (94/255, 85/255, 60/255, 0.25);
				cr.fill ();
			}

			//  date
			layout.get_font_description ().set_absolute_size ((int) (42 * surface.Height / 100 * Pango.SCALE));
			layout.set_text (now.format ("%d"), -1);
			layout.get_pixel_extents (out ink_rect, out logical_rect);

			cr.move_to (0, 33 * surface.Height / 100);
			
			Pango.cairo_layout_path (cr, layout);
			cr.set_source_rgba (94/255, 85/255, 60/255, 0.25);
			cr.fill ();
		}

		public override Gee.ArrayList<Gtk.MenuItem> get_menu_items ()
		{
			unowned CalendarPreferences prefs = (CalendarPreferences) Prefs;
			var items = new Gee.ArrayList<Gtk.MenuItem> ();
			
			var checked_item = new Gtk.CheckMenuItem.with_mnemonic (_("Show Day of the Week"));
			checked_item.active = prefs.ShowDay;
			checked_item.activate.connect (() => {
				prefs.ShowDay = !prefs.ShowDay;
			});
			items.add (checked_item);
			
			checked_item = new Gtk.CheckMenuItem.with_mnemonic (_("Show Month"));
			checked_item.active = prefs.ShowMonth;
			checked_item.activate.connect (() => {
				prefs.ShowMonth = !prefs.ShowMonth;
			});
			items.add (checked_item);

			return items;
		}
	}
}
