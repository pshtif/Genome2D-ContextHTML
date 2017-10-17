/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.context.filters;

import js.html.Float32Array;
import com.genome2d.textures.GTexture;

class GFilter {
    public var id:String;
    public var overrideFragmentShader:Bool = true; // Always true for JS as it doesn't support shader injecting jet
    public var fragmentCode:String = "";
    static private var g2d_count:Int = 0;

    private var g2d_fragmentConstants:Array<Float>;

    private function new() {
        id = untyped (g2d_count++)+"";
    }

    public function bind(p_context:IGContext, p_renderer:IGRenderer, p_defaultTexture:GTexture):Void {
        //if (fragmentConstants != null && fragmentConstants.length>0) p_context.getNativeContext().setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, fragmentConstants, untyped __int__(fragmentConstants.length/4));
    }

    /**
        Called when filter is finished rendering
    **/
    public function clear(p_context:IGContext):Void {}
}
