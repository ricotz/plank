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

using Plank.Items;
using Plank.Drawing;
using Plank.Services;
using Plank.Services.Windows;

namespace Plank.Widgets
{
	public class PreferencesWindow : Gtk.Window
	{
		public DockPreferences prefs { get; construct; }
		
		Gtk.Builder? builder;
		
		Gtk.ComboBoxText cb_theme;
		Gtk.ComboBoxText cb_hidemode;
		Gtk.ComboBoxText cb_position;
		Gtk.ComboBoxText cb_alignment;
		Gtk.ComboBoxText cb_items_alignment;
		
		Gtk.SpinButton sp_monitor;
		Gtk.SpinButton sp_unhide_delay;
		Gtk.Scale s_offset;
		
		Gtk.Adjustment adj_unhide_delay;
		Gtk.Adjustment adj_iconsize;
		Gtk.Adjustment adj_offset;
		
		Gtk.Switch sw_hide;
		Gtk.Switch sw_primary_display;
		Gtk.Switch sw_workspace_only;
		Gtk.Switch sw_show_unpinned;
		Gtk.Switch sw_lock_items;
		Gtk.Switch sw_auto_pinning;
		Gtk.Switch sw_pressure_reveal;
		
		public PreferencesWindow (DockPreferences prefs)
		{
			Object (prefs : prefs, type: Gtk.WindowType.TOPLEVEL, type_hint: Gdk.WindowTypeHint.DIALOG);
		}
		
		construct
		{
			skip_pager_hint = true;
			skip_taskbar_hint = true;
			title = _("Preferences");
			resizable = false;
			deletable = true;
			window_position = Gtk.WindowPosition.CENTER;
			gravity = Gdk.Gravity.CENTER;
			icon_name = "plank";
			
#if HAVE_GTK_3_10
			var headerbar = new Gtk.HeaderBar ();
			headerbar.show_close_button = true;
			headerbar.set_title (_("Preferences"));
			headerbar.show ();
			set_titlebar (headerbar);
#endif
			
			try {
				builder = new Gtk.Builder ();
				builder.add_from_resource ("%s/ui/preferences.ui".printf (Plank.G_RESOURCE_PATH));
				
				var notebook = builder.get_object ("dock_preferences") as Gtk.Notebook;
				add (notebook);
				
				cb_theme = builder.get_object ("cb_theme") as Gtk.ComboBoxText;
				cb_hidemode = builder.get_object ("cb_hidemode") as Gtk.ComboBoxText;
				cb_position = builder.get_object ("cb_position") as Gtk.ComboBoxText;
				sp_monitor = builder.get_object ("sp_monitor") as Gtk.SpinButton;
				sp_unhide_delay = builder.get_object ("sp_unhide_delay") as Gtk.SpinButton;
				adj_unhide_delay = builder.get_object ("adj_unhide_delay") as Gtk.Adjustment;
				adj_iconsize = builder.get_object ("adj_iconsize") as Gtk.Adjustment;
				adj_offset = builder.get_object ("adj_offset") as Gtk.Adjustment;
				s_offset = builder.get_object ("s_offset") as Gtk.Scale;
				sw_hide = builder.get_object ("sw_hide") as Gtk.Switch;
				sw_primary_display = builder.get_object ("sw_primary_display") as Gtk.Switch;
				sw_workspace_only = builder.get_object ("sw_workspace_only") as Gtk.Switch;
				sw_show_unpinned = builder.get_object ("sw_show_unpinned") as Gtk.Switch;
				sw_lock_items = builder.get_object ("sw_lock_items") as Gtk.Switch;
				sw_auto_pinning = builder.get_object ("sw_auto_pinning") as Gtk.Switch;
				sw_pressure_reveal = builder.get_object ("sw_pressure_reveal") as Gtk.Switch;
				cb_alignment = builder.get_object ("cb_alignment") as Gtk.ComboBoxText;
				cb_items_alignment = builder.get_object ("cb_items_alignment") as Gtk.ComboBoxText;
				
				init_dock_tab ();
 				connect_signals ();
			} catch (Error e) {
				builder = null;
				critical (e.message);
			}
		}
		
		void prefs_changed (Object o, ParamSpec prop)
		{
			switch (prop.name) {
			case "Alignment":
				cb_alignment.active_id = ((int) prefs.Alignment).to_string ();
				break;
			case "AutoPinning":
				sw_auto_pinning.set_active (prefs.AutoPinning);
				break;
			case "CurrentWorkspaceOnly":
				sw_workspace_only.set_active (prefs.CurrentWorkspaceOnly);
				break;
			case "IconSize":
				adj_iconsize.value = prefs.IconSize;
				break;
			case "ItemsAlignment":
				cb_items_alignment.active_id = ((int) prefs.ItemsAlignment).to_string ();
				break;
			case "HideMode":
				var hide_none = (prefs.HideMode != HideType.NONE);
				sw_hide.set_active (hide_none);
				if (!hide_none)
					cb_hidemode.active_id = ((int) prefs.HideMode).to_string ();
				break;
			case "LockItems":
				sw_lock_items.set_active (prefs.LockItems);
				break;
			case "Monitor":
				sp_monitor.value = prefs.Monitor;
				break;
			case "Offset":
				adj_offset.value = prefs.Offset;
				break;
			case "PinnedOnly":
				sw_show_unpinned.set_active (!prefs.PinnedOnly);
				break;
			case "Position":
				cb_position.active_id = ((int) prefs.Position).to_string ();
				break;
			case "PressureReveal":
				sw_pressure_reveal.set_active (prefs.PressureReveal);
				break;
			case "Theme":
				var pos = 0;
				foreach (var theme in Plank.Drawing.Theme.get_theme_list ()) {
					if (theme == prefs.Theme)
						cb_theme.set_active (pos);
					pos++;
				}
				break;
			case "UnhideDelay":
				adj_unhide_delay.value = prefs.UnhideDelay;
				break;
			// Ignored settings
			case "DockItems":
				break;
			default:
				warning ("%s not supported", prop.name);
				break;
			}
			
		}
		
		void cb_theme_changed (Gtk.ComboBox widget)
		{
			prefs.Theme = ((Gtk.ComboBoxText) widget).get_active_text ();
		}
		
		void cb_hidemode_changed (Gtk.ComboBox widget)
		{
			prefs.HideMode = (HideType) int.parse (widget.get_active_id ());
		}
		
		void cb_position_changed (Gtk.ComboBox widget)
		{
			prefs.Position = (Gtk.PositionType) int.parse (widget.get_active_id ());
		}
		
		void cb_alignment_changed (Gtk.ComboBox widget)
		{
			prefs.Alignment = (Gtk.Align) int.parse (widget.get_active_id ());
			cb_items_alignment.sensitive = (prefs.Alignment == Gtk.Align.FILL);
			s_offset.sensitive = (prefs.Alignment == Gtk.Align.CENTER);
		}
		
		void cb_items_alignment_changed (Gtk.ComboBox widget)
		{
			prefs.ItemsAlignment = (Gtk.Align) int.parse (widget.get_active_id ());
		}
		
		void hide_toggled (GLib.Object widget, ParamSpec param)
		{
			if (((Gtk.Switch) widget).get_active ()) {
				cb_hidemode.sensitive = true;
				sp_monitor.sensitive = false;
			} else {
				prefs.HideMode = HideType.NONE;
				sp_monitor.sensitive = true;
			}
		}
		
		void primary_display_toggled (GLib.Object widget, ParamSpec param)
		{
			if (((Gtk.Switch) widget).get_active ()) {
				prefs.Monitor = -1;
				sp_monitor.sensitive = false;
			} else {
				prefs.Monitor = 0;
				sp_monitor.sensitive = true;
			}
		}
		
		void workspace_only_toggled (GLib.Object widget, ParamSpec param)
		{
			prefs.CurrentWorkspaceOnly = ((Gtk.Switch) widget).get_active ();
		}
		
		void show_unpinned_toggled (GLib.Object widget, ParamSpec param)
		{
			prefs.PinnedOnly = !((Gtk.Switch) widget).get_active ();
		}
		
		void lock_items_toggled (GLib.Object widget, ParamSpec param)
		{
			prefs.LockItems = ((Gtk.Switch) widget).get_active ();
		}
		
		void auto_pinning_toggled (GLib.Object widget, ParamSpec param)
		{
			prefs.AutoPinning = ((Gtk.Switch) widget).get_active ();
		}
		
		void pressure_reveal_toggled (GLib.Object widget, ParamSpec param)
		{
			prefs.PressureReveal = ((Gtk.Switch) widget).get_active ();
		}
		
		void iconsize_changed (Gtk.Adjustment adj)
		{
			prefs.IconSize = (int) adj.value;
		}
		
		void offset_changed (Gtk.Adjustment adj)
		{
			prefs.Offset = (int) adj.value;
		}
		
		void unhide_delay_changed (Gtk.Adjustment adj)
		{
			prefs.UnhideDelay = (int) adj.value;
		}
		
		void monitor_changed (Gtk.SpinButton widget)
		{
			prefs.Monitor = widget.get_value_as_int ();
		}
		
		void connect_signals ()
		{
			prefs.notify.connect (prefs_changed);
			
			cb_theme.changed.connect (cb_theme_changed);
			cb_hidemode.changed.connect (cb_hidemode_changed);
			cb_position.changed.connect (cb_position_changed);
			adj_unhide_delay.value_changed.connect (unhide_delay_changed);
			sp_monitor.value_changed.connect (monitor_changed);
			adj_iconsize.value_changed.connect (iconsize_changed);
			adj_offset.value_changed.connect (offset_changed);
			sw_hide.notify["active"].connect (hide_toggled);
			sw_primary_display.notify["active"].connect (primary_display_toggled);
			sw_workspace_only.notify["active"].connect (workspace_only_toggled);
			sw_show_unpinned.notify["active"].connect (show_unpinned_toggled);
			sw_lock_items.notify["active"].connect (lock_items_toggled);
			sw_auto_pinning.notify["active"].connect (auto_pinning_toggled);
			sw_pressure_reveal.notify["active"].connect (pressure_reveal_toggled);
			cb_alignment.changed.connect (cb_alignment_changed);
			cb_items_alignment.changed.connect (cb_items_alignment_changed);
		}
		
		void init_dock_tab ()
		{
			var pos = 0;
			foreach (var theme in Plank.Drawing.Theme.get_theme_list ()) {
				cb_theme.append ("%i".printf (pos), theme);
				if (theme == prefs.Theme)
					cb_theme.set_active (pos);
				pos++;
			}

			cb_hidemode.active_id = ((int) prefs.HideMode).to_string ();
			cb_position.active_id = ((int) prefs.Position).to_string ();
			adj_unhide_delay.value = prefs.UnhideDelay;

			sp_monitor.set_range (-1, Gdk.Screen.get_default ().get_n_monitors () - 1);
			//sp_monitor.adjustment = new Gtk.Adjustment (prefs.Monitor, -1, Gdk.Screen.get_default ().get_n_monitors () - 1, 1, 1, 0);
			sp_monitor.adjustment = new Gtk.Adjustment (prefs.Monitor, -1, 9, 1, 1, 0);
			sp_monitor.value = prefs.Monitor;
			sp_monitor.sensitive = (prefs.Monitor > -1);

			adj_iconsize.value = prefs.IconSize;
			adj_offset.value = prefs.Offset;
			s_offset.sensitive = (prefs.Alignment == Gtk.Align.CENTER);
			sw_hide.set_active (prefs.HideMode != HideType.NONE);
			sw_primary_display.set_active (prefs.Monitor == -1);
			sw_workspace_only.set_active (prefs.CurrentWorkspaceOnly);
			sw_show_unpinned.set_active (!prefs.PinnedOnly);
			sw_lock_items.set_active (prefs.LockItems);
			sw_auto_pinning.set_active (prefs.AutoPinning);
			sw_pressure_reveal.set_active (prefs.PressureReveal);
			cb_alignment.active_id = ((int) prefs.Alignment).to_string ();
			cb_items_alignment.active_id = ((int) prefs.ItemsAlignment).to_string ();
			cb_items_alignment.sensitive = (prefs.Alignment == Gtk.Align.FILL);
		}
	}
}
