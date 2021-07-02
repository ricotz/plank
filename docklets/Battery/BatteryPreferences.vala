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
    public class BatteryPreferences : DockItemPreferences
    {
        [Description(nick = "battery-name", blurb = "The name of the battery unit under /sys/class/powe_supply (default=BAT0)")]
        public string BatteryName {get;set;}

        public BatteryPreferences.with_file (GLib.File file)
        {
            base.with_file (file);
        }
        
        protected override void reset_properties ()
        {
            BatteryName = "BAT0";
        }
    }
}