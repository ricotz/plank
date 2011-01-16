//  
//  Copyright (C) 2011 Robert Dyer
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
using Gtk;

using Plank.Items;
using Plank.Services.Drawing;

namespace Plank
{
	public class DockRenderer : GLib.Object
	{
		public signal void render_needed ();
		
		DockWindow window;
		
		PlankSurface background_buffer;
		PlankSurface main_buffer;
		
		public int DockWidth {
			get { return (int) window.Items.Items.length () * (ItemPadding+ Prefs.IconSize) + 2 * DockPadding; }
		}
		
		public int DockHeight {
			get { return IndicatorSize + DockPadding + (int) (Prefs.Zoom * Prefs.IconSize); }
		}
		
		int VisibleDockHeight {
			get { return IndicatorSize + DockPadding + Prefs.IconSize; }
		}
		
		int IndicatorSize {
			get { return DockPadding; }
		}
		
		int DockPadding {
			get { return (int) (0.1 * Prefs.IconSize); }
		}
		
		int ItemPadding {
			get { return DockPadding; }
		}
		
		DockPreferences Prefs {
			get { return window.Prefs; }
		}
		
		public DockRenderer (DockWindow window)
		{
			this.window = window;
			Prefs.notify.connect (reset_buffers);
		}
		
		public void reset_buffers ()
		{
			main_buffer = null;
			background_buffer = null;
			
			render_needed ();
		}
		
		public Gdk.Rectangle item_region (DockItem item)
		{
			Gdk.Rectangle rect = Gdk.Rectangle ();
			rect.x = DockPadding + item.Position * (ItemPadding + Prefs.IconSize);
			rect.y = DockHeight - IndicatorSize - Prefs.IconSize;
			rect.width = Prefs.IconSize + ItemPadding;
			rect.height = Prefs.IconSize + DockPadding + IndicatorSize;
			return rect;
		}
		
		public void draw_dock (Context cr)
		{
			if (main_buffer != null && (main_buffer.Height != DockHeight || main_buffer.Width != DockWidth))
				reset_buffers ();
			
			if (main_buffer == null)
				main_buffer = new PlankSurface.with_surface (DockWidth, DockHeight, cr.get_target ());
			
			main_buffer.Clear ();
			
			draw_dock_background (main_buffer);
			
			foreach (DockItem item in window.Items.Items)
				draw_item (main_buffer, item);
			
			cr.set_operator (Operator.SOURCE);
			cr.set_source_surface (main_buffer.Internal, 0, 0);
			cr.paint ();
		}
		
		void draw_dock_background (PlankSurface surface)
		{
			if (background_buffer == null) {
				background_buffer = new PlankSurface.with_plank_surface (surface.Width, VisibleDockHeight, surface);
				
				background_buffer.Context.rectangle (0, 0, background_buffer.Width, background_buffer.Height);
				background_buffer.Context.set_source_rgba (1, 0, 0, 0.2);
				background_buffer.Context.fill ();
			}
			
			surface.Context.set_source_surface (background_buffer.Internal, 0, surface.Height - VisibleDockHeight);
			surface.Context.paint ();
		}
		
		void draw_item (PlankSurface surface, DockItem item)
		{
			PlankSurface icon_surface = new PlankSurface (Prefs.IconSize, Prefs.IconSize);
			
			Pixbuf pbuf = Drawing.load_pixbuf (item.Icon, Prefs.IconSize);
			cairo_set_source_pixbuf (icon_surface.Context, pbuf, 0, 0);
			icon_surface.Context.paint ();
			
			var lighten = 0.0;
			var darken = 0.0;
			
			if (window.HoveredItem == item && !Prefs.zoom_enabled ())
				lighten = 0.2;
			
			if (lighten > 0) {
				Cairo.Operator operator = icon_surface.Context.get_operator ();
				icon_surface.Context.set_operator (Cairo.Operator.ADD);
				icon_surface.Context.paint_with_alpha (lighten);
				icon_surface.Context.set_operator (operator);
			}
			
			if (darken > 0) {
				icon_surface.Context.rectangle (0, 0, Prefs.IconSize, Prefs.IconSize);
				icon_surface.Context.set_source_rgba (0, 0, 0, darken);
				
				Cairo.Operator operator = icon_surface.Context.get_operator ();
				icon_surface.Context.set_operator (Cairo.Operator.ATOP);
				icon_surface.Context.fill ();
				icon_surface.Context.set_operator (operator);
			}
			
			Gdk.Rectangle rect = item_region (item);
			surface.Context.set_source_surface (icon_surface.Internal, rect.x + ItemPadding / 2, rect.y);
			surface.Context.paint ();
		}
	}
}
