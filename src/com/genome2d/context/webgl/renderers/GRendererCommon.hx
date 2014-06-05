package com.genome2d.context.webgl.renderers;

/**
 * ...
 * @author 
 */
class GRendererCommon
{
    static public var DEFAULT_CONSTANTS:Array<Float>;
	
	static public var NORMALIZED_VERTICES:Array<Float>;
	
	static public var NORMALIZED_UVS:Array<Float>;

    static public function init():Void {
        DEFAULT_CONSTANTS = [1, 0, 0, .5];
        NORMALIZED_VERTICES = [-.5, .5,
                               -.5,-.5,
                                .5,-.5,
                                .5, .5
                             ];
        NORMALIZED_UVS = [ .0, 1.0,
                          .0,  .0,
                         1.0,  .0,
                         1.0, 1.0
                        ];
    }
}