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

using Plank;

namespace Docky
{
	public class ClippyPreferences : DockItemPreferences
	{
		[Description(nick = "max-entries", blurb = "How many recent clipboard entries to keep.")]
		public uint MaxEntries { get; set; default = 15; }
		
		[Description(nick = "timer-delay", blurb = "How often to poll (in ms) for new clipboard data.")]
		public uint TimerDelay { get; set; default = 500; }
		
		[Description(nick = "track-mouse-selections", blurb = "If it should track the primary (mouse selection) clipboard.")]
		public bool TrackMouseSelections { get; set; default = false; }
		
		public ClippyPreferences.with_file (GLib.File file)
		{
			base.with_file (file);
		}
		
		protected override void reset_properties ()
		{
			MaxEntries = 15;
			TimerDelay = 500;
			TrackMouseSelections = false;
		}
	}
}
