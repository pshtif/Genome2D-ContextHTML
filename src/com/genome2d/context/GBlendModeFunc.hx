/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.context;

import js.html.webgl.RenderingContext;

/**

**/
class GBlendModeFunc
{
	private static var blendFactors:Array<Map<GBlendMode,Array<Int>>> = [
		[
			GBlendMode.NONE => [RenderingContext.ONE, RenderingContext.ZERO],
			GBlendMode.NORMAL => [RenderingContext.SRC_ALPHA, RenderingContext.ONE_MINUS_SRC_ALPHA],
			GBlendMode.ADD => [RenderingContext.SRC_ALPHA, RenderingContext.BLEND_DST_ALPHA],
			GBlendMode.MULTIPLY => [RenderingContext.BLEND_DST_RGB, RenderingContext.ONE_MINUS_SRC_ALPHA],
			GBlendMode.SCREEN => [RenderingContext.SRC_ALPHA, RenderingContext.ONE],
			GBlendMode.ERASE => [RenderingContext.ZERO, RenderingContext.ONE_MINUS_SRC_ALPHA],
		],
		[
			GBlendMode.NONE => [RenderingContext.ONE, RenderingContext.ZERO],
			GBlendMode.NORMAL => [RenderingContext.ONE, RenderingContext.ONE_MINUS_SRC_ALPHA],
			GBlendMode.ADD => [RenderingContext.ONE, RenderingContext.ONE],
			GBlendMode.MULTIPLY => [RenderingContext.BLEND_DST_RGB, RenderingContext.ONE_MINUS_SRC_ALPHA],
			GBlendMode.SCREEN => [RenderingContext.ONE, RenderingContext.ONE_MINUS_SRC_COLOR],
			GBlendMode.ERASE => [RenderingContext.ZERO, RenderingContext.ONE_MINUS_SRC_ALPHA],
		]
	];
	
	inline static public var NONE:Int = 0;
	inline static public var NORMAL:Int = 1;
	inline static public var ADD:Int = 2;
	inline static public var MULTIPLY:Int = 3;
	inline static public var SCREEN:Int = 4;
	inline static public var ERASE:Int = 5;

	/*
	static public function addBlendMode(p_normalFactors:Array<Int>, p_premultipliedFactors:Array<Int>):Int {
		blendFactors[0].push(p_normalFactors);
		blendFactors[1].push(p_premultipliedFactors);
		
		return blendFactors[0].length;
	}
	/**/
	
	static public function setBlendMode(p_context:RenderingContext, p_mode:GBlendMode, p_premultiplied:Bool):Void {
		var p:Int = (p_premultiplied) ? 1 : 0;
        p_context.blendFunc(blendFactors[p][p_mode][0], blendFactors[p][p_mode][1]);
	}
}