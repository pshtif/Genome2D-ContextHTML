package com.genome2d.assets;
import js.html.compat.DataView;
import js.html.compat.ArrayBuffer;
import com.genome2d.macros.MGDebug;
import js.html.XMLHttpRequestResponseType;
import js.html.XMLHttpRequest;
import haxe.io.Bytes;

class GBinaryAsset extends GAsset {

    public var data:Bytes;

    private var g2d_request:XMLHttpRequest;

    override public function load():Void {
        g2d_request = new XMLHttpRequest();

        g2d_request.addEventListener("load", loadedHandler);
        g2d_request.addEventListener("error", errorHandler);
        g2d_request.open("GET", g2d_url);
        g2d_request.responseType = XMLHttpRequestResponseType.ARRAYBUFFER;
        g2d_request.send();
    }

    private function loadedHandler(p_data:String):Void {
        g2d_loaded = true;
        if (Std.is(g2d_request.response, ArrayBuffer)) {
            data = Bytes.ofData(g2d_request.response);
        } else {
            MGDebug.G2D_WARNING("Request doesn't contain binary data.");
        }

        onLoaded.dispatch(this);
    }

    private function errorHandler(p_error:String):Void {
        MGDebug.G2D_ERROR(p_error);
    }
}
