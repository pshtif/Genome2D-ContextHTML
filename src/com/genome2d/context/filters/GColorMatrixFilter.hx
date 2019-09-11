package com.genome2d.context.filters;

import com.genome2d.geom.GFloat;
import com.genome2d.textures.GTexture;

class GColorMatrixFilter extends GFilter {

    public function setMatrix(p_matrix:Array<GFloat>):Void {
        // Not cloning but keeping a reference, something to keep in mind. -- sHTiF

        p_matrix[4] /= 255;
        p_matrix[9] /= 255;
        p_matrix[14] /= 255;
        p_matrix[19] /= 255;
        g2d_fragmentConstants = p_matrix;
    }

    public function new() {
        super();

        fragmentCode = "
            precision lowp float;

            varying vec4 vColor;
            varying vec2 vTexCoord;
            uniform sampler2D sTexture;
            uniform float m[20];

            void main(void)
            {
                vec4 c = texture2D(sTexture, vTexCoord);

                vec4 result;

                if (c.a > 0.0) {
                    c.rgb /= c.a;
                }

                result.r = (m[0] * c.r);
                    result.r += (m[1] * c.g);
                    result.r += (m[2] * c.b);
                    result.r += (m[3] * c.a);
                    result.r += m[4];

                result.g = (m[5] * c.r);
                    result.g += (m[6] * c.g);
                    result.g += (m[7] * c.b);
                    result.g += (m[8] * c.a);
                    result.g += m[9];

                result.b = (m[10] * c.r);
                   result.b += (m[11] * c.g);
                   result.b += (m[12] * c.b);
                   result.b += (m[13] * c.a);
                   result.b += m[14];

                result.a = (m[15] * c.r);
                   result.a += (m[16] * c.g);
                   result.a += (m[17] * c.b);
                   result.a += (m[18] * c.a);
                   result.a += m[19];

                // Premultiply alpha again.
                result.rgb *= result.a;

                gl_FragColor = vec4(result.rgb, result.a) * vColor;
            }
	    ";
    }

    override public function bind(p_context:IGContext, p_renderer:IGRenderer, p_defaultTexture:GTexture):Void {

        p_context.getNativeContext().uniform1fv(p_context.getNativeContext().getUniformLocation(p_renderer.getProgram(), "m"), g2d_fragmentConstants);
    }
}
