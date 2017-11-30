/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.context;

#if !webglonly
import com.genome2d.context.GBlendMode;
import com.genome2d.macros.MGDebug;
import com.genome2d.input.GKeyboardInputType;
import com.genome2d.callbacks.GCallback.GCallback0;
import com.genome2d.callbacks.GCallback.GCallback1;
import com.genome2d.callbacks.GCallback.GCallback2;
import js.html.TouchEvent;
import js.html.DOMRect;
import js.html.WheelEvent;
import js.Browser;
import com.genome2d.input.GMouseInputType;
import com.genome2d.geom.GMatrix3D;
import com.genome2d.context.filters.GFilter;
import com.genome2d.context.stats.GStats;
import com.genome2d.input.GKeyboardInput;
import com.genome2d.input.GMouseInput;
import com.genome2d.textures.GTexture;
import com.genome2d.geom.GRectangle;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import com.genome2d.input.IGFocusable;
import js.html.Event;
import js.html.MouseEvent;
import js.html.KeyboardEvent;
import com.genome2d.context.stats.IGStats;

class GCanvasContext implements IGContext
{
    public function hasFeature(p_feature:Int):Bool {
        return false;
    }

    private var g2d_nativeStage:CanvasElement;
    public function getNativeStage():CanvasElement {
        return g2d_nativeStage;
    }

    private var g2d_activeCamera:GCamera;
    public function getActiveCamera():GCamera {
        return g2d_activeCamera;
    }

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
    private var g2d_stats:IGStats;
    private var g2d_activeBlendMode:GBlendMode;
    private var g2d_activePremultiply:Bool;

    private var g2d_stageViewRect:GRectangle;
    inline public function getStageViewRect():GRectangle {
        return g2d_stageViewRect;
    }
    private var g2d_activeViewRect:GRectangle;
    private var g2d_backgroundRed:Float = 0;
    private var g2d_backgroundGreen:Float = 0;
    private var g2d_backgroundBlue:Float = 0;
    private var g2d_backgroundAlpha:Float = 1;
    public function setBackgroundColor(p_color:Int, p_alpha:Float = 1):Void {
        g2d_backgroundRed = Std.int(p_color >> 16 & 0xFF) / 0xFF;
        g2d_backgroundGreen = Std.int(p_color >> 8 & 0xFF) / 0xFF;
        g2d_backgroundBlue = Std.int(p_color & 0xFF) / 0xFF;
        g2d_backgroundAlpha = p_alpha;
    }


    public var onInitialized(default,null):GCallback0;
    public var onFailed(default,null):GCallback1<String>;
    public var onInvalidated(default, null):GCallback0;
    public var onResize(default,null):GCallback2<Int,Int>;
    public var onFrame(default,null):GCallback1<Float>;
    public var onMouseInput(default,null):GCallback1<GMouseInput>;
    public var onKeyboardInput(default, null):GCallback1<GKeyboardInput>;

    public var g2d_onMouseInputInternal:GMouseInput->Void;
	
	public function new(p_config:GContextConfig) {
        g2d_nativeStage = p_config.nativeStage;
        g2d_stageViewRect = p_config.viewRect;
        g2d_stats = new GStats(g2d_nativeStage);

        onInitialized = new GCallback0();
        onFailed = new GCallback1<String>();
        onInvalidated = new GCallback0();
        onResize = new GCallback2<Int,Int>();
        onFrame = new GCallback1<Float>();
        onMouseInput = new GCallback1<GMouseInput>();
        onKeyboardInput = new GCallback1<GKeyboardInput>();
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
        g2d_nativeStage.addEventListener("wheel", g2d_mouseEventHandler);

        g2d_nativeStage.addEventListener("touchstart", g2d_mouseEventHandler);
        g2d_nativeStage.addEventListener("touchend", g2d_mouseEventHandler);
        g2d_nativeStage.addEventListener("touchmove", g2d_mouseEventHandler);
        g2d_nativeStage.addEventListener("touchcancel", g2d_mouseEventHandler);

        g2d_nativeStage.addEventListener("keyup", g2d_keyboardEventHandler);
        g2d_nativeStage.addEventListener("keydown", g2d_keyboardEventHandler);

        Browser.window.addEventListener("keyup", g2d_keyboardEventHandler);
        Browser.window.addEventListener("keydown", g2d_keyboardEventHandler);

        onInitialized.dispatch();
	}

    public function getMaskRect():GRectangle {
        return g2d_activeMaskRect;
    }
    public function setMaskRect(p_maskRect:GRectangle):Void {
        g2d_activeMaskRect = p_maskRect;
    }

    public function setActiveCamera(p_camera:GCamera):Bool {
        if (g2d_stageViewRect.width*p_camera.normalizedViewWidth <= 0 ||
        g2d_stageViewRect.height*p_camera.normalizedViewHeight <= 0) return false;

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

        return true;
    }
    /**/

    public function resize(p_rect:GRectangle):Void {
        MGDebug.WARNING("Not implemented.");
    }

    public function begin():Bool {
        g2d_stats.clear();

        g2d_activePremultiply = true;
        g2d_activeBlendMode = GBlendMode.NORMAL;

		g2d_nativeContext.setTransform(1, 0, 0, 1, 0, 0);
		g2d_nativeContext.clearRect(g2d_stageViewRect.x, g2d_stageViewRect.y, g2d_stageViewRect.width, g2d_stageViewRect.height);
        g2d_nativeContext.fillStyle = "#"+StringTools.hex(Std.int(g2d_backgroundRed*255),2)+StringTools.hex(Std.int(g2d_backgroundGreen*255),2)+StringTools.hex(Std.int(g2d_backgroundBlue*255),2);
        g2d_nativeContext.fillRect(g2d_stageViewRect.x, g2d_stageViewRect.y, g2d_stageViewRect.width, g2d_stageViewRect.height);
		g2d_nativeContext.globalCompositeOperation = "source-over";

        setActiveCamera(g2d_defaultCamera);

        return true;
	}
	
	public function end():Void {
	    g2d_nativeContext.restore();

        g2d_stats.render(this);
	}

    @:access(com.genome2d.textures.GTexture)
	public function draw(p_texture:GTexture, p_blendMode:GBlendMode, p_x:Float, p_y:Float, p_scaleX:Float = 1, p_scaleY:Float = 1, p_rotation:Float = 0, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float = 1, p_filter:GFilter = null):Void {
        g2d_nativeContext.save();

        g2d_nativeContext.globalAlpha = p_alpha;
        g2d_nativeContext.translate(p_x/g2d_activeCamera.scaleX, p_y/g2d_activeCamera.scaleY);
        g2d_nativeContext.scale(p_scaleX, p_scaleY);
        g2d_nativeContext.rotate(p_rotation);
		var w:Float = p_texture.width;
		var h:Float = p_texture.height;

		g2d_nativeContext.drawImage(p_texture.g2d_source, p_texture.g2d_region.x, p_texture.g2d_region.y, p_texture.g2d_region.width, p_texture.g2d_region.height, -p_texture.pivotX - w / 2, -p_texture.pivotY - h / 2, w, h);

		g2d_nativeContext.restore();
	}

    public function drawSource(p_texture:GTexture, p_blendMode:GBlendMode, p_sourceX:Float, p_sourceY:Float, p_sourceWidth:Float, p_sourceHeight:Float, p_sourcePivotX:Float, p_sourcePivotY:Float, p_x:Float, p_y:Float, p_scaleX:Float = 1, p_scaleY:Float = 1, p_rotation:Float = 0, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float = 1, p_filter:GFilter = null):Void {
        g2d_nativeContext.save();

        g2d_nativeContext.globalAlpha = p_alpha;
        g2d_nativeContext.translate(p_x/g2d_activeCamera.scaleX, p_y/g2d_activeCamera.scaleY);
        g2d_nativeContext.scale(p_scaleX, p_scaleY);
        g2d_nativeContext.rotate(p_rotation);

        g2d_nativeContext.drawImage(p_texture.g2d_source, p_sourceX, p_sourceY, p_sourceWidth, p_sourceHeight, p_sourcePivotX, p_sourcePivotY, p_sourceWidth, p_sourceHeight);

        g2d_nativeContext.restore();
    }

    public function drawMatrix(p_texture:GTexture, p_blendMode:GBlendMode, p_a:Float, p_b:Float, p_c:Float, p_d:Float, p_tx:Float, p_ty:Float, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float=1, p_filter:GFilter = null):Void {
        g2d_nativeContext.save();

        g2d_nativeContext.globalAlpha = p_alpha;
        g2d_nativeContext.setTransform(p_a, p_b, p_c, p_d, p_tx, p_ty);
        var w:Float = p_texture.width;
        var h:Float = p_texture.height;

        g2d_nativeContext.drawImage(p_texture.g2d_source, p_texture.g2d_region.x, p_texture.g2d_region.y, p_texture.g2d_region.width, p_texture.g2d_region.height, -p_texture.pivotX - w / 2, -p_texture.pivotY - h / 2, w, h);

        g2d_nativeContext.restore();
    }

    public function drawPoly(p_texture:GTexture, p_blendMode:GBlendMode, p_vertices:Array<Float>, p_uvs:Array<Float>, p_x:Float, p_y:Float, p_scaleX:Float = 1, p_scaleY:Float = 1, p_rotation:Float = 0, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float = 1, p_filter:GFilter = null):Void {
        MGDebug.WARNING("Not implemented.");
    }


    public function bindRenderer(p_renderer:Dynamic):Void {
        MGDebug.WARNING("Not implemented.");
    }

    public function setBlendMode(p_blendMode:GBlendMode, p_premultiplied:Bool):Void {
        if (p_blendMode != g2d_activeBlendMode || p_premultiplied != g2d_activePremultiply) {
            g2d_activeBlendMode = p_blendMode;
            switch (g2d_activeBlendMode) {
                case GBlendMode.MULTIPLY:
                    g2d_nativeContext.globalCompositeOperation = "multiply"
                case GBlendMode.SCREEN:
                    g2d_nativeContext.globalCompositeOperation = "screen";
                case GBlendMode.ADD:
                    g2d_nativeContext.globalCompositeOperation = "lighter";
                default:
                    g2d_nativeContext.globalCompositeOperation = "source-over";
            }
        }


    }

    public function dispose():Void {

    }

    public function clearStencil():Void {

    }

    public function renderToStencil(p_stencilLayer:Int):Void {
        MGDebug.WARNING("Not implemented.");
    }

    public function renderToColor(p_stencilLayer:Int):Void {
        MGDebug.WARNING("Not implemented.");
    }

    public function setRenderTarget(p_texture:GTexture = null, p_transform:GMatrix3D = null, p_clear:Bool = false):Void {
        MGDebug.WARNING("Not implemented.");
    }

    public function setRenderTargets(p_textures:Array<GTexture>, p_transform:GMatrix3D = null, p_clear:Bool = false):Void {
        MGDebug.WARNING("Not implemented.");
    }

    public function getRenderTarget():GTexture {
        return null;
    }

    public function getRenderTargetMatrix():GMatrix3D {
        return null;
    }

    public function setRenderer(p_renderer:IGRenderer):Void {
        MGDebug.WARNING("Not implemented.");
    }

    public function flushRenderer():Void {
    }

    public function getRenderer():IGRenderer {
        MGDebug.WARNING("Not implemented.");

        return null;
    }

    private var g2d_nextFrameCallback:Void->Void;
    public function callNextFrame(p_callback:Void->Void):Void {
        g2d_nextFrameCallback = p_callback;
    }

    private function g2d_enterFrameHandler():Void {
        var currentTime:Float = Date.now().getTime();
        g2d_currentDeltaTime = currentTime - g2d_currentTime;
        g2d_currentTime = currentTime;
        g2d_stats.render(this);
        if (g2d_nextFrameCallback != null) {
            var callback:Void->Void = g2d_nextFrameCallback;
            g2d_nextFrameCallback = null;
            callback();
        }
        onFrame.dispatch(g2d_currentDeltaTime);
        GRequestAnimationFrame.request(g2d_enterFrameHandler);
    }

    private function g2d_mouseEventHandler(event:Event):Void {
        var captured:Bool = false;
        event.preventDefault();
        event.stopPropagation();
        var mx:Float;
        var my:Float;
        var buttonDown:Bool = false;
        var ctrlKey:Bool = false;
        var altKey:Bool = false;
        var shiftKey:Bool = false;
        var delta:Float = 0;
        if (Std.is(event,WheelEvent)) {
            var we:WheelEvent = cast event;
            var rect:DOMRect = g2d_nativeStage.getBoundingClientRect();
            mx = we.pageX - rect.left;//g2d_nativeStage.offsetLeft;
            my = we.pageY - rect.top;//g2d_nativeStage.offsetTop;
            buttonDown = we.buttons & 1 == 1;
            ctrlKey = we.ctrlKey;
            altKey = we.altKey;
            shiftKey = we.shiftKey;
            delta = we.deltaY;
        } else if (Std.is(event,MouseEvent)) {
            var me:MouseEvent = cast event;
            var rect:DOMRect = g2d_nativeStage.getBoundingClientRect();
            mx = me.pageX - rect.left;//g2d_nativeStage.offsetLeft;
            my = me.pageY - rect.top;//g2d_nativeStage.offsetTop;
            buttonDown = me.buttons & 1 == 1;
            ctrlKey = me.ctrlKey;
            altKey = me.altKey;
            shiftKey = me.shiftKey;
        } else {
            var te:TouchEvent = cast event;
            mx = te.targetTouches[0].pageX;
            my = te.targetTouches[0].pageY;
            ctrlKey = te.ctrlKey;
            altKey = te.altKey;
            shiftKey = te.shiftKey;
        }

        var input:GMouseInput = new GMouseInput(this, this, GMouseInputType.fromNative(event.type), mx, my);
        input.worldX = input.contextX = mx;
        input.worldY = input.contextY = my;
        input.buttonDown = buttonDown;
        input.ctrlKey = ctrlKey;
        input.altKey = altKey;
        input.shiftKey = shiftKey;
        input.delta = 0;
        input.nativeCaptured = captured;

        onMouseInput.dispatch(input);
        g2d_onMouseInputInternal(input);
    }

    private function g2d_keyboardEventHandler(event:Event):Void {
        event.preventDefault();
        event.stopPropagation();

        var keyEvent:KeyboardEvent = cast event;

        var input:GKeyboardInput = new GKeyboardInput(GKeyboardInputType.fromNative(event.type), keyEvent.keyCode, keyEvent.charCode);
        onKeyboardInput.dispatch(input);
    }

    public function setDepthTest(p_depthMask:Bool, p_depthFunc:GDepthFunc):Void {

    }

    private function gotFocus():Void {

    }

    private function lostFocus():Void {

    }
}
#end