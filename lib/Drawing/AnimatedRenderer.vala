//
//  Copyright (C) 2011 Robert Dyer
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

namespace Plank.Drawing
{
	/**
	 * Handles animated rendering.  Uses a timer and continues requesting
	 * redraws for a widget until no more animation is needed.
	 */
	public abstract class AnimatedRenderer : GLib.Object
	{
		public Gtk.Widget widget { get; construct; }
		
		[CCode (notify = false)]
		public int64 frame_time { get; private set; }
		
		uint timer_id = 0;
		ulong widget_realize_id = 0;
		ulong widget_draw_id = 0;
		
		/**
		 * Creates a new animation renderer.
		 */
		public AnimatedRenderer (Gtk.Widget widget)
		{
			Object (widget : widget);
		}
		
		construct
		{
			widget_realize_id = widget.realize.connect (on_widget_realize);
			widget_draw_id = widget.draw.connect (on_widget_draw);
		}
		
		~AnimatedRenderer ()
		{
			if (timer_id > 0) {
				GLib.Source.remove (timer_id);
				timer_id = 0;
			}
			
			if (widget_realize_id > 0) {
				widget.disconnect (widget_realize_id);
				widget_realize_id = 0;
			}
			
			if (widget_draw_id > 0) {
				widget.disconnect (widget_draw_id);
				widget_draw_id = 0;
			}
		}
		
		/**
		 * Determines if animation should continue.
		 *
		 * @param frame_time the current time for this frame's render
		 * @return if another animation frame is needed
		 */
		protected abstract bool animation_needed (int64 frame_time);
		
		/**
		 * Preparations which are not requiring a drawing context yet.
		 *
		 * @param frame_time the current time for this frame's render
		 */
		protected abstract void initialize_frame (int64 frame_time);
		
		/**
		 * Draws onto a context.
		 *
		 * @param cr the context to use for drawing
		 */
		public abstract void draw (Cairo.Context cr, int64 frame_time);
		
		/**
		 * Force an immediate update of the frame_time property.
		 */
		protected void force_frame_time_update ()
		{
			frame_time = GLib.get_monotonic_time ();
		}
		
		/**
		 * Request re-drawing.
		 */
		public void animated_draw ()
		{
			if (timer_id > 0)
				return;
			
			widget.queue_draw ();
			
			force_frame_time_update ();
			if (animation_needed (frame_time)) {
				// This roughly means driving animations with 60 fps
				timer_id = Gdk.threads_add_timeout (16, draw_timeout);
			}
		}
		
		bool draw_timeout ()
		{
			widget.queue_draw ();
			
			force_frame_time_update ();
			if (animation_needed (frame_time))
				return true;
			
			timer_id = 0;
			return false;
		}
		
		[CCode (instance_pos = -1)]
		bool on_widget_draw (Gtk.Widget widget, Cairo.Context cr)
		{
			force_frame_time_update ();
			initialize_frame (frame_time);
			
			draw (cr, frame_time);
		
			return Gdk.EVENT_PROPAGATE;
		}
		
		[CCode (instance_pos = -1)]
		void on_widget_realize (Gtk.Widget widget)
		{
			force_frame_time_update ();
			initialize_frame (frame_time);
			
			if (widget_realize_id > 0) {
				widget.disconnect (widget_realize_id);
				widget_realize_id = 0;
			}
		}
		
	}
}
