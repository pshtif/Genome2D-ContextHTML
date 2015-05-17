/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.context.webgl;

import js.html.TouchEvent;
import com.genome2d.context.webgl.renderers.IGRenderer;
import msignal.Signal.Signal0;
import msignal.Signal.Signal1;
import com.genome2d.context.webgl.renderers.GRendererCommon;
import js.html.Float32Array;
import com.genome2d.geom.GMatrix3D;
import com.genome2d.context.stats.GStats;
import com.genome2d.textures.GContextTexture;
import com.genome2d.input.GMouseInputType;
import js.html.Event;
import js.html.MouseEvent;
import com.genome2d.context.stats.IStats;
import com.genome2d.geom.GRectangle;
import com.genome2d.signals.GKeyboardInput;
import com.genome2d.input.GMouseInput;
import js.html.CanvasElement;
import com.genome2d.context.filters.GFilter;
import com.genome2d.context.webgl.renderers.GQuadTextureShaderRenderer;
import js.html.webgl.RenderingContext;

#if webglonly
class GWebGLContext
#else
class GWebGLContext implements IContext
#end
{
    public function hasFeature(p_feature:Int):Bool {
        switch (p_feature) {
            case GContextFeature.RECTANGLE_TEXTURES:
                return true;
        }

        return false;
    }

    private var g2d_projectionMatrix:Float32Array;
    private var g2d_reinitialize:Bool = false;

    private var g2d_nativeStage:CanvasElement;
    public function getNativeStage():CanvasElement {
        return g2d_nativeStage;
    }

	private var g2d_nativeContext:RenderingContext;
    inline public function getNativeContext():RenderingContext {
        return g2d_nativeContext;
    }

	private var g2d_drawRenderer:GQuadTextureShaderRenderer;

    private var g2d_activeRenderer:IGRenderer;

    private var g2d_backgroundRed:Float = 0;
    private var g2d_backgroundGreen:Float = 0;
    private var g2d_backgroundBlue:Float = 0;
    private var g2d_backgroundAlpha:Float = 1;
    public function setBackgroundRGBA(p_color:Int, p_alpha:Float = 1):Void {
        g2d_backgroundRed = Std.int(p_color >> 16 & 0xFF) / 0xFF;
        g2d_backgroundGreen = Std.int(p_color >> 8 & 0xFF) / 0xFF;
        g2d_backgroundBlue = Std.int(p_color & 0xFF) / 0xFF;
        g2d_backgroundAlpha = p_alpha;
    }

    private var g2d_activeCamera:GCamera;
    private var g2d_defaultCamera:GCamera;
    public function getDefaultCamera():GCamera {
        return g2d_defaultCamera;
    }

    private var g2d_currentDeltaTime:Float;
    private var g2d_currentTime:Float;
    private var g2d_stats:IStats;

    private var g2d_stageViewRect:GRectangle;
    inline public function getStageViewRect():GRectangle {
        return g2d_stageViewRect;
    }
    private var g2d_activeViewRect:GRectangle;

    public var onInitialized(default,null):Signal0;
    public var onFailed(default,null):Signal1<String>;
    public var onInvalidated(default,null):Signal0;
    public var onFrame(default,null):Signal1<Float>;
    public var onMouseSignal(default,null):Signal1<GMouseInput>;
    public var onKeyboardSignal(default,null):Signal1<GKeyboardInput>;

	public function new(p_config:GContextConfig) {
        g2d_nativeStage = p_config.nativeStage;
        g2d_stageViewRect = p_config.viewRect;
        g2d_stats = new GStats(g2d_nativeStage);

        onInitialized = new Signal0();
        onFailed = new Signal1<String>();
        onInvalidated = new Signal0();
        onFrame = new Signal1<Float>();
        onMouseSignal = new Signal1<GMouseInput>();
        onKeyboardSignal = new Signal1<GKeyboardInput>();
    }
	
	public function init():Void {
        try {
            g2d_nativeContext = g2d_nativeStage.getContext("webgl");
            if (g2d_nativeContext == null) g2d_nativeContext = g2d_nativeStage.getContext("experimental-webgl");
        } catch (e:Dynamic) {
        }

        if (g2d_nativeContext == null) {
            onFailed.dispatch("No WebGL support detected.");
            return;
        }

        GRendererCommon.init();

        g2d_drawRenderer = new GQuadTextureShaderRenderer();

        g2d_defaultCamera = new GCamera();
        g2d_defaultCamera.x = g2d_stageViewRect.width/2;
        g2d_defaultCamera.y = g2d_stageViewRect.height/2;

        g2d_activeViewRect = new GRectangle();
        g2d_currentTime = Date.now().getTime();

        g2d_nativeStage.addEventListener("mousedown", g2d_mouseEventHandler);
        g2d_nativeStage.addEventListener("mouseup", g2d_mouseEventHandler);
        g2d_nativeStage.addEventListener("mousemove", g2d_mouseEventHandler);

		g2d_nativeStage.addEventListener("touchstart", g2d_mouseEventHandler);
		g2d_nativeStage.addEventListener("touchend", g2d_mouseEventHandler);
		g2d_nativeStage.addEventListener("touchmove", g2d_mouseEventHandler);
		/**/

        g2d_nativeContext.pixelStorei(RenderingContext.UNPACK_PREMULTIPLY_ALPHA_WEBGL, RenderingContext.ONE);

        onInitialized.dispatch();
        GRequestAnimationFrame.request(g2d_enterFrameHandler);
    }

    public function setCamera(p_camera:GCamera):Void {
        g2d_projectionMatrix = new Float32Array([2.0/g2d_stageViewRect.width, 0.0, 0.0, -1.0,
                                                0.0, -2.0/g2d_stageViewRect.height, 0.0, 1.0,
                                                0.0, 0.0, 1.0, 0.0,
                                                0.0, 0.0, 0.0, 1.0]);
    }

    public function getMaskRect():GRectangle {
        return null;
    }
    public function setMaskRect(p_maskRect:GRectangle):Void {

    }
	
	public function begin():Void {
        g2d_stats.clear();
        g2d_activeRenderer = null;

        setCamera(g2d_defaultCamera);
        g2d_nativeContext.viewport(0, 0, Std.int(g2d_stageViewRect.width), Std.int(g2d_stageViewRect.height));

		g2d_nativeContext.clearColor(g2d_backgroundRed, g2d_backgroundGreen, g2d_backgroundBlue, g2d_backgroundAlpha);
        g2d_nativeContext.clear(RenderingContext.COLOR_BUFFER_BIT | RenderingContext.DEPTH_BUFFER_BIT);
        g2d_nativeContext.disable(RenderingContext.DEPTH_TEST);
        g2d_nativeContext.enable(RenderingContext.BLEND);
        GBlendMode.setBlendMode(g2d_nativeContext, GBlendMode.NORMAL, true);
    }
	
	inline public function draw(p_texture:GContextTexture, p_x:Float, p_y:Float, p_scaleX:Float = 1, p_scaleY:Float = 1, p_rotation:Float = 0, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float = 1, p_blendMode:Int = 1, p_filter:GFilter = null):Void {
        bindRenderer(g2d_drawRenderer);

        g2d_drawRenderer.draw(p_x, p_y, p_scaleX, p_scaleY, p_rotation, p_red, p_green, p_blue, p_alpha, p_texture);
    }

    public function drawMatrix(p_texture:GContextTexture, p_a:Float, p_b:Float, p_c:Float, p_d:Float, p_tx:Float, p_ty:Float, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float=1, p_blendMode:Int=1, p_filter:GFilter = null):Void {

    }

    public function drawSource(p_texture:GContextTexture, p_sourceX:Float, p_sourceY:Float, p_sourceWidth:Float, p_sourceHeight:Float, p_x:Float, p_y:Float, p_scaleX:Float = 1, p_scaleY:Float = 1, p_rotation:Float = 0, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float = 1, p_blendMode:Int = 1, p_filter:GFilter = null):Void {

    }

    public function drawPoly(p_texture:GContextTexture, p_vertices:Array<Float>, p_uvs:Array<Float>, p_x:Float, p_y:Float, p_scaleX:Float = 1, p_scaleY:Float = 1, p_rotation:Float = 0, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float = 1, p_blendMode:Int=1, p_filter:GFilter = null):Void {

    }

    inline public function bindRenderer(p_renderer:Dynamic):Void {
        if (p_renderer != g2d_activeRenderer || g2d_activeRenderer == null) {
            if (g2d_activeRenderer != null) {
                g2d_activeRenderer.push();
                g2d_activeRenderer.clear();
            }

            g2d_activeRenderer = p_renderer;
            g2d_activeRenderer.bind(this, g2d_reinitialize);
        }
    }
	
	public function end():Void {
        if (g2d_activeRenderer != null) {
            g2d_activeRenderer.push();
            g2d_activeRenderer.clear();
        }

        g2d_reinitialize = false;
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

        onFrame.dispatch(g2d_currentDeltaTime);
        GRequestAnimationFrame.request(g2d_enterFrameHandler);
    }

    private function g2d_mouseEventHandler(event:Event):Void {
        var captured:Bool = false;
        event.preventDefault();
        event.stopPropagation();
        var mx:Float;
        var my:Float;
        if (Std.is(event,MouseEvent)) {
            var me:MouseEvent = cast event;
            mx = me.pageX - g2d_nativeStage.offsetLeft;
            my = me.pageY - g2d_nativeStage.offsetTop;
        } else {
            var te:TouchEvent = cast event;
            mx = te.targetTouches[0].pageX;
            my = te.targetTouches[0].pageY;
        }

        var signal:GMouseInput = new GMouseInput(GMouseInputType.fromNative(event.type), mx, my, captured);// event.buttonDown, event.ctrlKey,
        onMouseSignal.dispatch(signal);
    }

    public function dispose():Void {

    }

    public function setDepthTest(p_depthMask:Bool, p_compareMode:Dynamic):Void {

    }

    public function setRenderTargets(p_textures:Array<GContextTexture>, p_transform:GMatrix3D = null):Void {

    }
}