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
	 * Creates a new surface based on the given information
	 *
	 * @param width the width
	 * @param height the height
	 * @param model existing surface to use as basis of new surface
	 * @param draw_data_func function which changes the surface
	 * @return the newly created surface or NULL
	 */
	public delegate Surface? DrawFunc<G> (int width, int height, Surface model, DrawDataFunc<G>? draw_data_func);
	
	/**
	 * Creates a new surface using the given element and information
	 *
	 * @param width the width
	 * @param height the height
	 * @param model existing surface to use as basis of new surface
	 * @param data the data object used for drawing
	 * @return the newly created surface or NULL
	 */
	public delegate Surface? DrawDataFunc<G> (int width, int height, Surface model, G? data);
	
	/**
	 * Controls some internal behaviors of a {@link Plank.SurfaceCache}
	 */
	[Flags]
	public enum SurfaceCacheFlags
	{
		NONE = 0,
		/**
		 * Allow down-scaling of an existing cached surface for better performance
		 */
		ALLOW_DOWNSCALE = 1 << 0,
		/**
		 * Allow up-scaling of an existing cached surface for better performance
		 */
		ALLOW_UPSCALE = 1 << 1,
		/**
		 * Allow scaling of an existing cached surface for better performance
		 * (This basically means the cache will only contain one entry which will be scaled accordingly on request)
		 */
		ALLOW_SCALE = ALLOW_UPSCALE | ALLOW_DOWNSCALE,
		/**
		 * Allow scaling if the drawing-time is significatly high
		 */
		ADAPTIVE_SCALE = 1 << 2,
	}
	
	/**
	 * Cache multiple sizes of the assumed same image
	 */
	public class SurfaceCache<G> : GLib.Object
	{
		const int64 MAX_CACHE_AGE = 5 * 60 * 1000 * 1000;
		const int64 MIN_DRAWING_TIME = 10 * 1000;
		const int64 INSANE_DRAWING_TIME = 30 * 1000;
		const int64 ACCESS_REWARD = 500 * 1000;
		
		class SurfaceInfo
		{
			public uint16 width;
			public uint16 height;
			public uint access_count;
			public int64 last_access_time;
			public int64 drawing_time;
			public double scale;
			
			public SurfaceInfo (uint16 width, uint16 height, int64 last_access_time, int64 drawing_time)
			{
				this.width = width;
				this.height = height;
				this.last_access_time = last_access_time;
				this.drawing_time = drawing_time;
				this.access_count = 0;
				this.scale = 1.0;
			}
			
			public static uint hash (SurfaceInfo s)
			{
				uint n1 = s.width, n2 = s.height;
				return (n1 >= n2 ? n1 * n1 + n1 + n2 : n1 + n2 * n2);
			}
			
			public static int compare (SurfaceInfo s1, SurfaceInfo s2)
			{
				if (s1 == s2)
					return 0;
				
				return (2 * (s1.width - s2.width) + s2.height - s2.height);
			}
			
			public int compare_with (uint16 width, uint16 height)
			{
				return (2 * (this.width - width) + this.height - height);
			}
		}
		
		public SurfaceCacheFlags flags { get; construct set; }
		
		Gee.TreeSet<unowned SurfaceInfo> infos;
		Gee.HashMap<SurfaceInfo, Surface> cache_map;
		unowned SurfaceInfo? last_info;
		Mutex cache_mutex;
		
		uint clean_up_timer_id = 0U;
		
		public SurfaceCache (SurfaceCacheFlags flags = SurfaceCacheFlags.NONE)
		{
			Object (flags: flags);
		}
		
		construct
		{
			infos = new Gee.TreeSet<unowned SurfaceInfo> ((CompareDataFunc) SurfaceInfo.compare);
			cache_map = new Gee.HashMap<SurfaceInfo, Surface> ((Gee.HashDataFunc<SurfaceInfo>) SurfaceInfo.hash);
			last_info = null;
			
			//TODO Adaptive delay depending on the access rate
			clean_up_timer_id = Gdk.threads_add_timeout (5 * 60 * 1000, () => {
				clean_up ();
				return true;
			});
		}
		
		~SurfaceCache ()
		{
			if (clean_up_timer_id > 0U) {
				GLib.Source.remove (clean_up_timer_id);
				clean_up_timer_id = 0U;
			}
			
			cache_map.clear ();
			infos.clear ();
			last_info = null;
		}
		
		public Surface? get_surface<G> (int width, int height, Surface model, DrawFunc<G> draw_func, DrawDataFunc<G>? draw_data_func)
			requires (width >= 0 && height >= 0)
		{
			cache_mutex.lock ();
			
			unowned SurfaceInfo? info;
			SurfaceInfo? current_info = null;
			Surface? surface = null;
			bool needs_scaling = false;
			
			info = find_match ((uint16) width, (uint16) height, out needs_scaling);
			last_info = info;
			current_info = info;
			
			var access_time = GLib.get_monotonic_time ();
			
			if (current_info != null) {
				current_info.last_access_time = access_time;
				current_info.access_count++;
				surface = cache_map.get (current_info);
				
				cache_mutex.unlock ();
				
				if (needs_scaling)
					return surface.scaled_copy (width, height);
				else
					return surface;
			}
			
			surface = draw_func (width, height, model, draw_data_func);
			
			var finish_time = GLib.get_monotonic_time ();
			var time_elapsed = finish_time - access_time;
			
			// FIXME There is probably a nicer way to accomplish this
			// Mark the created surface if drawing-time exceeded our limit and have
			// an upper drawing-layer (e.g. DockRenderer) handle it
			if (time_elapsed >= INSANE_DRAWING_TIME && flags == SurfaceCacheFlags.NONE) {
				warning ("Creating surface took WAY TOO LONG (%" + int64.FORMAT + "ms), enabled downscaling for this cache!", time_elapsed / 1000);
				flags = SurfaceCacheFlags.ALLOW_DOWNSCALE;
				surface.set_qdata<string> (quark_surface_stats, SURFACE_STATS_DRAWING_TIME_EXCEEDED);
			}
			
			current_info = new SurfaceInfo ((uint16) width, (uint16) height, finish_time, time_elapsed);
			current_info.access_count++;
			
			cache_map.set (current_info, surface);
			infos.add (current_info);
			
			cache_mutex.unlock ();
			
			return surface;
		}
		
		unowned SurfaceInfo? find_match (uint16 width, uint16 height, out bool needs_scaling)
		{
			needs_scaling = false;
			
			if (infos.is_empty)
				return null;
			
			unowned SurfaceInfo? info;
			// Check if the last requested entry matches already
			if (last_info != null) {
				info = last_info;
				if (info.width == width && info.height == height)
					return info;
				
				if ((flags & SurfaceCacheFlags.ALLOW_DOWNSCALE) != 0
					&& info.width > width && info.height > height) {
					needs_scaling = true;
					return info;
				}
				
				if ((flags & SurfaceCacheFlags.ALLOW_UPSCALE) != 0
					&& info.width < width && info.height < height) {
					needs_scaling = true;
					return info;
				}
			}
			
			Gee.BidirIterator<unowned SurfaceInfo> infos_it;
			if (last_info != null)
				infos_it = (Gee.BidirIterator<unowned SurfaceInfo>) infos.iterator_at (last_info);
			else
				infos_it = infos.bidir_iterator ();
			
			if (last_info != null && last_info.compare_with (width, height) > 0) {
				while (infos_it.previous ()) {
					info = infos_it.get ();
					
					if (info.width == width && info.height == height)
						return info;
					
					if ((flags & SurfaceCacheFlags.ALLOW_DOWNSCALE) != 0
						&& info.width > width && info.height > height) {
						needs_scaling = true;
						return info;
					}
					
					if ((flags & SurfaceCacheFlags.ALLOW_UPSCALE) != 0
						&& info.width < width && info.height < height) {
						needs_scaling = true;
						return info;
					}
				}
			} else {
				while (infos_it.next ()) {
					info = infos_it.get ();
					
					if (info.width == width && info.height == height)
						return info;
					
					if ((flags & SurfaceCacheFlags.ALLOW_DOWNSCALE) != 0
						&& info.width > width && info.height > height) {
						needs_scaling = true;
						return info;
					}
					
					if ((flags & SurfaceCacheFlags.ALLOW_UPSCALE) != 0
						&& info.width < width && info.height < height) {
						needs_scaling = true;
						return info;
					}
				}
			}
			
			return null;
		}
		
		public void clear ()
		{
			cache_mutex.lock ();
			
			infos.clear ();
			cache_map.clear ();
			last_info = null;
			
			cache_mutex.unlock ();
		}
		
		void clean_up ()
		{
			cache_mutex.lock ();
			
			if (cache_map.size <= 1) {
				cache_mutex.unlock ();
				return;
			}
			
			var now = GLib.get_monotonic_time ();
			var size_before = cache_map.size;
			var size_current = size_before;
			
			var cache_it = cache_map.map_iterator ();
			while (cache_it.next ()) {
				var info = cache_it.get_key ();
				
				if (now - info.last_access_time < ACCESS_REWARD * info.access_count)
					continue;
				
				if (info.drawing_time > MIN_DRAWING_TIME)
					continue;
				
				if (size_current <= 1)
					break;
				
				infos.remove (info);
				cache_it.unset ();
				size_current--;
			}
			
			last_info = null;
			
			Logger.verbose ("SurfaceCache.clean_up (%i -> %i) ", size_before, cache_map.size);
			
			cache_mutex.unlock ();
		}
	}
}
