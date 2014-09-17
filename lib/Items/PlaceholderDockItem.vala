//
//  Copyright (C) 2014 Rico Tzschichholz
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

namespace Plank.Items
{
	/**
	 * A dock item as a placeholder for the dock itself if nothing was added yet.
	 */
	public class PlaceholderDockItem : DockItem
	{
		/**
		 * Create a new placeholder dock-item
		 */
		public PlaceholderDockItem ()
		{
		}
		
		construct
		{
			Indicator = IndicatorState.NONE;
			Text = _("Drop applications or files here");
			Icon = "add";
		}
		
		/**
		 * {@inheritDoc}
		 */
		protected override Animation on_clicked (PopupButton button, Gdk.ModifierType mod)
		{
			return Animation.NONE;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool can_be_removed ()
		{
			return false;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override bool is_valid ()
		{
			return true;
		}
	}
}
