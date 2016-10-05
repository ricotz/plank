//
//  Copyright (C) 2010-2011 Robert Dyer
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
	public class ClippyDockItem : DockletItem
	{
		Gtk.Clipboard clipboard;
		Gee.ArrayList<string> clips;
		int cur_position = 0;
		uint timer_id = 0U;
		
		/**
		 * {@inheritDoc}
		 */
		public ClippyDockItem.with_dockitem_file (GLib.File file)
		{
			GLib.Object (Prefs: new ClippyPreferences.with_file (file));
		}
		
		construct
		{
			unowned ClippyPreferences prefs = (ClippyPreferences) Prefs;
			
			Icon = "edit-cut";
			
			if (prefs.TrackMouseSelections)
				clipboard = Gtk.Clipboard.get (Gdk.Atom.intern ("PRIMARY", true));
			else
				clipboard = Gtk.Clipboard.get (Gdk.Atom.intern ("CLIPBOARD", true));
			
			clips = new Gee.ArrayList<string> ();
			timer_id = Gdk.threads_add_timeout (prefs.TimerDelay, (SourceFunc) check_clipboard);
			
			updated ();
		}
		
		~ClippyDockItem ()
		{
			if (timer_id > 0U)
				GLib.Source.remove (timer_id);
		}
		
		bool check_clipboard ()
		{
			clipboard.request_text ((Gtk.ClipboardTextReceivedFunc) clipboard_text_received);
			
			return true;
		}
		
		[CCode (instance_pos = -1)]
		void clipboard_text_received (Gtk.Clipboard clipboard, string? text)
		{
			if (text == null || text == "")
				return;
			
			unowned ClippyPreferences prefs = (ClippyPreferences) Prefs;
			
			clips.remove (text);
			clips.add (text);
			while (clips.size > prefs.MaxEntries)
				clips.remove_at (0);
			
			cur_position = clips.size;
			
			updated ();
		}
		
		void updated ()
		{
			if (clips.size == 0)
				Text = _("Clipboard is currently empty.");
			else if (cur_position == 0 || cur_position > clips.size)
				Text = get_entry_at (clips.size);
			else
				Text = get_entry_at (cur_position);
		}
		
		string get_entry_at (int pos)
		{
			return clips.get (pos - 1).replace ("\n", "").replace ("\t", "");
		}
		
		void copy_entry_at (int pos)
		{
			if (pos < 1 || pos > clips.size)
				return;
			
			var str = clips.get (pos - 1);
			clipboard.set_text (str, (int) str.length);
			
			updated ();
		}
		
		void copy_entry ()
		{
			if (cur_position == 0)
				copy_entry_at (clips.size);
			else
				copy_entry_at (cur_position);
		}
		
		void clear ()
		{
			// Make sure we own the current clipboard content,
			// so we are allowed to clear it
			clipboard.set_text ("", 0);
			
			clipboard.clear ();
			clips.clear ();
			cur_position = 0;
			
			updated ();
		}
		
		protected override AnimationType on_scrolled (Gdk.ScrollDirection direction, Gdk.ModifierType mod, uint32 event_time)
		{
			if (direction == Gdk.ScrollDirection.UP)
				cur_position++;
			else
				cur_position--;
			
			if (cur_position < 1)
				cur_position = clips.size;
			else if (cur_position > clips.size)
				cur_position = 1;
			
			updated ();
			
			return AnimationType.NONE;
		}
		
		protected override AnimationType on_clicked (PopupButton button, Gdk.ModifierType mod, uint32 event_time)
		{
			if (button == PopupButton.LEFT && clips.size > 0) {
				copy_entry ();
				return AnimationType.BOUNCE;
			}
			
			return AnimationType.NONE;
		}
		
		public override Gee.ArrayList<Gtk.MenuItem> get_menu_items ()
		{
			var items = new Gee.ArrayList<Gtk.MenuItem> ();
			
			for (var i = clips.size ; i > 0; i--) {
				var item = create_menu_item (clips.get (i - 1), "edit-cut");
				var pos = i;
				item.activate.connect (() => {
					copy_entry_at (pos);
				});
				items.add (item);
			}
			
			if (clips.size > 0) {
				var item = create_menu_item (_("_Clear"), "edit-clear-all", true);
				item.activate.connect (clear);
				items.add (item);
			}
			
			return items;
		}
	}
}
