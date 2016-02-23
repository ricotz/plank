//
//  Copyright (C) 2015 Rico Tzschichholz
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
	 * Modify the given DrawItemValue
	 *
	 * @param item the dock-item
	 * @param draw_value the dock-item's drawvalue
	 */
	public delegate void DrawValueFunc (DockItem item, DockItemDrawValue draw_value);
	
	/**
	 * Modify all given DrawItemValues
	 *
	 * @param draw_values the map of dock-items with their draw-values
	 */
	public delegate void DrawValuesFunc (Gee.HashMap<DockElement, DockItemDrawValue> draw_values);
	
	public struct PointD
	{
		public double x;
		public double y;
	}
	
	/**
	 * Contains all positions and modifications to draw a dock-item on the dock
	 */
	public class DockItemDrawValue
	{
		public PointD center;
		public PointD static_center;
		public double icon_size;
		
		public Gdk.Rectangle hover_region;
		public Gdk.Rectangle draw_region;
		public Gdk.Rectangle background_region;
		
		public double zoom;
		public double opacity;
		
		public double darken;
		public double lighten;
		
		public bool show_indicator;
		
		public void move_in (Gtk.PositionType position, double damount)
		{
			var amount = (int) damount;
			
			switch (position) {
			default:
			case Gtk.PositionType.BOTTOM:
				center.y -= damount;
				static_center.y -= damount;
				hover_region.y -= amount;
				draw_region.y -= amount;
				break;
			case Gtk.PositionType.TOP:
				center.y += damount;
				static_center.y += damount;
				hover_region.y += amount;
				draw_region.y += amount;
				break;
			case Gtk.PositionType.LEFT:
				center.x += damount;
				static_center.x += damount;
				hover_region.x += amount;
				draw_region.x += amount;
				break;
			case Gtk.PositionType.RIGHT:
				center.x -= damount;
				static_center.x -= damount;
				hover_region.x -= amount;
				draw_region.x -= amount;
				break;
			}
		}
		
		public void move_right (Gtk.PositionType position, double damount)
		{
			var amount = (int) damount;
			
			switch (position) {
			default:
			case Gtk.PositionType.BOTTOM:
				center.x += damount;
				static_center.x += damount;
				hover_region.x += amount;
				draw_region.x += amount;
				background_region.x += amount;
				break;
			case Gtk.PositionType.TOP:
				center.x += damount;
				static_center.x += damount;
				hover_region.x += amount;
				draw_region.x += amount;
				background_region.x += amount;
				break;
			case Gtk.PositionType.LEFT:
				center.y += damount;
				static_center.y += damount;
				hover_region.y += amount;
				draw_region.y += amount;
				background_region.y += amount;
				break;
			case Gtk.PositionType.RIGHT:
				center.y += damount;
				static_center.y += damount;
				hover_region.y += amount;
				draw_region.y += amount;
				background_region.y += amount;
				break;
			}
		}
	}
}
