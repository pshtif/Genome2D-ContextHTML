package com.genome2d.context.filters;
import haxe.io.Float32Array;
import com.genome2d.textures.GTexture;
class GDesaturateFilter extends GFilter {

    public function new() {
        super();

        fragmentCode = "
			precision lowp float;

			varying vec2 vTexCoord;
			varying vec4 vColor;

			uniform sampler2D sTexture;
			uniform vec4 values;

			void main(void)
			{
			    vec4 mainColor = texture2D(sTexture, vTexCoord);
			    mainColor = vec4(vec3(dot(mainColor.xyz, vec3(0.3, 0.59, 0.11))), mainColor.w);

				gl_FragColor = mainColor;
			}
	    ";
    }

    override public function bind(p_context:IGContext, p_renderer:IGRenderer, p_defaultTexture:GTexture):Void {
    }
}
