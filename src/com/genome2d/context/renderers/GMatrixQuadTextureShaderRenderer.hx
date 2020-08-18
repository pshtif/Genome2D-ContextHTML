/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
 *
 *	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
 */
package com.genome2d.context.renderers;

import com.genome2d.context.GWebGLContext;
import com.genome2d.context.filters.GFilter;
import com.genome2d.context.stats.GStats;
import com.genome2d.context.IGRenderer;
import com.genome2d.context.IGContext;
import com.genome2d.debug.GDebug;
import com.genome2d.textures.GTexture;
import js.html.webgl.Texture;
import js.html.webgl.Shader;
import js.html.webgl.Program;
import js.html.webgl.Buffer;
import js.html.webgl.RenderingContext;
import js.html.webgl.UniformLocation;
#if (haxe_ver < 4) import js.html.Uint16Array; #else import js.lib.Uint16Array; #end
#if (haxe_ver < 4) import js.html.Float32Array; #else import js.lib.Float32Array; #end

class GMatrixQuadTextureShaderRenderer implements IGRenderer
{
    inline static private var BATCH_SIZE:Int = 30;

    inline static private var TRANSFORM_PER_VERTEX:Int = 3;
    inline static private var TRANSFORM_PER_VERTEX_ALPHA:Int = TRANSFORM_PER_VERTEX+1;

    inline static private var VERTEX_SHADER_CODE_ALPHA:String =
    "
			uniform mat4 projectionMatrix;
			uniform vec4 transforms["+BATCH_SIZE*TRANSFORM_PER_VERTEX_ALPHA+"];

			attribute vec2 aPosition;
			attribute vec2 aTexCoord;
			attribute vec4 aConstantIndex;

			varying vec2 vTexCoord;
			varying vec4 vColor;

			void main(void)
			{
				vec2 temp1 = vec2(aPosition.x * transforms[int(aConstantIndex.y)].z, aPosition.y * transforms[int(aConstantIndex.y)].w);
				vec2 temp2 = vec2(temp1.x * transforms[int(aConstantIndex.x)].x, temp1.y * transforms[int(aConstantIndex.x)].y);
				temp2.x += temp2.y;
				temp2.x += transforms[int(aConstantIndex.y)].x;

				vec2 temp3 = vec2(temp1.x * transforms[int(aConstantIndex.x)].z, temp1.y * transforms[int(aConstantIndex.x)].w);
				temp3.x += temp3.y;
				temp3.x += transforms[int(aConstantIndex.y)].y;

				gl_Position = vec4(temp2.x, temp3.x, 0, 1) * projectionMatrix;

				vTexCoord = vec2(aTexCoord.x*transforms[int(aConstantIndex.z)].z+transforms[int(aConstantIndex.z)].x, aTexCoord.y*transforms[int(aConstantIndex.z)].w+transforms[int(aConstantIndex.z)].y);
				vColor = transforms[int(aConstantIndex.w)];
			}
		 ";

    inline static private var FRAGMENT_SHADER_CODE_ALPHA:String =
    "
			precision lowp float;

			varying vec2 vTexCoord;
			varying vec4 vColor;

			uniform sampler2D sTexture;

			void main(void)
			{
				gl_FragColor = texture2D(sTexture, vTexCoord) * vColor;
			}
		";

    private var g2d_nativeContext:RenderingContext;
	private var g2d_quadCount:Int = 0;
	
	private var g2d_geometryBuffer:Buffer;
    private var g2d_uvBuffer:Buffer;
    private var g2d_constantIndexBuffer:Buffer;
    private var g2d_constantIndexAlphaBuffer:Buffer;

    private var g2d_indexBuffer:Buffer;

    private var g2d_activeNativeTexture:Texture;
    private var g2d_activeFilter:GFilter;
    private var g2d_activeAlpha:Bool = false;

    private var g2d_defaultProgram:Dynamic;
    private var g2d_currentProgram:Dynamic;
    private var g2d_cachedFilterPrograms:Map<String,Program>;
    private var g2d_vertexShader:Shader;
    private var g2d_defaultFragmentShader:Shader;
    private var g2d_previousFragmentShader:Shader;

    private var g2d_useSeparatedAlphaPipeline:Bool = false;

    private var g2d_transforms:Float32Array;
    private var g2d_context:GWebGLContext;

    private var g2d_initialized:Int = -1;
	
	public function new():Void {
    }

    public function getProgram():Program {
        return g2d_currentProgram;
    }

    private function getFilterProgram(p_filter:GFilter):Program {
        var program:Dynamic = null;
        if (g2d_cachedFilterPrograms == null) g2d_cachedFilterPrograms = new Map<String,Program>();
        if (g2d_cachedFilterPrograms.exists(p_filter.id)) {
            program = g2d_cachedFilterPrograms.get(p_filter.id);
        } else {
            var fragmentShader:Shader = getShader(p_filter.fragmentCode, RenderingContext.FRAGMENT_SHADER);
            program = g2d_nativeContext.createProgram();
            g2d_nativeContext.attachShader(program, g2d_vertexShader);
            g2d_nativeContext.attachShader(program, fragmentShader);
            g2d_nativeContext.linkProgram(program);

            program.samplerUniform = g2d_nativeContext.getUniformLocation(program, "sTexture");

            program.positionAttribute = g2d_nativeContext.getAttribLocation(program, "aPosition");
            g2d_nativeContext.enableVertexAttribArray(program.positionAttribute);

            program.texCoordAttribute = g2d_nativeContext.getAttribLocation(program, "aTexCoord");
            g2d_nativeContext.enableVertexAttribArray(program.texCoordAttribute);

            program.constantIndexAttribute = g2d_nativeContext.getAttribLocation(program, "aConstantIndex");
            g2d_nativeContext.enableVertexAttribArray(program.constantIndexAttribute);

            g2d_cachedFilterPrograms.set(p_filter.id, program);
        }

        return program;
    }

    private function getShader(shaderSrc:String, shaderType:Int):Shader {
        var shader:Shader = g2d_nativeContext.createShader(shaderType);
        g2d_nativeContext.shaderSource(shader, shaderSrc);
        g2d_nativeContext.compileShader(shader);

        // Check for erros
        if (!g2d_nativeContext.getShaderParameter(shader, RenderingContext.COMPILE_STATUS)) {
            GDebug.error("Shader compilation error: " + g2d_nativeContext.getShaderInfoLog(shader)); return null;
        }
        /**/
        return shader;
    }

    public function initialize(p_context:GWebGLContext):Void {
        g2d_context = p_context;
		g2d_nativeContext = g2d_context.getNativeContext();

        g2d_vertexShader = getShader(VERTEX_SHADER_CODE_ALPHA, RenderingContext.VERTEX_SHADER);
		g2d_defaultFragmentShader = getShader(FRAGMENT_SHADER_CODE_ALPHA, RenderingContext.FRAGMENT_SHADER);
        g2d_previousFragmentShader = g2d_defaultFragmentShader;

		g2d_defaultProgram = g2d_nativeContext.createProgram();
		g2d_nativeContext.attachShader(g2d_defaultProgram, g2d_vertexShader);
		g2d_nativeContext.attachShader(g2d_defaultProgram, g2d_defaultFragmentShader);
		g2d_nativeContext.linkProgram(g2d_defaultProgram);

		//if (!RenderingContext.getProgramParameter(program, RenderingContext.LINK_STATUS)) { ("Could not initialise shaders"); }

        var vertices:Float32Array = new Float32Array(8*BATCH_SIZE);
        var uvs:Float32Array = new Float32Array(8*BATCH_SIZE);
        var registerIndices:Float32Array = new Float32Array(TRANSFORM_PER_VERTEX*BATCH_SIZE*4);
        var registerIndicesAlpha:Float32Array = new Float32Array(TRANSFORM_PER_VERTEX_ALPHA*BATCH_SIZE*4);

        for (i in 0...BATCH_SIZE) {
            vertices[i*8] = GRendererCommon.NORMALIZED_VERTICES[0];
            vertices[i*8+1] = GRendererCommon.NORMALIZED_VERTICES[1];
            vertices[i*8+2] = GRendererCommon.NORMALIZED_VERTICES[2];
            vertices[i*8+3] = GRendererCommon.NORMALIZED_VERTICES[3];
            vertices[i*8+4] = GRendererCommon.NORMALIZED_VERTICES[4];
            vertices[i*8+5] = GRendererCommon.NORMALIZED_VERTICES[5];
            vertices[i*8+6] = GRendererCommon.NORMALIZED_VERTICES[6];
            vertices[i*8+7] = GRendererCommon.NORMALIZED_VERTICES[7];

            uvs[i*8] = GRendererCommon.NORMALIZED_UVS[0];
            uvs[i*8+1] = GRendererCommon.NORMALIZED_UVS[1];
            uvs[i*8+2] = GRendererCommon.NORMALIZED_UVS[2];
            uvs[i*8+3] = GRendererCommon.NORMALIZED_UVS[3];
            uvs[i*8+4] = GRendererCommon.NORMALIZED_UVS[4];
            uvs[i*8+5] = GRendererCommon.NORMALIZED_UVS[5];
            uvs[i*8+6] = GRendererCommon.NORMALIZED_UVS[6];
            uvs[i*8+7] = GRendererCommon.NORMALIZED_UVS[7];

            var index:Int = (i * TRANSFORM_PER_VERTEX);
            registerIndices[index*4] = index;
            registerIndices[index*4+1] = index+1;
            registerIndices[index*4+2] = index+2;
            registerIndices[index*4+3] = index;
            registerIndices[index*4+4] = index+1;
            registerIndices[index*4+5] = index+2;
            registerIndices[index*4+6] = index;
            registerIndices[index*4+7] = index+1;
            registerIndices[index*4+8] = index+2;
            registerIndices[index*4+9] = index;
            registerIndices[index*4+10] = index+1;
            registerIndices[index*4+11] = index+2;

            var index:Int = (i * TRANSFORM_PER_VERTEX_ALPHA);
            registerIndicesAlpha[index*4] = index;
            registerIndicesAlpha[index*4+1] = index+1;
            registerIndicesAlpha[index*4+2] = index+2;
            registerIndicesAlpha[index*4+3] = index+3;
            registerIndicesAlpha[index*4+4] = index;
            registerIndicesAlpha[index*4+5] = index+1;
            registerIndicesAlpha[index*4+6] = index+2;
            registerIndicesAlpha[index*4+7] = index+3;
            registerIndicesAlpha[index*4+8] = index;
            registerIndicesAlpha[index*4+9] = index+1;
            registerIndicesAlpha[index*4+10] = index+2;
            registerIndicesAlpha[index*4+11] = index+3;
            registerIndicesAlpha[index*4+12] = index;
            registerIndicesAlpha[index*4+13] = index+1;
            registerIndicesAlpha[index*4+14] = index+2;
            registerIndicesAlpha[index*4+15] = index+3;
        }

        g2d_geometryBuffer = g2d_nativeContext.createBuffer();
        g2d_nativeContext.bindBuffer(RenderingContext.ARRAY_BUFFER, g2d_geometryBuffer);
        g2d_nativeContext.bufferData(RenderingContext.ARRAY_BUFFER, vertices, RenderingContext.STREAM_DRAW);

        g2d_uvBuffer = g2d_nativeContext.createBuffer();
        g2d_nativeContext.bindBuffer(RenderingContext.ARRAY_BUFFER, g2d_uvBuffer);
        g2d_nativeContext.bufferData(RenderingContext.ARRAY_BUFFER, uvs, RenderingContext.STREAM_DRAW);

        g2d_constantIndexBuffer = g2d_nativeContext.createBuffer();
        g2d_nativeContext.bindBuffer(RenderingContext.ARRAY_BUFFER, g2d_constantIndexBuffer);
        g2d_nativeContext.bufferData(RenderingContext.ARRAY_BUFFER, registerIndices, RenderingContext.STREAM_DRAW);

        g2d_constantIndexAlphaBuffer = g2d_nativeContext.createBuffer();
        g2d_nativeContext.bindBuffer(RenderingContext.ARRAY_BUFFER, g2d_constantIndexAlphaBuffer);
        g2d_nativeContext.bufferData(RenderingContext.ARRAY_BUFFER, registerIndicesAlpha, RenderingContext.STREAM_DRAW);

        var indices:Uint16Array = new Uint16Array(BATCH_SIZE * 6);
        for (i in 0...BATCH_SIZE) {
            var ao:Int = i*6;
            var io:Int = i*4;
            indices[ao] = io;
            indices[ao+1] = io+1;
            indices[ao+2] = io+2;
            indices[ao+3] = io;
            indices[ao+4] = io+2;
            indices[ao+5] = io+3;
        }

        g2d_indexBuffer = g2d_nativeContext.createBuffer();
        g2d_nativeContext.bindBuffer(RenderingContext.ELEMENT_ARRAY_BUFFER, g2d_indexBuffer);
        g2d_nativeContext.bufferData(RenderingContext.ELEMENT_ARRAY_BUFFER, indices, RenderingContext.STATIC_DRAW);

		g2d_defaultProgram.samplerUniform = g2d_nativeContext.getUniformLocation(g2d_defaultProgram, "sTexture");

        g2d_defaultProgram.positionAttribute = g2d_nativeContext.getAttribLocation(g2d_defaultProgram, "aPosition");
        g2d_nativeContext.enableVertexAttribArray(g2d_defaultProgram.positionAttribute);

        g2d_defaultProgram.texCoordAttribute = g2d_nativeContext.getAttribLocation(g2d_defaultProgram, "aTexCoord");
        g2d_nativeContext.enableVertexAttribArray(g2d_defaultProgram.texCoordAttribute);

        g2d_defaultProgram.constantIndexAttribute = g2d_nativeContext.getAttribLocation(g2d_defaultProgram, "aConstantIndex");
        g2d_nativeContext.enableVertexAttribArray(g2d_defaultProgram.constantIndexAttribute);

        g2d_transforms = new Float32Array(BATCH_SIZE * TRANSFORM_PER_VERTEX_ALPHA * 4);
	}

    public function bind(p_context:IGContext, p_reinitialize:Int):Void {
        if (p_reinitialize != g2d_initialized) initialize(cast p_context);
		g2d_initialized = p_reinitialize;

        g2d_currentProgram = g2d_defaultProgram;
		g2d_nativeContext.useProgram(g2d_defaultProgram);
		
        // Bind camera matrix
        g2d_nativeContext.bindBuffer(RenderingContext.ELEMENT_ARRAY_BUFFER, g2d_indexBuffer);

        g2d_nativeContext.bindBuffer(RenderingContext.ARRAY_BUFFER, g2d_geometryBuffer);
        g2d_nativeContext.vertexAttribPointer(g2d_defaultProgram.positionAttribute, 2, RenderingContext.FLOAT, false, 0, 0);

        g2d_nativeContext.bindBuffer(RenderingContext.ARRAY_BUFFER, g2d_uvBuffer);
        g2d_nativeContext.vertexAttribPointer(g2d_defaultProgram.texCoordAttribute, 2, RenderingContext.FLOAT, false, 0, 0);

        g2d_nativeContext.bindBuffer(RenderingContext.ARRAY_BUFFER, g2d_constantIndexAlphaBuffer);
        g2d_nativeContext.vertexAttribPointer(g2d_defaultProgram.constantIndexAttribute, 4, RenderingContext.FLOAT, false, 0, 0);
    }

	@:access(com.genome2d.textures.GTexture)
    inline public function draw(p_a:Float, p_b:Float, p_c:Float, p_d:Float, p_tx:Float, p_ty:Float, p_red:Float, p_green:Float, p_blue:Float, p_alpha:Float, p_texture:GTexture, p_filter:GFilter, p_overrideSource:Bool, p_sourceX:Float, p_sourceY:Float, p_sourceWidth:Float, p_sourceHeight:Float):Void {
        var notSameTexture:Bool = g2d_activeNativeTexture != p_texture.nativeTexture;
        var useAlpha:Bool = !g2d_useSeparatedAlphaPipeline && !(p_red==1 && p_green==1 && p_blue==1 && p_alpha==1);
        var notSameUseAlpha:Bool = g2d_activeAlpha != useAlpha;
        var notSameFilter:Bool = g2d_activeFilter != p_filter;
        // TODO: Change this if we implement separate alpha pipeline
        g2d_activeAlpha = useAlpha;

        if (notSameTexture || notSameFilter) {
            if (g2d_activeNativeTexture != null) push();

            if (notSameFilter) {
                if (g2d_activeFilter != null) g2d_activeFilter.clear(g2d_context);
                g2d_activeFilter = p_filter;
                if (g2d_activeFilter != null) {
                    g2d_currentProgram = getFilterProgram(g2d_activeFilter);
                    g2d_nativeContext.useProgram(g2d_currentProgram);
                    g2d_activeFilter.bind(g2d_context, this, p_texture);
                } else {
                    g2d_currentProgram = g2d_defaultProgram;
                    g2d_nativeContext.useProgram(g2d_currentProgram);
                }
            }

            if (notSameTexture) {
                g2d_activeNativeTexture = p_texture.nativeTexture;
                g2d_nativeContext.activeTexture(RenderingContext.TEXTURE0);
                g2d_nativeContext.bindTexture(RenderingContext.TEXTURE_2D, p_texture.nativeTexture);
                untyped g2d_nativeContext.uniform1i(g2d_nativeContext.getUniformLocation(g2d_currentProgram, "sTexture"), 0);
            }
        }

        var uvx:Float;
        var uvy:Float;
        var uvsx:Float;
        var uvsy:Float;
        var sx:Float;
        var sy:Float;
        var px:Float;
        var py:Float;
        if (p_overrideSource) {
            uvx = p_sourceX / p_texture.nativeWidth;
            uvy = p_sourceY / p_texture.nativeHeight;
            uvsx = p_sourceWidth / p_texture.nativeWidth;
            uvsy = p_sourceHeight / p_texture.nativeHeight;
            sx = p_sourceWidth;
            sy = p_sourceHeight;
            px = 0;
            py = 0;
        } else {
            uvx = p_texture.g2d_u;
            uvy = p_texture.g2d_v;
            uvsx = p_texture.g2d_uScale;
            uvsy = p_texture.g2d_vScale;
            sx = p_texture.width;
            sy = p_texture.height;
            px = p_texture.pivotX;
            py = p_texture.pivotY;
        }

        if (px != 0 || py != 0) {
            p_tx = p_tx - px*p_a - py*p_c;
            p_ty = p_ty - px*p_b - py*p_d;
        }

        // Alpha is active and textures uses premultiplied source
        if (g2d_activeAlpha && p_texture.premultiplied) {
            p_red*=p_alpha;
            p_green*=p_alpha;
            p_blue*=p_alpha;
        }
        /**/
        var offset:Int = g2d_quadCount*TRANSFORM_PER_VERTEX_ALPHA<<2;
        g2d_transforms[offset] = p_a;
        g2d_transforms[offset+1] = p_c;
        g2d_transforms[offset+2] = p_b;
        g2d_transforms[offset+3] = p_d;

        g2d_transforms[offset+4] = p_tx;
        g2d_transforms[offset+5] = p_ty;
        g2d_transforms[offset+6] = sx;
        g2d_transforms[offset+7] = sy;

        g2d_transforms[offset + 8] = uvx;
        g2d_transforms[offset + 9] = uvy;
        g2d_transforms[offset + 10] = uvsx;
        g2d_transforms[offset + 11] = uvsy;

        g2d_transforms[offset + 12] = p_red;
        g2d_transforms[offset + 13] = p_green;
        g2d_transforms[offset + 14] = p_blue;
        g2d_transforms[offset + 15] = p_alpha;

		g2d_quadCount++;

        if (g2d_quadCount == BATCH_SIZE) push();
	}
	
	@:access(com.genome2d.context.GWebGLContext)
	inline public function push():Void {
        if (g2d_quadCount>0) {
            GStats.drawCalls++;

			g2d_nativeContext.uniformMatrix4fv(g2d_nativeContext.getUniformLocation(g2d_currentProgram, "projectionMatrix"), false,  g2d_context.g2d_projectionMatrix.rawData);
			
            g2d_nativeContext.uniform4fv(g2d_nativeContext.getUniformLocation(g2d_currentProgram, "transforms"), g2d_transforms);

            g2d_nativeContext.drawElements(RenderingContext.TRIANGLES, 6 * g2d_quadCount, RenderingContext.UNSIGNED_SHORT, 0);

            g2d_quadCount = 0;
        }
    }

    public function clear():Void {
        g2d_activeNativeTexture = null;

        if (g2d_activeFilter != null) {
            g2d_activeFilter.clear(g2d_context);
		    g2d_activeFilter = null;
        }
    }
}