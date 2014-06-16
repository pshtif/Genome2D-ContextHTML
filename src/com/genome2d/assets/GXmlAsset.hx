/*
* 	Genome2D - GPU 2D framework utilizing Molehill API
*
*	Copyright 2011 Peter Stefcek. All rights reserved.
*
*	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
*/
package com.genome2d.assets;

import com.genome2d.error.GError;
import haxe.Http;
import js.html.Event;
import js.Browser;

/**

**/
class GXmlAsset extends GAsset
{
    public var xml:Xml;

    override public function load():Void {
        var http:Http = new Http(g2d_url);
        http.onData = loadedHandler;
        http.onError = errorHandler;
        http.request();
    }

    private function loadedHandler(p_data:String):Void {
        g2d_loaded = true;
        xml = Xml.parse(p_data);
        onLoaded.dispatch(this);
    }

    private function errorHandler(p_error:String):Void {
        new GError(p_error);
    }
}
