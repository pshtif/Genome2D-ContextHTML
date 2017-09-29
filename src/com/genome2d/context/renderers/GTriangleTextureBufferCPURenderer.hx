/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.context.renderers;

import js.html.Uint16Array;
import com.genome2d.context.filters.GFilter;
import com.genome2d.textures.GTexture;
import com.genome2d.debug.GDebug;
import com.genome2d.context.GWebGLContext;
import js.html.webgl.Texture;
import js.html.webgl.Shader;
import js.html.webgl.Program;
import js.html.webgl.Buffer;
import js.html.webgl.RenderingContext;
import js.html.webgl.UniformLocation;
import js.html.Float32Array;

@:access(com.genome2d.textures.GTexture)
class GTriangleTextureBufferCPURenderer implements IGRenderer
{
    inline static private var BATCH_SIZE:Int = 1200;
    inline static private var DATA_PER_VERTEX:Int = 4;
    inline static private var DATA_PER_VERTEX_ALPHA:Int = DATA_PER_VERTEX+4;

    private var g2d_nativeContext:RenderingContext;
	private var g2d_triangleCount:Int = 0;
    private var g2d_activeAlpha:Bool = true;

    private var g2d_indexBuffer:Buffer;
	public var g2d_vertexBuffer:Buffer;
    public var g2d_vertices:Float32Array;

    private var g2d_activeNativeTexture:Texture;
	private var g2d_initialized:Int = -1;
    private var g2d_context:GWebGLContext;

	inline static private var VERTEX_SHADER_CODE:String = 
            "
			uniform mat4 projectionMatrix;

			attribute vec2 aPosition;
			attribute vec2 aTexCoord;
			attribute vec4 aColor;

			varying vec2 vTexCoord;
			varying vec4 vColor;

			void main(void)
			{
				gl_Position = vec4(aPosition.x, aPosition.y, 0, 1) * projectionMatrix;
				vTexCoord = aTexCoord;
				vColor = aColor;
			}
		";

	inline static private var FRAGMENT_SHADER_CODE:String =
            "
			#ifdef GL_ES
			precision highp float;
			#endif

			varying vec2 vTexCoord;
			varying vec4 vColor;

			uniform sampler2D sTexture;

			void main(void)
			{
				gl_FragColor = texture2D(sTexture, vTexCoord) * vColor;
			}
		";

	public var g2d_program:Program;
	
	inline public static var STRIDE : Int = 8;
	
	public function new():Void {
    }

    public function getProgram():Program {
        return g2d_program;
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

    public function initialize(p_context:GWebGLContext):Void {
        g2d_context = p_context;
        g2d_nativeContext = g2d_context.getNativeContext();
		
		var fragmentShader = getShader(FRAGMENT_SHADER_CODE, RenderingContext.FRAGMENT_SHADER);
		var vertexShader = getShader(VERTEX_SHADER_CODE, RenderingContext.VERTEX_SHADER);

		g2d_program = g2d_nativeContext.createProgram();
		g2d_nativeContext.attachShader(g2d_program, vertexShader);
		g2d_nativeContext.attachShader(g2d_program, fragmentShader);
		g2d_nativeContext.linkProgram(g2d_program);

		//if (!RenderingContext.getProgramParameter(program, RenderingContext.LINK_STATUS)) { ("Could not initialise shaders"); }

		untyped g2d_program.positionAttribute = g2d_nativeContext.getAttribLocation(g2d_program, "aPosition");
		untyped g2d_nativeContext.enableVertexAttribArray(g2d_program.positionAttribute);

        untyped g2d_program.uvAttribute = g2d_nativeContext.getAttribLocation(g2d_program, "aTexCoord");
        untyped g2d_nativeContext.enableVertexAttribArray(g2d_program.uvAttribute);

        untyped g2d_program.colorAttribute = g2d_nativeContext.getAttribLocation(g2d_program, "aColor");
        untyped g2d_nativeContext.enableVertexAttribArray(g2d_program.colorAttribute);

		untyped g2d_program.samplerUniform = g2d_nativeContext.getUniformLocation(g2d_program, "sTexture");

        var indices:Uint16Array = new Uint16Array(BATCH_SIZE * 3);
        for (i in 0...3 * BATCH_SIZE) {
            indices[i] = i;
        }
        g2d_indexBuffer = g2d_nativeContext.createBuffer();
        g2d_nativeContext.bindBuffer(RenderingContext.ELEMENT_ARRAY_BUFFER, g2d_indexBuffer);
        g2d_nativeContext.bufferData(RenderingContext.ELEMENT_ARRAY_BUFFER, indices, RenderingContext.STATIC_DRAW);

		g2d_vertices = new Float32Array((BATCH_SIZE * 3) * DATA_PER_VERTEX_ALPHA);
        g2d_vertexBuffer = g2d_nativeContext.createBuffer();
	}

    public function bind(p_context:IGContext, p_reinitialize:Int):Void {
        if (p_reinitialize != g2d_initialized) initialize(cast p_context);
        g2d_initialized = p_reinitialize;

        g2d_nativeContext.useProgram(g2d_program);

        g2d_nativeContext.bindBuffer(RenderingContext.ELEMENT_ARRAY_BUFFER, g2d_indexBuffer);
    }

    public function draw(p_vertices:Array<Float>, p_uvs:Array<Float>, p_x:Float, p_y:Float, p_scaleX:Float, p_scaleY:Float, p_rotation:Float, p_red:Float, p_green:Float, p_blue:Float, p_alpha:Float, p_texture:GTexture, p_filter:GFilter):Void {
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

        var cos:Float = (p_rotation==0) ? 1 : Math.cos(p_rotation);
        var sin:Float = (p_rotation==0) ? 0 : Math.sin(p_rotation);

        var ux:Float = p_texture.g2d_u;
        var usx:Float = p_texture.g2d_uScale;
        var uy:Float = p_texture.g2d_v;
        var usy:Float = p_texture.g2d_vScale;

        if (p_texture.premultiplied) {
            p_red*=p_alpha;
            p_green*=p_alpha;
            p_blue*=p_alpha;
        }

        var dataSize:Int = p_vertices.length;
        var vertexCount:Int = dataSize>>1;

        var triangleCount:Int = Std.int(vertexCount/3);
        if (g2d_triangleCount+triangleCount > BATCH_SIZE) push();
        var index:Int = (g2d_activeAlpha ? DATA_PER_VERTEX_ALPHA : DATA_PER_VERTEX)*3*g2d_triangleCount;
        var i:Int = 0;

        while (i<dataSize) {
            // xy
            g2d_vertices[index] = cos*p_vertices[i]*p_scaleX - sin*p_vertices[i+1]*p_scaleY + p_x;
            g2d_vertices[index+1] = sin*p_vertices[i]*p_scaleX + cos*p_vertices[i+1]*p_scaleY + p_y;
            // uv
            g2d_vertices[index+2] = ux+p_uvs[i]*usx;
            g2d_vertices[index+3] = uy+p_uvs[i+1]*usy;
            // color
            if (g2d_activeAlpha) {
                g2d_vertices[index+4] = p_red;
                g2d_vertices[index+5] = p_green;
                g2d_vertices[index+6] = p_blue;
                g2d_vertices[index+7] = p_alpha;

                index += DATA_PER_VERTEX_ALPHA;
            } else {
                index += DATA_PER_VERTEX;
            }

            i+=2;
        }

        g2d_triangleCount+=triangleCount;
        if (g2d_triangleCount >= BATCH_SIZE) push();
	}

    @:access(com.genome2d.context.GWebGLContext)
	public function push():Void {
        if (g2d_triangleCount>0) {
            g2d_nativeContext.uniformMatrix4fv(g2d_nativeContext.getUniformLocation(g2d_program, "projectionMatrix"), false,  g2d_context.g2d_projectionMatrix.rawData);

            g2d_nativeContext.bindBuffer(RenderingContext.ARRAY_BUFFER, g2d_vertexBuffer);
            g2d_nativeContext.bufferData(RenderingContext.ARRAY_BUFFER, g2d_vertices, RenderingContext.STREAM_DRAW);

            untyped g2d_nativeContext.vertexAttribPointer(g2d_program.positionAttribute, 2, RenderingContext.FLOAT, false, 32, 0);
            untyped g2d_nativeContext.vertexAttribPointer(g2d_program.uvAttribute, 2, RenderingContext.FLOAT, false, 32, 2*4);
            untyped g2d_nativeContext.vertexAttribPointer(g2d_program.colorAttribute, 4, RenderingContext.FLOAT, false, 32, 4*4);

            g2d_nativeContext.drawElements(RenderingContext.TRIANGLES, 3 * g2d_triangleCount, RenderingContext.UNSIGNED_SHORT, 0);

            g2d_triangleCount = 0;
        }
    }

    public function clear():Void {
        g2d_activeNativeTexture = null;
    }
}