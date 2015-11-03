//
//  Copyright (C) 2011-2012 Robert Dyer, Rico Tzschichholz
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
	 * An animated window that draws a 'poof' animation.
	 * Used when dragging items off the dock.
	 */
	public class PoofWindow : CompositedWindow
	{
		const int RUN_LENGTH = 300 * 1000;
		
		static PoofWindow? instance = null;
		
		public static unowned PoofWindow get_default ()
		{
			if (instance == null)
				instance = new PoofWindow ();
			
			return instance;
		}
		
		Gdk.Pixbuf poof_image;
		int poof_size;
		int poof_frames;
		
		int64 start_time = 0LL;
		int64 frame_time = 0LL;
		
		uint animation_timer_id = 0U;
		
		/**
		 * Creates a new poof window at the screen-relative coordinates specified.
		 */
		public PoofWindow ()
		{
			GLib.Object (type: Gtk.WindowType.TOPLEVEL, type_hint: Gdk.WindowTypeHint.DOCK);
		}
		
		construct
		{
			accept_focus = false;
			can_focus = false;
			set_keep_above (true);
			
			try {
				poof_image = new Gdk.Pixbuf.from_resource ("%s/img/poof.svg".printf (Plank.G_RESOURCE_PATH));
				poof_size = poof_image.width;
				poof_frames = (int) Math.floor (poof_image.height / poof_size);
				debug ("Loaded animation: size = %ipx, frame-count = %i, duration = %ims", poof_size, poof_frames, RUN_LENGTH / 1000);
			} catch (Error e) {
				poof_image = null;
				critical ("Unable to load poof animation image: %s", e.message);
			}
			
			set_size_request (poof_size, poof_size);
		}
		
		~PoofWindow ()
		{
			if (animation_timer_id > 0U) {
				GLib.Source.remove (animation_timer_id);
				animation_timer_id = 0U;
			}
		}
		
		/**
		 * Show the animated poof-window at the given coordinates
		 *
		 * @param x the x position of the poof window
		 * @param y the y position of the poof window
		 */
		public void show_at (int x, int y)
		{
			if (animation_timer_id > 0U)
				GLib.Source.remove (animation_timer_id);
			
			if (poof_image == null && poof_frames > 0)
				return;
			
			Logger.verbose ("Show animation: size = %ipx, frame-count = %i, duration = %ims", poof_size, poof_frames, RUN_LENGTH / 1000);
			
			start_time = GLib.get_monotonic_time ();
			frame_time = start_time;
						
			show ();
			move (x - (poof_size / 2), y - (poof_size / 2));

			animation_timer_id = Gdk.threads_add_timeout (30, () => {
				frame_time = GLib.get_monotonic_time ();
				
				if (frame_time - start_time <= RUN_LENGTH) {
					queue_draw ();
					return true;
				}
				
				animation_timer_id = 0U;
				hide ();
				return false;
			});
		}
		
		public override bool draw (Cairo.Context cr)
		{
			cr.set_operator (Cairo.Operator.SOURCE);
			Gdk.cairo_set_source_pixbuf (cr, poof_image, 0, -poof_size * (int) (poof_frames * (frame_time - start_time) / (double) RUN_LENGTH));
			cr.paint ();
			
			return Gdk.EVENT_STOP;
		}
	}
}
