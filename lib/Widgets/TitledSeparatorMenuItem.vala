//
//  Copyright (C) 2010 Michal Hruby <michal.mhr@gmail.com>
//  Copyright (C) 2011-2012 Robert Dyer, Rico Tzschichholz
//  Copyright (C) 2013 Rico Tzschichholz
//
//  This library is free software; you can redistribute it and/or
//  modify it under the terms of the GNU Lesser General Public
//  License as published by the Free Software Foundation; either
//  version 2.1 of the License, or (at your option) any later version.
//
//  This library is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//  Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//  Authored by Michal Hruby <michal.mhr@gmail.com>
//  Modified by Robert Dyer, Rico Tzschichholz
//

namespace Plank
{
	/**
	 * A {@link Gtk.SeparatorMenuItem} with a title on it.
	 * The separator can be drawn with or without a line.
	 */
	public class TitledSeparatorMenuItem : Gtk.SeparatorMenuItem
	{
		static construct
		{
			set_accessible_role (Atk.Role.SEPARATOR);
			PlankCompat.gtk_widget_class_set_css_name ((GLib.ObjectClass) typeof (TitledSeparatorMenuItem).class_ref (), "menuitem");
		}
		
		bool draw_line = true;
		
		string text;
		
		public TitledSeparatorMenuItem (string text)
		{
			this.text = text;
		}
		
		public TitledSeparatorMenuItem.no_line (string text)
		{
			this (text);
			draw_line = false;
		}
		
		protected override bool draw (Cairo.Context cr)
		{
			unowned Gtk.StyleContext context = get_style_context ();
			var state = context.get_state ();
			
			int x, y, w, h;
			int border_width = (int) get_border_width ();
			
			x = border_width;
			y = border_width;
			w = get_allocated_width () - 2 * border_width;
			h = get_allocated_height () - 2 * border_width;
			
			var padding = context.get_padding (state);
			
			context.render_background (cr, x, y, w, h);
			context.render_frame (cr, x, y, w, h);
			
			if (draw_line) {
				bool wide_separators;
				int separator_height;
				
				style_get ("wide-separators", out wide_separators,
					"separator-height", out separator_height);
				
				if (wide_separators)
					context.render_frame (cr, x + padding.left, y + padding.top,
						w - padding.left - padding.right, separator_height);
				else
					context.render_line (cr, x + padding.left, y + padding.top,
						x + w - padding.right - 1, y + padding.top);
			}
			
			unowned Pango.FontDescription font_desc = style.font_desc;
			font_desc.set_absolute_size ((int) (h * Pango.SCALE * Pango.Scale.LARGE));
			font_desc.set_weight (Pango.Weight.BOLD);
			
			var layout = new Pango.Layout (Gdk.pango_context_get ());
			layout.set_font_description (font_desc);
			layout.set_width ((int) ((w - padding.left - padding.right) * Pango.SCALE));
			layout.set_text (text, -1);
			
			Pango.Rectangle logical_rect;
			layout.get_pixel_extents (null, out logical_rect);
			
			context.render_background (cr, 0, y, x + logical_rect.width + padding.left + padding.right, h);
			context.render_frame (cr, 0, y, x + logical_rect.width + padding.left + padding.right, h);
			
			var color = context.get_color (state);
			cr.set_source_rgba (color.red, color.green, color.blue, color.alpha);
			cr.move_to (x + padding.left, y + (h - logical_rect.height) / 2);
			Pango.cairo_show_layout (cr, layout);
			
			return Gdk.EVENT_STOP;
		}
	}
}

