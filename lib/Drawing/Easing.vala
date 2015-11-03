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
	/**
	 * Utility functions to calculate progress of transitions.
	 * Initially ported from clutter's clutter-enums.h and clutter-easing.c
	 */

	/**
	 * The available animation modes
	 */
	public enum AnimationMode
	{
		CUSTOM = 0,

		/**
		 * linear tweening
		 */
		LINEAR,

		/**
		 * quadratic tweening
		 */
		EASE_IN_QUAD,
		/**
		 * quadratic tweening, inverse of EASE_IN_QUAD
		 */
		EASE_OUT_QUAD,
		/**
		 * quadratic tweening, combininig EASE_IN_QUAD and EASE_OUT_QUAD
		 */
		EASE_IN_OUT_QUAD,

		/**
		 * cubic tweening
		 */
		EASE_IN_CUBIC,
		/**
		 * cubic tweening, invers of EASE_IN_CUBIC
		 */
		EASE_OUT_CUBIC,
		/**
		 * cubic tweening, combining EASE_IN_CUBIC and EASE_OUT_CUBIC
		 */
		EASE_IN_OUT_CUBIC,

		/**
		 * quartic tweening
		 */
		EASE_IN_QUART,
		/**
		 * quartic tweening, inverse of EASE_IN_QUART
		 */
		EASE_OUT_QUART,
		/**
		 * quartic tweening, combining EASE_IN_QUART and EASE_OUT_QUART
		 */
		EASE_IN_OUT_QUART,

		/**
		 * quintic tweening
		 */
		EASE_IN_QUINT,
		/**
		 * quintic tweening, inverse of EASE_IN_QUINT
		 */
		EASE_OUT_QUINT,
		/**
		 * fifth power tweening, combining EASE_IN_QUINT and EASE_OUT_QUINT
		 */
		EASE_IN_OUT_QUINT,

		/**
		 * sinusoidal tweening
		 */
		EASE_IN_SINE,
		/**
		 * sinusoidal tweening, inverse of EASE_IN_SINE
		 */
		EASE_OUT_SINE,
		/**
		 * sine wave tweening, combining EASE_IN_SINE and EASE_OUT_SINE
		 */
		EASE_IN_OUT_SINE,

		/**
		 * exponential tweening
		 */
		EASE_IN_EXPO,
		/**
		 * exponential tweening, inverse of EASE_IN_EXPO
		 */
		EASE_OUT_EXPO,
		/**
		 * exponential tweening, combining EASE_IN_EXPO and EASE_OUT_EXPO
		 */
		EASE_IN_OUT_EXPO,

		/**
		 * circular tweening
		 */
		EASE_IN_CIRC,
		/**
		 * circular tweening, inverse of EASE_IN_CIRC
		 */
		EASE_OUT_CIRC,
		/**
		 * circular tweening, combining EASE_IN_CIRC and EASE_OUT_CIRC
		 */
		EASE_IN_OUT_CIRC,

		/**
		 * elastic tweening, with offshoot on start
		 */
		EASE_IN_ELASTIC,
		/**
		 * elastic tweening, with offshoot on end
		 */
		EASE_OUT_ELASTIC,
		/**
		 * elastic tweening with offshoot on both ends
		 */
		EASE_IN_OUT_ELASTIC,

		/**
		 * overshooting cubic tweening, with backtracking on start
		 */
		EASE_IN_BACK,
		/**
		 * overshooting cubic tweening, with backtracking on end
		 */
		EASE_OUT_BACK,
		/**
		 * overshooting cubic tweening, with backtracking on both ends
		 */
		EASE_IN_OUT_BACK,

		/**
		 * exponentially decaying parabolic (bounce) tweening, with bounce on start
		 */
		EASE_IN_BOUNCE,
		/**
		 * exponentially decaying parabolic (bounce) tweening, with bounce on end
		 */
		EASE_OUT_BOUNCE,
		/**
		 * exponentially decaying parabolic (bounce) tweening, with bounce on both ends
		 */
		EASE_IN_OUT_BOUNCE,

		/* guard, before registered alpha functions */
		LAST
	}

	/**
	 * Internal type for the easing functions.
	 *
	 * @param t elapsed time
	 * @param d total duration
	 * @return the interpolated value, between -1.0 and 2.0
	 */
	[CCode (has_target = false)]
	delegate double EasingFunc (double t, double d);
	
	struct AnimationModeMapping
	{
		AnimationMode mode;
		EasingFunc func;
		string name;
	}

	const AnimationModeMapping[] ANIMATION_MODES = {
		{ AnimationMode.CUSTOM,              null, "custom" },

		{ AnimationMode.LINEAR,              linear, "linear" },
		{ AnimationMode.EASE_IN_QUAD,        ease_in_quad, "easeInQuad" },
		{ AnimationMode.EASE_OUT_QUAD,       ease_out_quad, "easeOutQuad" },
		{ AnimationMode.EASE_IN_OUT_QUAD,    ease_in_out_quad, "easeInOutQuad" },
		{ AnimationMode.EASE_IN_CUBIC,       ease_in_cubic, "easeInCubic" },
		{ AnimationMode.EASE_OUT_CUBIC,      ease_out_cubic, "easeOutCubic" },
		{ AnimationMode.EASE_IN_OUT_CUBIC,   ease_in_out_cubic, "easeInOutCubic" },
		{ AnimationMode.EASE_IN_QUART,       ease_in_quart, "easeInQuart" },
		{ AnimationMode.EASE_OUT_QUART,      ease_out_quart, "easeOutQuart" },
		{ AnimationMode.EASE_IN_OUT_QUART,   ease_in_out_quart, "easeInOutQuart" },
		{ AnimationMode.EASE_IN_QUINT,       ease_in_quint, "easeInQuint" },
		{ AnimationMode.EASE_OUT_QUINT,      ease_out_quint, "easeOutQuint" },
		{ AnimationMode.EASE_IN_OUT_QUINT,   ease_in_out_quint, "easeInOutQuint" },
		{ AnimationMode.EASE_IN_SINE,        ease_in_sine, "easeInSine" },
		{ AnimationMode.EASE_OUT_SINE,       ease_out_sine, "easeOutSine" },
		{ AnimationMode.EASE_IN_OUT_SINE,    ease_in_out_sine, "easeInOutSine" },
		{ AnimationMode.EASE_IN_EXPO,        ease_in_expo, "easeInExpo" },
		{ AnimationMode.EASE_OUT_EXPO,       ease_out_expo, "easeOutExpo" },
		{ AnimationMode.EASE_IN_OUT_EXPO,    ease_in_out_expo, "easeInOutExpo" },
		{ AnimationMode.EASE_IN_CIRC,        ease_in_circ, "easeInCirc" },
		{ AnimationMode.EASE_OUT_CIRC,       ease_out_circ, "easeOutCirc" },
		{ AnimationMode.EASE_IN_OUT_CIRC,    ease_in_out_circ, "easeInOutCirc" },
		{ AnimationMode.EASE_IN_ELASTIC,     ease_in_elastic, "easeInElastic" },
		{ AnimationMode.EASE_OUT_ELASTIC,    ease_out_elastic, "easeOutElastic" },
		{ AnimationMode.EASE_IN_OUT_ELASTIC, ease_in_out_elastic, "easeInOutElastic" },
		{ AnimationMode.EASE_IN_BACK,        ease_in_back, "easeInBack" },
		{ AnimationMode.EASE_OUT_BACK,       ease_out_back, "easeOutBack" },
		{ AnimationMode.EASE_IN_OUT_BACK,    ease_in_out_back, "easeInOutBack" },
		{ AnimationMode.EASE_IN_BOUNCE,      ease_in_bounce, "easeInBounce" },
		{ AnimationMode.EASE_OUT_BOUNCE,     ease_out_bounce, "easeOutBounce" },
		{ AnimationMode.EASE_IN_OUT_BOUNCE,  ease_in_out_bounce, "easeInOutBounce" },

		{ AnimationMode.LAST,                null, "sentinel" }
	};

	EasingFunc easing_func_for_mode (AnimationMode mode)
	{
		AnimationModeMapping* animation = &(ANIMATION_MODES[mode]);
		
		assert (animation.mode == mode);
		assert (animation.func != null);
		
		return animation.func;
	}

	unowned string easing_name_for_mode (AnimationMode mode)
	{
		AnimationModeMapping* animation = &(ANIMATION_MODES[mode]);
		
		assert (animation.mode == mode);
		assert (animation.func != null);
		
		return animation.name;
	}

	/**
	 * Calculate an interpolated value for selected animation-mode, and given
	 * elapsed time and total duration.
	 *
	 * @param mode animation-mode to be used
	 * @param t elapsed time
	 * @param d total duration
	 * @return the interpolated value, between -1.0 and 2.0
	 */
	public double easing_for_mode (AnimationMode mode, double t, double d)
		requires (t >= 0.0 && d > 0.0)
		requires (t <= d)
		ensures (result >= -1.0 && result <= 2.0)
	{
		AnimationModeMapping* animation = &(ANIMATION_MODES[mode]);
		
		assert (animation.mode == mode);
		assert (animation.func != null);
		
		return animation.func (t, d);
	}
	
	double linear (double t, double d)
	{
		return t / d;
	}

	double ease_in_quad (double t, double d)
	{
		double p = t / d;

		return p * p;
	}

	double ease_out_quad (double t, double d)
	{
		double p = t / d;

		return -1.0 * p * (p - 2);
	}

	double ease_in_out_quad (double t, double d)
	{
		double p = t / (d / 2);

		if (p < 1)
			return 0.5 * p * p;

		p -= 1;

		return -0.5 * (p * (p - 2) - 1);
	}

	double ease_in_cubic (double t, double d)
	{
		double p = t / d;

		return p * p * p;
	}

	double ease_out_cubic (double t, double d)
	{
		double p = t / d - 1;

		return p * p * p + 1;
	}

	double ease_in_out_cubic (double t, double d)
	{
		double p = t / (d / 2);

		if (p < 1)
			return 0.5 * p * p * p;

		p -= 2;

		return 0.5 * (p * p * p + 2);
	}

	double ease_in_quart (double t, double d)
	{
		double p = t / d;

		return p * p * p * p;
	}

	double ease_out_quart (double t, double d)
	{
		double p = t / d - 1;

		return -1.0 * (p * p * p * p - 1);
	}

	double ease_in_out_quart (double t, double d)
	{
		double p = t / (d / 2);

		if (p < 1)
			return 0.5 * p * p * p * p;

		p -= 2;

		return -0.5 * (p * p * p * p - 2);
	}

	double ease_in_quint (double t, double d)
	 {
		double p = t / d;

		return p * p * p * p * p;
	}

	double ease_out_quint (double t, double d)
	{
		double p = t / d - 1;

		return p * p * p * p * p + 1;
	}

	double ease_in_out_quint (double t, double d)
	{
		double p = t / (d / 2);

		if (p < 1)
			return 0.5 * p * p * p * p * p;

		p -= 2;

		return 0.5 * (p * p * p * p * p + 2);
	}

	double ease_in_sine (double t, double d)
	{
		return -1.0 * Math.cos (t / d * Math.PI_2) + 1.0;
	}

	double ease_out_sine (double t, double d)
	{
		return Math.sin (t / d * Math.PI_2);
	}

	double ease_in_out_sine (double t, double d)
	{
		return -0.5 * (Math.cos (Math.PI * t / d) - 1);
	}

	double ease_in_expo (double t, double d)
	{
		return (t == 0) ? 0.0 : Math.pow (2, 10 * (t / d - 1));
	}

	double ease_out_expo (double t, double d)
	{
		return (t == d) ? 1.0 : -Math.pow (2, -10 * t / d) + 1;
	}

	double ease_in_out_expo (double t, double d)
	{
		double p;

		if (t == 0)
			return 0.0;

		if (t == d)
			return 1.0;

		p = t / (d / 2);

		if (p < 1)
			return 0.5 * Math.pow (2, 10 * (p - 1));

		p -= 1;

		return 0.5 * (-Math.pow (2, -10 * p) + 2);
	}

	double ease_in_circ (double t, double d)
	{
		double p = t / d;

		return -1.0 * (Math.sqrt (1 - p * p) - 1);
	}

	double ease_out_circ (double t, double d)
	{
		double p = t / d - 1;

		return Math.sqrt (1 - p * p);
	}

	double ease_in_out_circ (double t, double d)
	{
		double p = t / (d / 2);

		if (p < 1)
			return -0.5 * (Math.sqrt (1 - p * p) - 1);

		p -= 2;

		return 0.5 * (Math.sqrt (1 - p * p) + 1);
	}

	double ease_in_elastic (double t, double d)
	{
		double p = d * 0.3;
		double s = p / 4;
		double q = t / d;

		if (q == 1)
			return 1.0;

		q -= 1;

		return -(Math.pow (2, 10 * q) * Math.sin ((q * d - s) * (2 * Math.PI) / p));
	}

	double ease_out_elastic (double t, double d)
	{
		double p = d * 0.3;
		double s = p / 4;
		double q = t / d;

		if (q == 1)
			return 1.0;

		return Math.pow (2, -10 * q) * Math.sin ((q * d - s) * (2 * Math.PI) / p) + 1.0;
	}

	double ease_in_out_elastic (double t, double d)
	{
		double p = d * (0.3 * 1.5);
		double s = p / 4;
		double q = t / (d / 2);

		if (q == 2)
			return 1.0;

		if (q < 1) {
			q -= 1;

			return -0.5 * (Math.pow (2, 10 * q) * Math.sin ((q * d - s) * (2 * Math.PI) / p));
		} else {
			q -= 1;

			return Math.pow (2, -10 * q)
				 * Math.sin ((q * d - s) * (2 * Math.PI) / p)
				 * 0.5 + 1.0;
		}
	}

	double ease_in_back (double t, double d)
	{
		double p = t / d;

		return p * p * ((1.70158 + 1) * p - 1.70158);
	}

	double ease_out_back (double t, double d)
	{
		double p = t / d - 1;

		return p * p * ((1.70158 + 1) * p + 1.70158) + 1;
	}

	double ease_in_out_back (double t, double d)
	{
		double p = t / (d / 2);
		double s = 1.70158 * 1.525;

		if (p < 1)
			return 0.5 * (p * p * ((s + 1) * p - s));

		p -= 2;

		return 0.5 * (p * p * ((s + 1) * p + s) + 2);
	}

	static inline double ease_out_bounce_internal (double t, double d)
	{
		double p = t / d;

		if (p < (1 / 2.75)) {
			return 7.5625 * p * p;
		} else if (p < (2 / 2.75)) {
			p -= (1.5 / 2.75);

			return 7.5625 * p * p + 0.75;
		} else if (p < (2.5 / 2.75)) {
			p -= (2.25 / 2.75);

			return 7.5625 * p * p + 0.9375;
		} else {
			p -= (2.625 / 2.75);

			return 7.5625 * p * p + 0.984375;
		}
	}

	static inline double ease_in_bounce_internal (double t, double d)
	{
		return 1.0 - ease_out_bounce_internal (d - t, d);
	}

	double ease_in_bounce (double t, double d)
	{
		return ease_in_bounce_internal (t, d);
	}

	double ease_out_bounce (double t, double d)
	{
		return ease_out_bounce_internal (t, d);
	}

	double ease_in_out_bounce (double t, double d)
	{
		if (t < d / 2)
			return ease_in_bounce_internal (t * 2, d) * 0.5;
		else
			return ease_out_bounce_internal (t * 2 - d, d) * 0.5 + 1.0 * 0.5;
	}
}
