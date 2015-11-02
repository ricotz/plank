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

namespace Docky
{
	/**
	 * The base class for all docklets.
	 */
	public abstract class Docklet : Object
	{
		public string name { get; construct; }
		
		public virtual bool supports_launcher (string launcher)
		{
			return (launcher == "docklet://%s".printf (name));
		}
		
		public abstract Plank.Items.DockElement make_element (string launcher, GLib.File file);
	}
}
