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

namespace Plank
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
		
		uint timer_id = 0U;
		ulong widget_realize_handler_id = 0UL;
		ulong widget_draw_handler_id = 0UL;
#if HAVE_GTK_3_8
		bool is_updating = false;
#endif
		
		/**
		 * Creates a new animation renderer.
		 */
		public AnimatedRenderer (Gtk.Widget widget)
		{
			Object (widget : widget);
		}
		
		construct
		{
#if HAVE_GTK_3_8
			timer_id = widget.add_tick_callback ((Gtk.TickCallback) draw_timeout);
#endif
			widget_realize_handler_id = widget.realize.connect (on_widget_realize);
			widget_draw_handler_id = widget.draw.connect (on_widget_draw);
		}
		
		~AnimatedRenderer ()
		{
			if (timer_id > 0U) {
#if HAVE_GTK_3_8
				widget.remove_tick_callback (timer_id);
#else
				GLib.Source.remove (timer_id);
#endif
				timer_id = 0U;
			}
			
			if (widget_realize_handler_id > 0UL) {
				widget.disconnect (widget_realize_handler_id);
				widget_realize_handler_id = 0UL;
			}
			
			if (widget_draw_handler_id > 0UL) {
				widget.disconnect (widget_draw_handler_id);
				widget_draw_handler_id = 0UL;
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
#if HAVE_GTK_3_8
			unowned Gdk.FrameClock? frame_clock = widget.get_frame_clock ();
			if (frame_clock != null) {
				frame_time = frame_clock.get_frame_time ();
			} else {
#endif
				frame_time = GLib.get_monotonic_time ();
#if HAVE_GTK_3_8
				critical ("FrameClock not available");
			}
#endif
		}
		
		/**
		 * Request re-drawing.
		 */
		public void animated_draw ()
		{
#if HAVE_GTK_3_8
			if (is_updating || !widget.get_realized ())
#else
			if (timer_id > 0U)
#endif
				return;
			
			force_frame_time_update ();
			initialize_frame (frame_time);
			
			widget.queue_draw ();
			
			if (animation_needed (frame_time)) {
#if HAVE_GTK_3_8
				unowned Gdk.FrameClock? frame_clock = widget.get_frame_clock ();
				frame_clock.begin_updating ();
				is_updating = true;
#else
				// This roughly means driving animations with 60 fps
				timer_id = Gdk.threads_add_timeout (16, draw_timeout);
#endif
			}
		}
		
#if HAVE_GTK_3_8
		[CCode (instance_pos = -1)]
		bool draw_timeout (Gtk.Widget widget, Gdk.FrameClock frame_clock)
		{
			frame_time = frame_clock.get_frame_time ();
			initialize_frame (frame_time);
#else
		bool draw_timeout ()
		{
			force_frame_time_update ();
#endif
			widget.queue_draw ();
			
			if (animation_needed (frame_time))
				return true;
			
#if HAVE_GTK_3_8
			frame_clock.end_updating ();
			is_updating = false;
			return true;
#else
			timer_id = 0U;
			return false;
#endif
		}
		
		[CCode (instance_pos = -1)]
		bool on_widget_draw (Gtk.Widget widget, Cairo.Context cr)
		{
#if !HAVE_GTK_3_8
			force_frame_time_update ();
			initialize_frame (frame_time);
#endif
			draw (cr, frame_time);
		
			return Gdk.EVENT_PROPAGATE;
		}
		
		[CCode (instance_pos = -1)]
		void on_widget_realize (Gtk.Widget widget)
		{
			force_frame_time_update ();
			initialize_frame (frame_time);
			
			if (widget_realize_handler_id > 0UL) {
				widget.disconnect (widget_realize_handler_id);
				widget_realize_handler_id = 0UL;
			}
		}
		
	}
}
