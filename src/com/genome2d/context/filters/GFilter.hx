package com.genome2d.context.filters;
import com.genome2d.textures.GTexture;

class GFilter {
    public var g2d_id:String;
    public var overrideFragmentShader:Bool = false;
    public var fragmentCode:String = "";

    private var g2d_fragmentConstants:Array<Float>;

    private function new() {
        g2d_id = Std.string(Type.getClass(this));
        //g2d_fragmentConstants = new Vector<Float>();
    }
/*
    public function bind(p_context:Context3D, p_texture:GTexture):Void {
        p_context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, g2d_fragmentConstants, Std.int(g2d_fragmentConstants.length/4));
    }

    public function clear(p_context:Context3D):Void {}
/**/
}
