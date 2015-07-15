/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.context;

import com.genome2d.geom.GRectangle;
import com.genome2d.debug.GDebug;
import com.genome2d.context.stats.IGStats;
import com.genome2d.context.webgl.GWebGLContext;
import com.genome2d.geom.GRectangle;
import js.Browser;
import js.html.CanvasElement;

/**

**/
class GContextConfig
{
	public var viewRect:GRectangle;
    public var enableStats:Bool = false;
    public var nativeStage:CanvasElement;
	
	public var contextClass:Class<IGContext>;
    public var fallbackContextClass:Class<IGContext>;
    public var statsClass:Class<IGStats>;
	
    public function new(?p_viewRect:GRectangle = null) {
		nativeStage = cast Browser.document.getElementById("canvas");

		viewRect = p_viewRect;
        if (nativeStage == null) {
            if (p_viewRect == null) {
                GDebug.error("No canvas found");
            }

            nativeStage = Browser.document.createCanvasElement();
            nativeStage.width = Std.int(viewRect.width);
            nativeStage.height = Std.int(viewRect.height);
            Browser.document.body.appendChild(nativeStage);
        } else {
            if (viewRect == null) {
                viewRect = new GRectangle(0,0,nativeStage.width,nativeStage.height);
            }
        }
        //contextClass = GCanvasContext;
        contextClass = GWebGLContext;
    }
}
