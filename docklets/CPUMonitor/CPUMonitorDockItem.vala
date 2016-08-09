//
//  Copyright (C) 2016 Rico Tzschichholz
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
	public class CPUMonitorDockItem : DockletItem
	{
		const ulong UPDATE_DELAY = 1000000UL;
		const double RADIUS_PERCENT = 0.9;
		const double CPU_THRESHOLD = 0.03;
		const double MEM_THRESHOLD = 0.01;
		
		bool disposed = false;
		
		ulong last_usage;
		ulong last_idle;
		
		double cpu_utilization;
		double memory_utilization;
		double last_cpu_utilization;
		double last_memory_utilization;
		
		/**
		 * {@inheritDoc}
		 */
		public CPUMonitorDockItem.with_dockitem_file (GLib.File file)
		{
			GLib.Object (Prefs: new DockItemPreferences.with_file (file));
		}
		
		construct
		{
			new Thread<void*> (null, () => {
				while (!disposed) {
					update ();
					Thread.usleep (UPDATE_DELAY);
				}
				return null;
			});
		}
		
		~CPUMonitorDockItem ()
		{
			disposed = true;
		}
		
		protected override AnimationType on_clicked (PopupButton button, Gdk.ModifierType mod, uint32 event_time)
		{
			if (button == PopupButton.LEFT) {
				//System.get_default ().open_command ("gnome-system-monitor");
				//return AnimationType.BOUNCE;
			}
			
			return AnimationType.NONE;
		}
		
		void update ()
		{
			FileStream? stream;
			
			stream = FileStream.open ("/proc/stat", "r");
			if (stream != null) {
				ulong user, nice, system, idle, iowait, irq, softirq;
				stream.scanf ("%*s %llu %llu %llu %llu %llu %llu %llu",
					out user, out nice, out system, out idle, out iowait, out irq, out softirq);
				
				var usage_final = user + nice + system + idle + iowait + irq + softirq;
				var idle_final = idle + iowait;
				
				var usage_diff = usage_final - last_usage;
				var idle_diff = idle_final - last_idle;
				
				last_idle = idle_final;
				last_usage = usage_final;
				
				// average it for smoothing
				if (usage_diff > 0UL)
					cpu_utilization = double.max (0.01, (1.0 - (idle_diff / (double) usage_diff) + cpu_utilization) / 2.0);
			}
			
			stream = FileStream.open ("/proc/meminfo", "r");
			if (stream != null) {
				ulong mem_total, mem_free, mem_avail;
				stream.scanf ("%*s %llu %*s", out mem_total);
				stream.scanf ("%*s %llu %*s", out mem_free);
				stream.scanf ("%*s %llu %*s", out mem_avail);
				
				memory_utilization = 1.0 - (mem_avail / (double) mem_total);
			}
			
			Text = ("CPU: %.1f% | Mem: %.1f%").printf (cpu_utilization * 100, memory_utilization * 100);
			
			// Redrawing the icon is quite expensive so better restrict updates to significant ones
			if (Math.fabs (last_cpu_utilization - cpu_utilization) >= CPU_THRESHOLD
				|| Math.fabs (last_memory_utilization - memory_utilization) >= MEM_THRESHOLD) {
				Idle.add (() => {
					reset_icon_buffer ();
					return false;
				});
				
				last_cpu_utilization = cpu_utilization;
				last_memory_utilization = memory_utilization;
			}
		}
		
		protected override void draw_icon (Surface surface)
		{
			var size = int.max (surface.Width, surface.Height);
			unowned Cairo.Context cr = surface.Context;
			Cairo.Pattern pattern;
			
			double center = size / 2.0;
			Plank.Color base_color = { 1.0, 0.3, 0.3, 0.5 };
			base_color.set_hue (120.0 * (1.0 - cpu_utilization));
			
			double radius = double.max (double.min (cpu_utilization * 1.3, 1.0), 0.001);
			
			// draw underlay
			cr.arc (center, center, center * RADIUS_PERCENT, 0.0, 2.0 * Math.PI);
			cr.set_source_rgba (0.0, 0.0, 0.0, 0.5);
			cr.fill_preserve ();
			
			pattern = new Cairo.Pattern.radial (center, center, 0.0, center, center, center * RADIUS_PERCENT);
			pattern.add_color_stop_rgba (0.0, base_color.red, base_color.green, base_color.blue, base_color.alpha);
			pattern.add_color_stop_rgba (0.2, base_color.red, base_color.green, base_color.blue, base_color.alpha);
			pattern.add_color_stop_rgba (1.0, base_color.red, base_color.green, base_color.blue, 0.15);
			cr.set_source (pattern);
			cr.fill_preserve ();
			
			// draw cpu indicator
			pattern = new Cairo.Pattern.radial (center, center, 0, center, center, center * RADIUS_PERCENT * radius);
			pattern.add_color_stop_rgba (0.0, base_color.red, base_color.green, base_color.blue, 1.0);
			pattern.add_color_stop_rgba (0.2, base_color.red, base_color.green, base_color.blue, 1.0);
			pattern.add_color_stop_rgba (1.0, base_color.red, base_color.green, base_color.blue, double.max (0.0, cpu_utilization * 1.3 - 1.0));
			cr.set_source (pattern);
			cr.fill ();
			
			// draw highlight
			cr.arc (center, center * 0.8, center * 0.6, 0.0, 2.0 * Math.PI);
			pattern = new Cairo.Pattern.linear (0.0, 0.0, 0.0, center);
			pattern.add_color_stop_rgba (0.0, 1.0, 1.0, 1.0, 0.35);
			pattern.add_color_stop_rgba (1.0, 1.0, 1.0, 1.0, 0.0);
			cr.set_source (pattern);
			cr.fill ();
			
			// draw outer circles
			cr.set_line_width (1.0);
			cr.arc (center, center, center * RADIUS_PERCENT, 0.0, 2.0 * Math.PI);
			cr.set_source_rgba (1.0, 1.0, 1.0, 0.75);
			cr.stroke ();
			
			cr.set_line_width (1.0);
			cr.arc (center, center, center * RADIUS_PERCENT - 1.0, 0.0, 2.0 * Math.PI);
			cr.set_source_rgba (0.8, 0.8, 0.8, 0.75);
			cr.stroke ();
			
			// draw memory indicator
			cr.set_line_width (size / 32.0);
			cr.arc_negative (center, center, center * RADIUS_PERCENT - 1.0, Math.PI, Math.PI - Math.PI * (2.0 * memory_utilization));
			cr.set_source_rgba (1.0, 1.0, 1.0, 0.85);
			cr.stroke ();
		}
	}
}
