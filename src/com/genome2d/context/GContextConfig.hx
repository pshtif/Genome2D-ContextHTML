package com.genome2d.context;
import com.genome2d.context.stats.IStats;
import com.genome2d.context.canvas.GCanvasContext;
import com.genome2d.context.webgl.GWebGLContext;
import com.genome2d.geom.GRectangle;
import js.Browser;
import js.html.CanvasElement;
class GContextConfig {
	
	public var viewRect:GRectangle;
    public var enableStats:Bool = false;
    public var nativeStage:CanvasElement;
	
	public var contextClass:Class<IContext>;
    public var fallbackContextClass:Class<IContext>;
    public var statsClass:Class<IStats>;
	
    public function new(p_viewRect:GRectangle) {
		nativeStage = cast Browser.document.getElementById("canvas2d");
		viewRect = p_viewRect;
        if (nativeStage == null) {
            nativeStage = Browser.document.createCanvasElement();
            nativeStage.width = Std.int(viewRect.width);
            nativeStage.height = Std.int(viewRect.height);
            Browser.document.body.appendChild(nativeStage);
        }
        contextClass = GCanvasContext;
        //contextClass = GWebGLContext;
    }
}
