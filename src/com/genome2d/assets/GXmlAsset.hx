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
import com.genome2d.debug.GDebug;
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
        GDebug.error(p_error);
    }
}
