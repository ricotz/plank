//
//  Copyright (C) 2010 Michal Hruby <michal.mhr@gmail.com>
//  Copyright (C) 2011-2012 Robert Dyer, Rico Tzschichholz
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

using Cairo;
using Gdk;
using Gtk;
using Pango;

namespace Plank.Widgets
{
	/**
	 * A {@link Gtk.SeparatorMenuItem} with a title on it.
	 * The separator can be drawn with or without a line.
	 */
	public class TitledSeparatorMenuItem : SeparatorMenuItem
	{
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
			Gtk.Allocation alloc;
			get_allocation (out alloc);
			
			bool wide_separators;
			int separator_height;
			int horizontal_padding;
			
			style_get ("wide-separators", out wide_separators,
				"separator-height", out separator_height,
				"horizontal-padding", out horizontal_padding);
			
			var style = get_style ();
			
			if (draw_line) {
				var xthickness = style.xthickness;
				var ythickness = style.ythickness;
				
				if (wide_separators)
					Gtk.paint_box (style,
						cr, StateType.NORMAL, ShadowType.ETCHED_OUT,
						this, "hseparator",
						alloc.x + horizontal_padding + xthickness,
						alloc.y + (alloc.height - separator_height - ythickness)/2,
						alloc.width - 2 * (horizontal_padding + xthickness),
						separator_height);
				else
					Gtk.paint_hline (style,
						cr, StateType.NORMAL,
						this, "menuitem",
						alloc.x + horizontal_padding + xthickness,
						alloc.x + alloc.width - horizontal_padding - xthickness - 1,
						alloc.y + (alloc.height - ythickness) / 2);
			}
			
			var font_desc = style.font_desc;
			font_desc.set_absolute_size ((int) (alloc.height * Pango.SCALE * Pango.Scale.LARGE));
			font_desc.set_weight (Weight.BOLD);
			
			var layout = new Pango.Layout (pango_context_get ());
			layout.set_font_description (font_desc);
			layout.set_width ((int) ((alloc.width - 2 * horizontal_padding) * Pango.SCALE));
			layout.set_text (text, -1);
			
			Pango.Rectangle logical_rect;
			layout.get_pixel_extents (null, out logical_rect);
			
			Gtk.paint_flat_box (parent.get_style (),
				cr, StateType.NORMAL, ShadowType.NONE,
				this, null,
				0, alloc.y,
				alloc.x + logical_rect.width + 2 * horizontal_padding, alloc.height);
			
			var color = style.fg[StateType.NORMAL];
			
			cr.move_to (alloc.x + horizontal_padding, alloc.y + (alloc.height - logical_rect.height) / 2);
			cr.set_source_rgba (color.red, color.green, color.blue, 0.6);
			Pango.cairo_show_layout (cr, layout);
			
			return true;
		}
	}
}

