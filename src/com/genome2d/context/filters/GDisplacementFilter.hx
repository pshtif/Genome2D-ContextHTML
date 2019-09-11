package com.genome2d.context.filters;

import com.genome2d.context.filters.GFilter;
import com.genome2d.context.IGContext;
import com.genome2d.context.IGRenderer;
import com.genome2d.textures.GTexture;
import js.html.webgl.Program;
import js.html.webgl.RenderingContext;

class GDisplacementFilter extends GFilter {

    private var _scaleX:Float;
    private var _scaleY:Float;
    public var offset:Float = 0;

    public var displacementMap:GTexture;


    public function new(p_scaleX:Float = .1, p_scaleY:Float = .1) {

        super();

        _scaleX = p_scaleX;
        _scaleY = p_scaleY;

        fragmentCode = "
            precision lowp float;

            varying vec2 vTexCoord;
            uniform sampler2D sTexture;

            uniform sampler2D sDisplacementTexture;

            uniform vec2 scale;

            uniform float sOffset;
            uniform float sOne;

            void main(void)
            {
                vec2 copyTexCoord = vTexCoord;

                copyTexCoord.y = copyTexCoord.y + sOffset;

                vec4 cDisp = texture2D(sDisplacementTexture, copyTexCoord);

                copyTexCoord.x = vTexCoord.x + cDisp.r * scale.x;
                copyTexCoord.y = vTexCoord.y + cDisp.r * scale.y;

                vec4 c = texture2D(sTexture, copyTexCoord);

                gl_FragColor = c;
            }
	    ";
    }

    override public function bind(p_context:IGContext, p_renderer:IGRenderer, p_defaultTexture:GTexture):Void {

        var nativeContext:RenderingContext = p_context.getNativeContext();
        var nativeProgram:Program = p_renderer.getProgram();

        nativeContext.uniform2fv(nativeContext.getUniformLocation(nativeProgram, "scale"), [_scaleX, _scaleY]);
        nativeContext.uniform1f(nativeContext.getUniformLocation(nativeProgram, "sOffset"), offset);

        nativeContext.activeTexture(RenderingContext.TEXTURE1);
        nativeContext.bindTexture(RenderingContext.TEXTURE_2D, displacementMap.nativeTexture);
        untyped nativeContext.uniform1i(nativeContext.getUniformLocation(nativeProgram, "sDisplacementTexture"), 1);
    }
}