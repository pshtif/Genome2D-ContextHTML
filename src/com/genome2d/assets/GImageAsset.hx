package com.genome2d.assets;

import haxe.Http;
import js.html.ImageElement;
import js.html.Event;
import js.Browser;

class GImageAsset extends GAsset {
    public var g2d_nativeImage:ImageElement;

    public function new(p_id:String, p_url:String) {
        super(p_id, p_url);
    }

    override public function load(p_url:String = null):Void {
        super.load(p_url);

		g2d_nativeImage = Browser.document.createImageElement();
		g2d_nativeImage.onload = loadedHandler;
		g2d_nativeImage.src = g2d_url;
    }

    private function loadedHandler(event:Event):Void {
        onLoaded.dispatch(this);
    }
}
