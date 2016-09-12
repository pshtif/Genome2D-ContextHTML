/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.geom;

class GRectangle {
    public var bottom (get, set):Float;
    private function get_bottom() { return y + height; }
    private function set_bottom(p_value:Float) { height = p_value - y; return p_value; }

    public var left (get, set):Float;
    private function get_left() { return x; }
    private function set_left(p_value:Float) { width -= p_value - x; x = p_value; return p_value; }

    public var right (get, set):Float;
    private function get_right() { return x + width; }
    private function set_right(p_value:Float) { width = p_value - x; return p_value; }

    public var top (get, set):Float;
    private function get_top() { return y; }
    private function set_top(p_value:Float) { height -= p_value - y; y = p_value; return p_value; }

    public var x:Float;
    public var y:Float;

    public var width:Float;
    public var height:Float;

    public function new(p_x:Float=0, p_y:Float=0, p_width:Float=0, p_height:Float=0) {
        x = p_x;
        y = p_y;
        width = p_width;
        height = p_height;
    }

    public function setTo(p_x:Float, p_y:Float, p_width:Float, p_height:Float):Void {
        x = p_x;
        y = p_y;
        width = p_width;
        height = p_height;
    }

    public function clone():GRectangle {
        return new GRectangle(x,y,width,height);
    }

    public function intersection(p_rect:GRectangle):GRectangle {
        var result:GRectangle;

        var x0 = x < p_rect.x ? p_rect.x : x;
        var x1 = right > p_rect.right ? p_rect.right : right;
        if (x1 <= x0) {
            result = new GRectangle ();
        } else {
            var y0 = y < p_rect.y ? p_rect.y : y;
            var y1 = bottom > p_rect.bottom ? p_rect.bottom : bottom;
            if (y1 <= y0) {
                result = new GRectangle ();
            } else {
                result = new GRectangle (x0, y0, x1 - x0, y1 - y0);
            }
        }

        return result;
    }
	
	public function intersects(p_rect:GRectangle):GRectangle {
        var result:Bool = false;

        var x0 = x < p_rect.x ? p_rect.x : x;
        var x1 = right > p_rect.right ? p_rect.right : right;
        if (x1 > x0) {
            var y0 = y < p_rect.y ? p_rect.y : y;
            var y1 = bottom > p_rect.bottom ? p_rect.bottom : bottom;
            if (y1 > y0) {
                result = true;
            }
        }

        return result;
    }

    public function contains (p_x:Float, p_y:Float):Bool {
        return p_x >= x && p_y >= y && p_x < right && p_y < bottom;
    }
}
