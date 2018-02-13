//
//  Copyright (C) 2011 Robert Dyer
//  Copyright (C) 2018 Faissal Bensefia
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
	public class BatteryDockItem : DockletItem
	{
		int capacity = -1;
		string status = "Unknown";
		uint battery_mon_id = 0U;

		/**
		 * {@inheritDoc}
		 */
		public BatteryDockItem.with_dockitem_file(GLib.File file)
		{
			GLib.Object(Prefs: new DockItemPreferences.with_file(file));
		}

		construct
		{
			Icon = "battery-missing";
			Text = _("No battery");
			update_bat();

			battery_mon_id = Gdk.threads_add_timeout(1000, (SourceFunc)update_bat);
		}

		~BatteryDockItem()
		{
			if (battery_mon_id > 0U)
			{
				GLib.Source.remove(battery_mon_id);
			}
		}

		int get_capacity() throws GLib.FileError
		{
			string cap;
			FileUtils.get_contents(BAT_CAP, out cap);
			return int.parse(cap);
		}

		string get_status() throws GLib.FileError
		{
			string stat;
			FileUtils.get_contents(BAT_STAT, out stat);
			return stat.chomp();
		}

		bool update_bat()
		{
			string oldIcon=Icon;
			try
			{
				status = get_status();
				capacity = get_capacity();
				Text = _(capacity.to_string()+"% "+status);
				switch ((int)Math.ceil(capacity*0.04))
				{
					case 4:
						Icon = "battery-full";
						break;
					case 3:
						Icon = "battery-good";
						break;
					case 2:
						Icon = "battery-low";
						break;
					case 1:
						Icon = "battery-caution";
						break;
				}

				switch (status)
				{
					case "Full":
					case "Charging":
						Icon += "-charging";
						break;
					case "Discharging":
						break;
				}
			}
			catch
			{
				Icon = "battery-missing";
				Text = _("No battery");
			}

			if (oldIcon!=Icon)
			{
				reset_icon_buffer();
			}
			return true;
		}
	}
}
