//
//  Copyright (C) 2015 Rico Tzschichholz
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
	public class DesktopDockItem : DockletItem
	{

        Wnck.Screen screen;
        Pango.Layout layout;
		/**
		 * {@inheritDoc}
		 */
		public DesktopDockItem.with_dockitem_file (GLib.File file)
		{
			GLib.Object (Prefs: new DockItemPreferences.with_file (file));
		}
		
		construct
		{
            screen = Wnck.Screen.get_default ();
            unowned GLib.List<Wnck.Workspace> workspaces = screen.get_workspaces();
            Wnck.Workspace current_workspace = workspaces.nth_data(screen.get_active_workspace().get_number());

            layout = new Pango.Layout (Gdk.pango_context_get ()); 
            var font_description = new Gtk.Style ().font_desc;
            font_description.set_weight (Pango.Weight.BOLD);
            layout.set_font_description (font_description);
            layout.set_ellipsize (Pango.EllipsizeMode.NONE);

			Icon = "Desktop";
			Text = current_workspace.get_number().to_string();

            screen.active_workspace_changed.connect_after (handle_workspace_changed);
		}

        protected override void draw_icon (Surface surface)
        {
            unowned Cairo.Context cr = surface.Context;
            Pango.Rectangle ink_rect, logical_rect;

            layout.set_width ((int) (surface.Width * Pango.SCALE));
            layout.get_font_description ().set_absolute_size ((int) (surface.Width * Pango.SCALE));

            if (Text.length > 1)
                layout.set_text (Text.substring(0, 1), -1);
            else
                layout.set_text (Text, -1);

            layout.get_pixel_extents (out ink_rect, out logical_rect);   
            int x_offset = (surface.Width - ink_rect.width) / 2;
            int y_offset = -10;
            cr.move_to(x_offset, y_offset);

            Pango.cairo_layout_path (cr, layout);       
            cr.set_line_width (3);                      
            cr.set_source_rgba (0, 0, 0, 0.5);          
            cr.stroke_preserve ();                      
            cr.set_source_rgba (1, 1, 1, 0.8);          
            cr.fill ();     
        }                

		~DesktopDockItem ()
		{
            screen.active_workspace_changed.disconnect(handle_workspace_changed);
		}

        void handle_workspace_changed(Wnck.Screen screen, Wnck.Workspace? previous_workspace)
        {
            unowned GLib.List<Wnck.Workspace> workspaces = screen.get_workspaces();
            Wnck.Workspace current_workspace = workspaces.nth_data(screen.get_active_workspace().get_number());
            Text = current_workspace.get_number ().to_string ();
            reset_icon_buffer();
        }
		
		protected override AnimationType on_clicked (PopupButton button, Gdk.ModifierType mod, uint32 event_time)
		{
			if (button == PopupButton.LEFT) {
				unowned Wnck.Screen screen = Wnck.Screen.get_default ();
				screen.toggle_showing_desktop (!screen.get_showing_desktop ());
				return AnimationType.BOUNCE;
			}
			
			return AnimationType.NONE;
		}
	}
}
