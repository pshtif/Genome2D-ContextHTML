/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.context;

import js.html.WheelEvent;
import js.html.DOMRect;
import com.genome2d.context.renderers.GTriangleTextureBufferCPURenderer;
import com.genome2d.context.renderers.GMatrixQuadTextureShaderRenderer;
import com.genome2d.context.GCamera;
import com.genome2d.context.GDepthFunc;
import com.genome2d.geom.GVector3D;
import com.genome2d.macros.MGDebug;
import js.html.CanvasElement;
import js.html.TouchEvent;
import js.html.Float32Array;
import js.html.Event;
import js.html.MouseEvent;
import js.html.KeyboardEvent;
import js.html.webgl.RenderingContext;
import js.Browser;

import com.genome2d.callbacks.GCallback.GCallback0;
import com.genome2d.callbacks.GCallback.GCallback1;
import com.genome2d.callbacks.GCallback.GCallback2;
import com.genome2d.input.IGFocusable;
import com.genome2d.textures.GTexture;
import com.genome2d.context.IGRenderer;
import com.genome2d.context.renderers.GRendererCommon;
import com.genome2d.geom.GMatrix3D;
import com.genome2d.context.stats.GStats;
import com.genome2d.context.stats.IGStats;
import com.genome2d.geom.GRectangle;
import com.genome2d.input.GKeyboardInput;
import com.genome2d.input.GKeyboardInputType;
import com.genome2d.input.GMouseInput;
import com.genome2d.input.GMouseInputType;
import com.genome2d.context.filters.GFilter;
import com.genome2d.context.renderers.GQuadTextureShaderRenderer;

#if webglonly
@:native("com.genome2d.context.IGContext")
#end
class GWebGLContext
#if !webglonly
implements IGContext
#else
implements IGFocusable
#end
{
    public function hasFeature(p_feature:Int):Bool {
        switch (p_feature) {
            case GContextFeature.RECTANGLE_TEXTURES:
                return true;
        }

        return false;
    }

    private var g2d_projectionMatrix:GProjectionMatrix;
    private var g2d_reinitialize:Int = 0;
    private var g2d_depthTestEnabled:Bool = false;

    private var g2d_nativeStage:CanvasElement;
    public function getNativeStage():CanvasElement {
        return g2d_nativeStage;
    }

    private var g2d_nativeContext:RenderingContext;
    inline public function getNativeContext():RenderingContext {
        return g2d_nativeContext;
    }

    private var g2d_drawRenderer:GQuadTextureShaderRenderer;
    private var g2d_matrixQuadTextureShaderRenderer:GMatrixQuadTextureShaderRenderer;
    private var g2d_triangleTextureBufferCPURenderer:GTriangleTextureBufferCPURenderer;

    private var g2d_activeRenderer:IGRenderer;
    private var g2d_activeBlendMode:GBlendMode;
    private var g2d_activePremultiply:Bool;
    private var g2d_activeMaskRect:GRectangle;

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

    private var g2d_activeCamera:GCamera;
    public function getActiveCamera():GCamera {
        return g2d_activeCamera;
    }
    private var g2d_defaultCamera:GCamera;
    public function getDefaultCamera():GCamera {
        return g2d_defaultCamera;
    }

    private var g2d_currentDeltaTime:Float;
    private var g2d_currentTime:Float;
    private var g2d_stats:IGStats;

    private var g2d_stageViewRect:GRectangle;
    inline public function getStageViewRect():GRectangle {
        return g2d_stageViewRect;
    }
    private var g2d_activeViewRect:GRectangle;

    public var onInitialized(default,null):GCallback0;
    public var onFailed(default,null):GCallback1<String>;
    public var onInvalidated(default, null):GCallback0;
    public var onResize(default,null):GCallback2<Int,Int>;
    public var onFrame(default,null):GCallback1<Float>;
    public var onMouseInput(default,null):GCallback1<GMouseInput>;
    public var onKeyboardInput(default,null):GCallback1<GKeyboardInput>;
    public var onVisibilityChange(default,null):GCallback1<Bool>;

    public var preventDefaultKeyboard:Bool = true;

    private var g2d_lastMouseButtonsDown:Int = 0;
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
        onVisibilityChange = new GCallback1<Bool>();
    }

    public function init():Void {
        try {
            g2d_nativeContext = g2d_nativeStage.getContext("webgl");
            if (g2d_nativeContext == null) g2d_nativeContext = g2d_nativeStage.getContext("webgl");
        } catch (e:Dynamic) {
        }

        if (g2d_nativeContext == null) {
            onFailed.dispatch("No WebGL support detected.");
            return;
        }

        GRendererCommon.init();

        g2d_drawRenderer = new GQuadTextureShaderRenderer();
        g2d_matrixQuadTextureShaderRenderer = new GMatrixQuadTextureShaderRenderer();
        g2d_triangleTextureBufferCPURenderer = new GTriangleTextureBufferCPURenderer();

        g2d_defaultCamera = new GCamera();
        g2d_defaultCamera.x = g2d_stageViewRect.width / 2;
        g2d_defaultCamera.y = g2d_stageViewRect.height / 2;

        g2d_activeViewRect = new GRectangle();
        g2d_currentTime = Date.now().getTime();

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
        g2d_nativeStage.addEventListener("contextmenu", g2d_contextEventHandler);

        Browser.window.addEventListener("keyup", g2d_keyboardEventHandler);
        Browser.window.addEventListener("keydown", g2d_keyboardEventHandler);
        /**/

        Browser.document.addEventListener("visibilitychange", g2d_visibilityChange_handler);

        g2d_nativeContext.pixelStorei(RenderingContext.UNPACK_PREMULTIPLY_ALPHA_WEBGL, RenderingContext.ONE);

        onInitialized.dispatch();
        GRequestAnimationFrame.request(g2d_enterFrameHandler);
    }

    public function resize(p_rect:GRectangle):Void {
        g2d_stageViewRect = p_rect;

        g2d_defaultCamera.x = g2d_stageViewRect.width/2;
        g2d_defaultCamera.y = g2d_stageViewRect.height/2;

        onResize.dispatch(Std.int(g2d_stageViewRect.width), Std.int(g2d_stageViewRect.height));
    }

    public function setActiveCamera(p_camera:GCamera):Bool {
        if (g2d_stageViewRect.width*p_camera.normalizedViewWidth <= 0 ||
        g2d_stageViewRect.height*p_camera.normalizedViewHeight <= 0) return false;

        if (g2d_activeRenderer != null) g2d_activeRenderer.push();

        g2d_activeCamera = p_camera;

        g2d_activeViewRect.setTo(Std.int(g2d_stageViewRect.width*g2d_activeCamera.normalizedViewX),
        Std.int(g2d_stageViewRect.height*g2d_activeCamera.normalizedViewY),
        Std.int(g2d_stageViewRect.width*g2d_activeCamera.normalizedViewWidth),
        Std.int(g2d_stageViewRect.height*g2d_activeCamera.normalizedViewHeight));

        var vx:Float = g2d_activeViewRect.x + g2d_activeViewRect.width*.5;
        var vy:Float = g2d_activeViewRect.y + g2d_activeViewRect.height * .5;

        g2d_projectionMatrix = new GProjectionMatrix();
        g2d_projectionMatrix.ortho(g2d_stageViewRect.width, g2d_stageViewRect.height);

        g2d_projectionMatrix.prependTranslation(vx, vy, 0);
        g2d_projectionMatrix.prependRotation(g2d_activeCamera.rotation*180/Math.PI, GVector3D.Z_AXIS, new GVector3D());
        g2d_projectionMatrix.prependScale(g2d_activeCamera.scaleX, g2d_activeCamera.scaleY, 1);
        g2d_projectionMatrix.prependTranslation(-g2d_activeCamera.x, -g2d_activeCamera.y, 0);

        g2d_projectionMatrix.transpose();
        g2d_nativeContext.scissor(Std.int(g2d_activeViewRect.x), Std.int(g2d_stageViewRect.height-g2d_activeViewRect.height-g2d_activeViewRect.y), Std.int(g2d_activeViewRect.width), Std.int(g2d_activeViewRect.height));

        return true;
    }

    inline public function getMaskRect():GRectangle {
        return g2d_activeMaskRect;
    }
    inline public function setMaskRect(p_maskRect:GRectangle):Void {
        if (p_maskRect != g2d_activeMaskRect || ((p_maskRect != null && g2d_activeMaskRect != null) && (p_maskRect.width != g2d_activeMaskRect.width || p_maskRect.height != g2d_activeMaskRect.height && p_maskRect.x != g2d_activeMaskRect.x || p_maskRect.y != g2d_activeMaskRect.y))) {
            if (g2d_activeRenderer != null) g2d_activeRenderer.push();

            if (p_maskRect == null) {
                g2d_activeMaskRect = null;
                g2d_nativeContext.scissor(0, 0, Std.int(g2d_activeViewRect.width), Std.int(g2d_activeViewRect.height));
            } else {
                g2d_activeMaskRect = g2d_activeViewRect.intersection(new GRectangle(p_maskRect.x + g2d_activeViewRect.x + g2d_activeViewRect.width * .5 - g2d_activeCamera.x * g2d_activeCamera.scaleX, p_maskRect.y + g2d_activeViewRect.y + g2d_activeViewRect.height * .5 - g2d_activeCamera.y * g2d_activeCamera.scaleY, p_maskRect.width, p_maskRect.height));
                g2d_nativeContext.scissor(Std.int(g2d_activeMaskRect.x), Std.int(g2d_activeViewRect.height-g2d_activeMaskRect.y-g2d_activeMaskRect.height), Std.int(g2d_activeMaskRect.width), Std.int(g2d_activeMaskRect.height));
            }
        }
    }

    public function begin():Bool {
        g2d_stats.clear();
        g2d_activeRenderer = null;
        g2d_activePremultiply = true;
        g2d_activeBlendMode = GBlendMode.NORMAL;

        setActiveCamera(g2d_defaultCamera);
        g2d_nativeContext.viewport(0, 0, Std.int(g2d_stageViewRect.width), Std.int(g2d_stageViewRect.height));

        g2d_nativeContext.clearColor(g2d_backgroundRed, g2d_backgroundGreen, g2d_backgroundBlue, g2d_backgroundAlpha);
        g2d_nativeContext.clear(RenderingContext.COLOR_BUFFER_BIT | RenderingContext.DEPTH_BUFFER_BIT);
        setDepthTest(false, GDepthFunc.ALWAYS);
        g2d_nativeContext.enable(RenderingContext.BLEND);
        g2d_nativeContext.enable(RenderingContext.SCISSOR_TEST);
        // Culling is not necessary for 2D and we can also run into issue due to flipped FBOs
        g2d_nativeContext.disable(RenderingContext.CULL_FACE);
        //g2d_nativeContext.cullFace(RenderingContext.FRONT);
        GBlendModeFunc.setBlendMode(g2d_nativeContext, GBlendMode.NORMAL, true);

        return true;
    }

    inline public function draw(p_texture:GTexture, p_blendMode:GBlendMode, p_x:Float, p_y:Float, p_scaleX:Float = 1, p_scaleY:Float = 1, p_rotation:Float = 0, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float = 1, p_filter:GFilter = null):Void {
        if (p_alpha != 0) {
            setBlendMode(p_blendMode, p_texture.premultiplied);
            setRenderer(g2d_drawRenderer);

            g2d_drawRenderer.draw(p_x, p_y, p_scaleX, p_scaleY, p_rotation, p_red, p_green, p_blue, p_alpha, p_texture, p_filter, false, 0, 0, 0, 0, 0, 0);
        }
    }

    inline public function drawMatrix(p_texture:GTexture, p_blendMode:GBlendMode, p_a:Float, p_b:Float, p_c:Float, p_d:Float, p_tx:Float, p_ty:Float, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float=1, p_filter:GFilter = null):Void {
        if (p_alpha != 0) {
            setBlendMode(p_blendMode, p_texture.premultiplied);
            setRenderer(g2d_matrixQuadTextureShaderRenderer);
            g2d_matrixQuadTextureShaderRenderer.draw(p_a, p_b, p_c, p_d, p_tx, p_ty, p_red, p_green, p_blue, p_alpha, p_texture, p_filter, false, 0, 0, 0, 0);
        }
        /**/
    }

    public function drawSource(p_texture:GTexture, p_blendMode:GBlendMode, p_sourceX:Float, p_sourceY:Float, p_sourceWidth:Float, p_sourceHeight:Float, p_sourcePivotX:Float, p_sourcePivotY:Float, p_x:Float, p_y:Float, p_scaleX:Float = 1, p_scaleY:Float = 1, p_rotation:Float = 0, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float = 1, p_filter:GFilter = null):Void {
        if (p_alpha != 0) {
            setBlendMode(p_blendMode, p_texture.premultiplied);
            setRenderer(g2d_drawRenderer);

            g2d_drawRenderer.draw(p_x, p_y, p_scaleX, p_scaleY, p_rotation, p_red, p_green, p_blue, p_alpha, p_texture, p_filter, true, p_sourceX, p_sourceY, p_sourceWidth, p_sourceHeight, p_sourcePivotX, p_sourcePivotY);
        }
    }

    inline public function drawPoly(p_texture:GTexture, p_blendMode:GBlendMode, p_vertices:Array<Float>, p_uvs:Array<Float>, p_x:Float, p_y:Float, p_scaleX:Float = 1, p_scaleY:Float = 1, p_rotation:Float = 0, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float = 1, p_filter:GFilter = null):Void {
        if (p_alpha != 0) {
            setBlendMode(p_blendMode, p_texture.premultiplied);
            setRenderer(g2d_triangleTextureBufferCPURenderer);

            g2d_triangleTextureBufferCPURenderer.draw(p_vertices, p_uvs, p_x, p_y, p_scaleX, p_scaleY, p_rotation, p_red, p_green, p_blue, p_alpha, p_texture, p_filter);
        }
    }

    public function end():Void {
        flushRenderer();
    }

    inline public function setRenderer(p_renderer:IGRenderer):Void {
        if(p_renderer != g2d_activeRenderer || g2d_activeRenderer == null) {
            flushRenderer();
            g2d_activeRenderer = p_renderer;
            g2d_activeRenderer.bind(this, g2d_reinitialize);
        }
    }

    inline public function getRenderer():IGRenderer {
        return g2d_activeRenderer;
    }

    public function flushRenderer():Void {
        if(g2d_activeRenderer != null) {
            g2d_activeRenderer.push();
            g2d_activeRenderer.clear();
        }
    }

    public function clearStencil():Void {

    }

    public function renderToStencil(p_stencilLayer:Int):Void {

    }

    public function renderToColor(p_stencilLayer:Int):Void {

    }

    private var g2d_renderTarget:GTexture;
    private var g2d_renderTargetMatrix:GMatrix3D;
    private var g2d_usedRenderTargets:Int = 0;

    public function getRenderTargetMatrix():GMatrix3D {
        return null;
    }

    public function getRenderTarget():GTexture {
        return null;
    }

    public function setRenderTarget(p_texture:GTexture = null, p_transform:GMatrix3D = null, p_clear:Bool = true):Void {
        // Check if we aren't setting it to the same texture while not using MRT
        if (g2d_renderTarget == p_texture && g2d_usedRenderTargets == 0) return;

        // If there is any active renderer we will push it to the current target
        if (g2d_activeRenderer != null) {
            g2d_activeRenderer.push();
            g2d_activeRenderer = null;
        }

        // Doesn't support MRT yet but we will reset it anyway
        g2d_usedRenderTargets = 0;

        // If the target is null its a backbuffer
        if (p_texture == null) {
            g2d_nativeContext.bindFramebuffer(RenderingContext.FRAMEBUFFER, null);
            g2d_nativeContext.viewport(0, 0, Std.int(g2d_stageViewRect.width), Std.int(g2d_stageViewRect.height));
            g2d_nativeContext.enable(RenderingContext.SCISSOR_TEST);

            // Reset camera
            setActiveCamera(g2d_activeCamera);
            // Otherwise its a render texture
        } else {
            if (p_texture.nativeTexture == null) MGDebug.G2D_WARNING("Null render texture, will incorrectly render to backbuffer instead.");
            g2d_nativeContext.bindFramebuffer(RenderingContext.FRAMEBUFFER, p_texture.getFrameBuffer());
            g2d_nativeContext.viewport(0, 0, Std.int(p_texture.nativeWidth), Std.int(p_texture.nativeHeight));
            if (p_texture.needClearAsRenderTarget(p_clear)) {
                g2d_nativeContext.clearColor(0, 0, 0, 0);
                g2d_nativeContext.clear(RenderingContext.COLOR_BUFFER_BIT | RenderingContext.DEPTH_BUFFER_BIT);
            }

            if (p_transform != null) MGDebug.G2D_WARNING("setRenderTarget p_transform argument is not supported for this target.");
            g2d_projectionMatrix = new GProjectionMatrix();
            g2d_projectionMatrix.orthoRtt(p_texture.nativeWidth, p_texture.nativeHeight);
            g2d_projectionMatrix.transpose();
            g2d_nativeContext.disable(RenderingContext.SCISSOR_TEST);
        }

        g2d_renderTargetMatrix = p_transform;
        g2d_renderTarget = p_texture;
    }

    public function setRenderTargets(p_textures:Array<GTexture>, p_transform:GMatrix3D = null, p_clear:Bool = false):Void {

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
        var isRight:Bool = false;
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
            if (we.deltaMode != 1) {
                delta = 3*delta/Math.abs(delta);
            }
        } else if (Std.is(event,MouseEvent)) {
            var me:MouseEvent = cast event;
            var rect:DOMRect = g2d_nativeStage.getBoundingClientRect();
            mx = me.pageX - rect.left;//g2d_nativeStage.offsetLeft;
            my = me.pageY - rect.top;//g2d_nativeStage.offsetTop;
            buttonDown = me.buttons & 1 == 1;
            // Right down check
            if (me.buttons & 2 == 2) {
                buttonDown = isRight = true;
            }
            // Right up check
            if ((g2d_lastMouseButtonsDown & 2 == 2) && (me.buttons & 2 != 2)) {
                isRight = true;
            }
            ctrlKey = me.ctrlKey;
            altKey = me.altKey;
            shiftKey = me.shiftKey;
            g2d_lastMouseButtonsDown = me.buttons;

        } else {
            var te:TouchEvent = cast event;

            // For the touchstart event, it is a list of the touch points that became active with the current event.
            // For the touchmove event, it is a list of the touch points that have changed since the last event.
            // For the touchend event, it is a list of the touch points that have been removed from the surface (that is, the set of touch points corresponding to fingers no longer touching the surface).
            if (te.targetTouches != null && te.targetTouches.length > 0) {
                mx = te.targetTouches[0].pageX;
                my = te.targetTouches[0].pageY;
            } else if (te.changedTouches != null && te.changedTouches.length > 0) {
                mx = te.changedTouches[0].pageX;
                my = te.changedTouches[0].pageY;
            } else {
                mx = 0;
                my = 0;
            }

            var rect:DOMRect = g2d_nativeStage.getBoundingClientRect();
            mx = mx - rect.left;//g2d_nativeStage.offsetLeft;
            my = my - rect.top;//g2d_nativeStage.offsetTop;

            // The Window property devicePixelRatio returns the ratio of the resolution in physical pixels to the
            // resolution in CSS pixels for the current display device. This value could also be interpreted as the
            // ratio of pixel sizes: the size of one CSS pixel to the size of one physical pixel. In simpler terms,
            // this tells the browser how many of the screen's actual pixels should be used to draw a single CSS pixel.
            // This is useful when dealing with the difference between rendering on a standard display versus a HiDPI
            // or Retina display, which use more screen pixels to draw the same objects, resulting in a sharper image.
            mx *= Browser.window.devicePixelRatio;
            my *= Browser.window.devicePixelRatio;

            ctrlKey = te.ctrlKey;
            altKey = te.altKey;
            shiftKey = te.shiftKey;
        }

        var input:GMouseInput = null;
        if (isRight) {
            if (buttonDown) {
                input = new GMouseInput(this, this, GMouseInputType.fromNative("rightMouseDown"), mx, my);
            } else {
                input = new GMouseInput(this, this, GMouseInputType.fromNative("rightMouseUp"), mx, my);
            }
        } else {
            input = new GMouseInput(this, this, GMouseInputType.fromNative(event.type), mx, my);
        }
        input.worldX = input.contextX = mx;
        input.worldY = input.contextY = my;
        input.buttonDown = buttonDown;
        input.ctrlKey = ctrlKey;
        input.altKey = altKey;
        input.shiftKey = shiftKey;
        input.delta = -Std.int(delta);
        input.nativeCaptured = captured;
        onMouseInput.dispatch(input);
        g2d_onMouseInputInternal(input);
    }

    private function g2d_contextEventHandler(event:Event):Void {
        event.preventDefault();
    }

    private function g2d_visibilityChange_handler(event:Event):Void {
        onVisibilityChange.dispatch(Browser.document.hidden);
    }

    private function g2d_keyboardEventHandler(event:Event):Void {
        if (preventDefaultKeyboard) {
            event.preventDefault();
            event.stopPropagation();
        }

        var keyEvent:KeyboardEvent = cast event;

        var input:GKeyboardInput = new GKeyboardInput(GKeyboardInputType.fromNative(event.type), keyEvent.keyCode, keyEvent.key.charCodeAt(0));
        onKeyboardInput.dispatch(input);
    }

    public function dispose():Void {
        g2d_onMouseInputInternal = null;
    }

    public function setDepthTest(p_depthMask:Bool, p_depthFunc:GDepthFunc):Void {
        if (p_depthMask != g2d_depthTestEnabled) {
            if (p_depthMask) {
                g2d_nativeContext.enable(RenderingContext.DEPTH_TEST);
                switch (p_depthFunc) {
                    case GDepthFunc.EQUAL:
                        g2d_nativeContext.depthFunc(RenderingContext.EQUAL);
                    case GDepthFunc.GEQUAL:
                        g2d_nativeContext.depthFunc(RenderingContext.GEQUAL);
                    case GDepthFunc.GREATER:
                        g2d_nativeContext.depthFunc(RenderingContext.GREATER);
                    case GDepthFunc.LEQUAL:
                        g2d_nativeContext.depthFunc(RenderingContext.LEQUAL);
                    case GDepthFunc.LESS:
                        g2d_nativeContext.depthFunc(RenderingContext.LESS);
                    case GDepthFunc.NEVER:
                        g2d_nativeContext.depthFunc(RenderingContext.NEVER);
                    case GDepthFunc.NOTEQUAL:
                        g2d_nativeContext.depthFunc(RenderingContext.NOTEQUAL);
                    case GDepthFunc.ALWAYS:
                        g2d_nativeContext.depthFunc(RenderingContext.ALWAYS);

                }
            } else {
                g2d_nativeContext.disable(RenderingContext.DEPTH_TEST);
            }
            g2d_depthTestEnabled = p_depthMask;
        }
    }

    public function setBlendMode(p_blendMode:GBlendMode, p_premultiplied:Bool):Void {
        if (p_blendMode != g2d_activeBlendMode || p_premultiplied != g2d_activePremultiply) {
            if (g2d_activeRenderer != null) {
                g2d_activeRenderer.push();
            }

            g2d_activeBlendMode = p_blendMode;
            g2d_activePremultiply = p_premultiplied;
            GBlendModeFunc.setBlendMode(g2d_nativeContext, g2d_activeBlendMode, g2d_activePremultiply);
        }
    }

    private function gotFocus():Void {

    }

    private function lostFocus():Void {

    }
}