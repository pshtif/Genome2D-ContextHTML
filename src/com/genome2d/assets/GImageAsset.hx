/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.assets;

import com.genome2d.assets.GAsset;
import js.html.ImageElement;
import js.html.Event;
import js.Browser;

/**

**/
class GImageAsset extends GAsset
{
    public var g2d_imageElement:ImageElement;
    public var imageElement(get,never):ImageElement;
    inline private function get_imageElement():ImageElement {
        return g2d_imageElement;
    }
	
	private var g2d_type:GImageAssetType;
    #if swc @:extern #end
    public var type(get,never):GImageAssetType;
    #if swc @:getter(type) #end
    inline private function get_type():GImageAssetType {
        return g2d_type;
    }

    override public function load():Void {
		g2d_imageElement = Browser.document.createImageElement();
        g2d_imageElement.onerror = error_handler;
		g2d_imageElement.onload = loaded_handler;
		g2d_imageElement.src = g2d_url;
    }

    private function loaded_handler(event:Event):Void {
		g2d_type = GImageAssetType.IMAGEELEMENT;
        g2d_loaded = true;
        onLoaded.dispatch(this);
    }

    private function error_handler(event:Event):Void {
        g2d_type = GImageAssetType.IMAGEELEMENT;
        g2d_loaded = false;
        onFailed.dispatch(this);
    }
}
