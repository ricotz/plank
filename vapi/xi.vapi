/* xi.vapi
 *
 * Copyright (C) 2014  Rico Tzschichholz
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Authors:
 * 	Rico Tzschichholz <ricotz@ubuntu.com>
 */

[CCode (cheader_filename = "X11/extensions/XI2.h,X11/extensions/XInput2.h")]
namespace XInput {
	[CCode (cname = "XIAllMasterDevices")]
	public const int ALL_MASTER_DEVICES;

	[CCode (cname = "XIBarrierPointerReleased")]
	public const int BARRIER_POINTER_RELEASED;
	[CCode (cname = "XIBarrierDeviceIsGrabbed")]
	public const int BARRIER_DEVICE_IS_GRABBED;

	[CCode (cname = "XISetMask")]
	public static void set_mask (uchar* mask, XInput.EventType event);
	[CCode (cname = "XIClearMask")]
	public static void clear_mask (uchar* mask, XInput.EventType event);
	[CCode (cname = "XIMaskIsSet")]
	public static bool mask_is_set (uchar* mask, XInput.EventType event);
	[CCode (cname = "XIMaskLen")]
	public static int mask_length (XInput.EventType event);

	[CCode (has_type_id = false)]
	public enum EventType {
		[CCode (cname = "XI_DeviceChanged")]
		DEVICE_CHANGED,
		[CCode (cname = "XI_KeyPress")]
		KEY_PRESS,
		[CCode (cname = "XI_KeyRelease")]
		KEY_RELEASE,
		[CCode (cname = "XI_ButtonPress")]
		BUTTON_PRESS,
		[CCode (cname = "XI_ButtonRelease")]
		BUTTON_RELEASE,
		[CCode (cname = "XI_Motion")]
		MOTION,
		[CCode (cname = "XI_Enter")]
		ENTER,
		[CCode (cname = "XI_Leave")]
		LEAVE,
		[CCode (cname = "XI_FocusIn")]
		FOCUS_IN,
		[CCode (cname = "XI_FocusOut")]
		FOCUS_OUT,
		[CCode (cname = "XI_HierarchyChanged")]
		HIERARCHY_CHANGED,
		[CCode (cname = "XI_PropertyEvent")]
		PROPERTY_EVENT,
		[CCode (cname = "XI_RawKeyPress")]
		RAW_KEY_PRESS,
		[CCode (cname = "XI_RawKeyRelease")]
		RAW_KEY_RELEASE,
		[CCode (cname = "XI_RawButtonPress")]
		RAW_BUTTON_PRESS,
		[CCode (cname = "XI_RawButtonRelease")]
		RAW_BUTTON_RELEASE,
		[CCode (cname = "XI_RawMotion")]
		RAW_MOTION,
		[CCode (cname = "XI_TouchBegin")]
		TOUCH_BEGIN,
		[CCode (cname = "XI_TouchUpdate")]
		TOUCH_UPDATE,
		[CCode (cname = "XI_TouchEnd")]
		TOUCH_END,
		[CCode (cname = "XI_TouchOwnership")]
		TOUCH_OWNERSHIP,
		[CCode (cname = "XI_RawTouchBegin")]
		RAW_TOUCH_BEGIN,
		[CCode (cname = "XI_RawTouchUpdate")]
		RAW_TOUCH_UPDATE,
		[CCode (cname = "XI_RawTouchEnd")]
		RAW_TOUCH_END,
		[CCode (cname = "XI_BarrierHit")]
		BARRIER_HIT,
		[CCode (cname = "XI_BarrierLeave")]
		BARRIER_LEAVE,
		
		[CCode (cname = "XI_LASTEVENT")]
		LASTEVENT;
	}

	[CCode (has_type_id = false)]
	[Flags]
	public enum EventFlags {
		[CCode (cname = "XI_DeviceChangedMask")]
		DEVICE_CHANGED_MASK,
		[CCode (cname = "XI_KeyPressMask")]
		KEY_PRESS_MASK,
		[CCode (cname = "XI_KeyReleaseMask")]
		KEY_RELEASE_MASK,
		[CCode (cname = "XI_ButtonPressMask")]
		BUTTON_PRESS_MASK,
		[CCode (cname = "XI_ButtonReleaseMask")]
		BUTTON_RELEASE_MASK,
		[CCode (cname = "XI_MotionMask")]
		MOTION_MASK,
		[CCode (cname = "XI_EnterMask")]
		ENTER_MASK,
		[CCode (cname = "XI_LeaveMask")]
		LEAVE_MASK,
		[CCode (cname = "XI_FocusInMask")]
		FOCUS_IN_MASK,
		[CCode (cname = "XI_FocusOutMask")]
		FOCUS_OUT_MASK,
		[CCode (cname = "XI_HierarchyChangedMask")]
		HIERARCHY_CHANGED_MASK,
		[CCode (cname = "XI_PropertyEventMask")]
		PROPERTY_EVENT_MASK,
		[CCode (cname = "XI_RawKeyPressMask")]
		RAW_KEY_PRESS_MASK,
		[CCode (cname = "XI_RawKeyReleaseMask")]
		RAW_KEY_RELEASE_MASK,
		[CCode (cname = "XI_RawButtonPressMask")]
		RAW_BUTTON_PRESS_MASK,
		[CCode (cname = "XI_RawButtonReleaseMask")]
		RAW_BUTTON_RELEASE_MASK,
		[CCode (cname = "XI_RawMotionMask")]
		RAW_MOTION_MASK,
		
		/* XI 2.2 */
		[CCode (cname = "XI_TouchBeginMask")]
		TOUCH_BEGIN_MASK,
		[CCode (cname = "XI_TouchUpdateMask")]
		TOUCH_UPDATE_MASK,
		[CCode (cname = "XI_TouchEndMask")]
		TOUCH_END_MASK,
		[CCode (cname = "XI_TouchOwnershipMask")]
		TOUCH_OWNERSHIP_MASK,
		[CCode (cname = "XI_RawTouchBeginMask")]
		RAW_TOUCH_BEGIN_MASK,
		[CCode (cname = "XI_RawTouchUpdateMask")]
		RAW_TOUCH_UPDATE_MASK,
		[CCode (cname = "XI_RawTouchEndMask")]
		RAW_TOUCH_END_MASK,
		
		/* XI 2.3 */
		[CCode (cname = "XI_BarrierHitMask")]
		BARRIER_HIT_MASK,
		[CCode (cname = "XI_BarrierLeaveMask")]
		BARRIER_LEAVE_MASK;
	}

	[CCode (cname = "XIAddMasterInfo", has_type_id = false)]
	public struct AddMasterInfo {
		int type;
		string name;
		bool send_core;
		bool enable;
	}

	[CCode (cname = "XIRemoveMasterInfo", has_type_id = false)]
	public struct RemoveMasterInfo {
		int type;
		int deviceid;
		int return_mode;
		int return_pointer;
		int return_keyboard;
	}

	[CCode (cname = "XIAttachSlaveInfo", has_type_id = false)]
	public struct AttachSlaveInfo {
		int type;
		int deviceid;
		int new_master;
	}

	[CCode (cname = "XIDetachSlaveInfo", has_type_id = false)]
	public struct DetachSlaveInfo {
		int type;
		int deviceid;
	}

	// union
	[CCode (cname = "XIAnyHierarchyChangeInfo", has_type_id = false)]
	public struct AnyHierarchyChangeInfo {
		int type;
		XInput.AddMasterInfo add;
		XInput.RemoveMasterInfo remove;
		XInput.AttachSlaveInfo attach;
		XInput.DetachSlaveInfo detach;
	}
	
	[CCode (cname = "XIModifierState", has_type_id = false)]
	public struct ModifierState {
		int @base;
		int latched;
		int locked;
		int effective;
	}
	
	[CCode (cname = "XIGroupState", has_type_id = false)]
	public struct GroupState : ModifierState {
	}

	[CCode (cname = "XIButtonState", has_type_id = false)]
	public struct ButtonState {
		int mask_len;
		[CCode (array_length_cname = "mask_len")]
		uchar[] mask;
	}

	[CCode (cname = "XIValuatorState", has_type_id = false)]
	public struct ValuatorState {
		int mask_len;
		[CCode (array_length_cname = "mask_len")]
		uchar[] mask;
		[CCode (array_length_cname = "mask_len")]
		double[] values;
	}

	[CCode (cname = "XIEventMask", has_destroy_function = false, has_type_id = false)]
	public struct EventMask {
		int deviceid;
		int mask_len;
		[CCode (array_length_cname = "mask_len")]
		uchar[] mask;
	}
	
	[CCode (cname = "XIAnyClassInfo", has_type_id = false)]
	public struct AnyClassInfo {
		int type;
		int sourceid;
	}

	[CCode (cname = "XIButtonClassInfo", has_type_id = false)]
	public struct ButtonClassInfo {
		int type;
		int sourceid;
		int num_buttons;
		[CCode (array_length = false)]
		X.Atom[] labels;
		XInput.ButtonState state;
	}

	[CCode (cname = "XIKeyClassInfo", has_type_id = false)]
	public struct KeyClassInfo {
		int type;
		int sourceid;
		int num_keycodes;
		[CCode (array_length_cname = "num_keycodes")]
		int[] keycodes;
	}

	[CCode (cname = "XIValuatorClassInfo", has_type_id = false)]
	public struct ValuatorClassInfo {
		int type;
		int sourceid;
		int number;
		X.Atom label;
		double min;
		double max;
		double @value;
		int resolution;
		int mode;
	}

	[CCode (cname = "XIScrollClassInfo", has_type_id = false)]
	public struct ScrollClassInfo {
		int type;
		int sourceid;
		int number;
		int scroll_type;
		double increment;
		int flags;
	}

	[CCode (cname = "XITouchClassInfo", has_type_id = false)]
	public struct TouchClassInfo {
		int type;
		int sourceid;
		int mode;
		int num_touches;
	}

	[CCode (cname = "XIDeviceInfo", free_function = "XIFreeDeviceInfo", has_type_id = false)]
	public struct DeviceInfo {
		int deviceid;
		string name;
		int use;
		int attachment;
		bool enabled;
		int num_classes;
		[CCode (array_length_cname = "num_classes")]
		XInput.AnyClassInfo[] classes;
	}

	[CCode (cname = "XIGrabModifiers", has_type_id = false)]
	public struct GrabModifiers {
		int modifiers;
		int status;
	}

	[SimpleType]
	[CCode (cname = "BarrierEventID", has_type_id = false)]
	public struct BarrierEventID : uint {
	}

	[CCode (cname = "XIBarrierReleasePointerInfo", has_type_id = false)]
	public struct BarrierReleasePointerInfo {
		int deviceid;
		XFixes.PointerBarrier barrier;
		XInput.BarrierEventID eventid;
	}

	[CCode (cname = "XIEvent", has_type_id = false)]
	public struct Event {
		int type;
		ulong serial;
		bool send_event;
		unowned X.Display display;
		int extension;
		int evtype;
		ulong time;
	}

	[CCode (cname = "XIHierarchyInfo", has_type_id = false)]
	public struct HierarchyInfo {
		int deviceid;
		int attachment;
		int use;
		bool enabled;
		int flags;
	}

	[CCode (cname = "XIHierarchyEvent", has_type_id = false)]
	public struct HierarchyEvent {
		int type;
		ulong serial;
		bool send_event;
		unowned X.Display display;
		int extension;
		int evtype;
		ulong time;
		int flags;
		int num_info;
		XInput.HierarchyInfo info;
	}

	[CCode (cname = "XIDeviceChangedEvent", has_type_id = false)]
	public struct DeviceChangedEvent {
		int type;
		ulong serial;
		bool send_event;
		unowned X.Display display;
		int extension;
		int evtype;
		ulong time;
		int deviceid;
		int sourceid;
		int reason;
		int num_classes;
		[CCode (array_length_cname = "num_classes")]
		XInput.AnyClassInfo[] classes;
	}

	[CCode (cname = "XIDeviceEvent", has_type_id = false)]
	public struct DeviceEvent {
		int type;
		ulong serial;
		bool send_event;
		unowned X.Display display;
		int extension;
		int evtype;
		ulong time;
		int deviceid;
		int sourceid;
		int detail;
		X.Window root;
		X.Window event;
		X.Window child;
		double root_x;
		double root_y;
		double event_x;
		double event_y;
		int flags;
		XInput.ButtonState buttons;
		XInput.ValuatorState valuators;
		XInput.ModifierState mods;
		XInput.GroupState  group;
	}

	[CCode (cname = "XIRawEvent", has_type_id = false)]
	public struct RawEvent {
		int type;
		ulong serial;
		bool send_event;
		unowned X.Display display;
		int extension;
		int evtype;
		ulong time;
		int deviceid;
		int sourceid;
		int detail;
		int flags;
		XInput.ValuatorState valuators;
		[CCode (array_length = false)]
		double[] raw_values;
	}

	[CCode (cname = "XIEnterEvent", has_type_id = false)]
	public struct EnterEvent {
		int type;
		ulong serial;
		bool send_event;
		unowned X.Display display;
		int extension;
		int evtype;
		ulong time;
		int deviceid;
		int sourceid;
		int detail;
		X.Window root;
		X.Window event;
		X.Window child;
		double root_x;
		double root_y;
		double event_x;
		double event_y;
		int mode;
		bool focus;
		bool same_screen;
		XInput.ButtonState buttons;
		XInput.ModifierState mods;
		XInput.GroupState group;
	}

	[CCode (cname = "XILeaveEvent", has_type_id = false)]
	public struct LeaveEvent : EnterEvent {
	}
	
	[CCode (cname = "XIFocusInEvent", has_type_id = false)]
	public struct FocusInEvent : EnterEvent {
	}

	[CCode (cname = "XIFocusOutEvent", has_type_id = false)]
	public struct FocusOutEvent : EnterEvent {
	}

	[CCode (cname = "XIPropertyEvent", has_type_id = false)]
	public struct PropertyEvent {
		int type;
		ulong serial;
		bool send_event;
		unowned X.Display display;
		int extension;
		int evtype;
		ulong time;
		int deviceid;
		X.Atom property;
		int what;
	}

	[CCode (cname = "XITouchOwnershipEvent", has_type_id = false)]
	public struct TouchOwnershipEvent {
		int type;
		ulong serial;
		bool send_event;
		unowned X.Display display;
		int extension;
		int evtype;
		ulong time;
		int deviceid;
		int sourceid;
		uint touchid;
		X.Window root;
		X.Window event;
		X.Window child;
		int flags;
	}

	[CCode (cname = "XIBarrierEvent", has_type_id = false)]
	public struct BarrierEvent {
		int type;
		ulong serial;
		bool send_event;
		unowned X.Display display;
		int extension;
		int evtype;
		ulong time;
		int deviceid;
		int sourceid;
		X.Window event;
		X.Window root;
		double root_x;
		double root_y;
		double dx;
		double dy;
		int dtime;
		int flags;
		XFixes.PointerBarrier barrier;
		XInput.BarrierEventID eventid;
	}

	[CCode (cname = "XIQueryPointer")]
	public static bool query_pointer (X.Display display, int deviceid, X.Window win, out X.Window root, out X.Window child, out double root_x, out double root_y, out double win_x, out double win_y, out XInput.ButtonState buttons, out XInput.ModifierState mods, out XInput.GroupState group);

	[CCode (cname = "XIWarpPointer")]
	public static bool warp_pointer (X.Display display, int deviceid, X.Window src_win, X.Window dst_win, double src_x, double src_y, uint src_width, uint src_height, double dst_x, double dst_y);

	[CCode (cname = "XIDefineCursor")]
	public static X.Status define_cursor (X.Display display, int deviceid, X.Window win, X.Cursor cursor);

	[CCode (cname = "XIUndefineCursor")]
	public static X.Status undefine_cursor (X.Display display, int deviceid, X.Window win);

	[CCode (cname = "XIChangeHierarchy")]
	public static X.Status change_hierarchy (X.Display display, [CCode (array_length_cname = "num_changes", array_length_pos = 2.1, array_length_type = "int")] XInput.AnyHierarchyChangeInfo[] changes);

	[CCode (cname = "XISetClientPointer")]
	public static X.Status set_client_pointer (X.Display display, X.Window win, int deviceid);

	[CCode (cname = "XIGetClientPointer")]
	public static bool get_client_pointer (X.Display display, X.Window win, out int deviceid);

	[CCode (cname = "XISelectEvents")]
	public static int select_events (X.Display display, X.Window window, XInput.EventMask* masks, int masks_len);

	[CCode (cname = "XIGetSelectedEvents", array_length_cname = "num_masks_return")]
	public static XInput.EventMask[] get_selected_events (X.Display display, X.Window window);

	[CCode (cname = "XIQueryVersion")]
	public static X.Status query_version (X.Display display, ref int major_version, ref int minor_version);

	[CCode (cname = "XIQueryDevice", array_length_cname = "ndevices_return")]
	public static XInput.DeviceInfo[] query_device (X.Display display, X.Window window);

	[CCode (cname = "XISetFocus")]
	public static X.Status set_focus (X.Display display, int deviceid, X.Window win, ulong time);

	[CCode (cname = "XIGetFocus")]
	public static X.Status get_focus (X.Display display, int deviceid, out X.Window focus_return);

	[CCode (cname = "XIGrabDevice")]
	public static X.Status grab_device (X.Display display, int deviceid, X.Window grab_window, ulong time, X.Cursor cursor, int grab_mode, int paired_device_mode, bool owner_events, XInput.EventMask mask);

	[CCode (cname = "XIUngrabDevice")]
	public static X.Status ungrab_device (X.Display display, int deviceid, ulong time);

	[CCode (cname = "XIAllowEvents")]
	public static X.Status allow_events (X.Display display, int deviceid, int event_mode, ulong time);

	[CCode (cname = "XIAllowTouchEvents")]
	public static X.Status allow_touch_events (X.Display display, int deviceid, uint touchid, X.Window grab_window, int event_mode);

	[CCode (cname = "XIGrabButton")]
	public static int grab_button (X.Display display, int deviceid, int button, X.Window grab_window, X.Cursor cursor, int grab_mode, int paired_device_mode, int owner_events, XInput.EventMask mask, [CCode (array_length_cname = "num_modifiers", array_length_pos = 8.9, array_length_type = "int")] ref XInput.GrabModifiers[] modifiers_inout);

	[CCode (cname = "XIGrabKeycode")]
	public static int grab_keycode (X.Display display, int deviceid, int keycode, X.Window grab_window, int grab_mode, int paired_device_mode, int owner_events, XInput.EventMask mask, [CCode (array_length_cname = "num_modifiers", array_length_pos = 4.9, array_length_type = "int")] ref XInput.GrabModifiers[] modifiers_inout);




	[CCode (cname = "XIBarrierReleasePointers")]
	public static void barrier_release_pointers (X.Display display, [CCode (array_length_cname = "num_barriers", array_length_pos = 2.1, array_length_type = "int")] XInput.BarrierReleasePointerInfo[] barriers);

	[CCode (cname = "XIBarrierReleasePointer")]
	public static void barrier_release_pointer (X.Display display, int deviceid, XFixes.PointerBarrier barrier, XInput.BarrierEventID eventid);

}

