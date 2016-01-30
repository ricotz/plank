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
	public class ClockDockItem : DockletItem
	{
		const string THEME_BASE_URI = "resource://" + Docky.G_RESOURCE_PATH + "/themes/";
		
		Pango.Layout layout;
		uint timer_id = 0U;
		int minute;
		string current_theme;
		
		/**
		 * {@inheritDoc}
		 */
		public ClockDockItem.with_dockitem_file (GLib.File file)
		{
			GLib.Object (Prefs: new ClockPreferences.with_file (file));
		}
		
		construct
		{
			// shared by all text
			layout = new Pango.Layout (Gdk.pango_context_get ());
			var font_description = new Gtk.Style ().font_desc;
			font_description.set_weight (Pango.Weight.BOLD);
			layout.set_font_description (font_description);
			layout.set_ellipsize (Pango.EllipsizeMode.NONE);
			
			Icon = "clock";
			Text = "time";
			
			unowned ClockPreferences prefs = (ClockPreferences) Prefs;
			prefs.notify["ShowMilitary"].connect (handle_prefs_changed);
			prefs.notify["ShowDate"].connect (handle_prefs_changed);
			prefs.notify["ShowDigital"].connect (handle_prefs_changed);
			
			timer_id = Gdk.threads_add_timeout (1000, (SourceFunc) update_timer);
			current_theme = (prefs.ShowMilitary ? THEME_BASE_URI + "Default24" : THEME_BASE_URI + "Default");
		}
		
		~ClockDockItem ()
		{
			if (timer_id > 0U)
				GLib.Source.remove (timer_id);
			
			unowned ClockPreferences prefs = (ClockPreferences) Prefs;
			prefs.notify["ShowMilitary"].disconnect (handle_prefs_changed);
			prefs.notify["ShowDate"].disconnect (handle_prefs_changed);
			prefs.notify["ShowDigital"].disconnect (handle_prefs_changed);
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
		
		void handle_prefs_changed ()
		{
			unowned ClockPreferences prefs = (ClockPreferences) Prefs;
			current_theme = (prefs.ShowMilitary ? THEME_BASE_URI + "Default24" : THEME_BASE_URI + "Default");
			
			reset_icon_buffer ();
		}
		
		protected override void draw_icon (Surface surface)
		{
			unowned ClockPreferences prefs = (ClockPreferences) Prefs;
			
			var now = new DateTime.now_local ();
			if (prefs.ShowMilitary)
				Text = now.format ("%a, %b %d %H:%M");
			else
				Text = now.format ("%a, %b %d %I:%M %p");
			
			var size = int.max (surface.Width, surface.Height);
			if (prefs.ShowDigital)
				render_digital_clock (surface, now, size);
			else
				render_analog_clock (surface.Context, now, size);
		}
		
		void render_file_onto_context (Cairo.Context cr, string uri, int size)
		{
			var pbuf = DrawingService.load_icon (uri, size, size);
			Gdk.cairo_set_source_pixbuf (cr, pbuf, 0, 0);
			cr.paint ();
		}
		
		void render_digital_clock (Surface surface, DateTime now, int size)
		{
			unowned ClockPreferences prefs = (ClockPreferences) Prefs;
			unowned Cairo.Context cr = surface.Context;
			
			// useful sizes
			int timeSize = surface.Height / 4;
			int dateSize = surface.Height / 5;
			int ampmSize = surface.Height / 5;
			int spacing = timeSize / 2;
			int center = surface.Height / 2;
			
			layout.set_width ((int) (surface.Width * Pango.SCALE));
			
			// draw the time, outlined
			layout.get_font_description ().set_absolute_size ((int) (timeSize * Pango.SCALE));
			
			if (prefs.ShowMilitary)
				layout.set_text (now.format ("%H:%M"), -1);
			else
				layout.set_text (now.format ("%l:%M").chug (), -1);
			
			Pango.Rectangle ink_rect, logical_rect;
			layout.get_pixel_extents (out ink_rect, out logical_rect);
			
			int timeYOffset = prefs.ShowMilitary ? timeSize : timeSize / 2;
			int timeXOffset = (surface.Width - ink_rect.width) / 2;
			if (prefs.ShowDate)
				cr.move_to (timeXOffset, timeYOffset);
			else
				cr.move_to (timeXOffset, timeYOffset + timeSize / 2);
			
			Pango.cairo_layout_path (cr, layout);
			cr.set_line_width (3);
			cr.set_source_rgba (0, 0, 0, 0.5);
			cr.stroke_preserve ();
			cr.set_source_rgba (1, 1, 1, 0.8);
			cr.fill ();
			
			// draw the date, outlined
			if (prefs.ShowDate) {
				layout.get_font_description ().set_absolute_size ((int) (dateSize * Pango.SCALE));
				
				layout.set_text (now.format ("%b %d"), -1);
				layout.get_pixel_extents (out ink_rect, out logical_rect);
				cr.move_to ((surface.Width - ink_rect.width) / 2, surface.Height - spacing - dateSize);
				
				Pango.cairo_layout_path (cr, layout);
				cr.set_line_width (2.5);
				cr.set_source_rgba (0, 0, 0, 0.5);
				cr.stroke_preserve ();
				cr.set_source_rgba (1, 1, 1, 0.8);
				cr.fill ();
			}
			
			if (!prefs.ShowMilitary) {
				layout.get_font_description ().set_absolute_size ((int) (ampmSize * Pango.SCALE));
				
				int yOffset = (prefs.ShowDate ? center - spacing : surface.Height - spacing - ampmSize);
				
				// draw AM indicator
				layout.set_text ("am", -1);
				layout.get_pixel_extents (out ink_rect, out logical_rect);
				cr.move_to ((center - ink_rect.width) / 2, yOffset);
				Pango.cairo_layout_path (cr, layout);
				cr.set_line_width (2);
				if (now.get_hour () < 12)
					cr.set_source_rgba (0, 0, 0, 0.5);
				else
					cr.set_source_rgba (1, 1, 1, 0.4);
				cr.stroke_preserve ();
				if (now.get_hour () < 12)
					cr.set_source_rgba (1, 1, 1, 0.8);
				else
					cr.set_source_rgba (0, 0, 0, 0.5);
				cr.fill ();
				
				// draw PM indicator
				layout.set_text ("pm", -1);
				layout.get_pixel_extents (out ink_rect, out logical_rect);
				cr.move_to (center + (center - ink_rect.width) / 2, yOffset);
				Pango.cairo_layout_path (cr, layout);
				cr.set_line_width (2);
				if (now.get_hour () < 12)
					cr.set_source_rgba (1, 1, 1, 0.4);
				else
					cr.set_source_rgba (0, 0, 0, 0.5);
				cr.stroke_preserve ();
				if (now.get_hour () < 12)
					cr.set_source_rgba (0, 0, 0, 0.5);
				else
					cr.set_source_rgba (1, 1, 1, 0.8);
				cr.fill ();
			}
		}
		
		void render_analog_clock (Cairo.Context cr, DateTime now, int size)
		{
			int center = size / 2;
			var radius = center;
			
			render_file_onto_context (cr, current_theme + "/clock-drop-shadow.svg", radius * 2);
			render_file_onto_context (cr, current_theme + "/clock-face-shadow.svg", radius * 2);
			render_file_onto_context (cr, current_theme + "/clock-face.svg", radius * 2);
			render_file_onto_context (cr, current_theme + "/clock-marks.svg", radius * 2);
			
			cr.translate (center, center);
			cr.set_source_rgba (0.15, 0.15, 0.15, 1);
			
			cr.set_line_width (double.max (1.0, size / 48.0));
			cr.set_line_cap (Cairo.LineCap.ROUND);
			var minuteRotation = Math.PI * (now.get_minute () / 30.0 + 1.0);
			cr.rotate (minuteRotation);
			cr.move_to (0, radius - radius * 0.35);
			cr.line_to (0, 0 - radius * 0.15);
			cr.stroke ();
			cr.rotate (0 - minuteRotation);
			
			cr.set_source_rgba (0, 0, 0, 1);
			var total_hours = (current_theme.has_suffix ("24") ? 24 : 12);
			var hourRotation = Math.PI * ((now.get_hour () % total_hours) / (total_hours / 2.0) + now.get_minute () / (30.0 * total_hours) + 1.0);
			cr.rotate (hourRotation);
			cr.move_to (0, radius - radius * 0.5);
			cr.line_to (0, 0 - radius * 0.15);
			cr.stroke ();
			cr.rotate (0 - hourRotation);
			
			cr.translate (0 - center, 0 - center);
			
			render_file_onto_context (cr, current_theme + "/clock-glass.svg", radius * 2);
			render_file_onto_context (cr, current_theme + "/clock-frame.svg", radius * 2);
		}
		
		public override Gee.ArrayList<Gtk.MenuItem> get_menu_items ()
		{
			unowned ClockPreferences prefs = (ClockPreferences) Prefs;
			var items = new Gee.ArrayList<Gtk.MenuItem> ();
			
			var checked_item = new Gtk.CheckMenuItem.with_mnemonic (_("Di_gital Clock"));
			checked_item.active = prefs.ShowDigital;
			checked_item.activate.connect (() => {
				prefs.ShowDigital = !prefs.ShowDigital;
			});
			items.add (checked_item);
			
			checked_item = new Gtk.CheckMenuItem.with_mnemonic (_("24-Hour _Clock"));
			checked_item.active = prefs.ShowMilitary;
			checked_item.activate.connect (() => {
				prefs.ShowMilitary = !prefs.ShowMilitary;
			});
			items.add (checked_item);
			
			checked_item = new Gtk.CheckMenuItem.with_mnemonic (_("Show _Date"));
			checked_item.active = prefs.ShowDate;
			checked_item.sensitive = prefs.ShowDigital;
			checked_item.activate.connect (() => {
				prefs.ShowDate = !prefs.ShowDate;
			});
			items.add (checked_item);
			
			return items;
		}
	}
}
