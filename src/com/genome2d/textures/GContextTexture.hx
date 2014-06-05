/*
* 	Genome2D - GPU 2D framework utilizing Molehill API
*
*	Copyright 2011 Peter Stefcek. All rights reserved.
*
*	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
*/
package com.genome2d.textures;

import com.genome2d.context.IContext;
import com.genome2d.context.IContext;
import com.genome2d.geom.GRectangle;
import com.genome2d.textures.GContextTexture;
import com.genome2d.context.webgl.GWebGLContext;
import js.html.Image;
import js.html.webgl.RenderingContext;
import js.html.webgl.Texture;
import com.genome2d.textures.GTextureType;
import com.genome2d.textures.GTextureSourceType;

/**
 * 	@private
 */
class GContextTexture
{
    static public var g2d_references:Map<String,GContextTexture>;
    static public function getContextTextureById(p_id:String):GContextTexture {
        return g2d_references.get(p_id);
    }

    static public function invalidateAll(p_force:Bool) {
        if (g2d_references != null) {
            for (key in g2d_references.keys()) {
                g2d_references.get(key).invalidateNativeTexture(p_force);
            }
        }
    }

    private var g2d_context:IContext;
    private var g2d_nativeSource:Dynamic;
    public function getNativeSource():Dynamic {
        return g2d_nativeSource;
    }

    public var g2d_sourceType:Int;
    private var g2d_type:Int;
    inline public function getType():Int {
        return g2d_type;
    }

    public var g2d_contextId:Int;
    private var g2d_id:String;
    inline public function getId():String {
        return g2d_id;
    }

    public var width(get, never):Int;
    inline private function get_width():Int {
        return Std.int(g2d_region.width);
    }

    public var height(get, never):Int;
    inline private function get_height():Int {
        return Std.int(g2d_region.height);
    }

    private var g2d_gpuWidth:Int = 0;
    public var gpuWidth(get, never):Int;
    inline private function get_gpuWidth():Int {
        return g2d_gpuWidth;
    }

    private var g2d_gpuHeight:Int = 0;
    public var gpuHeight(get, never):Int;
    inline private function get_gpuHeight():Int {
        return g2d_gpuHeight;
    }

    @:allow(com.genome2d.context.canvas)
    private var g2d_region:GRectangle;
    private var g2d_parentAtlas:GContextTexture;

    public var uvX:Float = 0;
    public var uvY:Float = 0;
    public var uvScaleX:Float = 1;
    public var uvScaleY:Float = 1;

    public var pivotX:Float = 0;
    public var pivotY:Float = 0;

    public var nativeTexture:Texture;
    public var g2d_nativeImage:Image;

    private var g2d_format:String;

    //public var g2d_atfType:String = "";
    public var g2d_premultiplied:Bool = true;

    static public var defaultFilteringType:Int = 1;

    public var g2d_filteringType:Int;
    inline public function getFilteringType():Int {
        return g2d_filteringType;
    }
    inline public function setFilteringType(p_value:Int):Int {
    // TODO check for valid filtering type
        return g2d_filteringType = p_value;
    }

    static private var g2d_instanceCount:Int = 0;
	public function new(p_context:IContext, p_id:String, p_sourceType:Int, p_source:Dynamic, p_region:GRectangle, p_format:String, p_repeatable:Bool, p_pivotX:Float, p_pivotY:Float) {
        if (g2d_references == null) g2d_references = new Map<String, GContextTexture>();
        if (p_id == null || p_id.length == 0) throw "Invalid textures id";
        if (g2d_references.get(p_id) != null) throw "Duplicate textures id";

        g2d_format = p_format;
		g2d_instanceCount++;
		g2d_contextId = g2d_instanceCount;
        g2d_region = p_region;
		
        g2d_references.set(p_id, this);

        g2d_context = p_context;
        g2d_id = p_id;
        g2d_sourceType = p_sourceType;
        g2d_nativeSource = p_source;
        g2d_filteringType = defaultFilteringType;
	}

    public function invalidateNativeTexture(p_reinitialize:Bool):Void {
		if (Std.is(g2d_context, GWebGLContext)) {
			var webglContext:GWebGLContext = cast g2d_context;
			if (g2d_type != GTextureType.SUBTEXTURE) {
				switch (g2d_sourceType) {
					case GTextureSourceType.IMAGE:
						if (nativeTexture == null || p_reinitialize) {
							nativeTexture = webglContext.getNativeContext().createTexture();
						}
						webglContext.getNativeContext().bindTexture(RenderingContext.TEXTURE_2D, nativeTexture);
						webglContext.getNativeContext().texParameteri(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_MIN_FILTER, RenderingContext.LINEAR);
						webglContext.getNativeContext().texParameteri(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_MAG_FILTER, RenderingContext.LINEAR);
						webglContext.getNativeContext().texImage2D(RenderingContext.TEXTURE_2D, 0, RenderingContext.RGBA, RenderingContext.RGBA, RenderingContext.UNSIGNED_BYTE, cast g2d_nativeSource);
                        webglContext.getNativeContext().bindTexture(RenderingContext.TEXTURE_2D, null);
					default:
				}
			}
		} else {
			g2d_nativeImage = cast g2d_nativeSource;
		}
    }

    public function getAlphaAtUV(p_u:Float, p_v:Float):Float {
        return 1;
    }

    public function dispose():Void {

    }
}