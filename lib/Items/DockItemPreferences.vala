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
	 * Contains preference keys for a dock item.
	 */
	public class DockItemPreferences : Preferences
	{
		[Description(nick = "launcher", blurb = "The uri for this item.")]
		public string Launcher { get; set; }
		
		/**
		 * {@inheritDoc}
		 */
		public DockItemPreferences.with_launcher (string launcher)
		{
			base ();
			Launcher = launcher;
		}
		
		/**
		 * {@inheritDoc}
		 */
		public DockItemPreferences.with_file (GLib.File file)
		{
			base.with_file (file);
		}
		
		/**
		 * {@inheritDoc}
		 */
		public DockItemPreferences.with_filename (string filename)
		{
			base.with_filename (filename);
		}
		
		/**
		 * {@inheritDoc}
		 */
		public override void reset_properties ()
		{
			Launcher = "";
		}
		
		/**
		 * {@inheritDoc}
		 */
		protected override void verify (string prop)
		{
			switch (prop) {
			case "Launcher":
				if (Launcher.has_prefix ("/"))
					try {
						Launcher = Filename.to_uri (Launcher);
					} catch (ConvertError e) {
						warning (e.message);
					}
				break;
			}
		}
	}
}
