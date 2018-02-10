//
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

public static void docklet_init (Plank.DockletManager manager)
{
	manager.register_docklet(typeof (Docky.BatteryDocklet));
}

namespace Docky
{
	public const string G_RESOURCE_PATH = "/net/launchpad/plank/docklets/battery";
	public const string BAT_CAP = "/sys/class/power_supply/BAT0/capacity";
	public const string BAT_STAT = "/sys/class/power_supply/BAT0/status";
	public const string BAT_CHARGE = "/sys/class/power_supply/BAT0/charge";
	public const string BAT_ALARM = "/sys/class/power_supply/BAT0/alarm";

	public class BatteryDocklet : Object, Plank.Docklet
	{
		public unowned string get_id()
		{
			return "battery";
		}

		public unowned string get_name()
		{
			return _("Battery");
		}

		public unowned string get_description()
		{
			return _("Displays charging information");
		}

		public unowned string get_icon()
		{
			return "application-x-addon";
		}

		public bool is_supported()
		{
			return true;
		}

		public Plank.DockElement make_element(string launcher, GLib.File file)
		{
			return new BatteryDockItem.with_dockitem_file(file);
		}
	}
}
