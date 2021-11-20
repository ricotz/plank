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

using Plank;

namespace Docky
{
	public class BatteryDockItem : DockletItem
	{
		const string BAT_BASE_PATH = "/sys/class/power_supply";
		const string BAT_CAPACITY = BAT_BASE_PATH + "/%s/capacity";
		//const string BAT_CAPACITY_LEVEL = BAT_BASE_PATH + "/%s/capacity_level";
		const string BAT_STATUS = BAT_BASE_PATH + "/%s/status";
		const string BAT_CHARGE_NOW = BAT_BASE_PATH + "/%s/charge_now";
		const string BAT_ALARM = BAT_BASE_PATH + "/%s/alarm";
		const uint BAT_CHECK_TIMER = 6000;

		string current_battery = "BAT0";
		uint timer_id = 0U;

		/**
		 * {@inheritDoc}
		 */
		public BatteryDockItem.with_dockitem_file (GLib.File file)
		{
			GLib.Object (Prefs: new DockItemPreferences.with_file (file));
		}

		construct
		{
			Icon = "battery-missing";
			Text = _("No battery");
			update ();

			// timer_id = Gdk.threads_add_timeout (60 * 1000, (SourceFunc) update);
			// Replaced 60 * 1000 with const  BAT_CHECK_TIMER and lowered it to 60 * 100

			timer_id = Gdk.threads_add_timeout (BAT_CHECK_TIMER, (SourceFunc) update); 
		}

		~BatteryDockItem ()
		{
			if (timer_id > 0U) {
				GLib.Source.remove (timer_id);
			}
		}

		int get_capacity () throws GLib.FileError
		{
			string s;
			FileUtils.get_contents (BAT_CAPACITY.printf (current_battery), out s);
			return int.parse (s);
		}

		/*
		string get_capacity_level () throws GLib.FileError
		{
			string s;
			FileUtils.get_contents (BAT_CAPACITY_LEVEL.printf (current_battery), out s);
			return s.strip ();
		}
		*/

		string get_status () throws GLib.FileError
		{
			string s;
			FileUtils.get_contents (BAT_STATUS.printf (current_battery), out s);
			return s.strip ();
		}

		bool update ()
		{
			try {
				string new_icon;
				var status = get_status ().down ();
				//var capacity_level = get_capacity_level ().down ();
				var capacity = get_capacity ();
				
				/*
				switch (capacity_level) {
					case "full":
						new_icon = "battery-full";
						break;
					case "high":
						new_icon = "battery-good";
						break;
					case "normal":
						new_icon = "battery-medium";
						break;
					case "low":
						new_icon = "battery-low";
						break;
					case "critical":
						new_icon = "battery-caution";
						break;
					case "unknown":
						new_icon = "battery-empty";
						break;
					default:
						new_icon = "battery-missing";
						break;
				}
				*/

				if (capacity >= 95) { new_icon = "battery-full"; }
				else if (capacity >= 70) { new_icon = "battery-good"; }
				else if (capacity >= 35) { new_icon = "battery-medium"; }
				else if (capacity >= 15) { new_icon = "battery-low"; }
				else if (capacity > 1) { new_icon = "battery-caution"; }
				else { new_icon = "battery-empty"; }

				switch (status) {
					case "charging":
					case "full":
						new_icon += "-charging";
						break;
					case "discharging":
					case "notcharging":
					case "unknown":
					default:
						break;
				}

				Icon = new_icon;
				Text = "%i%%".printf (capacity);
			} catch {
				Icon = "battery-missing";
				Text = _("No battery");
			}

			return true;
		}
	}
}
