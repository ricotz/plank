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
	 * The main factory class for the dock.
	 */
	public class Factory : GLib.Object
	{
		/**
		 * The main class.
		 */
		public static AbstractMain main;
		
		/**
		 * The item factory.
		 */
		public static ItemFactory item_factory;
		
		/**
		 * Initializes the factory class.
		 *
		 * @param main_class the main class
		 * @param item the item factory
		 */
		public static void init (AbstractMain main_class, ItemFactory item)
		{
			main = main_class;
			item_factory = item;
		}
	}
}
