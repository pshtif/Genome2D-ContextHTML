package com.genome2d.context.filters;
import js.html.webgl.Program;
import js.html.webgl.RenderingContext;
import com.genome2d.textures.GTexture;
class GMaskFilter extends GFilter {

    public var maskTexture:GTexture;
    public var u1:Float = 0;
    public var v1:Float = 0;
    public var u2:Float = 0;
    public var v2:Float = 0;
    public var uRatio:Float = 1;
    public var vRatio:Float = 1;

    public function new() {
        super();

        fragmentCode = "
			precision lowp float;

			varying vec2 vTexCoord;

			uniform sampler2D sTexture;

			uniform sampler2D sMaskTexture;
			uniform vec2 uv1;
			uniform vec2 uv2;
			uniform vec2 uvRatio;

			void main(void)
			{
			    vec4 mainColor = texture2D(sTexture, vTexCoord);
			    vec2 modifyUv = vTexCoord - uv2;
			    modifyUv = modifyUv * uvRatio;
			    modifyUv = modifyUv + uv1;
			    vec4 maskColor = texture2D(sMaskTexture, modifyUv);

				gl_FragColor = mainColor * maskColor.xxxx;
			}
	    ";
    }

    override public function bind(p_context:IGContext, p_renderer:IGRenderer, p_defaultTexture:GTexture):Void {
        var nativeContext:RenderingContext = p_context.getNativeContext();
        var nativeProgram:Program = p_renderer.getProgram();

        nativeContext.uniform2f(nativeContext.getUniformLocation(nativeProgram, "uv1"), u1, v1);
        nativeContext.uniform2f(nativeContext.getUniformLocation(nativeProgram, "uv2"), u2, v2);
        nativeContext.uniform2f(nativeContext.getUniformLocation(nativeProgram, "uvRatio"), uRatio, vRatio);

        nativeContext.activeTexture(RenderingContext.TEXTURE1);
        nativeContext.bindTexture(RenderingContext.TEXTURE_2D, maskTexture.nativeTexture);
        untyped nativeContext.uniform1i(nativeContext.getUniformLocation(nativeProgram, "sMaskTexture"), 1);
    }
}
