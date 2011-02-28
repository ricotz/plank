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

using Plank.Services;

namespace Plank.Widgets
{
	public class PoofWindow : CompositedWindow
	{
		const int POOF_SIZE = 128;
		const int POOF_FRAMES = 5;
		const double RUN_LENGTH = 300 * 1000;

		Gdk.Pixbuf poof_image;

		DateTime start_time;

		public PoofWindow (int x, int y)
		{
			base ();
			
			can_focus = false;
			set_keep_above (true);
			type_hint = WindowTypeHint.SPLASHSCREEN;
			
			string poof_file = Paths.DataFolder.get_child ("poof.png").get_path ();
			try {
				poof_image = new Pixbuf.from_file (poof_file);
			} catch {
				Logger.error<PoofWindow> ("Unable to load poof animation image '%s'".printf (poof_file));
				return;
			}
			
			set_size_request (POOF_SIZE, POOF_SIZE);
			move (x - (POOF_SIZE / 2), y - (POOF_SIZE / 2));
			
			Timeout.add (30, () => {
				if (get_animation_state () == 1) {
					hide ();
					destroy ();
					return false;
				}
				queue_draw ();
				return true;
			});
			
			start_time = new DateTime.now_utc (); 
			show_all ();
		}

		double get_animation_state ()
		{
			return double.max (0, double.min (1, (double) new DateTime.now_utc ().difference (start_time) / RUN_LENGTH));
		}

		public override bool expose_event (EventExpose event)
		{
			var cr = cairo_create (event.window);
			
			cr.save ();
			cr.set_operator (Operator.SOURCE);
			cr.set_source_rgba (0, 0, 0, 0);
			cr.paint ();
			cr.restore ();
			
			cairo_set_source_pixbuf (cr, poof_image, 0, -POOF_SIZE * (int) (POOF_FRAMES * get_animation_state ()));
			cr.paint ();
			
			return true;
		}
	}
}
