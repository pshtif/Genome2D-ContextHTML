package com.genome2d.assets;

import com.genome2d.error.GError;
import haxe.Http;
import js.html.Event;
import js.Browser;

class GXmlAsset extends GAsset {
    public var xml:Xml;

    public function new(p_id:String, p_url:String) {
        super(p_id, p_url);
    }

    override public function load(p_url:String = null):Void {
        super.load(p_url);

        var http:Http = new Http(g2d_url);
        http.onData = loadedHandler;
        http.onError = errorHandler;
        http.request();
    }

    private function loadedHandler(p_data:String):Void {
        xml = Xml.parse(p_data);
        onLoaded.dispatch(this);
    }

    private function errorHandler(p_error:String):Void {
        new GError(p_error);
    }
}
