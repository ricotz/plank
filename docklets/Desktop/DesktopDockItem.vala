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
            unowned Wnck.Workspace? workspace = screen.get_active_workspace ();
            layout = new Pango.Layout (Gdk.pango_context_get ()); 
            var font_description = new Gtk.Style ().font_desc;
            font_description.set_weight (Pango.Weight.BOLD);
            layout.set_font_description (font_description);
            layout.set_ellipsize (Pango.EllipsizeMode.NONE);

			//Icon = "show-desktop;;resource://" + Docky.G_RESOURCE_PATH + "/icons/show-desktop.svg";
            Icon = "desktop";
			Text = _(workspace.get_name ());

            screen.active_workspace_changed.connect_after (handle_workspace_changed);
		}

        protected override void draw_icon (Surface surface)
        {
            unowned Cairo.Context cr = surface.Context;
            Pango.Rectangle ink_rect, logical_rect;
            int font_size = surface.Width;

            layout.set_width ((int) (surface.Width * Pango.SCALE));
            layout.get_font_description ().set_absolute_size ((int) (font_size * Pango.SCALE));

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

        void handle_workspace_changed(Wnck.Workspace previous_workspace)
        {
            bool succeed = false;
            uint8[] current_desktop_number;
            Gdk.Atom property_type, property_format;
            Gdk.Window root_window = Gdk.Screen.get_default().get_root_window();

            // first get current desktop offset in ATOM element
            Gdk.Atom prop_atom = Gdk.Atom.intern("_NET_CURRENT_DESKTOP", false);
            Gdk.Atom type_atom = Gdk.Atom.intern("CARDINAL", false);
            succeed = Gdk.property_get(root_window, prop_atom, type_atom,
                    0, 255, 0, out property_type, out property_format, out current_desktop_number);
            if (succeed)
            {
                // get _NET_DESKTOP_NAMES property
                uint8[] current_desktop_name;
                Gdk.Atom desktop_name_prop = Gdk.Atom.intern("_NET_DESKTOP_NAMES", false);
                Gdk.Atom desktop_type_atom = Gdk.Atom.intern("UTF8_STRING", false);
                succeed = Gdk.property_get(root_window, desktop_name_prop, desktop_type_atom,
                        0, 255, 0, out property_type, out property_format, out current_desktop_name);
                if (succeed)
                {
                    Array<string> names = new Array<string>();
                    for (int i = 0, j = 0; i < current_desktop_name.length; ++i)
                    {
                        if (0 == current_desktop_name[i])
                        {
                            names.append_val((string)current_desktop_name[j:i]);
                            j = ++i;
                        }
                    }
                    Text = names.index(current_desktop_number[0]);
                    reset_icon_buffer();
                }
            }
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
