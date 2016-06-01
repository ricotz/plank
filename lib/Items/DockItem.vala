//
//  Copyright (C) 2011-2012 Robert Dyer, Rico Tzschichholz
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
	 * The base class for all dock items.
	 */
	public abstract class DockItem : DockElement
	{
		/**
		 * Signal fired when the .dockitem for this item was deleted.
		 */
		public signal void deleted ();
		
		/**
		 * The dock item's icon.
		 */
		public string Icon { get; set; default = ""; }
		
		protected Gdk.Pixbuf? ForcePixbuf { get; set; default = null; }
		
		/**
		 * The count for the dock item.
		 */
		public int64 Count { get; set; default = 0; }
		
		/**
		 * Show the item's count or not.
		 */
		public bool CountVisible { get; set; default = false; }
		
		/**
		 * The progress for this dock item.
		 */
		public double Progress { get; set; default = 0; }
		
		/**
		 * Show the item's progress or not.
		 */
		public bool ProgressVisible { get; set; default = false; }
		
		int position = -1;
		/**
		 * The dock item's position on the dock.
		 */
		public int Position {
			get {
				return position;
			}
			set {
				if (position == value)
					return;
				
				if (LastPosition != position)
					LastPosition = position;
				
				position = value;
				
				// Only trigger animation if this isn't the initial position set
				if (LastPosition > -1) {
					LastMove = GLib.get_monotonic_time ();
					State |= ItemState.MOVE;
				}
			}
		}
		
		/**
		 * The dock item's last position on the dock.
		 */
		public int LastPosition { get; protected set; default = -1; }
		
		/**
		 * The item's current state.
		 */
		public ItemState State { get; protected set; default = ItemState.NORMAL; }
		
		/**
		 * The indicator shown for the item.
		 */
		public IndicatorState Indicator { get; protected set; default = IndicatorState.NONE; }
		
		/**
		 * The average color of this item's icon.
		 */
		public Color AverageIconColor { get; protected set; default = Color () { red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0 }; }
		
		/**
		 * The filename of the preferences backing file.
		 */
		public string DockItemFilename {
			owned get { return Prefs.get_filename (); }
		}
		
		/**
		 * The launcher associated with this item.
		 */
		public string Launcher {
			get { return Prefs.Launcher; }
		}
		
		/**
		 * The underlying preferences for this item.
		 */
		public DockItemPreferences Prefs { get; construct; }
		
		SurfaceCache<DockItem> buffer;
		SurfaceCache<DockItem> background_buffer;
		Surface? foreground_surface = null;
		
		FileMonitor? launcher_file_monitor = null;
		FileMonitor? icon_file_monitor = null;
		
		bool launcher_exists = false;
		uint removal_timer_id = 0U;
		
		/**
		 * Creates a new dock item.
		 */
		public DockItem ()
		{
			GLib.Object (Prefs: new DockItemPreferences ());
		}
		
		construct
		{
			buffer = new SurfaceCache<DockItem> (SurfaceCacheFlags.NONE);
			background_buffer = new SurfaceCache<DockItem> (SurfaceCacheFlags.ALLOW_SCALE);
			
			Prefs.deleted.connect (handle_deleted);
			Prefs.notify["Launcher"].connect (handle_launcher_changed);
			
			DrawingService.get_icon_theme ().changed.connect (icon_theme_changed);
			notify["Icon"].connect (icon_changed);
			notify["ForcePixbuf"].connect (icon_changed);
			
			notify["Count"].connect (reset_foreground_buffer);
			notify["CountVisible"].connect (reset_foreground_buffer);
			notify["Progress"].connect (reset_foreground_buffer);
			notify["ProgressVisible"].connect (reset_foreground_buffer);
			
			launcher_file_monitor_start ();
			if (ForcePixbuf == null)
				icon_file_monitor_start ();
		}
		
		~DockItem ()
		{
			buffer.clear ();
			background_buffer.clear ();
			
			Prefs.deleted.disconnect (handle_deleted);
			Prefs.notify["Launcher"].disconnect (handle_launcher_changed);
			
			DrawingService.get_icon_theme ().changed.disconnect (icon_theme_changed);
			notify["Icon"].disconnect (icon_changed);
			notify["ForcePixbuf"].disconnect (icon_changed);
			
			notify["Count"].disconnect (reset_foreground_buffer);
			notify["CountVisible"].disconnect (reset_foreground_buffer);
			notify["Progress"].disconnect (reset_foreground_buffer);
			notify["ProgressVisible"].disconnect (reset_foreground_buffer);
			
			launcher_file_monitor_stop ();
			icon_file_monitor_stop ();
			
			if (stop_removal ())
				@delete ();
		}
		
		/**
		 * Signal handler called when the underlying preferences file is deleted.
		 */
		void handle_deleted ()
		{
			deleted ();
		}
		
		/**
		 * Parses the associated launcher and e.g. sets the icon and text from it.
		 */
		protected virtual void load_from_launcher ()
		{
			// No default implementation needed
		}
		
		void handle_launcher_changed ()
		{
			launcher_file_monitor_stop ();
			
			load_from_launcher ();
			
			launcher_file_monitor_start ();
		}
		
		/**
		 * Deletes the underlying preferences file.
		 */
		public void delete ()
		{
			launcher_file_monitor_stop ();
			
			Prefs.delete ();
		}
		
		/**
		 * Resets the buffer for this item's icon and requests a redraw.
		 */
		protected void reset_icon_buffer ()
		{
			buffer.clear ();
			background_buffer.clear ();
			foreground_surface = null;
			
			needs_redraw ();
		}
		
		/**
		 * Resets the buffers for this item's icon.
		 */
		public override void reset_buffers ()
		{
			background_buffer.clear ();
			foreground_surface = null;
		}
		
		public void unset_move_state ()
		{
			State &= ~ItemState.MOVE;
		}
		
		void reset_foreground_buffer ()
		{
			foreground_surface = null;
			
			needs_redraw ();
		}
		
		void icon_theme_changed ()
		{
			// Put Gtk.IconTheme.changed emmitted signals in idle queue to avoid
			// race conditions with concurrent handles
			Gdk.threads_add_idle_full (GLib.Priority.LOW, () => {
				reset_icon_buffer ();
				return false;
			});
		}
		
		void icon_changed ()
		{
			icon_file_monitor_stop ();
			
			if (ForcePixbuf == null)
				icon_file_monitor_start ();
			
			reset_icon_buffer ();
		}
		
		[CCode (instance_pos = -1)]
		void icon_file_changed (File f, File? other, FileMonitorEvent event)
		{
			switch (event) {
			case FileMonitorEvent.CHANGES_DONE_HINT:
				reset_icon_buffer ();
				break;
			default:
				break;
			}
		}
		
		void icon_file_monitor_start ()
		{
			var icon_file = DrawingService.try_get_icon_file (Icon);
			if (icon_file == null || icon_file.get_uri_scheme () != "file")
				return;
			
			try {
				icon_file_monitor = icon_file.monitor_file (0);
				icon_file_monitor.changed.connect (icon_file_changed);
			} catch (Error e) {
				critical ("Unable to watch the icon file '%s'", icon_file.get_path () ?? "");
				debug (e.message);
			}
		}
		
		void icon_file_monitor_stop ()
		{
			if (icon_file_monitor == null)
				return;
			
			icon_file_monitor.changed.disconnect (icon_file_changed);
			icon_file_monitor.cancel ();
			icon_file_monitor = null;
		}
		
		[CCode (instance_pos = -1)]
		void launcher_file_changed (File f, File? other, FileMonitorEvent event)
		{
			switch (event) {
			case FileMonitorEvent.CHANGES_DONE_HINT:
				Logger.verbose ("Launcher file '%s' changed, reloading", f.get_uri ());
				
				load_from_launcher ();
				break;
			case FileMonitorEvent.MOVED:
				if (other == null)
					break;
				var launcher = other.get_uri ();
				Logger.verbose ("Launcher file '%s' moved to '%s'", f.get_uri (), launcher);
				
				replace_launcher (launcher);
				
				load_from_launcher ();
				break;
			case FileMonitorEvent.DELETED:
				debug ("Launcher file '%s' deleted, item is invalid now", f.get_uri ());
				
				launcher_exists = false;
				LastValid = GLib.get_monotonic_time ();
				State |= ItemState.INVALID;
				
				schedule_removal_if_needed ();
				break;
			case FileMonitorEvent.CREATED:
				debug ("Launcher file '%s' created, item is valid again", f.get_uri ());
				
				launcher_exists = true;
				State &= ~ItemState.INVALID;
				
				stop_removal ();
				break;
			default:
				break;
			}
			
			needs_redraw ();
		}
		
		void launcher_file_monitor_start ()
		{
			if (launcher_file_monitor != null)
				return;
			
			unowned string? launcher = Prefs.Launcher;
			if (launcher == null || launcher == "") {
				State &= ~ItemState.INVALID;
				return;
			}
			
			try {
				var launcher_file = File.new_for_uri (launcher);
				launcher_exists = launcher_file.query_exists ();
				launcher_file_monitor = launcher_file.monitor_file (FileMonitorFlags.SEND_MOVED);
				launcher_file_monitor.changed.connect (launcher_file_changed);
			} catch {
				warning ("Unable to watch the launcher file '%s'", launcher);
			}
		}
		
		void launcher_file_monitor_stop ()
		{
			if (launcher_file_monitor == null)
				return;
			
			launcher_file_monitor.changed.disconnect (launcher_file_changed);
			launcher_file_monitor.cancel ();
			launcher_file_monitor = null;
		}
		
		void replace_launcher (string launcher)
		{
			if (launcher == Prefs.Launcher)
				return;
			
			launcher_file_monitor_stop ();
			Prefs.notify["Launcher"].disconnect (handle_launcher_changed);
			Prefs.Launcher = launcher;
			Prefs.notify["Launcher"].connect (handle_launcher_changed);
			launcher_file_monitor_start ();
		}
		
		bool schedule_removal_if_needed ()
		{
			if (removal_timer_id > 0U)
				return true;
			
			if (launcher_file_monitor == null || is_valid ())
				return false;
			
			removal_timer_id = Gdk.threads_add_timeout (ITEM_INVALID_DURATION, () => {
				removal_timer_id = 0U;
				if (!is_valid ())
					@delete ();
				return false;
			});
			
			return true;
		}
		
		bool stop_removal ()
		{
			if (removal_timer_id == 0U)
				return false;
			
			Source.remove (removal_timer_id);
			removal_timer_id = 0U;
			
			return true;
		}
		
		/**
		 * Returns the surface for this item.
		 *
		 * It might trigger an internal redraw if the requested size
		 * isn't cached yet.
		 *
		 * @param width width of the icon surface
		 * @param height height of the icon surface
		 * @param model existing surface to use as basis of new surface
		 * @return the surface for this item which may not be changed
		 */
		public Surface get_surface (int width, int height, Surface model)
		{
			return buffer.get_surface<DockItem> (width, height, model, (DrawFunc<DockItem>) internal_get_surface, null);
		}
		
		[CCode (instance_pos = -1)]
		Surface internal_get_surface (int width, int height, Surface model, DrawDataFunc<DockItem>? draw_data_func)
		{
			var surface = new Surface.with_surface (width, height, model);
			
			Logger.verbose ("DockItem.draw_icon (width = %i, height = %i)", width, height);
			draw_icon (surface);
			
			AverageIconColor = surface.average_color ();
			
			return surface;
		}
		
		/**
		 * Returns the background surface for this item.
		 *
		 * The draw_func may pass through the given previously computed surface
		 * or change it as needed. This surface will be buffered internally.
		 *
		 * Passing null as draw_func will destroy the internal background buffer.
		 *
		 * @param draw_data_func function which creates/changes the background surface
		 * @return the background surface of this item which may not be changed
		 */
		public Surface? get_background_surface (int width, int height, Surface model, DrawDataFunc<DockItem>? draw_data_func)
		{
			return background_buffer.get_surface<DockItem> (width, height, model, (DrawFunc<DockItem>) internal_get_background_surface, (DrawDataFunc<DockItem>) draw_data_func);
		}
		
		[CCode (instance_pos = -1)]
		Surface? internal_get_background_surface (int width, int height, Surface model, DrawDataFunc<DockItem>? draw_data_func)
		{
			if (draw_data_func == null)
				return null;
			
			return draw_data_func (width, height, model, this);
		}
		
		/**
		 * Returns the foreground surface for this item.
		 *
		 * The draw_func may pass through the given previously computed surface
		 * or change it as needed. This surface will be buffered internally.
		 *
		 * Passing null as draw_func will destroy the internal foreground buffer.
		 *
		 * @param draw_data_func function which creates/changes the foreground surface
		 * @return the background surface of this item which may not be changed
		 */
		public Surface? get_foreground_surface (int width, int height, Surface model, DrawDataFunc<DockItem>? draw_data_func)
		{
			if (draw_data_func == null) {
				foreground_surface = null;
				return null;
			}
			
			if (foreground_surface != null
				&& foreground_surface.Width == width && foreground_surface.Height == height)
				return foreground_surface;
			
			foreground_surface = draw_data_func (width, height, model, this);
			
			return foreground_surface;
		}
		
		/**
		 * Returns a copy of the surface for this item.
		 *
		 * It will trigger an internal redraw if the requested size
		 * isn't matching the cache.
		 *
		 * @param width width of the icon surface
		 * @param height height of the icon surface
		 * @param model existing surface to use as basis of new surface
		 * @return the copied surface for this item
		 */
		public Surface get_surface_copy (int width, int height, Surface model)
		{
			return get_surface (width, height, model).copy ();
		}

		/**
		 * Draws the item's icon onto a surface.
		 *
		 * @param surface the surface to draw on
		 */
		protected virtual void draw_icon (Surface surface)
		{
			Cairo.Surface? icon = null;
			Gdk.Pixbuf? pbuf = ForcePixbuf;
			if (pbuf == null) {
#if HAVE_HIDPI
				double x_scale = 1.0, y_scale = 1.0;
				surface.Internal.get_device_scale (out x_scale, out y_scale);
				icon = DrawingService.load_icon_for_scale (Icon, surface.Width, surface.Height, (int) double.max (x_scale, y_scale));
				if (icon != null)
					icon.set_device_scale (1.0, 1.0);
#else
				pbuf = DrawingService.load_icon (Icon, surface.Width, surface.Height);
#endif
			} else {
				pbuf = DrawingService.ar_scale (pbuf, surface.Width, surface.Height);
			}
			
			unowned Cairo.Context cr = surface.Context;
			
			if (pbuf != null) {
				Gdk.cairo_set_source_pixbuf (cr, pbuf, (surface.Width - pbuf.width) / 2, (surface.Height - pbuf.height) / 2);
				cr.paint ();
			} else if (icon != null) {
				cr.set_source_surface (icon, 0, 0);
				cr.paint ();
			} else {
				warn_if_reached ();
			}
		}
		
		/**
		 * Draws a placeholder icon onto a surface.
		 * This method should be considered time-critical!
		 * Make sure to only use simple drawing routines, and do not rely on external resources!
		 *
		 * @param surface the surface to draw on
		 */
		protected virtual void draw_icon_fast (Surface surface)
		{
			unowned Cairo.Context cr = surface.Context;
			var width = surface.Width;
			var height = surface.Height;
			var radius = width / 2 - 1;
			
			var line_width_half = 1;
			
			cr.move_to (radius, line_width_half);
			cr.arc (radius + line_width_half, radius + line_width_half, radius, 0, 2 * Math.PI);
			cr.close_path ();
			
			cr.set_source_rgba (1, 1, 1, 0.2);
			cr.set_line_width (2 * line_width_half);
			cr.stroke_preserve ();
			
			var rg = new Cairo.Pattern.radial (width / 2, height, height / 8, width / 2, height, height);
			rg.add_color_stop_rgba (0, 0, 0, 0, 0.6);
			rg.add_color_stop_rgba (1, 0, 0, 0, 0.3);
			
			cr.set_source (rg);
			cr.fill ();
		}
		
		/**
		 * Check the validity of this item.
		 *
		 * @return Whether or not this item is valid for the .dockitem given
		 */
		public virtual bool is_valid ()
		{
			return launcher_exists || Prefs.Launcher == "";
		}
		
		/**
		 * Copy all property value of this dockitem instance to target instance.
		 *
		 * @param target the dockitem to copy the values to
		 */
		public void copy_values_to (DockItem target)
		{
#if VALA_0_32
			(unowned ParamSpec)[] properties = get_class ().list_properties ();
#else
			(unowned ParamSpec)[] properties = g_object_class_list_properties (get_class ());
#endif
			
			foreach (unowned ParamSpec prop in properties) {
				// Skip non-copyable properties to avoid warnings
				if ((prop.flags & ParamFlags.WRITABLE) == 0
					|| (prop.flags & ParamFlags.CONSTRUCT_ONLY) != 0)
					continue;
				
				unowned string name = prop.get_name ();
				
				// Do not copy these
				if (name == "Container")
					continue;
				
				var type = prop.value_type;
				var val = Value (type);
				get_property (name, ref val);
				target.set_property (name, val);
			}
		}
	}
}
