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

namespace Plank.Drawing
{
	/**
	 * Handles animated rendering.  Uses a timer and continues requesting
	 * redraws for a widget until no more animation is needed.
	 */
	public abstract class AnimatedRenderer : GLib.Object
	{
		/**
		 * How many frames per second (roughly) we want while animating.
		 */
		const uint FPS = 60;
		
		public Gtk.Widget widget { get; construct; }
		
		uint animation_timer = 0;
		
		/**
		 * Creates a new animation renderer.
		 */
		public AnimatedRenderer (Gtk.Widget widget)
		{
			Object (widget : widget);
		}
		
		~AnimatedRenderer ()
		{
			if (animation_timer > 0) {
				GLib.Source.remove (animation_timer);
				animation_timer = 0;
			}
		}
		
		/**
		 * Determines if animation should continue.
		 *
		 * @param render_time the current time for this frame's render
		 * @return if another animation frame is needed
		 */
		protected abstract bool animation_needed (int64 render_time);
		
		/**
		 * Request re-drawing.
		 */
		public void animated_draw ()
		{
			if (animation_timer > 0)
				return;
			
			widget.queue_draw ();
			
			if (animation_needed (GLib.get_monotonic_time ()))
				animation_timer = Gdk.threads_add_timeout (1000 / FPS, draw_timeout);
		}
		
		bool draw_timeout ()
		{
			widget.queue_draw ();
			
			if (animation_needed (GLib.get_monotonic_time ()))
				return true;
			
			if (animation_timer > 0) {
				GLib.Source.remove (animation_timer);
				animation_timer = 0;
			}

			// one final draw to clear out the end of previous animations
			widget.queue_draw ();
			return false;
		}
	}
}
