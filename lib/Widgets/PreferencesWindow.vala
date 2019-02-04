//
//  Copyright (C) 2014 Rico Tzschichholz
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
	[GtkTemplate (ui = "/net/launchpad/plank/ui/preferences.ui")]
	public class PreferencesWindow : Gtk.Window
	{
		/**
		 * The controller for this dock.
		 */
		public DockController controller { get; construct set; }
		
		DockPreferences prefs;
		
		[GtkChild]
		Gtk.ComboBoxText cb_theme;
		[GtkChild]
		Gtk.ComboBoxText cb_hidemode;
		[GtkChild]
		Gtk.ComboBoxText cb_display_plug;
		[GtkChild]
		Gtk.ComboBoxText cb_position;
		[GtkChild]
		Gtk.ComboBoxText cb_alignment;
		[GtkChild]
		Gtk.ComboBoxText cb_items_alignment;
		
		[GtkChild]
		Gtk.SpinButton sp_hide_delay;
		[GtkChild]
		Gtk.SpinButton sp_unhide_delay;
		[GtkChild]
		Gtk.Scale s_offset;
		[GtkChild]
		Gtk.Scale s_zoom_percent;
		
		[GtkChild]
		Gtk.Adjustment adj_hide_delay;
		[GtkChild]
		Gtk.Adjustment adj_unhide_delay;
		[GtkChild]
		Gtk.Adjustment adj_iconsize;
		[GtkChild]
		Gtk.Adjustment adj_offset;
		[GtkChild]
		Gtk.Adjustment adj_zoom_percent;
		
		[GtkChild]
		Gtk.Switch sw_hide;
		[GtkChild]
		Gtk.Switch sw_primary_display;
		[GtkChild]
		Gtk.Switch sw_workspace_only;
		[GtkChild]
		Gtk.Switch sw_show_unpinned;
		[GtkChild]
		Gtk.Switch sw_lock_items;
		[GtkChild]
		Gtk.Switch sw_pressure_reveal;
		[GtkChild]
		Gtk.Switch sw_zoom_enabled;
		
		[GtkChild]
		Gtk.IconView view_docklets;
		
		public PreferencesWindow (DockController controller)
		{
			Object (controller: controller);
		}
		
		construct
		{
			var title = _("Preferences");
			
			prefs = controller.prefs;
			
			init_dock_tab ();
			init_docklets_tab ();
			connect_signals ();
			
			notify["controller"].connect (controller_changed);
		}
		
		void controller_changed ()
		{
			disconnect_signals ();
			
			prefs = controller.prefs;
			
			init_dock_tab ();
			connect_signals ();
		}
		
		public override bool key_press_event (Gdk.EventKey event)
		{
			if (event.keyval == Gdk.Key.Escape)
				hide ();
			
			return base.key_press_event (event);
		}
		
		void prefs_changed (Object o, ParamSpec prop)
		{
			switch (prop.name) {
			case "Alignment":
				cb_alignment.active_id = ((int) prefs.Alignment).to_string ();
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
				var pos = 0;
				foreach (unowned string plug_name in Plank.PositionManager.get_monitor_plug_names (get_screen ())) {
					if (plug_name == prefs.Monitor)
						cb_display_plug.set_active (pos);
					pos++;
				}
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
				foreach (unowned string theme in Plank.Theme.get_theme_list ()) {
					if (theme == prefs.Theme)
						cb_theme.set_active (pos);
					pos++;
				}
				break;
			case "HideDelay":
				adj_hide_delay.value = prefs.HideDelay;
				break;
			case "UnhideDelay":
				adj_unhide_delay.value = prefs.UnhideDelay;
				break;
			case "ZoomEnabled":
				sw_zoom_enabled.set_active (prefs.ZoomEnabled);
				break;
			case "ZoomPercent":
				adj_zoom_percent.value = prefs.ZoomPercent;
				break;
			// Ignored settings
			case "DockItems":
				break;
			default:
				warning ("%s not supported", prop.name);
				break;
			}
			
		}
		
		void theme_changed (Gtk.ComboBox widget)
		{
			prefs.Theme = ((Gtk.ComboBoxText) widget).get_active_text ();
		}
		
		void hidemode_changed (Gtk.ComboBox widget)
		{
			prefs.HideMode = (HideType) int.parse (widget.get_active_id ());
		}
		
		void position_changed (Gtk.ComboBox widget)
		{
			prefs.Position = (Gtk.PositionType) int.parse (widget.get_active_id ());
		}
		
		void alignment_changed (Gtk.ComboBox widget)
		{
			prefs.Alignment = (Gtk.Align) int.parse (widget.get_active_id ());
			cb_items_alignment.sensitive = (prefs.Alignment == Gtk.Align.FILL);
			s_offset.sensitive = (prefs.Alignment == Gtk.Align.CENTER);
		}
		
		void items_alignment_changed (Gtk.ComboBox widget)
		{
			prefs.ItemsAlignment = (Gtk.Align) int.parse (widget.get_active_id ());
		}
		
		void hide_toggled (GLib.Object widget, ParamSpec param)
		{
			if (((Gtk.Switch) widget).get_active ()) {
				prefs.HideMode = HideType.INTELLIGENT;
				cb_hidemode.sensitive = true;
				sp_hide_delay.sensitive = true;
				sp_unhide_delay.sensitive = true;
				sw_pressure_reveal.sensitive = true;
			} else {
				prefs.HideMode = HideType.NONE;
				cb_hidemode.sensitive = false;
				sp_hide_delay.sensitive = false;
				sp_unhide_delay.sensitive = false;
				sw_pressure_reveal.sensitive = false;
			}
		}
		
		void primary_display_toggled (GLib.Object widget, ParamSpec param)
		{
			if (((Gtk.Switch) widget).get_active ()) {
				prefs.Monitor = "";
				cb_display_plug.sensitive = false;
			} else {
				prefs.Monitor = cb_display_plug.get_active_text ();
				cb_display_plug.sensitive = true;
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
		
		void pressure_reveal_toggled (GLib.Object widget, ParamSpec param)
		{
			prefs.PressureReveal = ((Gtk.Switch) widget).get_active ();
		}
		
		void zoom_enabled_toggled (GLib.Object widget, ParamSpec param)
		{
			if (((Gtk.Switch) widget).get_active ()) {
				prefs.ZoomEnabled = true;
				s_zoom_percent.sensitive = true;
			} else {
				prefs.ZoomEnabled = false;
				s_zoom_percent.sensitive = false;
			}
		}
		
		void iconsize_changed (Gtk.Adjustment adj)
		{
			prefs.IconSize = (int) adj.value;
		}
		
		void offset_changed (Gtk.Adjustment adj)
		{
			prefs.Offset = (int) adj.value;
		}
		
		void hide_delay_changed (Gtk.Adjustment adj)
		{
			prefs.HideDelay = (int) adj.value;
		}
		
		void unhide_delay_changed (Gtk.Adjustment adj)
		{
			prefs.UnhideDelay = (int) adj.value;
		}
		
		void zoom_percent_changed (Gtk.Adjustment adj)
		{
			prefs.ZoomPercent = (int) adj.value;
		}
		
		void monitor_changed (Gtk.ComboBox widget)
		{
			prefs.Monitor = ((Gtk.ComboBoxText) widget).get_active_text ();
		}
		
		void connect_signals ()
		{
			prefs.notify.connect (prefs_changed);
			
			cb_theme.changed.connect (theme_changed);
			cb_hidemode.changed.connect (hidemode_changed);
			cb_position.changed.connect (position_changed);
			adj_hide_delay.value_changed.connect (hide_delay_changed);
			adj_unhide_delay.value_changed.connect (unhide_delay_changed);
			cb_display_plug.changed.connect (monitor_changed);
			adj_iconsize.value_changed.connect (iconsize_changed);
			adj_offset.value_changed.connect (offset_changed);
			adj_zoom_percent.value_changed.connect (zoom_percent_changed);
			sw_hide.notify["active"].connect (hide_toggled);
			sw_primary_display.notify["active"].connect (primary_display_toggled);
			sw_workspace_only.notify["active"].connect (workspace_only_toggled);
			sw_show_unpinned.notify["active"].connect (show_unpinned_toggled);
			sw_lock_items.notify["active"].connect (lock_items_toggled);
			sw_pressure_reveal.notify["active"].connect (pressure_reveal_toggled);
			sw_zoom_enabled.notify["active"].connect (zoom_enabled_toggled);
			cb_alignment.changed.connect (alignment_changed);
			cb_items_alignment.changed.connect (items_alignment_changed);
		}
		
		void disconnect_signals ()
		{
			prefs.notify.disconnect (prefs_changed);
			
			cb_theme.changed.disconnect (theme_changed);
			cb_hidemode.changed.disconnect (hidemode_changed);
			cb_position.changed.disconnect (position_changed);
			adj_hide_delay.value_changed.disconnect (hide_delay_changed);
			adj_unhide_delay.value_changed.disconnect (unhide_delay_changed);
			cb_display_plug.changed.disconnect (monitor_changed);
			adj_iconsize.value_changed.disconnect (iconsize_changed);
			adj_offset.value_changed.disconnect (offset_changed);
			adj_zoom_percent.value_changed.disconnect (zoom_percent_changed);
			sw_hide.notify["active"].disconnect (hide_toggled);
			sw_primary_display.notify["active"].disconnect (primary_display_toggled);
			sw_workspace_only.notify["active"].disconnect (workspace_only_toggled);
			sw_show_unpinned.notify["active"].disconnect (show_unpinned_toggled);
			sw_lock_items.notify["active"].disconnect (lock_items_toggled);
			sw_pressure_reveal.notify["active"].disconnect (pressure_reveal_toggled);
			sw_zoom_enabled.notify["active"].disconnect (zoom_enabled_toggled);
			cb_alignment.changed.disconnect (alignment_changed);
			cb_items_alignment.changed.disconnect (items_alignment_changed);
		}
		
		void init_dock_tab ()
		{
			var pos = 0;
			cb_theme.remove_all ();
			foreach (unowned string theme in Plank.Theme.get_theme_list ()) {
				cb_theme.append ("%i".printf (pos), theme);
				if (theme == prefs.Theme)
					cb_theme.set_active (pos);
				pos++;
			}

			cb_hidemode.active_id = ((int) prefs.HideMode).to_string ();
			cb_hidemode.sensitive = (prefs.HideMode != HideType.NONE);
			cb_position.active_id = ((int) prefs.Position).to_string ();
			adj_hide_delay.value = prefs.HideDelay;
			adj_unhide_delay.value = prefs.UnhideDelay;

			pos = 0;
			cb_display_plug.remove_all ();
			foreach (unowned string plug_name in Plank.PositionManager.get_monitor_plug_names (get_screen ())) {
				cb_display_plug.append ("%i".printf (pos), plug_name);
				if (plug_name == prefs.Monitor)
					cb_display_plug.set_active (pos);
				pos++;
			}
			if (prefs.Monitor == "")
				cb_display_plug.set_active (0);
			cb_display_plug.sensitive = (prefs.Monitor != "");
			
			sp_hide_delay.sensitive = (prefs.HideMode != HideType.NONE);
			sp_unhide_delay.sensitive = (prefs.HideMode != HideType.NONE);
			
			adj_iconsize.value = prefs.IconSize;
			adj_offset.value = prefs.Offset;
			adj_zoom_percent.value = prefs.ZoomPercent;
			s_offset.sensitive = (prefs.Alignment == Gtk.Align.CENTER);
			s_zoom_percent.sensitive = prefs.ZoomEnabled;
			sw_hide.set_active (prefs.HideMode != HideType.NONE);
			sw_primary_display.set_active (prefs.Monitor == "");
			sw_workspace_only.set_active (prefs.CurrentWorkspaceOnly);
			sw_show_unpinned.set_active (!prefs.PinnedOnly);
			sw_lock_items.set_active (prefs.LockItems);
			sw_pressure_reveal.set_active (prefs.PressureReveal);
			sw_zoom_enabled.set_active (prefs.ZoomEnabled);
			cb_alignment.active_id = ((int) prefs.Alignment).to_string ();
			cb_items_alignment.active_id = ((int) prefs.ItemsAlignment).to_string ();
			cb_items_alignment.sensitive = (prefs.Alignment == Gtk.Align.FILL);
		}
		
		void init_docklets_tab ()
		{
			var model_docklets = new DockletViewModel ();
			var sorted_docklets = new Gtk.TreeModelSort.with_model (model_docklets);
			
			Gtk.TargetEntry te = { "text/plank-uri-list", Gtk.TargetFlags.SAME_APP, 0};
			view_docklets.enable_model_drag_source (Gdk.ModifierType.BUTTON1_MASK, { te }, Gdk.DragAction.PRIVATE);
			view_docklets.set_text_column (DockletViewModel.Column.NAME);
			view_docklets.set_tooltip_column (DockletViewModel.Column.DESCRIPTION);
			view_docklets.set_pixbuf_column (DockletViewModel.Column.PIXBUF);
			view_docklets.drag_begin.connect_after (view_drag_begin);
			view_docklets.item_activated.connect (view_item_activated);
			
			foreach (var docklet in DockletManager.get_default ().list_docklets ()) {
				var pixbuf = DrawingService.load_icon (docklet.get_icon (), 48, 48);
				model_docklets.add (docklet.get_id (), docklet.get_name (), docklet.get_description (), docklet.get_icon (), pixbuf);
			}
			
			sorted_docklets.set_sort_column_id (DockletViewModel.Column.NAME, Gtk.SortType.ASCENDING);
			view_docklets.set_model (sorted_docklets);
		}
		
		[CCode (instance_pos = -1)]
		void view_drag_begin (Gtk.Widget widget, Gdk.DragContext context)
		{
			unowned Gtk.IconView view = (Gtk.IconView) widget;
			var selection = view.get_selected_items ();
			unowned List<Gtk.TreePath>? path_list = selection.first ();
			if (path_list == null)
				return;
			
			unowned Gtk.TreeModel model = view.get_model ();
			Gtk.TreeIter iter;
			GLib.Value val;
			var path = path_list.data;
			model.get_iter (out iter, path);
			model.get_value (iter, DockletViewModel.Column.ICON, out val);
			
			var icon_name = val.get_string ();
			var icon_size = prefs.IconSize;
			var window_scale_factor = get_window ().get_scale_factor ();
			icon_size *= window_scale_factor;
			var surface = DrawingService.load_icon_for_scale (icon_name, icon_size, icon_size, window_scale_factor);
			surface.set_device_offset (-icon_size / 2.0, -icon_size / 2.0);
			Gtk.drag_set_icon_surface (context, surface);
		}
		
		[CCode (instance_pos = -1)]
		void view_item_activated (Gtk.IconView view, Gtk.TreePath path)
		{
			unowned ApplicationDockItemProvider? provider = (controller.default_provider as ApplicationDockItemProvider);
			if (provider == null)
				return;
			
			unowned Gtk.TreeModel model = view.get_model ();
			Gtk.TreeIter iter;
			GLib.Value val;
			model.get_iter (out iter, path);
			model.get_value (iter, DockletViewModel.Column.ID, out val);
			
			var uri = "%s%s".printf (DOCKLET_URI_PREFIX, val.get_string ());
			debug ("Try to add docklet for '%s'", uri);
			provider.add_item_with_uri (uri);
		}
	}
}
