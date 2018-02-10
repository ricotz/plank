//
//  Copyright (C) 2011 Robert Dyer
//  Copyright (C) 2018 Faissal Bensefia
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
	public class BatteryDockItem : DockletItem
	{
		Pango.Layout layout;
		int capacity = -1;
		string status = "Unknown";
		uint battery_mon_id = 0U;
		bool low_bat = false;

		/**
		 * {@inheritDoc}
		 */
		public BatteryDockItem.with_dockitem_file (GLib.File file)
		{
			GLib.Object (Prefs: new BatteryPreferences.with_file(file));
		}

		construct
		{
			layout = new Pango.Layout(Gdk.pango_context_get());
			var font_description = new Gtk.Style().font_desc;
			font_description.set_weight(Pango.Weight.BOLD);
			layout.set_font_description(font_description);
			layout.set_ellipsize(Pango.EllipsizeMode.NONE);

			Icon = "Battery";
			Text = _("Battery");

			unowned BatteryPreferences prefs = (BatteryPreferences)Prefs;
			battery_mon_id = Gdk.threads_add_timeout(1000, (SourceFunc)update_bat);
		}

		~BatteryDockItem()
		{
			if (battery_mon_id > 0U)
			{
				GLib.Source.remove(battery_mon_id);
			}
			unowned BatteryPreferences prefs = (BatteryPreferences)Prefs;
		}

		int get_capacity()
		{
			string cap;
			try
			{
				FileUtils.get_contents(BAT_CAP, out cap);
				return int.parse(cap);
			}
			catch
			{
				return -1;
			}
		}

		string get_status()
		{
			string stat;
			try
			{
				FileUtils.get_contents(BAT_STAT, out stat);
				return stat.chomp();
			}
			catch
			{
				return "Unknown";
			}
		}

		bool low_battery()
		{
			string alarm;
			string charge;
			try
			{
				FileUtils.get_contents(BAT_CHARGE, out charge);
				FileUtils.get_contents(BAT_ALARM, out alarm);
				if (int.parse(charge) <= int.parse(alarm))
				{
					return true;
				}
				else
				{
					return false;
				}
			}
			catch
			{
				return false;
			}
		}

		bool update_bat()
		{
			var cur_cap = get_capacity();
			var cur_stat = get_status();
			var cur_low_bat = low_battery();

			if (cur_cap!=capacity || cur_stat!=status || cur_low_bat!=low_bat)
			{
				reset_icon_buffer();
			}
			capacity=cur_cap;
			status=cur_stat;
			low_bat=cur_low_bat;
			return true;
		}

		void handle_prefs_changed()
		{
			unowned BatteryPreferences prefs = (BatteryPreferences)Prefs;
			reset_icon_buffer();
		}

		protected override void draw_icon(Surface surface)
		{
			int txtSize = surface.Height / 2;
			unowned BatteryPreferences prefs = (BatteryPreferences)Prefs;
			unowned Cairo.Context cr = surface.Context;

			layout.set_width ((int) (surface.Width * Pango.SCALE));
			layout.get_font_description().set_absolute_size ((int)(txtSize * Pango.SCALE));

			if (status=="Charging" || status=="Full")
			{
				layout.set_text("⚡", -1);
				cr.move_to(0,txtSize);
				//Stick the layout on the context
				Pango.cairo_layout_path(cr, layout);

				cr.set_line_width(3);
				cr.set_source_rgba(0, 0, 0, 0.5);
				cr.stroke_preserve();
				cr.set_source_rgba(1, 0.89, 0, 1);
				cr.fill();
			}

			if (low_bat)
			{
				layout.set_text("!", -1);
				cr.move_to(txtSize,txtSize);
				Pango.cairo_layout_path(cr, layout);

				cr.set_line_width(3);
				cr.set_source_rgba(0, 0, 0, 0.5);
				cr.stroke_preserve();
				cr.set_source_rgba(1, 0, 0, 1);
				cr.fill();
			}

			layout.set_text(capacity.to_string()+"%", -1);
			cr.move_to(0,0);
			Pango.cairo_layout_path(cr, layout);
			cr.set_line_width(3);
			cr.set_source_rgba(0, 0, 0, 0.5);
			cr.stroke_preserve();
			cr.set_source_rgba(1, 1, 1, 1);
			cr.fill();
		}

		void render_file_onto_context (Cairo.Context cr, string uri, int size)
		{
			var pbuf = DrawingService.load_icon(uri, size, size);
			Gdk.cairo_set_source_pixbuf(cr, pbuf, 0, 0);
			cr.paint();
		}

		public override Gee.ArrayList<Gtk.MenuItem> get_menu_items()
		{
			unowned BatteryPreferences prefs = (BatteryPreferences)Prefs;
			var items = new Gee.ArrayList<Gtk.MenuItem>();
			//Add menu items here as needed
			return items;
		}
	}
}
