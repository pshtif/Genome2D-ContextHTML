/*
* 	Genome2D - GPU 2D framework utilizing Molehill API
*
*	Copyright 2011 Peter Stefcek. All rights reserved.
*
*	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
*/
package com.genome2d.textures.factories;

import com.genome2d.error.GError;
import com.genome2d.geom.GRectangle;
import js.html.ImageElement;
import com.genome2d.context.IContext;
import com.genome2d.assets.GImageAsset;
import com.genome2d.assets.GXmlAsset;

class GTextureAtlasFactory
{
    static public var g2d_context:IContext;

    static public function createFromImageAndXml(p_id:String, p_image:ImageElement, p_xml:Xml, p_format:String = "bgra"):GTextureAtlas {
        if (!GTextureUtils.isValidTextureSize(p_image.width) || !GTextureUtils.isValidTextureSize(p_image.height)) new GError("Atlas bitmap needs to have power of 2 size.");
        var textureAtlas:GTextureAtlas = new GTextureAtlas(g2d_context, p_id, GTextureSourceType.IMAGE, p_image, new GRectangle(0,0,p_image.width,p_image.height), p_format, null);

        var root = p_xml.firstElement();
        var it:Iterator<Xml> = root.elements();

        while(it.hasNext()) {
            var node:Xml = it.next();

            var region:GRectangle = new GRectangle(Std.parseInt(node.get("x")), Std.parseInt(node.get("y")), Std.parseInt(node.get("width")), Std.parseInt(node.get("height")));

            var pivotX:Float = (node.get("frameX") == null || node.get("frameWidth") == null) ? 0 : (Std.parseInt(node.get("frameWidth"))-region.width)/2 + Std.parseInt(node.get("frameX"));
            var pivotY:Float = (node.get("frameY") == null || node.get("frameHeight") == null) ? 0 : (Std.parseInt(node.get("frameHeight"))-region.height)/2 + Std.parseInt(node.get("frameY"));

            textureAtlas.addSubTexture(node.get("name"), region, pivotX, pivotY);
        }

        textureAtlas.invalidateNativeTexture(false);
        return textureAtlas;
    }

    static public function createFromImageAndFontXml(p_id:String, p_image:ImageElement, p_fontXml:Xml, p_format:String = "bgra"):GTextureAtlas {
        if (!GTextureUtils.isValidTextureSize(p_image.width) || !GTextureUtils.isValidTextureSize(p_image.height)) new GError("Atlas bitmap needs to have power of 2 size.");
        var textureAtlas:GTextureAtlas = new GTextureAtlas(g2d_context, p_id, GTextureSourceType.IMAGE, p_image, new GRectangle(0,0,p_image.width,p_image.height), p_format, null);

        var root = p_fontXml.firstElement();
        var it:Iterator<Xml> = root.elementsNamed("chars");
        it = it.next().elements();

        while(it.hasNext()) {
            var node:Xml = it.next();
            var region:GRectangle = new GRectangle(Std.parseInt(node.get("x")), Std.parseInt(node.get("y")), Std.parseInt(node.get("width")), Std.parseInt(node.get("height")));

            var pivotX:Float = -Std.parseFloat(node.get("xoffset"));
            var pivotY:Float = -Std.parseFloat(node.get("yoffset"));

            textureAtlas.addSubTexture(node.get("id"), region, pivotX, pivotY);
        }

        textureAtlas.invalidateNativeTexture(false);
        return textureAtlas;
    }

    static public function createFromAssets(p_id:String, p_imageAsset:GImageAsset, p_xmlAsset:GXmlAsset, p_format:String = "bgra"):GTextureAtlas {
        return createFromImageAndXml(p_id, p_imageAsset.g2d_nativeImage, p_xmlAsset.xml, p_format);
    }

    static public function createFontFromAssets(p_id:String, p_imageAsset:GImageAsset, p_xmlAsset:GXmlAsset, p_format:String = "bgra"):GTextureAtlas {
        return createFromImageAndFontXml(p_id, p_imageAsset.g2d_nativeImage, p_xmlAsset.xml, p_format);
    }
}