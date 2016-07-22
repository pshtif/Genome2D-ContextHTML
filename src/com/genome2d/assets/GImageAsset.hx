/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.assets;

import Genome2D-ContextCommon.src.com.genome2d.assets.GAsset;
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
	
	private var g2d_type:Int;
    #if swc @:extern #end
    public var type(get,never):Int;
    #if swc @:getter(type) #end
    inline private function get_type():Int {
        return g2d_type;
    }

    override public function load():Void {
		g2d_imageElement = Browser.document.createImageElement();
		g2d_imageElement.onload = loadedHandler;
		g2d_imageElement.src = g2d_url;
    }

    private function loadedHandler(event:Event):Void {
		g2d_type = GImageAssetType.IMAGEELEMENT;
        g2d_loaded = true;
        onLoaded.dispatch(this);
    }
}
