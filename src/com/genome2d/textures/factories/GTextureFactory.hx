/*
* 	Genome2D - GPU 2D framework utilizing Molehill API
*
*	Copyright 2011 Peter Stefcek. All rights reserved.
*
*	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
*/
package com.genome2d.textures.factories;

import js.html.ImageElement;
import com.genome2d.context.IContext;
import com.genome2d.error.GError;
import com.genome2d.geom.GRectangle;
import com.genome2d.assets.GImageAsset;
import com.genome2d.textures.factories.GTextureFactory;
import com.genome2d.textures.GTexture;

class GTextureFactory {
    static public var g2d_context:IContext;

    static public function createFromImage(p_id:String, p_image:ImageElement):GTexture {
		return new GTexture(g2d_context, p_id, GTextureSourceType.IMAGE, p_image, new GRectangle(0,0,p_image.width,p_image.height), "", false, 0, 0, null);
	}

    static public function createFromAsset(p_id:String, p_imageAsset:GImageAsset):GTexture {
        return createFromImage(p_id, p_imageAsset.g2d_nativeImage);
    }

    static public function createRenderTexture(p_id:String, p_width:Int, p_height:Int):GTexture {
        return null;
    }
}
