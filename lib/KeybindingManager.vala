//
//  Copyright (C) 2012 Rico Tzschichholz
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

namespace Plank
{
	[Flags]
	public enum Keybinding {
		ITEMS = 1 << 0,
		ITEMS_OPTION = 1 << 1
	}
	
	/**
	 * This class is in charge to grab keybindings on the X11 display
	 * and filter X11-events and passing on such events to the registed
	 * handler methods.
	 */
	public class KeybindingManager : GLib.Object
	{
		/**
		 * The controller for this dock.
		 */
		public DockController controller { private get; construct; }
		
		/**
		 * list of bound keybindings
		 */
		Gee.ArrayList<Binding> bindings = new Gee.ArrayList<Binding> ();
		
		/**
		 * locked modifiers used to grab all keys whatever lock key
		 * is pressed.
		 */
		static uint[] ignored_masks = {
			0,
			Gdk.ModifierType.MOD2_MASK, // NUM_LOCK
			Gdk.ModifierType.LOCK_MASK, // CAPS_LOCK
			Gdk.ModifierType.MOD5_MASK, // SCROLL_LOCK
			Gdk.ModifierType.MOD2_MASK | Gdk.ModifierType.LOCK_MASK,
			Gdk.ModifierType.MOD2_MASK | Gdk.ModifierType.MOD5_MASK,
			Gdk.ModifierType.LOCK_MASK | Gdk.ModifierType.MOD5_MASK,
			Gdk.ModifierType.MOD2_MASK | Gdk.ModifierType.LOCK_MASK | Gdk.ModifierType.MOD5_MASK
		};
		
		/**
		 * Helper class to store keybinding
		 */
		class Binding
		{
			public string accelerator;
			public uint8 keycode;
			public Gdk.ModifierType modifiers;
			public KeybindingHandlerFunc handler;
			
			public Binding (string _accelerator, uint8 _keycode,
				Gdk.ModifierType _modifiers, owned KeybindingHandlerFunc _handler)
			{
				accelerator = _accelerator;
				keycode = _keycode;
				modifiers = _modifiers;
				handler = _handler;
			}
		}
		
		/**
		 * Keybinding func needed to bind key to handler
		 *
		 * @param event passing on gdk event
		 */
		public delegate void KeybindingHandlerFunc (X.Event event);
		
		public KeybindingManager (DockController controller)
		{
			GLib.Object (controller: controller);
		}
		
		construct
		{
			gdk_window_add_filter (null, (Gdk.FilterFunc) xevent_filter);
		}
		
		~KeybindingManager ()
		{
			unbind_all ();
			
			gdk_window_remove_filter (null, (Gdk.FilterFunc) xevent_filter);
		}
		
		public void initialize ()
		{
			var item_accel = controller.prefs.ItemAccelerator;
			var item_option_accel = controller.prefs.ItemOptionAccelerator;
			
			var mod = KeybindingManager.convert_to_modifier_only (item_accel);
			var option_mod = KeybindingManager.convert_to_modifier_only (item_option_accel);
			
			if (controller.prefs.ItemAccelerator == "") {
				warning ("%s is not a modifier! Keybindings will not be available!", item_accel);
				return;
			}
			
			// bind base accelerator
			if (!bind (item_accel, controller.renderer.show_keybindings)
				|| !bind ("<Release>" + item_accel, controller.renderer.hide_keybindings)) {
				warning ("Keybindings will not be available!");
				return;
			}
			
			bind (mod + "1", () => { controller.virtual_click_item_at (0, PopupButton.LEFT); });
			bind (mod + "2", () => { controller.virtual_click_item_at (1, PopupButton.LEFT); });
			bind (mod + "3", () => { controller.virtual_click_item_at (2, PopupButton.LEFT); });
			bind (mod + "4", () => { controller.virtual_click_item_at (3, PopupButton.LEFT); });
			bind (mod + "5", () => { controller.virtual_click_item_at (4, PopupButton.LEFT); });
			bind (mod + "6", () => { controller.virtual_click_item_at (5, PopupButton.LEFT); });
			bind (mod + "7", () => { controller.virtual_click_item_at (6, PopupButton.LEFT); });
			bind (mod + "8", () => { controller.virtual_click_item_at (7, PopupButton.LEFT); });
			bind (mod + "9", () => { controller.virtual_click_item_at (8, PopupButton.LEFT); });
			bind (mod + "0", () => { controller.virtual_click_item_at (9, PopupButton.LEFT); });
			
			// bind option accelerator
			if (item_option_accel == "") {
				warning ("%s is not a modifier! Optional keybindings will not be available!", item_option_accel);
				return;
			}
			
			bind (mod + item_option_accel, () => {
				controller.renderer.VisibleKeybinding |= Keybinding.ITEMS_OPTION;
				controller.renderer.animated_draw ();
			});
			bind ("<Release>" + mod + item_option_accel, () => {
				controller.renderer.VisibleKeybinding &= ~Keybinding.ITEMS_OPTION;
				controller.renderer.animated_draw ();
			});
			bind ("<Release>" + option_mod + item_option_accel, controller.renderer.hide_keybindings);
			
			bind (mod + option_mod + "1", () => { controller.virtual_click_item_at  (0, PopupButton.MIDDLE); });
			bind (mod + option_mod + "2", () => { controller.virtual_click_item_at  (1, PopupButton.MIDDLE); });
			bind (mod + option_mod + "3", () => { controller.virtual_click_item_at  (2, PopupButton.MIDDLE); });
			bind (mod + option_mod + "4", () => { controller.virtual_click_item_at  (3, PopupButton.MIDDLE); });
			bind (mod + option_mod + "5", () => { controller.virtual_click_item_at  (4, PopupButton.MIDDLE); });
			bind (mod + option_mod + "6", () => { controller.virtual_click_item_at  (5, PopupButton.MIDDLE); });
			bind (mod + option_mod + "7", () => { controller.virtual_click_item_at  (6, PopupButton.MIDDLE); });
			bind (mod + option_mod + "8", () => { controller.virtual_click_item_at  (7, PopupButton.MIDDLE); });
			bind (mod + option_mod + "9", () => { controller.virtual_click_item_at  (8, PopupButton.MIDDLE); });
			bind (mod + option_mod + "0", () => { controller.virtual_click_item_at  (9, PopupButton.MIDDLE); });
		}
		
		/**
		 * Bind accelerator to given handler
		 *
		 * @param accelerator accelerator parsable by Gtk.accelerator_parse
		 * @param handler handler called when given accelerator is pressed
		 * @return wether the bind was successful or not
		 */
		public bool bind (string accelerator, owned KeybindingHandlerFunc handler)
		{
			Logger.verbose ("Binding key " + accelerator);
			
			// convert accelerator
			uint keysym;
			Gdk.ModifierType modmask;
			Gtk.accelerator_parse (accelerator, out keysym, out modmask);
			
			unowned X.Display display = Gdk.X11.get_default_xdisplay ();
			var xid = Gdk.X11.get_default_root_xwindow ();
			
			uint8 keycode = display.keysym_to_keycode (keysym);
			if (keycode == 0)
				return false;
			
			var keystr = X.keysym_to_string (keysym);
			if (keystr == null)
				return false;
			
			// FIXME somethings is wrong with the SUPER modifier between the GDK and X values
			// so replace SUPER_MASK with MOD4_MASK
			if ((modmask & Gdk.ModifierType.SUPER_MASK) == Gdk.ModifierType.SUPER_MASK)
				modmask = (modmask & ~Gdk.ModifierType.SUPER_MASK) | Gdk.ModifierType.MOD4_MASK;
			
			// trap XErrors to avoid closing of application
			// even when grabing of key fails
			Gdk.error_trap_push ();
			
			// grab key finally
			// also grab all keys which are combined with a lock key such NumLock
			foreach (var ignored_mask in ignored_masks) {
				Gdk.error_trap_push ();
				display.grab_key (keycode, modmask | ignored_mask, xid, false, X.GrabMode.Async, X.GrabMode.Async);
				
				// wait until all X request have been processed
				Gdk.flush ();
				var result = Gdk.error_trap_pop ();
				if (result != X.ErrorCode.SUCCESS) {
					warning ("Failed to bind key 0x%X ('%s') with modifiers 0x%X", keycode, keystr, modmask);
					if (result == X.ErrorCode.BAD_ACCESS)
						debug ("Some other program is already using the key 0x%X ('%s') with modifiers 0x%X as a binding", keycode, keystr, modmask | ignored_mask);
					return false;
				}
			}
			
			Gdk.error_trap_pop ();
			
			Logger.verbose ("Successfully bound key 0x%X ('%s') with modifiers 0x%X", keycode, keystr, modmask);
			
			// if this is a key-released binding then add corresponding modifiermask
			// for keycode to our modmask if it is a modifier
			if ((modmask & Gdk.ModifierType.RELEASE_MASK) == Gdk.ModifierType.RELEASE_MASK)
				modmask |= get_modmask_for_keycode (keycode);
			
			// store binding
			var binding = new Binding (accelerator, keycode, modmask, handler);
			bindings.add (binding);
			
			return true;
		}
		
		/**
		 * Unbind given accelerator.
		 *
		 * @param accelerator accelerator parsable by Gtk.accelerator_parse
		 */
		public void unbind (string accelerator)
		{
			Logger.verbose ("Unbinding key " + accelerator);
			
			unowned X.Display display = Gdk.X11.get_default_xdisplay ();
			var xid = Gdk.X11.get_default_root_xwindow ();
			
			// unbind all keys with given accelerator
			var remove_bindings = new Gee.ArrayList<Binding> ();
			foreach (var binding in bindings) {
				if (str_equal (accelerator, binding.accelerator)) {
					// if this is a key-released binding then remove corresponding modifiermask
					// for keycode to our modmask if it is a modifier which we added on bind
					if ((binding.modifiers & Gdk.ModifierType.RELEASE_MASK) == Gdk.ModifierType.RELEASE_MASK)
						binding.modifiers &= ~get_modmask_for_keycode (binding.keycode);
					
					foreach (var ignored_mask in ignored_masks)
						display.ungrab_key (binding.keycode, binding.modifiers | ignored_mask, xid);
					remove_bindings.add (binding);
				}
			}
			
			// remove unbound keys
			bindings.remove_all (remove_bindings);
		}
		
		/**
		 * Unbind all registered bindings.
		 */
		public void unbind_all ()
		{
			unowned X.Display display = Gdk.X11.get_default_xdisplay ();
			var xid = Gdk.X11.get_default_root_xwindow ();
			
			// unbind all keys
			foreach (var binding in bindings)
				foreach (var ignored_mask in ignored_masks) {
					// if this is a key-released binding then remove corresponding modifiermask
					// for keycode to our modmask if it is a modifier which we added on bind
					if ((binding.modifiers & Gdk.ModifierType.RELEASE_MASK) != 0)
						binding.modifiers &= ~get_modmask_for_keycode (binding.keycode);
					
					display.ungrab_key (binding.keycode, binding.modifiers | ignored_mask, xid);
				}
			
			bindings.clear ();
		}
		
		/**
		 * Event filter method needed to fetch X.Events
		 */
		[CCode (instance_pos = -1)]
		Gdk.FilterReturn xevent_filter (Gdk.XEvent gdk_xevent, Gdk.Event gdk_event)
		{
			var filter_return = Gdk.FilterReturn.CONTINUE;
			X.Event* xevent = (X.Event*) gdk_xevent;
			
			if (xevent->type != X.EventType.KeyPress && xevent->type != X.EventType.KeyRelease)
				return filter_return;
			
			// remove NumLock, CapsLock and ScrollLock from key state
			uint event_mods = (xevent->xkey.state & ~(ignored_masks[7]));
			
			foreach (var binding in bindings) {
				if (xevent->xkey.keycode != binding.keycode)
					continue;
				
				if ((xevent->type == X.EventType.KeyPress && (binding.modifiers == event_mods))
					|| (xevent->type == X.EventType.KeyRelease
					&& (binding.modifiers & Gdk.ModifierType.RELEASE_MASK) == Gdk.ModifierType.RELEASE_MASK
					&& (binding.modifiers & ~Gdk.ModifierType.RELEASE_MASK) == event_mods)) {
					
					binding.handler (*xevent);
					
					// don't pass this event any futher
					filter_return = Gdk.FilterReturn.REMOVE;
				}
			}
			
			return filter_return;
		}
		
		/**
		 * Convert the given accelerator to a modifier only accelerator.
		 * This will convert the key to a modifier if possible and append it.
		 *
		 * @param accelerator accelerator parsable by Gtk.accelerator_parse
		 */
		public static string convert_to_modifier_only (string accelerator)
		{
			uint keysym;
			Gdk.ModifierType modmask;
			Gtk.accelerator_parse (accelerator, out keysym, out modmask);
			
			unowned X.Display display = Gdk.X11.get_default_xdisplay ();
			uint8 keycode = display.keysym_to_keycode (keysym);
			
			if (keycode > 0)
				modmask |= get_modmask_for_keycode (keycode);
			
			return get_accelerator_for_modmask (modmask);
		}
		
		static string get_accelerator_for_modmask (Gdk.ModifierType modmask)
		{
			string result = "";
			
			if ((modmask & Gdk.ModifierType.CONTROL_MASK) == Gdk.ModifierType.CONTROL_MASK)
				result += "<Ctrl>";
			if ((modmask & Gdk.ModifierType.MOD1_MASK) == Gdk.ModifierType.MOD1_MASK)
				result += "<Alt>";
			if ((modmask & Gdk.ModifierType.SHIFT_MASK) == Gdk.ModifierType.SHIFT_MASK)
				result += "<Shift>";
			if ((modmask & Gdk.ModifierType.META_MASK) == Gdk.ModifierType.META_MASK)
				result += "<AltGr>";
			if ((modmask & Gdk.ModifierType.HYPER_MASK) == Gdk.ModifierType.HYPER_MASK)
				result += "";
			if (((modmask & Gdk.ModifierType.SUPER_MASK) == Gdk.ModifierType.SUPER_MASK
				|| (modmask & Gdk.ModifierType.MOD4_MASK) == Gdk.ModifierType.MOD4_MASK))
				result += "<Super>";
			
			return result;
		}
		
		/**
		 * Convert keycode to ModifierType if it is a modifier
		 * otherwise return 0x0
		 */
		static Gdk.ModifierType get_modmask_for_keycode (uint keycode)
		{
			Gdk.ModifierType modmask;
			
			unowned X.Display display = Gdk.X11.get_default_xdisplay ();
			var i = 0;
			var keysym = display.keycode_to_keysym ((uint8)keycode, i);
			
			switch (keysym) {
			case Gdk.Key.Control_L:
			case Gdk.Key.Control_R:
				modmask = Gdk.ModifierType.CONTROL_MASK;
				break;
			case Gdk.Key.Alt_L:
			case Gdk.Key.Alt_R:
				modmask = Gdk.ModifierType.MOD1_MASK;
				break;
			case Gdk.Key.Shift_L:
			case Gdk.Key.Shift_R:
				modmask = Gdk.ModifierType.SHIFT_MASK;
				break;
			case Gdk.Key.Meta_L:
			case Gdk.Key.Meta_R:
				modmask = Gdk.ModifierType.META_MASK;
				break;
			case Gdk.Key.Hyper_L:
			case Gdk.Key.Hyper_R:
				modmask = Gdk.ModifierType.HYPER_MASK;
				break;
			case Gdk.Key.Super_L:
			case Gdk.Key.Super_R:
				// FIXME somethings is wrong with the SUPER modifier between the GDK and X values
				modmask = Gdk.ModifierType.MOD4_MASK; //Gdk.ModifierType.SUPER_MASK;
				break;
			default:
				modmask = 0x0;
				break;
			}
			
			return modmask;
		}
	}
}
