//
//  Copyright (C) 2019 Amogh Gaur
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
  [DBus (name = "org.freedesktop.UPower")]
  interface IUPower : GLib.Object
  {
    public signal void device_added(GLib.ObjectPath obj);
    public signal void device_removed(GLib.ObjectPath obj);

    public abstract GLib.ObjectPath get_display_device() throws DBusError, IOError;
  }

  [DBus (name = "org.freedesktop.UPower.Device")]
  interface IUPowerDevice : GLib.Object
  {
    [DBus (name = "Percentage")]
    public abstract double percentage { get; }

    [DBus (name = "IconName")]
    public abstract string icon_name { owned get; }
  }

  public class BatteryUPowerDockItem : DockletItem
  {
    const string UPowerName = "org.freedesktop.UPower";
    const string UPowerPath = "/org/freedesktop/UPower";

    private IUPower upower;
    private IUPowerDevice power_device;

    private uint timer_id = 0U;

    /**
     *{@inheritDoc}
     */
    public BatteryUPowerDockItem.with_dockitem_file (GLib.File file)
    {
      GLib.Object (Prefs: new DockItemPreferences.with_file (file));
    }

    construct
    {
      Icon = "battery-missing";
      Text = _("No battery");

      try {
        upower = Bus.get_proxy_sync(BusType.SYSTEM, UPowerName, UPowerPath);
        upower.device_added.connect(on_device_changed);
        upower.device_removed.connect(on_device_changed);
        power_device = get_display_device(upower);

        update();
        timer_id = Gdk.threads_add_timeout (20 * 1000, (SourceFunc) update);
      }
      catch (Error e) {
        warning("Cannot initialize battery docklet: %s", e.message);
				upower = null;
        power_device = null;
      }
    }

    ~BatteryUPowerDockItem()
    {
      if (timer_id > 0U) {
        GLib.Source.remove (timer_id);
      }
      if(upower != null) {
  			upower.device_added.disconnect(on_device_changed);
  			upower.device_removed.disconnect(on_device_changed);
      }
    }

    public static bool is_supported
    {
      get {
        return DBus.is_interface_name(UPowerName);
      }
    }

    private void on_device_changed(GLib.ObjectPath obj)
    {
			if(upower != null) {
      	power_device = get_display_device(upower);
			}
    }

    private IUPowerDevice get_display_device(IUPower power)
    {
      IUPowerDevice dev = null;
      try {
        GLib.ObjectPath s = power.get_display_device();
        dev = Bus.get_proxy_sync(BusType.SYSTEM, UPowerName, s);
      }
      catch(Error e) {
        warning("Error caught: %s", e.message);
        dev = null;
      }
      return dev;
    }

    private bool update()
    {
      if(power_device == null) {
        warning("Battery docklet not initialized");
        return false;
      }
      string icon = power_device.icon_name;
      int percent = (int)power_device.percentage;
      Icon = icon;
      Text = "%i%%".printf (percent);
      return true;
    }
  }

}
