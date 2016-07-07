/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.textures;

import com.genome2d.debug.GDebug;
import com.genome2d.context.IGContext;
import com.genome2d.geom.GRectangle;
import com.genome2d.context.GContextFeature;
import com.genome2d.context.GWebGLContext;
import com.genome2d.textures.GTextureSourceType;

import js.html.Image;
import js.html.webgl.RenderingContext;
import js.html.webgl.Texture;
import js.html.ImageElement;

class GTexture extends GTextureBase
{
	override public function setSource(p_value:Dynamic):Dynamic {
        if (g2d_source != p_value) {
            g2d_dirty = true;
			g2d_source = p_value;
            if (Std.is(g2d_source, ImageElement)) {
				var imageElement:ImageElement = cast g2d_source;
                g2d_sourceType = GTextureSourceType.IMAGE;
                g2d_nativeWidth = imageElement.width;
                g2d_nativeHeight = imageElement.height;
                premultiplied = true;
            } else if (Std.is(g2d_source,GRectangle)) {
                g2d_sourceType = GTextureSourceType.RENDER_TARGET;
                g2d_nativeWidth = p_value.width;
                g2d_nativeHeight = p_value.height;
            } else if (Std.is(g2d_source, GTexture)) {
				var parent:GTexture = cast g2d_source;
				parent.onInvalidated.add(parentInvalidated_handler);
				parent.onDisposed.add(parentDisposed_handler);
				g2d_gpuWidth = parent.g2d_gpuWidth;
				g2d_gpuHeight = parent.g2d_gpuHeight;
				g2d_nativeWidth = parent.g2d_nativeWidth;
				g2d_nativeHeight = parent.g2d_nativeHeight;
				g2d_nativeTexture = parent.nativeTexture;
				g2d_sourceType = GTextureSourceType.TEXTURE;
			} else {
                GDebug.error("Invalid texture source.");
            }
            g2d_dirty = true;
        }
        return g2d_source;
    }
	
    public function invalidateNativeTexture(p_reinitialize:Bool):Void {
		if (Std.is(g2d_context, GWebGLContext)) {
			var webglContext:GWebGLContext = cast g2d_context;
			var nativeContext:RenderingContext = webglContext.getNativeContext();
			if (g2d_sourceType != GTextureSourceType.TEXTURE) {
				g2d_gpuWidth = usesRectangle() ? g2d_nativeWidth : GTextureUtils.getNextValidTextureSize(g2d_nativeWidth);
                g2d_gpuHeight = usesRectangle() ? g2d_nativeHeight : GTextureUtils.getNextValidTextureSize(g2d_nativeHeight);
				
				switch (g2d_sourceType) {
					case GTextureSourceType.IMAGE:
						if (nativeTexture == null || p_reinitialize) {
							g2d_nativeTexture = nativeContext.createTexture();
						}

						nativeContext.bindTexture(RenderingContext.TEXTURE_2D, nativeTexture);
                        nativeContext.texImage2D(RenderingContext.TEXTURE_2D, 0, RenderingContext.RGBA, RenderingContext.RGBA, RenderingContext.UNSIGNED_BYTE, cast g2d_source);
						nativeContext.texParameteri(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_MIN_FILTER, RenderingContext.LINEAR);
						nativeContext.texParameteri(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_MAG_FILTER, RenderingContext.LINEAR);
                        nativeContext.texParameteri(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_WRAP_S, RenderingContext.CLAMP_TO_EDGE);
                        nativeContext.texParameteri(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_WRAP_T, RenderingContext.CLAMP_TO_EDGE);

                        nativeContext.bindTexture(RenderingContext.TEXTURE_2D, null);
					case GTextureSourceType.RENDER_TARGET:
						if (nativeTexture == null || p_reinitialize) {
							g2d_nativeTexture = nativeContext.createTexture();
						}
						
						nativeContext.bindTexture(RenderingContext.TEXTURE_2D, nativeTexture);
                        nativeContext.texImage2D(RenderingContext.TEXTURE_2D, 0, RenderingContext.RGBA, 16, 16, 0, RenderingContext.RGBA, RenderingContext.UNSIGNED_BYTE, null);
						nativeContext.texParameteri(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_MIN_FILTER, RenderingContext.LINEAR);
						nativeContext.texParameteri(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_MAG_FILTER, RenderingContext.LINEAR);
                        nativeContext.texParameteri(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_WRAP_S, RenderingContext.CLAMP_TO_EDGE);
                        nativeContext.texParameteri(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_WRAP_T, RenderingContext.CLAMP_TO_EDGE);
						
						var fb = nativeContext.createFramebuffer();
						nativeContext.bindFramebuffer(RenderingContext.FRAMEBUFFER, fb);
						nativeContext.framebufferTexture2D(RenderingContext.FRAMEBUFFER, RenderingContext.COLOR_ATTACHMENT0, RenderingContext.TEXTURE_2D, g2d_nativeTexture, 0);
						
						nativeContext.clearColor(0, 1, 0, 1);
						nativeContext.clear(RenderingContext.COLOR_BUFFER_BIT);
						// TODO: should be handled in main pipeline
						nativeContext.bindFramebuffer(RenderingContext.FRAMEBUFFER, null);
					default:
				}
			}
		} else {
			//g2d_nativeImage = cast g2d_nativeSource;
		}
    }
	
	/****************************************************************************************************
	 * 	GPU DEPENDANT PROPERTIES
	 ****************************************************************************************************/
	
	private var g2d_nativeTexture:Texture;
	/**
	 * 	Native texture reference
	 */
    #if swc @:extern #end
    public var nativeTexture(get,never):Texture;
    #if swc @:getter(nativeTexture) #end
    inline private function get_nativeTexture():Texture {
        return g2d_nativeTexture;
    }
	
	/**
	 * 	Check if this texture has same gpu texture as the passed texture
	 *
	 * 	@param p_texture
	 */
    public function hasSameGPUTexture(p_texture:GTexture):Bool {
        return p_texture.nativeTexture == nativeTexture;
    }
}