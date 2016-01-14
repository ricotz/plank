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

namespace Plank
{
	class DockletNode
	{
		public string id;
		public string name;
		public string description;
		public string icon;
		public Gdk.Pixbuf pixbuf;
		
		public DockletNode (string id, string name, string description, string icon, Gdk.Pixbuf pixbuf) {
			this.id = id;
			this.name = name;
			this.description = description;
			this.icon = icon;
			this.pixbuf = pixbuf;
		}
	}
	
	public class DockletViewModel : GLib.Object, Gtk.TreeModel, Gtk.TreeDragSource
	{
		public enum Column
		{
			ID,
			NAME,
			DESCRIPTION,
			ICON,
			PIXBUF,
			N_COLUMNS,
		}
		
		GenericArray<DockletNode> data;
		int stamp = 0;
		
		public DockletViewModel ()
		{
			data = new GenericArray<DockletNode> ();
		}
		
		public void add (string id, string name, string descpription, string icon, Gdk.Pixbuf pixbuf)
		{
			data.add (new DockletNode (id, name, descpription, icon, pixbuf));
			stamp++;
		}
		
		public Type get_column_type (int index)
		{
			switch (index) {
			case Column.ID:
			case Column.NAME:
			case Column.DESCRIPTION:
			case Column.ICON:
				return typeof (string);
			case Column.PIXBUF:
				return typeof (Gdk.Pixbuf);
			default:
				return Type.INVALID;
			}
		}
		
		public Gtk.TreeModelFlags get_flags ()
		{
			return 0;
		}
		
		public void get_value (Gtk.TreeIter iter, int column, out Value val)
		{
			assert (iter.stamp == stamp);
			
			unowned DockletNode node = data.get ((int) iter.user_data);
			switch (column) {
			case Column.ID:
				val = Value (typeof (string));
				val.set_string (node.id);
				break;
			case Column.NAME:
				val = Value (typeof (string));
				val.set_string (node.name);
				break;
			case Column.DESCRIPTION:
				val = Value (typeof (string));
				val.set_string (node.description);
				break;
			case Column.ICON:
				val = Value (typeof (string));
				val.set_string (node.icon);
				break;
			case Column.PIXBUF:
				val = Value (typeof (Gdk.Pixbuf));
				val.set_object (node.pixbuf);
				break;
			default:
				val = Value (Type.INVALID);
				break;
			}
		}
		
		public bool get_iter (out Gtk.TreeIter iter, Gtk.TreePath path)
		{
			if (path.get_depth () != 1 || data.length == 0) {
				return invalid_iter (out iter);
			}
			
			iter = Gtk.TreeIter ();
			iter.user_data = path.get_indices ()[0].to_pointer ();
			iter.stamp = stamp;
			
			return true;
		}
		
		public int get_n_columns ()
		{
			return Column.N_COLUMNS;
		}
		
		public Gtk.TreePath? get_path (Gtk.TreeIter iter)
		{
			assert (iter.stamp == stamp);
			
			Gtk.TreePath path = new Gtk.TreePath ();
			path.append_index ((int) iter.user_data);
			
			return path;
		}
		
		public int iter_n_children (Gtk.TreeIter? iter)
		{
			assert (iter == null || iter.stamp == stamp);
			
			return (iter == null ? data.length : 0);
		}
		
		public bool iter_next (ref Gtk.TreeIter iter)
		{
			assert (iter.stamp == stamp);
			
			int pos = ((int) iter.user_data) + 1;
			if (pos >= data.length)
				return false;
			
			iter.user_data = pos.to_pointer ();
			
			return true;
		}
		
		public bool iter_previous (ref Gtk.TreeIter iter)
		{
			assert (iter.stamp == stamp);
			
			int pos = (int) iter.user_data;
			if (pos >= 0)
				return false;
			
			iter.user_data = (--pos).to_pointer ();
			
			return true;
		}
		
		public bool iter_nth_child (out Gtk.TreeIter iter, Gtk.TreeIter? parent, int n)
		{
			assert (parent == null || parent.stamp == stamp);
			
			if (parent == null && n < data.length) {
				iter = Gtk.TreeIter ();
				iter.stamp = stamp;
				iter.user_data = n.to_pointer ();
				return true;
			}
			
			// Only used for trees
			return invalid_iter (out iter);
		}
		
		public bool iter_children (out Gtk.TreeIter iter, Gtk.TreeIter? parent)
		{
			assert (parent == null || parent.stamp == stamp);
			
			// Only used for trees
			return invalid_iter (out iter);
		}
		
		public bool iter_has_child (Gtk.TreeIter iter)
		{
			assert (iter.stamp == stamp);
			
			// Only used for trees
			return false;
		}
		
		public bool iter_parent (out Gtk.TreeIter iter, Gtk.TreeIter child)
		{
			assert (child.stamp == stamp);
			
			// Only used for trees
			return invalid_iter (out iter);
		}
		
		bool invalid_iter (out Gtk.TreeIter iter)
		{
			iter = Gtk.TreeIter ();
			iter.stamp = -1;
			
			return false;
		}
		
		
		public bool drag_data_delete (Gtk.TreePath path)
		{
			return false;
		}
		
		public bool drag_data_get (Gtk.TreePath path, Gtk.SelectionData selection_data)
		{
			Gtk.TreeIter iter;
			string docklet_id;
			
			get_iter (out iter, path);
			get (iter, Column.ID, out docklet_id, -1);
			
			string uri = "%s%s\r\n".printf (DOCKLET_URI_PREFIX, docklet_id);
			selection_data.set (selection_data.get_target (), 8, (uchar[]) uri.to_utf8 ());
			
			return true;
		}
		
		public bool row_draggable (Gtk.TreePath path)
		{
			return true;
		}
	}
}
