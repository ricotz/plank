//  
//  Copyright (C) 2011 Robert Dyer
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

using Gdk;
using Gee;
using Gtk;

using Plank.Drawing;
using Plank.Items;
using Plank.Widgets;

namespace Plank
{
	public class DragManager : GLib.Object
	{
		Gdk.Window proxy_window;
		
		bool drag_known;
		bool drag_data_requested;
		bool drag_is_desktop_file;
		uint marker = 0;
		uint drag_hover_timer;
		Gee.Map<DockItem, int> original_item_pos = new HashMap<DockItem, int> ();
		
		public DockWindow Owner { get; private set; }
		
		public bool InternalDragActive { get; private set; }

		public bool HoveredAcceptsDrop { get; private set; }
		
		public ArrayList<string> drag_data;
		
		public DockItem DragItem { get; private set; }
		
		bool externalDragActive;
		public bool ExternalDragActive {
			get { return externalDragActive; }
			private set {
				if (externalDragActive == value)
					return;
				externalDragActive = value;
				
				if (!value) {
					drag_known = false;
					drag_data = null;
					drag_data_requested = false;
					drag_is_desktop_file = false;
				}
			} 
		}

		public DragManager (DockWindow owner)
		{
			Owner = owner;
			
			owner.drag_motion.connect (drag_motion);
			owner.drag_begin.connect (drag_begin);
			owner.drag_data_received.connect (drag_data_received);
			owner.drag_data_get.connect (drag_data_get);
			owner.drag_drop.connect (drag_drop);
			owner.drag_end.connect (drag_end);
			owner.drag_leave.connect (drag_leave);
			owner.drag_failed.connect (drag_failed);
			
			owner.motion_notify_event.connect (owner_motion_notify_event);
			
			enable_drag_to ();
			enable_drag_from ();
		}
		
		public bool ItemAcceptsDrop ()
		{
			if (drag_data == null)
				return false;
			
			/* TODO
			DockItem item = Owner.HoveredItem;
			
			if (!drag_is_desktop_file && item != null && item.CanAcceptDrop (drag_data))
				return true;
			*/
			
			return false;
		}
		
		bool owner_motion_notify_event (Widget w, EventMotion event)
		{
			ExternalDragActive = false;
			return false;
		}
		
		void drag_data_get (Widget w, DragContext context, SelectionData selection_data, uint info, uint time_)
		{
			if (InternalDragActive && DragItem != null) {
				string uri = "%s\r\n".printf (DragItem.as_uri ());
				selection_data.set (selection_data.target, 8, (uchar[]) uri.to_utf8 ());
			}
		}

		void drag_begin (Widget w, DragContext context)
		{
			Owner.notify["HoveredItem"].connect (hovered_item_changed);
			
			InternalDragActive = true;
			keyboard_grab (Owner.window, true, get_current_event_time ());
			drag_canceled = false;
			
			if (proxy_window != null) {
				enable_drag_to ();
				proxy_window = null;
			}
			
			Pixbuf pbuf;
			DragItem = Owner.HoveredItem;
			original_item_pos.clear ();
			
			if (DragItem != null) {
				foreach (DockItem item in Owner.Items.Items)
					original_item_pos [item] = item.Position;
				
				var icon_surface = new DockSurface (Owner.Prefs.IconSize, Owner.Prefs.IconSize);
				pbuf = Owner.HoveredItem.get_surface (icon_surface).load_to_pixbuf ();
			} else {
				pbuf = new Pixbuf (Colorspace.RGB, true, 8, 1, 1);
			}
			
			drag_set_icon_pixbuf (context, pbuf, pbuf.width / 2, pbuf.height / 2);
		}

		void drag_data_received (Widget w, DragContext context, int x, int y, SelectionData selection_data, uint info, uint time_)
		{
			if (drag_data_requested) {
				string uris = (string) selection_data.get_data ();
				
				drag_is_desktop_file = false;
				
				drag_data = new ArrayList<string> ();
				foreach (string s in uris.split ("\r\n"))
					if (s.has_prefix ("file://")) {
						drag_data.add (s);
						if (s.has_suffix (".desktop"))
							drag_is_desktop_file = true;
					}
				
				drag_data_requested = false;
				// TODO
				//Owner.SetHoveredAcceptsDrop ();
			}
			
			drag_status (context, DragAction.COPY, get_current_event_time ());
			// TODO ??
			//args.RetVal = true;
		}

		bool drag_drop (Widget w, DragContext context, int x, int y, uint time_)
		{
			drag_finish (context, true, false, time_);
			
			if (drag_data == null)
				return true;
			
			if (ItemAcceptsDrop ()) {
				// TODO
				//Owner.HoveredItem.AcceptDrop (drag_data);
			}
			
			ExternalDragActive = false;
			return true;
		}
		
		bool drag_canceled;
		
		void drag_end (Widget w, DragContext context)
		{
			if (!drag_canceled && DragItem != null) {
				if (!Owner.HideTracker.DockHovered) {
					// Remove from dock
					Owner.Items.remove_item (DragItem);
					
					int x, y;
					ModifierType mod;
					Screen screen;
					Owner.get_display ().get_pointer (out screen, out x, out y, out mod);
					new PoofWindow (x, y);
				} else {
					// Dropped somewhere on dock
					/* TODO
					DockItem item = Owner.HoveredItem;
					if (item != null && item.CanAcceptDrop (DragItem))
						item.AcceptDrop (DragItem);
					*/
					// TODO is this needed? removing the item would update it
					//Owner.Renderer.animated_draw ();
				}
			}
			
			InternalDragActive = false;
			DragItem = null;
			keyboard_ungrab (get_current_event_time ());
			
			Owner.notify["HoveredItem"].disconnect (hovered_item_changed);
		}

		void drag_leave (Widget w, DragContext context, uint time_)
		{
			drag_known = false;
		}
		
		bool drag_failed (Widget w, DragContext context, DragResult result)
		{
			drag_canceled = result == DragResult.USER_CANCELLED;
			
			if (drag_canceled)
				foreach (var entry in original_item_pos.entries)
					entry.key.set_sort (entry.value);
			
			return !drag_canceled;
		}

		bool drag_motion (Widget w, DragContext context, int x, int y, uint time_)
		{
			ExternalDragActive = !InternalDragActive;
			
			if (marker != direct_hash (context)) {
				marker = direct_hash (context);
				drag_known = false;
			}
			
			Owner.update_hovered (x, y);
			Owner.HideTracker.update_dock_hovered ();
			
			// we own the drag if InternalDragActive is true, lets not be silly
			if (!drag_known && !InternalDragActive) {
				drag_known = true;
				Atom atom = drag_dest_find_target (Owner, context, drag_dest_get_target_list (Owner));
				if (atom.name () != Atom.NONE.name ()) {
					drag_get_data (Owner, context, atom, time_);
					drag_data_requested = true;
				} else {
					drag_status (context, DragAction.PRIVATE, time_);
				}
			} else {
				drag_status (context, DragAction.COPY, time_);
			}
			return true;
		}
		
		void hovered_item_changed ()
		{
			if (InternalDragActive && Owner.HoveredItem != null && DragItem != Owner.HoveredItem) {
				int destPos = Owner.HoveredItem.Position;
				
				// drag right
				if (DragItem.Position < destPos) {
					foreach (DockItem item in Owner.Items.Items)
						if (item.Position > DragItem.Position && item.Position <= destPos)
							item.Position--;
				// drag left
				} else if (DragItem.Position > destPos) {
					foreach (DockItem item in Owner.Items.Items)
						if (item.Position < DragItem.Position && item.Position >= destPos)
							item.Position++;
				}
				DragItem.Position = destPos;
			}
			
			if (drag_hover_timer > 0)
				GLib.Source.remove (drag_hover_timer);
			drag_hover_timer = 0;
			
			if (ExternalDragActive && drag_data != null)
				drag_hover_timer = GLib.Timeout.add (1500, () => {
					DockItem item = Owner.HoveredItem;
					if (item != null)
						item.scrolled (ScrollDirection.DOWN, 0);
					return true;
				});
		}
		
		Gdk.Window? best_proxy_window ()
		{
			try {
				/* TODO
				int pid = System.Diagnostics.Process.GetCurrentProcess ().Id;
				IEnumerable<ulong> xids = Wnck.Screen.Default.WindowsStacked
					.Reverse () // top to bottom order
					.Where (wnk => wnk.IsVisibleOnWorkspace (Wnck.Screen.Default.ActiveWorkspace) && 
							                                 wnk.Pid != pid &&
							                                 wnk.EasyGeometry ().Contains (Owner.CursorTracker.Cursor))
					.Select (wnk => wnk.Xid);
				
				if (!xids.Any ())
					return null;
				
				return Gdk.Window.ForeignNew ((uint) xids.First ());
				*/
				return null;
			} catch {
				return null;
			}
		}
		
		public void ensure_proxy ()
		{
			// having a proxy window here is VERY bad ju-ju
			if (InternalDragActive)
				return;
			
			if (Owner.HideTracker.DockHovered) {
				if (proxy_window == null)
					return;
				proxy_window = null;
				enable_drag_to ();
				return;
			}
			
		// FIXME
		//	if ((Owner.CursorTracker.Modifier & ModifierType.BUTTON1_MASK) != 0) {
				Gdk.Window bestProxy = best_proxy_window ();
				if (proxy_window != bestProxy) {
					proxy_window = bestProxy;
					drag_dest_set_proxy (Owner, proxy_window, DragProtocol.XDND, true);
				}
		//	}
		}

		TargetEntry new_target_entry (string target, uint flags, uint info)
		{
			var te = TargetEntry ();
			te.target = target;
			te.flags = flags;
			te.info = info;
			return te;
		}
		
		void enable_drag_to ()
		{
			TargetEntry[] dest = {
				new_target_entry ("text/uri-list", 0, 0),
				new_target_entry ("text/plank-uri-list", 0, 0)
			};
			drag_dest_set (Owner, 0, dest, DragAction.COPY);
		}
		
		void enable_drag_from ()
		{
			// we dont really want to offer the drag to anything, merely pretend to, so we set a mimetype nothing takes
			var te = new_target_entry ("text/plank-uri-list", TargetFlags.SAME_APP, 0);
			drag_source_set (Owner, ModifierType.BUTTON1_MASK, { te }, DragAction.PRIVATE);
		}
	}
}
