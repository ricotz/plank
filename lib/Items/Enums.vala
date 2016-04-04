//
//  Copyright (C) 2015 Rico Tzschichholz
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
	 * What type of animation to perform when an item is or was interacted with.
	 */
	public enum AnimationType
	{
		/**
		 * No animation.
		 */
		NONE,
		/**
		 * Bounce the icon.
		 */
		BOUNCE,
		/**
		 * Darken the icon, then restore it.
		 */
		DARKEN,
		/**
		 * Brighten the icon, then restore it.
		 */
		LIGHTEN
	}
	
	/**
	 * What item indicator to show.
	 */
	public enum IndicatorState
	{
		/**
		 * None - no windows for this item.
		 */
		NONE,
		/**
		 * Show a single indicator - there is 1 window for this item.
		 */
		SINGLE,
		/**
		 * Show multiple indicators - there are more than 1 window for this item.
		 */
		SINGLE_PLUS
	}
	
	/**
	 * The current activity state of an item.  The item has several
	 * states to track and can be in any combination of them.
	 */
	[Flags]
	public enum ItemState
	{
		/**
		 * The item is in a normal state.
		 */
		NORMAL = 1 << 0,
		/**
		 * The item is currently active (a window in the group is focused).
		 */
		ACTIVE = 1 << 1,
		/**
		 * The item is currently urgent (a window in the group has the urgent flag).
		 */
		URGENT = 1 << 2,
		/**
		 * The item is currently moved to its new position.
		 */
		MOVE = 1 << 3,
		/**
		 * The item is invalid and should be removed.
		 */
		INVALID = 1 << 4
	}
	
	/**
	 * What mouse button pops up the context menu on an item.
	 * Can be multiple buttons.
	 */
	[Flags]
	public enum PopupButton
	{
		/**
		 * No button pops up the context.
		 */
		NONE = 1 << 0,
		/**
		 * Left button pops up the context.
		 */
		LEFT = 1 << 1,
		/**
		 * Middle button pops up the context.
		 */
		MIDDLE = 1 << 2,
		/**
		 * Right button pops up the context.
		 */
		RIGHT = 1 << 3;
		
		/**
		 * Convenience method to map {@link Gdk.EventButton} to this enum.
		 *
		 * @param event the event to map
		 * @return the PopupButton representation of the event
		 */
		public static PopupButton from_event_button (Gdk.EventButton event)
		{
			switch (event.button) {
			default:
			case Gdk.BUTTON_PRIMARY:
				return PopupButton.LEFT;
			
			case Gdk.BUTTON_MIDDLE:
				return PopupButton.MIDDLE;
			
			case Gdk.BUTTON_SECONDARY:
				return PopupButton.RIGHT;
			}
		}
	}
}
