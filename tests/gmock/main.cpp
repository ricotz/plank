//
//  Copyright (C) 2015 Kay van der Zander
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

#include "gtest/gtest.h"
#include "plank.h"

int main (int argc, char** argv)
{
	::testing::GTEST_FLAG (throw_on_failure) = true;

	// Important: Google Test must be initialized.
	::testing::InitGoogleTest (&argc, argv);

	return RUN_ALL_TESTS ();
}
