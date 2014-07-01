/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
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

    static public function createFromImageAndFontXml(p_id:String, p_image:ImageElement, p_fontXml:Xml, p_format:String = "bgra"):GFontTextureAtlas {
        var textureAtlas:GFontTextureAtlas = new GFontTextureAtlas(g2d_context, p_id, GTextureSourceType.IMAGE, p_image, new GRectangle(0,0,p_image.width,p_image.height), p_format, null);

        var root:Xml = p_fontXml.firstElement();

        var common:Xml = root.elementsNamed("common").next();
        textureAtlas.lineHeight = Std.parseInt(common.get("lineHeight"));

        var it:Iterator<Xml> = root.elementsNamed("chars");
        it = it.next().elements();

        while(it.hasNext()) {
            var node:Xml = it.next();
            var w:Int = Std.parseInt(node.get("width"));
            var h:Int = Std.parseInt(node.get("height"));
            var region:GRectangle = new GRectangle(Std.parseInt(node.get("x")), Std.parseInt(node.get("y")), w, h);

            var subtexture:GCharTexture = textureAtlas.addSubTexture(node.get("id"), region, -w/2, -h/2);
            subtexture.xoffset = Std.parseInt(node.get("xoffset"));
            subtexture.yoffset = Std.parseInt(node.get("yoffset"));
            subtexture.xadvance = Std.parseInt(node.get("xadvance"));
        }

        var kernings:Xml = root.elementsNamed("kernings").next();
        if (kernings != null) {
            it = kernings.elements();
            textureAtlas.g2d_kerning = new Map<Int,Map<Int,Int>>();

            while(it.hasNext()) {
                var node:Xml = it.next();
                var first:Int = Std.parseInt(node.get("first"));
                var map:Map<Int,Int> = textureAtlas.g2d_kerning.get(first);
                if (map == null) {
                    map = new Map<Int,Int>();
                    textureAtlas.g2d_kerning.set(first, map);
                }
                var second:Int = Std.parseInt(node.get("second"));
                map.set(second, Std.parseInt("amount"));
            }
        }

        textureAtlas.invalidateNativeTexture(false);
        return textureAtlas;
    }

    static public function createFromAssets(p_id:String, p_imageAsset:GImageAsset, p_xmlAsset:GXmlAsset, p_format:String = "bgra"):GTextureAtlas {
        return createFromImageAndXml(p_id, p_imageAsset.g2d_nativeImage, p_xmlAsset.xml, p_format);
    }

    static public function createFontFromAssets(p_id:String, p_imageAsset:GImageAsset, p_xmlAsset:GXmlAsset, p_format:String = "bgra"):GFontTextureAtlas {
        return createFromImageAndFontXml(p_id, p_imageAsset.g2d_nativeImage, p_xmlAsset.xml, p_format);
    }
}