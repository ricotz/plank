//
//  Copyright (C) 2016 Rico Tzschichholz
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
	const string SURFACE_STATS = "plank-quark-surface-stats";
	
	public static Quark quark_surface_stats;
	
	public static void internal_quarks_initialize ()
	{
		quark_surface_stats = quark_from_static_string (SURFACE_STATS);
	}
}
