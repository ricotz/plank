/* xfixes.vapi
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

[CCode (cheader_filename = "X11/extensions/Xfixes.h")]
namespace XFixes {
	[CCode (cname = "XFixesQueryExtension")]
	public static bool query_extension (X.Display display, out int event_base, out int error_base);
	[CCode (cname = "XFixesQueryVersion")]
	public static X.Status query_version (X.Display display, out int major_version, out int minor_version);

	[SimpleType]
	[CCode (cname = "PointerBarrier", has_type_id = false)]
	public struct PointerBarrier : X.ID	{
	}
	[CCode (cname = "XFixesCreatePointerBarrier")]
	public static XFixes.PointerBarrier create_pointer_barrier (X.Display display, X.Window window,
		int x1, int y1, int x2, int y2, int directions, int num_devices, int *devices);
	[CCode (cname = "XFixesDestroyPointerBarrier")]
	public static void destroy_pointer_barrier (X.Display display, XFixes.PointerBarrier barrier);
}

