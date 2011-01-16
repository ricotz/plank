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

using Cairo;

namespace Plank
{
	public class PlankSurface : GLib.Object
	{
		Surface surface;
		Context context;

		public Surface Internal {
			get {
				if (surface == null)
					surface = new ImageSurface (Format.ARGB32, Width, Height);
				return surface;
			}
			private set { surface = value; }
		}
		
		bool HasInternal {
			get { return surface != null; }
		}
		
		public int Width { get; private set; }
		
		public int Height { get; private set; }
		
		public Cairo.Context Context {
			get {
				if (context == null)
					context = new Cairo.Context (Internal);
				return context;
			}
		}
		
		public PlankSurface (int width, int height)
		{
			Width = width;
			Height = height;
		}
		
		public PlankSurface.with_surface (int width, int height, Surface model)
		{
			this (width, height);
			if (model != null)
				Internal = new Surface.similar (model, Content.COLOR_ALPHA, Width, Height);
		}

		public PlankSurface.with_plank_surface (int width, int height, PlankSurface model)
		{
			this (width, height);
			if (model != null)
				Internal = new Surface.similar (model.Internal, Content.COLOR_ALPHA, Width, Height);
		}
		
		public PlankSurface.with_image_surface (ImageSurface image)
		{
			this (image.get_width (), image.get_height ());
			Internal = image;
		}
		
		public void Clear ()
		{
			Context.save ();
			
			context.set_source_rgba (0, 0, 0, 0);
			context.set_operator (Operator.SOURCE);
			context.paint ();
			
			context.restore ();
		}
	}
}
