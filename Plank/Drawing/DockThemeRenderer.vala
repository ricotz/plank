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

namespace Plank.Drawing
{
	public class DockThemeRenderer : ThemeRenderer
	{
		const double MIN_INDICATOR_SIZE = 0.0;
		const double MAX_INDICATOR_SIZE = 10.0;
		
		public double HorizPadding { get; set; default = 0.0; }
		
		public double TopPadding { get; set; default = -11.0; }
		
		public double BottomPadding { get; set; default = 3.0; }
		
		public double ItemPadding { get; set; default = 2.0; }
		
		public double IndicatorSize { get; set; default = 5.0; }
		
		public int UrgentBounceHeight { get; set; default = 80; }
		
		public int LaunchBounceHeight { get; set; default = 30; }
		
		public int GlowSize { get; set; default = 30; }
		
		public int ClickTime { get; set; default = 600; }
		
		public int BounceTime { get; set; default = 600; }
		
		public int ActiveTime { get; set; default = 300; }
		
		protected override void verify (string prop)
		{
			base.verify (prop);
			
			switch (prop) {
			case "ItemPadding":
				if (ItemPadding < 0)
					ItemPadding = 0;
				break;
			
			case "IndicatorSize":
				if (IndicatorSize < MIN_INDICATOR_SIZE)
					IndicatorSize = MIN_INDICATOR_SIZE;
				else if (IndicatorSize > MAX_INDICATOR_SIZE)
					IndicatorSize = MAX_INDICATOR_SIZE;
				break;
			
			case "UrgentBounceHeight":
				if (UrgentBounceHeight < 0)
					UrgentBounceHeight = 0;
				break;
			
			case "LaunchBounceHeight":
				if (LaunchBounceHeight < 0)
					LaunchBounceHeight = 0;
				break;
			
			case "GlowSize":
				if (GlowSize < 0)
					GlowSize = 0;
				break;
			
			case "ClickTime":
				if (ClickTime < 0)
					ClickTime = 0;
				break;
			
			case "BounceTime":
				if (BounceTime < 0)
					BounceTime = 0;
				break;
			
			case "ActiveTime":
				if (ActiveTime < 0)
					ActiveTime = 0;
				break;
			}
		}
	}
}
