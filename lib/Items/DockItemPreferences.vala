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

using Plank.Services;

namespace Plank.Items
{
	/**
	 * Contains preference keys for a dock item.
	 */
	public class DockItemPreferences : Preferences
	{
		[Description(nick = "launcher", blurb = "The path to the launcher for this item.")]
		public string Launcher { get; set; }
		
		[Description(nick = "sort", blurb = "The sort value for this item (lower sort values are left of higher values).")]
		public int Sort { get; set; }
		
		/**
		 * {@inheritDoc}
		 */
		public DockItemPreferences.with_file (string filename)
		{
			base.with_file (filename);
		}
		
		/**
		 * {@inheritDoc}
		 */
		protected override void reset_properties ()
		{
			Launcher = "";
			Sort = 0;
		}
	}
}
