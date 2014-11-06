/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.context.canvas;

#if !webGLonly
import com.genome2d.geom.GMatrix3D;
import com.genome2d.textures.GContextTexture;
import js.html.Event;
import com.genome2d.signals.GMouseSignalType;
import js.html.MouseEvent;
import com.genome2d.signals.GKeyboardSignal;
import com.genome2d.signals.GMouseSignal;
import com.genome2d.context.stats.IStats;
import com.genome2d.context.stats.GStats;
import com.genome2d.geom.GRectangle;
import js.html.CanvasElement;
import StringTools;
import js.Lib;
import js.html.Document;
import com.genome2d.context.filters.GFilter;
import com.genome2d.context.GContextConfig;
import com.genome2d.textures.GTexture;
import js.html.CanvasRenderingContext2D;

/**

**/
class GCanvasContext implements IContext
{
    public function hasFeature(p_feature:Int):Bool {
        return false;
    }

    private var g2d_nativeStage:CanvasElement;
    public function getNativeStage():CanvasElement {
        return g2d_nativeStage;
    }

    private var g2d_activeCamera:GCamera;
    private var g2d_defaultCamera:GCamera;
    public function getDefaultCamera():GCamera {
        return g2d_defaultCamera;
    }

	public var g2d_nativeContext:CanvasRenderingContext2D;
    public function getNativeContext():CanvasRenderingContext2D {
        return g2d_nativeContext;
    }

    private var g2d_activeMaskRect:GRectangle;

    private var g2d_currentDeltaTime:Float;
    private var g2d_currentTime:Float;
    private var g2d_stats:IStats;

    private var g2d_stageViewRect:GRectangle;
    inline public function getStageViewRect():GRectangle {
        return g2d_stageViewRect;
    }
    private var g2d_activeViewRect:GRectangle;

    private var g2d_onInitialized:Void->Void;
    public function onInitialized(p_callback:Void->Void):Void {
        g2d_onInitialized = p_callback;
    }
    private var g2d_onInvalidated:Void->Void;
    public function onInvalidated(p_callback:Void->Void):Void {
        g2d_onInvalidated = p_callback;
    }
    private var g2d_onFailed:String->Void;
    public function onFailed(p_callback:String->Void):Void {
        g2d_onFailed = p_callback;
    }
    private var g2d_onFrame:Float->Void;
    public function onFrame(p_callback:Float->Void):Void {
        g2d_onFrame = p_callback;
    }

    private var g2d_onMouseInteraction:GMouseSignal->Void;
    public function onMouseInteraction(p_callback:GMouseSignal->Void):Void {
        g2d_onMouseInteraction = p_callback;
    }

    private var g2d_onKeyboardInteraction:GKeyboardSignal->Void;
    public function onKeyboardInteraction(p_callback:GKeyboardSignal->Void):Void {
        g2d_onKeyboardInteraction = p_callback;
    }
	
	public function new(p_config:GContextConfig) {
        g2d_nativeStage = p_config.nativeStage;
        g2d_stageViewRect = p_config.viewRect;
        g2d_stats = new GStats(g2d_nativeStage);
	}
	
	public function init():Void {
		g2d_nativeContext =  g2d_nativeStage.getContext("2d");

        g2d_defaultCamera = new GCamera();
        g2d_defaultCamera.x = g2d_stageViewRect.width/2;
        g2d_defaultCamera.y = g2d_stageViewRect.height/2;

        g2d_activeViewRect = new GRectangle();
        g2d_currentTime = Date.now().getTime();
        GRequestAnimationFrame.request(g2d_enterFrameHandler);

        g2d_nativeStage.addEventListener("mousedown", g2d_mouseEventHandler);
        g2d_nativeStage.addEventListener("mouseup", g2d_mouseEventHandler);
        g2d_nativeStage.addEventListener("mousemove", g2d_mouseEventHandler);
/*
		g2d_stage.addEventListener("touchstart", onTouchEvent);
		g2d_stage.addEventListener("touchend", onTouchEvent);
		g2d_stage.addEventListener("touchmove", onTouchEvent);
		/**/

        if (g2d_onInitialized != null) g2d_onInitialized();
	}

    public function getMaskRect():GRectangle {
        return g2d_activeMaskRect;
    }
    public function setMaskRect(p_maskRect:GRectangle):Void {
        g2d_activeMaskRect = p_maskRect;
    }

    public function setCamera(p_camera:GCamera):Void {
        g2d_activeCamera = p_camera;

        g2d_activeViewRect.setTo(Std.int(g2d_stageViewRect.width*g2d_activeCamera.normalizedViewX),
                                 Std.int(g2d_stageViewRect.height*g2d_activeCamera.normalizedViewY),
                                 Std.int(g2d_stageViewRect.width*g2d_activeCamera.normalizedViewWidth),
                                 Std.int(g2d_stageViewRect.height*g2d_activeCamera.normalizedViewHeight));

        g2d_nativeContext.restore();
        g2d_nativeContext.save();

        g2d_nativeContext.beginPath();
        g2d_nativeContext.rect(g2d_activeViewRect.x, g2d_activeViewRect.y, g2d_activeViewRect.width, g2d_activeViewRect.height);
        g2d_nativeContext.closePath();
        g2d_nativeContext.clip();
        /**/
        g2d_nativeContext.translate(g2d_activeViewRect.x+g2d_activeViewRect.width/2-g2d_activeCamera.x, g2d_activeViewRect.y+g2d_activeViewRect.height/2-g2d_activeCamera.y);
        if (g2d_activeCamera.scaleX != 1 || g2d_activeCamera.scaleY != 1) g2d_nativeContext.scale(g2d_activeCamera.scaleX, g2d_activeCamera.scaleY);
        //if (g2d_activeCamera.rotation != 0) g2d_nativeContext.rotate(g2d_activeCamera.rotation);
        /**/
        // use matrix
        //g2d_nativeContext.setTransform(g2d_activeCamera.scaleX, 0, 0, g2d_activeCamera.scaleY, g2d_activeViewRect.x+g2d_activeViewRect.width/2-g2d_activeCamera.x, g2d_activeViewRect.y+g2d_activeViewRect.height/2-g2d_activeCamera.y);
    }
    /**/

    public function begin(p_red:Float, p_green:Float, p_blue:Float, p_alpha:Float, p_useDefaultCamera:Bool = true):Void {
        g2d_stats.clear();

		g2d_nativeContext.setTransform(1, 0, 0, 1, 0, 0);
		g2d_nativeContext.clearRect(g2d_stageViewRect.x, g2d_stageViewRect.y, g2d_stageViewRect.width, g2d_stageViewRect.height);
        g2d_nativeContext.fillStyle = "#"+StringTools.hex(Std.int(p_red*255),2)+StringTools.hex(Std.int(p_green*255),2)+StringTools.hex(Std.int(p_blue*255),2);
        g2d_nativeContext.fillRect(g2d_stageViewRect.x, g2d_stageViewRect.y, g2d_stageViewRect.width, g2d_stageViewRect.height);
		g2d_nativeContext.globalCompositeOperation = "source-over";

        setCamera(g2d_defaultCamera);
	}
	
	public function end():Void {
	    g2d_nativeContext.restore();

        g2d_stats.render(this);
	}
	
	public function draw(p_texture:GContextTexture, p_x:Float, p_y:Float, p_scaleX:Float = 1, p_scaleY:Float = 1, p_rotation:Float = 0, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float = 1, p_blendMode:Int = 1, p_filter:GFilter = null):Void {
        g2d_nativeContext.save();

        g2d_nativeContext.globalAlpha = p_alpha;
        g2d_nativeContext.translate(p_x/g2d_activeCamera.scaleX, p_y/g2d_activeCamera.scaleY);
        g2d_nativeContext.scale(p_scaleX, p_scaleY);
        g2d_nativeContext.rotate(p_rotation);
		var w:Float = p_texture.width;
		var h:Float = p_texture.height;

		g2d_nativeContext.drawImage(p_texture.g2d_nativeImage, p_texture.g2d_region.x, p_texture.g2d_region.y, p_texture.g2d_region.width, p_texture.g2d_region.height, -p_texture.pivotX - w / 2, -p_texture.pivotY - h / 2, w, h);

		g2d_nativeContext.restore();
	}

    public function drawPoly(p_texture:GContextTexture, p_vertices:Array<Float>, p_uvs:Array<Float>, p_x:Float, p_y:Float, p_scaleX:Float = 1, p_scaleY:Float = 1, p_rotation:Float = 0, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float = 1, p_blendMode:Int=1, p_filter:GFilter = null):Void {

    }

    public function drawSource(p_texture:GContextTexture, p_sourceX:Float, p_sourceY:Float, p_sourceWidth:Float, p_sourceHeight:Float, p_x:Float, p_y:Float, p_scaleX:Float = 1, p_scaleY:Float = 1, p_rotation:Float = 0, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float = 1, p_blendMode:Int = 1, p_filter:GFilter = null):Void {

    }

    public function drawMatrix(p_texture:GContextTexture, p_a:Float, p_b:Float, p_c:Float, p_d:Float, p_tx:Float, p_ty:Float, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float=1, p_blendMode:Int=1, p_filter:GFilter = null):Void {

    }

    public function bindRenderer(p_renderer:Dynamic):Void {

    }

    public function dispose():Void {

    }

    public function clearStencil():Void {

    }

    public function renderToStencil(p_stencilLayer:Int):Void {

    }

    public function renderToColor(p_stencilLayer:Int):Void {

    }

    public function setRenderTarget(p_texture:GContextTexture = null, p_transform:GMatrix3D = null):Void {
    }

    private function g2d_enterFrameHandler():Void {
        var currentTime:Float = Date.now().getTime();
        g2d_currentDeltaTime = currentTime - g2d_currentTime;
        g2d_currentTime = currentTime;
        g2d_stats.render(this);

        if (g2d_onFrame != null) g2d_onFrame(g2d_currentDeltaTime);
        GRequestAnimationFrame.request(g2d_enterFrameHandler);
    }

    private function g2d_mouseEventHandler(event:Event):Void {
        var captured:Bool = false;
        event.preventDefault();
        event.stopPropagation();
        var me:MouseEvent = cast event;
        var mx:Float = me.pageX - g2d_nativeStage.offsetLeft;
        var my:Float = me.pageY - g2d_nativeStage.offsetTop;

        var signal:GMouseSignal = new GMouseSignal(GMouseSignalType.fromNative(event.type), mx, my, captured);// event.buttonDown, event.ctrlKey,
        if (g2d_onMouseInteraction != null) g2d_onMouseInteraction(signal);
    }

    public function setDepthTest(p_depthMask:Bool, p_compareMode:Dynamic):Void {

    }

    public function setRenderTargets(p_textures:Array<GContextTexture>, p_transform:GMatrix3D = null):Void {

    }
}
#end