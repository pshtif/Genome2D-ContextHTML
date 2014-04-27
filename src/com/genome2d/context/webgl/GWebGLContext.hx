package com.genome2d.context.webgl;
import com.genome2d.context.webgl.materials.GMaterialCommon;
import js.html.webgl.UniformLocation;
import js.html.Float32Array;
import com.genome2d.geom.GMatrix3D;
import com.genome2d.context.stats.GStats;
import com.genome2d.textures.GContextTexture;
import com.genome2d.signals.GMouseSignalType;
import js.html.Event;
import js.html.MouseEvent;
import com.genome2d.context.stats.IStats;
import com.genome2d.geom.GRectangle;
import com.genome2d.signals.GKeyboardSignal;
import com.genome2d.signals.GMouseSignal;
import js.html.CanvasElement;
import com.genome2d.context.filters.GFilter;
import com.genome2d.context.webgl.materials.GDrawTextureCameraVertexShaderBatchMaterial;
import js.html.webgl.RenderingContext;
/**
 * ...
 * @author Peter "sHTiF" Stefcek
 */
class GWebGLContext implements IContext
{
    public function hasFeature(p_feature:Int):Bool {
        return false;
    }

    private var g2d_projectionMatrix:Float32Array;

    private var g2d_nativeStage:CanvasElement;
    public function getNativeStage():CanvasElement {
        return g2d_nativeStage;
    }

	private var g2d_nativeContext:RenderingContext;
    inline public function getNativeContext():RenderingContext {
        return g2d_nativeContext;
    }

	private var g2d_drawMaterial:GDrawTextureCameraVertexShaderBatchMaterial;

    private var g2d_activeCamera:GContextCamera;
    private var g2d_defaultCamera:GContextCamera;
    public function getDefaultCamera():GContextCamera {
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

    private var g2d_onInitialized:Void->Void;
    public function onInitialized(p_callback:Void->Void):Void {
        g2d_onInitialized = p_callback;
    }
    private var g2d_onFailed:String->Void;
    public function onFailed(p_callback:String->Void):Void {
        g2d_onFailed = p_callback;
    }
    private var g2d_onInvalidated:Void->Void;
    public function onInvalidated(p_callback:Void->Void):Void {
        g2d_onInvalidated = p_callback;
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
        try {
            g2d_nativeContext = g2d_nativeStage.getContext("webgl");
            if (g2d_nativeContext == null) g2d_nativeContext = g2d_nativeStage.getContext("experimental-webgl");
        } catch (e:Dynamic) {
        }

        if (g2d_nativeContext == null) {
            if (g2d_onFailed != null) g2d_onFailed("No WebGL support detected.");
            return;
        }

        GMaterialCommon.init();

        g2d_drawMaterial = new GDrawTextureCameraVertexShaderBatchMaterial();
        g2d_drawMaterial.initialize(g2d_nativeContext);

        g2d_defaultCamera = new GContextCamera();
        g2d_defaultCamera.x = g2d_stageViewRect.width/2;
        g2d_defaultCamera.y = g2d_stageViewRect.height/2;

        g2d_activeViewRect = new GRectangle();
        g2d_currentTime = Date.now().getTime();

        g2d_nativeStage.addEventListener("mousedown", g2d_mouseEventHandler);
        g2d_nativeStage.addEventListener("mouseup", g2d_mouseEventHandler);
        g2d_nativeStage.addEventListener("mousemove", g2d_mouseEventHandler);
/*
		g2d_stage.addEventListener("touchstart", onTouchEvent);
		g2d_stage.addEventListener("touchend", onTouchEvent);
		g2d_stage.addEventListener("touchmove", onTouchEvent);
		/**/

        GRequestAnimationFrame.request(g2d_enterFrameHandler);
        if (g2d_onInitialized != null) g2d_onInitialized();
    }

    public function setCamera(p_camera:GContextCamera):Void {

    }

    public function getMaskRect():GRectangle {
        return null;
    }
    public function setMaskRect(p_maskRect:GRectangle):Void {

    }
	
	public function begin(p_red:Float, p_green:Float, p_blue:Float, p_alpha:Float, p_useDefaultCamera:Bool = true):Void {
        g2d_nativeContext.viewport(0, 0, Std.int(g2d_stageViewRect.width), Std.int(g2d_stageViewRect.height));

        // Move to camera
        g2d_projectionMatrix = new Float32Array([2.0/g2d_stageViewRect.width, 0.0, 0.0, -1.0,
                                                 0.0, -2.0/g2d_stageViewRect.height, 0.0, 1.0,
                                                 0.0, 0.0, 1.0, 0.0,
                                                 0.0, 0.0, 0.0, 1.0]);

		g2d_nativeContext.clearColor(p_red, p_green, p_blue, p_alpha);
        g2d_nativeContext.clear(RenderingContext.COLOR_BUFFER_BIT | RenderingContext.DEPTH_BUFFER_BIT);
        g2d_nativeContext.disable(RenderingContext.DEPTH_TEST);
        g2d_nativeContext.enable(RenderingContext.BLEND);
        g2d_nativeContext.blendFunc(RenderingContext.SRC_ALPHA, RenderingContext.ONE_MINUS_SRC_ALPHA);
    }
	
	public function draw(p_texture:GContextTexture, p_x:Float, p_y:Float, p_scaleX:Float = 1, p_scaleY:Float = 1, p_rotation:Float = 0, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float = 1, p_blendMode:Int = 1, p_filter:GFilter = null):Void {
        g2d_drawMaterial.bind(g2d_projectionMatrix);
        g2d_drawMaterial.draw(p_x, p_y, p_scaleX, p_scaleY, p_rotation, p_texture);
    }

    public function drawMatrix(p_texture:GContextTexture, p_a:Float, p_b:Float, p_c:Float, p_d:Float, p_tx:Float, p_ty:Float, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float=1, p_blendMode:Int=1, p_filter:GFilter = null):Void {

    }

    public function drawPoly(p_texture:GContextTexture, p_vertices:Array<Float>, p_uvs:Array<Float>, p_x:Float, p_y:Float, p_scaleX:Float, p_scaleY:Float, p_rotation:Float, p_red:Float = 1, p_green:Float = 1, p_blue:Float = 1, p_alpha:Float = 1, p_blendMode:Int=1, p_filter:GFilter = null):Void {

    }
	
	public function end():Void {
		g2d_drawMaterial.push();
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
        //g2d_stats.render(this);

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

    public function dispose():Void {

    }
}