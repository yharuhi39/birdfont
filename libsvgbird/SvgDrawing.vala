/*
	Copyright (C) 2016 Johan Mattsson

	This library is free software; you can redistribute it and/or modify 
	it under the terms of the GNU Lesser General Public License as 
	published by the Free Software Foundation; either version 3 of the 
	License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful, but 
	WITHOUT ANY WARRANTY; without even the implied warranty of 
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
	Lesser General Public License for more details.
*/


using B;
using Cairo;
using Math;

namespace SvgBird {

public class SvgDrawing : Object {
	public Layer root_layer = new Layer ();
	public Defs defs = new Defs ();

	public double x = 0;
	public double y = 0;
	
	public double width {
		get {			
			return svg_width;
		}
		
		set {
			svg_width = value;
		}
	}

	public double height {
		get {			
			return svg_height;
		}
		
		set {
			svg_height = value;
		}
	}
	
	public double svg_width = 0;
	public double svg_height = 0;

	public override double left {
		get {
			return x;
		}

		set {
		}
	}

	public override double right {
		get {
			return x + width;
		}
		
		set {
		}
	}

	public override double top {
		get {
			return y;
		}
		
		set {
		}
	}

	public override double bottom {
		get {
			return y + height;
		}
		
		set {
		}
	}

	public override void update_region_boundaries () {
	}
	
	public override bool is_over (double x, double y) {
		return (this.x <= x <= this.x + width) 
			&& (this.y <= y <= this.y + height);
	}

	public void draw (Context cr) {
		root_layer.draw (cr);
	}
		
	public override void draw_outline (Context cr) {
		root_layer.draw_outline (cr);
	}
	
	public override Object copy () {
		SvgDrawing drawing = new SvgDrawing ();
		SvgBird.Object.copy_attributes (this, drawing);
		drawing.root_layer = (Layer) root_layer.copy ();
		drawing.defs = defs.copy ();
		drawing.x = x;
		drawing.y = y;
		drawing.width = width;
		drawing.height = height;
		return drawing;
	}
	
	public override void move (double dx, double dy) {
		x += dx;
		y += dy;
	}
	
	public override void rotate (double theta, double xc, double yc) {
	}
	
	public override bool is_empty () {
		return false;
	}
	
	public override void resize (double ratio_x, double ratio_y) {
	}

	public override string to_string () {
		return @"SvgDrawing x: $x, y: $y, width: $width, height: $height";
	}
}

}