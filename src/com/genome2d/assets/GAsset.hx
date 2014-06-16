/*
* 	Genome2D - GPU 2D framework utilizing Molehill API
*
*	Copyright 2011 Peter Stefcek. All rights reserved.
*
*	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
*/
package com.genome2d.assets;

import msignal.Signal.Signal1;

import js.html.Event;

/**
    Abstract asset superclass
**/
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