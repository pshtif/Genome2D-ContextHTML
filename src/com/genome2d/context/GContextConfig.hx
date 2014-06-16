/*
* 	Genome2D - GPU 2D framework utilizing Molehill API
*
*	Copyright 2011 Peter Stefcek. All rights reserved.
*
*	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
*/
package com.genome2d.context;

import com.genome2d.geom.GRectangle;
import com.genome2d.error.GError;
import com.genome2d.context.stats.IStats;
import com.genome2d.context.canvas.GCanvasContext;
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
	
	public var contextClass:Class<IContext>;
    public var fallbackContextClass:Class<IContext>;
    public var statsClass:Class<IStats>;
	
    public function new(?p_viewRect:GRectangle = null) {
		nativeStage = cast Browser.document.getElementById("canvas");

		viewRect = p_viewRect;
        if (nativeStage == null) {
            if (p_viewRect == null) {
                new GError("No canvas found");
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
