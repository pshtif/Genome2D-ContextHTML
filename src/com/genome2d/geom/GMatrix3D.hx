/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.geom;

import js.html.Float32Array;

class GMatrix3D {
	private static var helperMatrix:GMatrix3D = new GMatrix3D();

	public var rawData:Float32Array;

	public var determinant (get, never):Float;
	public function get_determinant ():Float {

		return 1 * ((rawData[0] * rawData[5] - rawData[4] * rawData[1]) * (rawData[10] * rawData[15] - rawData[14] * rawData[11])
		- (rawData[0] * rawData[9] - rawData[8] * rawData[1]) * (rawData[6] * rawData[15] - rawData[14] * rawData[7])
		+ (rawData[0] * rawData[13] - rawData[12] * rawData[1]) * (rawData[6] * rawData[11] - rawData[10] * rawData[7])
		+ (rawData[4] * rawData[9] - rawData[8] * rawData[5]) * (rawData[2] * rawData[15] - rawData[14] * rawData[3])
		- (rawData[4] * rawData[13] - rawData[12] * rawData[5]) * (rawData[2] * rawData[11] - rawData[10] * rawData[3])
		+ (rawData[8] * rawData[13] - rawData[12] * rawData[9]) * (rawData[2] * rawData[7] - rawData[6] * rawData[3]));

	}

	public var position(get, set):GVector3D;
	public function get_position():GVector3D {
		return new GVector3D(rawData[12], rawData[13], rawData[14]);
	}
	
	public function set_position(p_value:GVector3D):GVector3D {
		rawData[12] = p_value.x;
		rawData[13] = p_value.y;
		rawData[14] = p_value.z;
		return p_value;
	}
	
    public function new() {
		rawData = new Float32Array([1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0]);
    }

    public function append(p_lhs:GMatrix3D):Void {	
		var m111:Float = this.rawData[0], m121:Float = this.rawData[4], m131:Float = this.rawData[8], m141:Float = this.rawData[12],
			m112:Float = this.rawData[1], m122:Float = this.rawData[5], m132:Float = this.rawData[9], m142:Float = this.rawData[13],
			m113:Float = this.rawData[2], m123:Float = this.rawData[6], m133:Float = this.rawData[10], m143:Float = this.rawData[14],
			m114:Float = this.rawData[3], m124:Float = this.rawData[7], m134:Float = this.rawData[11], m144:Float = this.rawData[15],
			m211:Float = p_lhs.rawData[0], m221:Float = p_lhs.rawData[4], m231:Float = p_lhs.rawData[8], m241:Float = p_lhs.rawData[12],
			m212:Float = p_lhs.rawData[1], m222:Float = p_lhs.rawData[5], m232:Float = p_lhs.rawData[9], m242:Float = p_lhs.rawData[13],
			m213:Float = p_lhs.rawData[2], m223:Float = p_lhs.rawData[6], m233:Float = p_lhs.rawData[10], m243:Float = p_lhs.rawData[14],
			m214:Float = p_lhs.rawData[3], m224:Float = p_lhs.rawData[7], m234:Float = p_lhs.rawData[11], m244:Float = p_lhs.rawData[15];
		
		rawData[0] = m111 * m211 + m112 * m221 + m113 * m231 + m114 * m241;
		rawData[1] = m111 * m212 + m112 * m222 + m113 * m232 + m114 * m242;
		rawData[2] = m111 * m213 + m112 * m223 + m113 * m233 + m114 * m243;
		rawData[3] = m111 * m214 + m112 * m224 + m113 * m234 + m114 * m244;
		
		rawData[4] = m121 * m211 + m122 * m221 + m123 * m231 + m124 * m241;
		rawData[5] = m121 * m212 + m122 * m222 + m123 * m232 + m124 * m242;
		rawData[6] = m121 * m213 + m122 * m223 + m123 * m233 + m124 * m243;
		rawData[7] = m121 * m214 + m122 * m224 + m123 * m234 + m124 * m244;
		
		rawData[8] = m131 * m211 + m132 * m221 + m133 * m231 + m134 * m241;
		rawData[9] = m131 * m212 + m132 * m222 + m133 * m232 + m134 * m242;
		rawData[10] = m131 * m213 + m132 * m223 + m133 * m233 + m134 * m243;
		rawData[11] = m131 * m214 + m132 * m224 + m133 * m234 + m134 * m244;
		
		rawData[12] = m141 * m211 + m142 * m221 + m143 * m231 + m144 * m241;
		rawData[13] = m141 * m212 + m142 * m222 + m143 * m232 + m144 * m242;
		rawData[14] = m141 * m213 + m142 * m223 + m143 * m233 + m144 * m243;
		rawData[15] = m141 * m214 + m142 * m224 + m143 * m234 + m144 * m244;		
	}
	
	public function appendRotation(p_degrees:Float, p_axis:GVector3D, p_pivotPoint:GVector3D):Void {	
		var m = g2d_getAxisRotation(p_axis.x, p_axis.y, p_axis.z, p_degrees);
		
		if (p_pivotPoint != null) {
			
			var p = p_pivotPoint;
			m.appendTranslation (p.x, p.y, p.z);
			
		}
		
		this.append (m);	
	}
	
	public function appendScale (p_xScale:Float, p_yScale:Float, p_zScale:Float):Void {
		helperMatrix.rawData[0] = p_xScale;
		helperMatrix.rawData[1] = 0.0;
		helperMatrix.rawData[2] = 0.0;
		helperMatrix.rawData[3] = 0.0;

		helperMatrix.rawData[4] = 0.0;
		helperMatrix.rawData[5] = p_yScale;
		helperMatrix.rawData[6] = 0.0;
		helperMatrix.rawData[7] = 0.0;

		helperMatrix.rawData[8] = 0.0;
		helperMatrix.rawData[9] = 0.0;
		helperMatrix.rawData[10] = p_zScale;
		helperMatrix.rawData[11] = 0.0;

		helperMatrix.rawData[12] = 0.0;
		helperMatrix.rawData[13] = 0.0;
		helperMatrix.rawData[14] = 0.0;
		helperMatrix.rawData[15] = 1.0;
		
		this.append (helperMatrix);
		
	}
	
	
	public function appendTranslation (p_x:Float, p_y:Float, p_z:Float):Void {
		rawData[12] += p_x;
		rawData[13] += p_y;
		rawData[14] += p_z;
	}
	
	public function prepend(p_rhs:GMatrix3D):Void {
		var m111:Float = p_rhs.rawData[0], m121:Float = p_rhs.rawData[4], m131:Float = p_rhs.rawData[8], m141:Float = p_rhs.rawData[12],
			m112:Float = p_rhs.rawData[1], m122:Float = p_rhs.rawData[5], m132:Float = p_rhs.rawData[9], m142:Float = p_rhs.rawData[13],
			m113:Float = p_rhs.rawData[2], m123:Float = p_rhs.rawData[6], m133:Float = p_rhs.rawData[10], m143:Float = p_rhs.rawData[14],
			m114:Float = p_rhs.rawData[3], m124:Float = p_rhs.rawData[7], m134:Float = p_rhs.rawData[11], m144:Float = p_rhs.rawData[15],
			m211:Float = this.rawData[0], m221:Float = this.rawData[4], m231:Float = this.rawData[8], m241:Float = this.rawData[12],
			m212:Float = this.rawData[1], m222:Float = this.rawData[5], m232:Float = this.rawData[9], m242:Float = this.rawData[13],
			m213:Float = this.rawData[2], m223:Float = this.rawData[6], m233:Float = this.rawData[10], m243:Float = this.rawData[14],
			m214:Float = this.rawData[3], m224:Float = this.rawData[7], m234:Float = this.rawData[11], m244:Float = this.rawData[15];
		
		rawData[0] = m111 * m211 + m112 * m221 + m113 * m231 + m114 * m241;
		rawData[1] = m111 * m212 + m112 * m222 + m113 * m232 + m114 * m242;
		rawData[2] = m111 * m213 + m112 * m223 + m113 * m233 + m114 * m243;
		rawData[3] = m111 * m214 + m112 * m224 + m113 * m234 + m114 * m244;
		
		rawData[4] = m121 * m211 + m122 * m221 + m123 * m231 + m124 * m241;
		rawData[5] = m121 * m212 + m122 * m222 + m123 * m232 + m124 * m242;
		rawData[6] = m121 * m213 + m122 * m223 + m123 * m233 + m124 * m243;
		rawData[7] = m121 * m214 + m122 * m224 + m123 * m234 + m124 * m244;
		
		rawData[8] = m131 * m211 + m132 * m221 + m133 * m231 + m134 * m241;
		rawData[9] = m131 * m212 + m132 * m222 + m133 * m232 + m134 * m242;
		rawData[10] = m131 * m213 + m132 * m223 + m133 * m233 + m134 * m243;
		rawData[11] = m131 * m214 + m132 * m224 + m133 * m234 + m134 * m244;
		
		rawData[12] = m141 * m211 + m142 * m221 + m143 * m231 + m144 * m241;
		rawData[13] = m141 * m212 + m142 * m222 + m143 * m232 + m144 * m242;
		rawData[14] = m141 * m213 + m142 * m223 + m143 * m233 + m144 * m243;
		rawData[15] = m141 * m214 + m142 * m224 + m143 * m234 + m144 * m244;
	}
	
	public function prependRotation (p_degrees:Float, p_axis:GVector3D, p_pivotPoint:GVector3D):Void {
		var m = g2d_getAxisRotation (p_axis.x, p_axis.y, p_axis.z, p_degrees);
		
		if (p_pivotPoint != null) {
			var p = p_pivotPoint;
			m.appendTranslation (p.x, p.y, p.z);
		}
		
		this.prepend(m);
	}
	
	
	public function prependScale(p_xScale:Float, p_yScale:Float, p_zScale:Float):Void {
		helperMatrix.rawData[0] = p_xScale;
		helperMatrix.rawData[1] = 0.0;
		helperMatrix.rawData[2] = 0.0;
		helperMatrix.rawData[3] = 0.0;

		helperMatrix.rawData[4] = 0.0;
		helperMatrix.rawData[5] = p_yScale;
		helperMatrix.rawData[6] = 0.0;
		helperMatrix.rawData[7] = 0.0;

		helperMatrix.rawData[8] = 0.0;
		helperMatrix.rawData[9] = 0.0;
		helperMatrix.rawData[10] = p_zScale;
		helperMatrix.rawData[11] = 0.0;

		helperMatrix.rawData[12] = 0.0;
		helperMatrix.rawData[13] = 0.0;
		helperMatrix.rawData[14] = 0.0;
		helperMatrix.rawData[15] = 1.0;
		
		this.prepend (helperMatrix);
	}
	
	
	public function prependTranslation (p_x:Float, p_y:Float, p_z:Float):Void {
		helperMatrix.rawData[0] = 1.0;
		helperMatrix.rawData[1] = 0.0;
		helperMatrix.rawData[2] = 0.0;
		helperMatrix.rawData[3] = 0.0;

		helperMatrix.rawData[4] = 0.0;
		helperMatrix.rawData[5] = 1.0;
		helperMatrix.rawData[6] = 0.0;
		helperMatrix.rawData[7] = 0.0;

		helperMatrix.rawData[8] = 0.0;
		helperMatrix.rawData[9] = 0.0;
		helperMatrix.rawData[10] = 1.0;
		helperMatrix.rawData[11] = 0.0;

		helperMatrix.rawData[12] = p_x;
		helperMatrix.rawData[13] = p_y;
		helperMatrix.rawData[14] = p_z;
		helperMatrix.rawData[15] = 1.0;
		
		this.prepend (helperMatrix);
	}
	
	public function clone():GMatrix3D {
		var clone:GMatrix3D = new GMatrix3D();
		clone.rawData[0] = rawData[0];
		clone.rawData[1] = rawData[1];
		clone.rawData[2] = rawData[2];
		clone.rawData[3] = rawData[3];
		
		clone.rawData[4] = rawData[4];
		clone.rawData[5] = rawData[5];
		clone.rawData[6] = rawData[6];
		clone.rawData[7] = rawData[7];
		
		clone.rawData[8] = rawData[8];
		clone.rawData[9] = rawData[9];
		clone.rawData[10] = rawData[10];
		clone.rawData[11] = rawData[11];
		
		clone.rawData[12] = rawData[12];
		clone.rawData[13] = rawData[13];
		clone.rawData[14] = rawData[14];
		clone.rawData[15] = rawData[15];
		
		return clone;
	}
	
	public function transpose ():Void {
		var newData:Float32Array = new Float32Array(16);
		newData[0] = rawData[0];
		newData[1] = rawData[4];
		newData[2] = rawData[8];
		newData[3] = rawData[12];
		
		newData[4] = rawData[1];
		newData[5] = rawData[5];
		newData[6] = rawData[9];
		newData[7] = rawData[13];
		
		newData[8] = rawData[2];
		newData[9] = rawData[6];
		newData[10] = rawData[10];
		newData[11] = rawData[14];
		
		newData[12] = rawData[3];
		newData[13] = rawData[7];
		newData[14] = rawData[11];
		newData[15] = rawData[15];
		
		rawData = newData;
	}

	public function invert():Bool {
		var d = determinant;
		var invertable = Math.abs (d) > 0.00000000001;

		if (invertable) {

			d = 1 / d;

			var m11:Float = rawData[0]; var m21:Float = rawData[4]; var m31:Float = rawData[8]; var m41:Float = rawData[12];
			var m12:Float = rawData[1]; var m22:Float = rawData[5]; var m32:Float = rawData[9]; var m42:Float = rawData[13];
			var m13:Float = rawData[2]; var m23:Float = rawData[6]; var m33:Float = rawData[10]; var m43:Float = rawData[14];
			var m14:Float = rawData[3]; var m24:Float = rawData[7]; var m34:Float = rawData[11]; var m44:Float = rawData[15];

			rawData[0] = d * (m22 * (m33 * m44 - m43 * m34) - m32 * (m23 * m44 - m43 * m24) + m42 * (m23 * m34 - m33 * m24));
			rawData[1] = -d * (m12 * (m33 * m44 - m43 * m34) - m32 * (m13 * m44 - m43 * m14) + m42 * (m13 * m34 - m33 * m14));
			rawData[2] = d * (m12 * (m23 * m44 - m43 * m24) - m22 * (m13 * m44 - m43 * m14) + m42 * (m13 * m24 - m23 * m14));
			rawData[3] = -d * (m12 * (m23 * m34 - m33 * m24) - m22 * (m13 * m34 - m33 * m14) + m32 * (m13 * m24 - m23 * m14));
			rawData[4] = -d * (m21 * (m33 * m44 - m43 * m34) - m31 * (m23 * m44 - m43 * m24) + m41 * (m23 * m34 - m33 * m24));
			rawData[5] = d * (m11 * (m33 * m44 - m43 * m34) - m31 * (m13 * m44 - m43 * m14) + m41 * (m13 * m34 - m33 * m14));
			rawData[6] = -d * (m11 * (m23 * m44 - m43 * m24) - m21 * (m13 * m44 - m43 * m14) + m41 * (m13 * m24 - m23 * m14));
			rawData[7] = d * (m11 * (m23 * m34 - m33 * m24) - m21 * (m13 * m34 - m33 * m14) + m31 * (m13 * m24 - m23 * m14));
			rawData[8] = d * (m21 * (m32 * m44 - m42 * m34) - m31 * (m22 * m44 - m42 * m24) + m41 * (m22 * m34 - m32 * m24));
			rawData[9] = -d * (m11 * (m32 * m44 - m42 * m34) - m31 * (m12 * m44 - m42 * m14) + m41 * (m12 * m34 - m32 * m14));
			rawData[10] = d * (m11 * (m22 * m44 - m42 * m24) - m21 * (m12 * m44 - m42 * m14) + m41 * (m12 * m24 - m22 * m14));
			rawData[11] = -d * (m11 * (m22 * m34 - m32 * m24) - m21 * (m12 * m34 - m32 * m14) + m31 * (m12 * m24 - m22 * m14));
			rawData[12] = -d * (m21 * (m32 * m43 - m42 * m33) - m31 * (m22 * m43 - m42 * m23) + m41 * (m22 * m33 - m32 * m23));
			rawData[13] = d * (m11 * (m32 * m43 - m42 * m33) - m31 * (m12 * m43 - m42 * m13) + m41 * (m12 * m33 - m32 * m13));
			rawData[14] = -d * (m11 * (m22 * m43 - m42 * m23) - m21 * (m12 * m43 - m42 * m13) + m41 * (m12 * m23 - m22 * m13));
			rawData[15] = d * (m11 * (m22 * m33 - m32 * m23) - m21 * (m12 * m33 - m32 * m13) + m31 * (m12 * m23 - m22 * m13));

		}

		return invertable;
	}
	
	public function identity ():Void {		
		rawData = new Float32Array([1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0]);
	}
	
	static private function g2d_getAxisRotation (p_x:Float, p_y:Float, p_z:Float, p_degrees:Float):GMatrix3D {
		var m = new GMatrix3D();
		
		var a1 = new GVector3D(p_x, p_y, p_z);
		var rad = -p_degrees * (Math.PI / 180);
		var c = Math.cos (rad);
		var s = Math.sin (rad);
		var t = 1.0 - c;
		
		m.rawData[0] = c + a1.x * a1.x * t;
		m.rawData[5] = c + a1.y * a1.y * t;
		m.rawData[10] = c + a1.z * a1.z * t;
		
		var tmp1 = a1.x * a1.y * t;
		var tmp2 = a1.z * s;
		m.rawData[4] = tmp1 + tmp2;
		m.rawData[1] = tmp1 - tmp2;
		tmp1 = a1.x * a1.z * t;
		tmp2 = a1.y * s;
		m.rawData[8] = tmp1 - tmp2;
		m.rawData[2] = tmp1 + tmp2;
		tmp1 = a1.y * a1.z * t;
		tmp2 = a1.x*s;
		m.rawData[9] = tmp1 + tmp2;
		m.rawData[6] = tmp1 - tmp2;
		
		return m;
	}

	public function transformVector(p_vector:GVector3D):GVector3D {
		var x = p_vector.x;
		var y = p_vector.y;
		var z = p_vector.z;

		return new GVector3D((x * rawData[0] + y * rawData[4] + z * rawData[8] + rawData[12]),
							 (x * rawData[1] + y * rawData[5] + z * rawData[9] + rawData[13]),
							 (x * rawData[2] + y * rawData[6] + z * rawData[10] + rawData[14]),
							 (x * rawData[3] + y * rawData[7] + z * rawData[11] + rawData[15]));
	}
}