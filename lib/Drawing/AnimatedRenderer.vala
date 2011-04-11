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

using Gtk;

namespace Plank
{
	public abstract class AnimatedRenderer : GLib.Object
	{
		private Widget widget;
		
		private uint animation_timer = 0;
		
		public AnimatedRenderer (Widget widget)
		{
			this.widget = widget;
		}
		
		protected abstract bool animation_needed (DateTime render_time);
		
		public void animated_draw ()
		{
			if (animation_timer > 0) 
				return;
			
			widget.queue_draw ();
			
			if (animation_needed (new DateTime.now_utc ()))
				animation_timer = GLib.Timeout.add (1000 / 60, draw_timeout);
		}
		
		private bool draw_timeout ()
		{
			widget.queue_draw ();
			
			if (animation_needed (new DateTime.now_utc ()))
				return true;
			
			if (animation_timer > 0)
				GLib.Source.remove (animation_timer);
			animation_timer = 0;

			// one final draw to clear out the end of previous animations
			widget.queue_draw ();
			return false;
		}
	}
}
