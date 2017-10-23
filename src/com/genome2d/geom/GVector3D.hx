package com.genome2d.geom;

class GVector3D {
	static public var X_AXIS(get, null):GVector3D;
	inline static private function get_X_AXIS ():GVector3D {
		return new GVector3D (-1, 0, 0);
	}
	
	static public var Y_AXIS (get, null):GVector3D;	
	inline static private function get_Y_AXIS ():GVector3D {
		return new GVector3D (0, 1, 0);
	}
	
	static public var Z_AXIS (get, null):GVector3D;	
	inline static private function get_Z_AXIS ():GVector3D {
		return new GVector3D (0, 0, 1);
	}
	
    public var x:Float;
    public var y:Float;
    public var z:Float;
	public var w:Float;

    public function new(p_x:Float = 0, p_y:Float = 0, p_z:Float = 0, p_w:Float = 0) {
        x = p_x;
        y = p_y;
        z = p_z;
		w = p_w;
    }

	public function add(p_vector:GVector3D):GVector3D {

		return new GVector3D(x + p_vector.x,
		y + p_vector.y,
		z + p_vector.z);
	}

	public function subtract(p_vector:GVector3D):GVector3D {

		return new GVector3D(x - p_vector.x,
		y - p_vector.y,
		z - p_vector.z);
	}

	public function scaleBy(p_s:Float) {

		x = x * p_s;
		y = y * p_s;
		z = z * p_s;
	}

	public function normalize()
	{
		var nf:Float = 1 / Math.sqrt(x  x + y  y + z * z);
		x = x * nf;
		y = y * nf;
		z = z * nf;
	}
}
