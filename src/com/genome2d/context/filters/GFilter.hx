/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.context.filters;

/**

**/
class GFilter {
    public var g2d_id:String;
    public var overrideFragmentShader:Bool = false;
    public var fragmentCode:String = "";

    private var g2d_fragmentConstants:Array<Float>;

    private function new() {
        g2d_id = Std.string(Type.getClass(this));
        //g2d_fragmentConstants = new Vector<Float>();
    }
/*
    public function bind(p_context:Context3D, p_texture:GTexture):Void {
        p_context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, g2d_fragmentConstants, Std.int(g2d_fragmentConstants.length/4));
    }

    public function clear(p_context:Context3D):Void {}
/**/
}
