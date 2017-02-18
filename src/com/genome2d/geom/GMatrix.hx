/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.geom;

class GMatrix {
    public var a:Float;
    public var b:Float;
    public var c:Float;
    public var d:Float;
    public var tx:Float;
    public var ty:Float;

    public function new(p_a:Float = 1, p_b:Float = 0, p_c:Float = 0, p_d:Float = 1, p_tx:Float = 0, p_ty:Float = 0) {
        a = p_a;
        b = p_b;
        c = p_c;
        d = p_d;
        tx = p_tx;
        ty = p_ty;
    }

    public function copyFrom(p_from:GMatrix):Void {
        a = p_from.a;
        b = p_from.b;
        c = p_from.c;
        d = p_from.d;
        tx = p_from.tx;
        ty = p_from.ty;
    }

    public function setTo(p_a:Float, p_b:Float, p_c:Float, p_d:Float, p_tx:Float, p_ty:Float):Void {
        a = p_a;
        b = p_b;
        c = p_c;
        d = p_d;
        tx = p_tx;
        ty = p_ty;
    }

    public function identity():Void {
        a = 1;
        b = 0;
        c = 0;
        d = 1;
        tx = 0;
        ty = 0;
    }

    public function concat(p_matrix:GMatrix):Void {
        var a1:Float = a * p_matrix.a + b * p_matrix.c;
        b = a * p_matrix.b + b * p_matrix.d;
        a = a1;

        var c1:Float = c * p_matrix.a + d * p_matrix.c;
        d = c * p_matrix.b + d * p_matrix.d;

        c = c1;

        var tx1:Float = tx * p_matrix.a + ty * p_matrix.c + p_matrix.tx;
        ty = tx * p_matrix.b + ty * p_matrix.d + p_matrix.ty;
        tx = tx1;
    }

    public function invert():GMatrix {
        var n:Float = a * d - b * c;

        if (n == 0) {
            a = b = c = d = 0;
            tx = -tx;
            ty = -ty;
        } else {
            n = 1/n;
            var a1:Float = d * n;
            d = a * n;
            a = a1;
            b *= -n;
            c *= -n;

            var tx1:Float = - a * tx - c * ty;
            ty = - b * tx - d * ty;
            tx = tx1;
        }

        return this;
    }

    public function scale(p_scaleX:Float, p_scaleY:Float):Void {
        a *= p_scaleX;
        b *= p_scaleY;
        c *= p_scaleX;
        d *= p_scaleY;
        tx *= p_scaleX;
        ty *= p_scaleY;
    }

    public function rotate (p_angle:Float):Void {
        var cos:Float = Math.cos(p_angle);
        var sin:Float = Math.sin(p_angle);

        var a1 = a * cos - b * sin;
        b = a * sin + b * cos;
        a = a1;

        var c1 = c * cos - d * sin;
        d = c * sin + d * cos;
        c = c1;

        var tx1 = tx * cos - ty * sin;
        ty = tx * sin + ty * cos;
        tx = tx1;
    }

    public function translate(p_x:Float, p_y:Float):Void {
        tx += p_x;
        ty += p_y;
    }
}