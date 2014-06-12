package com.genome2d.assets;
import msignal.Signal.Signal1;

import js.html.Event;

/**
 * Simple asset class for alpha asset management, will be differentiated into multiple classes for different assets later
 * 
 * @author Peter "sHTiF" Stefcek / www.flash-core.com
 */
class GAsset
{
    private var g2d_url:String;

    private var g2d_loaded:Bool = false;
    public function isLoaded():Bool {
        return g2d_loaded;
    }

	public var onLoaded(default,null):Signal1<GAsset>;

    public var id(default, null):String;

	public function new(){
        onLoaded = new Signal1(GAsset);
    }

    public function initUrl(p_id:String, p_url:String) {
        id = p_id;
        g2d_url = p_url;
	}

    public function load():Void {

    }
}