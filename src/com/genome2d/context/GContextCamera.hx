package com.genome2d.context;

class GContextCamera {
    public var rotation:Float = 0;
    public var scaleX:Float = 1;
    public var scaleY:Float = 1;
    public var x:Float = 0;
    public var y:Float = 0;

    /**
	 * 	Camera mask used against node camera group a node is rendered through this camera if camera.mask and nodecameraGroup != 0
	 */
    public var mask:Int = 0xFFFFFF;

    /**
	 * 	Viewport x offset, this value should be always within 0 and 1 its based on context main viewport
	 */
    public var normalizedViewX:Float = 0;
    /**
	 * 	Viewport y offset, this value should be always within 0 and 1 it based on context main viewport
	 */
    public var normalizedViewY:Float = 0;
    /**
	 * 	Viewport width, this value should be always within 0 and 1 its based on context main viewport
	 */
    public var normalizedViewWidth:Float = 1;
    /**
	 * 	Viewport height, this value should be always within 0 and 1 its  based on context main viewport
	 */
    public var normalizedViewHeight:Float = 1;

    public function new() {
    }
}
