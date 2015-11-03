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

#include <gtest/gtest.h>
#include <stdio.h>
#include "plank.h"

TEST (color, set_hsv_zero_1)
{
	PlankColor* c = new PlankColor ();

	double h = 0;
	double s = 0;
	double v = 0;
	plank_color_set_hsv (c, h, s, v);

	EXPECT_DOUBLE_EQ (h, plank_color_get_hue (c));
	EXPECT_DOUBLE_EQ (s, plank_color_get_sat (c));
	EXPECT_DOUBLE_EQ (v, plank_color_get_val (c));

	delete (c);
}

TEST (color, set_hsv_inrange)
{
	PlankColor* c = new PlankColor ();

	double h = 100;
	double s = 0.5;
	double v = 0.5;
	plank_color_set_hsv (c, h, s, v);

	EXPECT_NEAR (h, plank_color_get_hue (c), 0.0001);
	EXPECT_NEAR (s, plank_color_get_sat (c), 0.0001);
	EXPECT_NEAR (v, plank_color_get_val (c), 0.0001);

	delete (c);
}

TEST (color, set_hsv_minus_value)
{
	PlankColor* c = new PlankColor ();

	double h = -1;
	double s = -1;
	double v = -1;
	plank_color_set_hsv (c, h, s, v);

	EXPECT_DOUBLE_EQ (0, plank_color_get_hue (c));
	EXPECT_DOUBLE_EQ (0, plank_color_get_sat (c));
	EXPECT_DOUBLE_EQ (0, plank_color_get_val (c));

	delete (c);
}

TEST (color, set_hsv_max)
{
	PlankColor* c = new PlankColor ();

	double h = 40000;
	double s = 50000;
	double v = 60000;
	plank_color_set_hsv (c, h, s, v);

	EXPECT_DOUBLE_EQ (0, plank_color_get_hue (c));
	EXPECT_DOUBLE_EQ (0, plank_color_get_sat (c));
	EXPECT_DOUBLE_EQ (0, plank_color_get_val (c));

	delete (c);
}

TEST (color, set_hue_in_range)
{
	PlankColor* c = new PlankColor ();

	//init color with value's
	plank_color_set_hsv (c, 100, 0.5, 0.5);

	plank_color_set_hue (c, 10);
	EXPECT_NEAR (10, plank_color_get_hue (c), 0.0001);
	double hue_value = 150;
	double hue_current = plank_color_get_hue (c);
	plank_color_set_hue (c, hue_value);

	EXPECT_EQ (hue_value, plank_color_get_hue (c));
	EXPECT_NE (hue_current, plank_color_get_hue (c));

	delete (c);
}

TEST (color, set_hue_zero)
{
	PlankColor* c = new PlankColor ();

	//init color with value's
	plank_color_set_hsv (c, 100, 0.5, 0.5);

	plank_color_set_hue (c, 5);
	double hue_zero = 0;
	double hue_current = plank_color_get_hue (c);
	plank_color_set_hue (c, hue_zero);

	EXPECT_DOUBLE_EQ (hue_zero, plank_color_get_hue (c));
	EXPECT_NE (hue_current, plank_color_get_hue (c));

	delete (c);
}

TEST (color, set_hue_out_of_range)
{
	PlankColor* c = new PlankColor ();

	double hue_value = 500;
	double hue_current = plank_color_get_hue (c);
	plank_color_set_hue (c, hue_value);

	EXPECT_NE (hue_value, plank_color_get_hue (c));
	EXPECT_DOUBLE_EQ (hue_current, plank_color_get_hue (c));

	delete (c);
}

TEST (color, add_hue)
{
	PlankColor* c = new PlankColor ();

	//init color with value's
	plank_color_set_hsv (c, 100, 0.5, 0.5);

	double hue_value = 50;
	plank_color_set_hue (c, hue_value);

	EXPECT_DOUBLE_EQ (hue_value, plank_color_get_hue (c));
	plank_color_add_hue (c, hue_value);

	EXPECT_NE (hue_value, plank_color_get_hue (c));
	EXPECT_DOUBLE_EQ (2 * hue_value, plank_color_get_hue (c));

	delete (c);
}

TEST (color, add_hue_shift_more_than_one_rad)
{
	PlankColor* c = new PlankColor ();

	//init color with value's
	plank_color_set_hsv (c, 100, 0.5, 0.5);

	double hue_value = 200;
	plank_color_set_hue (c, hue_value);

	EXPECT_DOUBLE_EQ (hue_value, plank_color_get_hue (c));
	plank_color_add_hue (c, hue_value);

	EXPECT_NE (hue_value, plank_color_get_hue (c));
	EXPECT_DOUBLE_EQ ((2 * hue_value - 360), plank_color_get_hue (c));

	delete (c);
}

TEST (color, set_sat_zero)
{
	PlankColor* c = new PlankColor ();

	//init color with value's
	plank_color_set_hsv (c, 100, 0.5, 0.5);

	double sat_zero = 0;
	double sat_old = plank_color_get_sat (c);
	plank_color_set_sat (c, sat_zero);

	EXPECT_DOUBLE_EQ (sat_zero, plank_color_get_sat (c));
	EXPECT_NE (sat_old, plank_color_get_sat (c));

	delete (c);
}

TEST (color, set_sat_in_range)
{
	PlankColor* c = new PlankColor ();

	//init color with value's
	plank_color_set_hsv (c, 100, 0.1, 0.5);

	double sat_in_range = 0.5; //50%
	double sat_old = plank_color_get_sat (c);
	plank_color_set_sat (c, sat_in_range);

	EXPECT_DOUBLE_EQ (sat_in_range, plank_color_get_sat (c));
	EXPECT_NE (sat_old, plank_color_get_sat (c));

	delete (c);
}

TEST (color, set_sat_out_of_range)
{
	PlankColor* c = new PlankColor ();

	//init color with value's
	plank_color_set_hsv (c, 100, 0.1, 0.5);

	double sat_out_range = 5; // 500%
	double sat_old = plank_color_get_sat (c);
	plank_color_set_sat (c, sat_out_range);

	EXPECT_NE (sat_out_range, plank_color_get_sat (c));
	EXPECT_DOUBLE_EQ (sat_old, plank_color_get_sat (c));
	
	delete (c);
}

TEST (color, set_min_sat)
{
	PlankColor* c = new PlankColor ();

	//init color with value's
	plank_color_set_hsv (c, 100, 0.1, 0.5);

	double sat_value = 0.5; //50%
	plank_color_set_min_sat (c, sat_value);
	EXPECT_DOUBLE_EQ (sat_value, plank_color_get_sat (c));

	delete (c);
}

TEST (color, set_min_sat_changed)
{
	PlankColor* c = new PlankColor ();

	//init color with value's
	plank_color_set_hsv (c, 100, 0.1, 0.5);

	double sat_value = 0.1; //10%
	double sat_min = 0.5; //50%
	plank_color_set_min_sat (c, sat_min);
	EXPECT_DOUBLE_EQ (sat_min, plank_color_get_sat (c));

	plank_color_set_sat (c, sat_value);
	EXPECT_DOUBLE_EQ (sat_value, plank_color_get_sat (c));

	plank_color_set_min_sat (c, sat_min);
	EXPECT_NE (sat_value, plank_color_get_sat (c));
	EXPECT_DOUBLE_EQ (sat_min, plank_color_get_sat (c));

	delete (c);
}

TEST (color, set_max_sat)
{
	PlankColor* c = new PlankColor ();

	//init color with value's
	plank_color_set_hsv (c, 100, 0.5, 0.5);

	double sat_value = 0.1; //10%
	plank_color_set_max_sat (c, sat_value);
	EXPECT_DOUBLE_EQ (sat_value, plank_color_get_sat (c));

	delete (c);
}

TEST (color, set_max_sat_changed)
{
	PlankColor* c = new PlankColor ();

	//init color with value's
	plank_color_set_hsv (c, 100, 0.5, 0.5);

	double sat_value = 0.5; //50%
	double sat_max = 0.2; //20%	
	plank_color_set_max_sat (c, sat_max);
	EXPECT_DOUBLE_EQ (sat_max, plank_color_get_sat (c));

	plank_color_set_sat (c, sat_value);	
	EXPECT_DOUBLE_EQ (sat_value, plank_color_get_sat (c));

	plank_color_set_max_sat (c, sat_max);
	EXPECT_NE (sat_value, plank_color_get_sat (c));
	EXPECT_DOUBLE_EQ (sat_max, plank_color_get_sat (c));

	delete (c);
}

TEST (color, set_max_and_min_sat)
{
	PlankColor* c = new PlankColor ();

	//init color with value's
	plank_color_set_hsv (c, 100, 0.5, 0.5);

	double sat_value = 0.25; //25%
	double sat_min = 0.5; //50%
	double sat_max = 0.1; //10%
	plank_color_set_max_sat (c, sat_max);
	EXPECT_DOUBLE_EQ (sat_max, plank_color_get_sat (c));

	plank_color_set_min_sat (c, sat_min);
	EXPECT_DOUBLE_EQ (sat_min, plank_color_get_sat (c));

	plank_color_set_sat (c, sat_value);
	EXPECT_DOUBLE_EQ (sat_value, plank_color_get_sat (c));

	delete (c);
}

TEST (color, multiply_sat)
{
	PlankColor* c = new PlankColor ();

	//init color with value's
	plank_color_set_hsv (c, 100, 0.5, 0.5);

	double sat_value = 0.2; //20%
	double sat_multiply = 2;
	plank_color_set_sat (c, sat_value);
	EXPECT_DOUBLE_EQ (sat_value, plank_color_get_sat (c));

	plank_color_multiply_sat (c, sat_multiply);
	// expect equal with sat_value * sat_multiply.
	EXPECT_DOUBLE_EQ (sat_value * sat_multiply, plank_color_get_sat (c));

	delete (c);
}

TEST (color, multiply_sat_false)
{
	PlankColor* c = new PlankColor ();

	//init color with value's
	plank_color_set_hsv (c, 100, 0.5, 0.5);

	double sat_value = 0.8; //20%
	double sat_multiply = 2;
	plank_color_set_sat (c, sat_value);
	EXPECT_DOUBLE_EQ (sat_value, plank_color_get_sat (c));

	plank_color_multiply_sat (c, sat_multiply);
	// expect 1 because 1 is the max
	EXPECT_DOUBLE_EQ (1, plank_color_get_sat (c));

	delete (c);
}

TEST (color, darken_by_sat)
{
	PlankColor* c = new PlankColor ();

	//init color with value's
	plank_color_set_hsv (c, 100, 0.5, 0.5);

	double sat = 0.2; //20%
	double value = 0.8; //80%
	double sat_darken_amount = 0.2;
	plank_color_set_sat (c, sat);
	EXPECT_DOUBLE_EQ (sat, plank_color_get_sat (c));

	plank_color_set_val (c, value);
	EXPECT_DOUBLE_EQ (value, plank_color_get_val (c));

	plank_color_darken_by_sat (c, sat_darken_amount);
	EXPECT_NEAR (0.2 , plank_color_get_sat (c), 0.0001);
	EXPECT_NEAR (value - 0.04, plank_color_get_val (c), 0.0001);

	delete (c);
}

TEST (color, darken_by_sat_false)
{
	PlankColor* c = new PlankColor ();

	//init color with value's
	plank_color_set_hsv (c, 100, 0.5, 0.5);

	double sat = 0.8; //20%
	double value = 0.2; //80%
	double sat_darken_amount = 0.8;
	plank_color_set_sat (c, sat);
	EXPECT_DOUBLE_EQ (sat, plank_color_get_sat (c));

	plank_color_set_val (c, value);
	EXPECT_DOUBLE_EQ (value, plank_color_get_val (c));

	plank_color_darken_by_sat (c, sat_darken_amount);
	EXPECT_DOUBLE_EQ (0, plank_color_get_val (c));

	delete (c);
}

TEST (color, set_value_zero)
{
	PlankColor* c = new PlankColor ();

	//init color with value's
	plank_color_set_hsv (c, 100, 0.5, 0.5);

	plank_color_set_val (c, 0.5);
	double value_zero = 0;
	double value_old = plank_color_get_val (c);
	plank_color_set_val (c, value_zero);

	// expect 0 and not equal with the old value.
	EXPECT_DOUBLE_EQ (value_zero, plank_color_get_val (c));
	EXPECT_NE (value_old, plank_color_get_val (c));

	delete (c);
}

TEST (color, set_value_in_range)
{
	PlankColor* c = new PlankColor ();

	//init color with value's
	plank_color_set_hsv (c, 100, 0.1, 0.1);

	double value_in_range = 0.5; //50%
	double value_old = plank_color_get_val (c);
	plank_color_set_val (c, value_in_range);

	// expect 50 and not equal with the old value.
	EXPECT_DOUBLE_EQ (value_in_range, plank_color_get_val (c));
	EXPECT_NE (value_old, plank_color_get_val (c));

	delete (c);
}

TEST (color, set_value_out_of_range)
{
	PlankColor* c = new PlankColor ();

	//init color with value's
	plank_color_set_hsv (c, 100, 0.5, 0.5);

	plank_color_set_val (c, 5);
	double vaule_out_range = 500; // 500%
	double value_old = plank_color_get_val (c);
	plank_color_set_val (c, vaule_out_range);

	// expect equal with the old value not 500.
	EXPECT_NE (vaule_out_range, plank_color_get_val (c));
	EXPECT_DOUBLE_EQ (value_old, plank_color_get_val (c));

	delete (c);
}

TEST (color, set_min_val)
{
	PlankColor* c = new PlankColor ();

	//init color with value's
	plank_color_set_hsv (c, 100, 0.1, 0.1);

	double value = 0.5; //50%
	plank_color_set_min_val (c, value);
	EXPECT_DOUBLE_EQ (value, plank_color_get_val (c));

	delete (c);
}

TEST (color, set_min_val_changed)
{
	PlankColor* c = new PlankColor ();

	//init color with value's
	plank_color_set_hsv (c, 100, 0.1, 0.1);

	double value = 0.1; //10%
	double val_min = 0.5; //50%
	plank_color_set_min_val (c, val_min);
	EXPECT_DOUBLE_EQ (val_min, plank_color_get_val (c));

	plank_color_set_val (c, value);
	EXPECT_DOUBLE_EQ (value, plank_color_get_val (c));

	plank_color_set_min_val (c, val_min);
	EXPECT_NE (value, plank_color_get_val (c));
	EXPECT_DOUBLE_EQ (val_min, plank_color_get_val (c));

	delete (c);
}

TEST (color, set_max_val)
{
	PlankColor* c = new PlankColor ();

	//init color with value's
	plank_color_set_hsv (c, 100, 0.5, 0.5);

	double sat_value = 0.1; //10%
	plank_color_set_max_val (c, sat_value);
	EXPECT_DOUBLE_EQ (sat_value, plank_color_get_val (c));

	delete (c);
}

TEST (color, set_max_val_changed)
{
	PlankColor* c = new PlankColor ();

	//init color with value's
	plank_color_set_hsv (c, 100, 0.5, 0.5);

	double value = 0.5; //50%
	double val_max = 0.2; //20%
	plank_color_set_max_val (c, val_max);
	EXPECT_DOUBLE_EQ (val_max, plank_color_get_val (c));

	plank_color_set_val (c, value);
	EXPECT_DOUBLE_EQ (value, plank_color_get_val (c));

	plank_color_set_max_val (c, val_max);
	EXPECT_NE (value, plank_color_get_val (c));
	EXPECT_DOUBLE_EQ (val_max, plank_color_get_val (c));

	delete (c);
}

TEST (color, set_max_and_min_val)
{
	PlankColor* c = new PlankColor ();

	//init color with value's
	plank_color_set_hsv (c, 100, 0.5, 0.5);

	double value = 0.25; //25%
	double val_min = 0.5; //50%
	double val_max = 0.1; //10%
	plank_color_set_max_val (c, val_max);
	EXPECT_DOUBLE_EQ (val_max, plank_color_get_val (c));

	plank_color_set_min_val (c, val_min);
	EXPECT_DOUBLE_EQ (val_min, plank_color_get_val (c));

	plank_color_set_val (c, value);
	EXPECT_DOUBLE_EQ (value, plank_color_get_val (c));

	delete (c);
}

TEST (color, brighten_val)
{
	PlankColor* c = new PlankColor ();

	//init color with value's
	plank_color_set_hsv (c, 100, 0.5, 0.5);

	double value = 0.25; //25%
	plank_color_brighten_val (c,value);
	EXPECT_DOUBLE_EQ (0.625, plank_color_get_val (c));

	delete (c);
}

TEST (color, darken_val)
{
	PlankColor* c = new PlankColor ();

	//init color with value's
	plank_color_set_hsv (c, 100, 0.5, 0.5);

	double value = 0.25; //25%
	plank_color_darken_val (c, value);
	EXPECT_DOUBLE_EQ (0.375, plank_color_get_val (c));

	delete (c);
}

TEST (color, prefs_string)
{
	PlankColor* c = new PlankColor ();

	//init color with value's
	plank_color_set_hsv (c, 100, 0.5, 0.5);
	const char* value = "85;;127;;63;;0";
	char* returned = plank_color_to_prefs_string (c);
	EXPECT_EQ (*value, *returned);

	delete (c);
}

