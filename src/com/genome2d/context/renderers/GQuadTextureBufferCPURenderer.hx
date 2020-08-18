/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.context.renderers;

import com.genome2d.textures.GTexture;
import com.genome2d.debug.GDebug;
import js.html.webgl.Texture;
import js.html.webgl.Shader;
import js.html.webgl.Program;
import js.html.webgl.Buffer;
import js.html.webgl.RenderingContext;
import js.html.webgl.UniformLocation;

class GQuadTextureBufferCPURenderer
{
    /*
    private var g2d_nativeContext:RenderingContext;
	private var g2d_quadCount:Int = 0;
	
	public var vertexBuffer(default, null) : Buffer;
    public var vertices(default, null) : Float32Array;

    private var g2d_activeNativeTexture:Texture;
	private var g2d_initialized:Int = 0;

	inline static private var VERTEX_SHADER_CODE:String = 
            "
			uniform mat4 projectionMatrix;

			attribute vec4 aPosition;
			attribute vec2 aTexCoord;

			varying vec2 vTexCoord;

			void main(void)
			{
				vTexCoord = aPosition.zw;
				gl_Position =  vec4(aPosition.x, aPosition.y, 0, 1);
				gl_Position = gl_Position * projectionMatrix;
			}
		";

	inline static private var FRAGMENT_SHADER_CODE:String =
            "
			#ifdef GL_ES
			precision highp float;
			#endif

			varying vec2 vTexCoord;

			uniform sampler2D sTexture;

			void main(void)
			{
				vec4 texColor;
				texColor = texture2D(sTexture, vTexCoord);
				gl_FragColor = texColor;
			}
		";

	public var g2d_program:Program;
	
	inline public static var STRIDE : Int = 24;
	
	public function new():Void {
    }

    private function getShader(shaderSrc:String, shaderType:Int):Shader {
        var shader:Shader = g2d_nativeContext.createShader(shaderType);
        g2d_nativeContext.shaderSource(shader, shaderSrc);
        g2d_nativeContext.compileShader(shader);

        if (!g2d_nativeContext.getShaderParameter(shader, RenderingContext.COMPILE_STATUS)) {
            GDebug.error("Shader compilation error: " + g2d_nativeContext.getShaderInfoLog(shader)); return null;
        }
		
        return shader;
    }

    public function initialize(p_context:RenderingContext):Void {
		g2d_nativeContext = p_context;
		
		var fragmentShader = getShader(FRAGMENT_SHADER_CODE, RenderingContext.FRAGMENT_SHADER);
		var vertexShader = getShader(VERTEX_SHADER_CODE, RenderingContext.VERTEX_SHADER);

		g2d_program = g2d_nativeContext.createProgram();
		g2d_nativeContext.attachShader(g2d_program, vertexShader);
		g2d_nativeContext.attachShader(g2d_program, fragmentShader);
		g2d_nativeContext.linkProgram(g2d_program);

		//if (!RenderingContext.getProgramParameter(program, RenderingContext.LINK_STATUS)) { ("Could not initialise shaders"); }

		g2d_nativeContext.useProgram(g2d_program);

		untyped g2d_program.positionAttribute = g2d_nativeContext.getAttribLocation(g2d_program, "aPosition");
		untyped g2d_nativeContext.enableVertexAttribArray(g2d_program.positionAttribute);
		untyped g2d_program.samplerUniform = g2d_nativeContext.getUniformLocation(g2d_program, "sTexture");
		
		var numSprites:Int = 1000;
		vertices = new Float32Array((numSprites * 6) * 4);
        vertexBuffer = g2d_nativeContext.createBuffer();
	}

    public function bind(p_projection:Float32Array):Void {
        g2d_nativeContext.uniformMatrix4fv(g2d_nativeContext.getUniformLocation(g2d_program, "projectionMatrix"), false,  p_projection);
    }
	
	public function draw(p_x:Float, p_y:Float, p_scaleX:Float, p_scaleY:Float, p_rotation:Float, p_texture:GTexture):Void {
        var notSameTexture:Bool = g2d_activeNativeTexture != p_texture.nativeTexture;

        if (notSameTexture) {
            if (g2d_activeNativeTexture != null) push();

            if (notSameTexture) {
                g2d_activeNativeTexture = p_texture.nativeTexture;
                g2d_nativeContext.activeTexture(RenderingContext.TEXTURE0);
                g2d_nativeContext.bindTexture(RenderingContext.TEXTURE_2D, p_texture.nativeTexture);
                untyped g2d_nativeContext.uniform1i(g2d_program.samplerUniform, 0);
            }
        }

        var width:Float = p_texture.width * p_scaleX/2;
        var height:Float = p_texture.height * p_scaleY/2;

        var cosx:Float = width;
        var cosy:Float = height;
        var sinx:Float = 0;
        var siny:Float = 0;

        if (p_rotation!=0) {
            var cos:Float = Math.cos(p_rotation);
            var sin:Float = Math.sin(p_rotation);

            cosx = cos * width;
            cosy = cos * height;
            sinx = sin * width;
            siny = sin * height;
        }

        var vi : Int = g2d_quadCount * STRIDE;

        vertices[vi++] = -cosx - siny + p_x;
        vertices[vi++] = cosy - sinx + p_y;
        vertices[vi++] = p_texture.uvX;
        vertices[vi++] = p_texture.uvY + p_texture.uvScaleY;

        vertices[vi++] = -cosx + siny + p_x;
        vertices[vi++] = -cosy - sinx + p_y;
        vertices[vi++] = p_texture.uvX;
        vertices[vi++] = p_texture.uvY;

        vertices[vi++] = cosx - siny + p_x;
        vertices[vi++] = cosy + sinx + p_y;
        vertices[vi++] = p_texture.uvX + p_texture.uvScaleX;
        vertices[vi++] = p_texture.uvY + p_texture.uvScaleY;

        vertices[vi++] = cosx + siny + p_x;
        vertices[vi++] = cosy + sinx + p_y;
        vertices[vi++] = p_texture.uvX + p_texture.uvScaleX;
        vertices[vi++] = p_texture.uvY + p_texture.uvScaleY;

        vertices[vi++] = -cosx + siny + p_x;
        vertices[vi++] = -cosy - sinx + p_y;
        vertices[vi++] = p_texture.uvX;
        vertices[vi++] = p_texture.uvY;

        vertices[vi++] = cosx + siny + p_x;
        vertices[vi++] = -cosy + sinx + p_y;
        vertices[vi++] = p_texture.uvX + p_texture.uvScaleX;
        vertices[vi++] = p_texture.uvY;

		g2d_quadCount++;

        if (g2d_quadCount == 1000) push();
	}
	
	public function push():Void {
        g2d_nativeContext.bindBuffer(RenderingContext.ARRAY_BUFFER, vertexBuffer);
        g2d_nativeContext.bufferData(RenderingContext.ARRAY_BUFFER, vertices, RenderingContext.STREAM_DRAW);

        var numItems:Int = Std.int((g2d_quadCount * STRIDE) / 4);
        untyped g2d_nativeContext.vertexAttribPointer(g2d_program.positionAttribute, 4, RenderingContext.FLOAT, false, 0, 0);

        g2d_nativeContext.drawArrays(RenderingContext.TRIANGLES, 0, numItems);

        g2d_quadCount = 0;
    }

    public function clear():Void {
        g2d_activeNativeTexture = null;
    }
    /**/
}