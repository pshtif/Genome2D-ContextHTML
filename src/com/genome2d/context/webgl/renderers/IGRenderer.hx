/*
* 	Genome2D - GPU 2D framework utilizing Molehill API
*
*	Copyright 2011 Peter Stefcek. All rights reserved.
*
*	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
*/
package com.genome2d.context.webgl.renderers;

import com.genome2d.context.webgl.GWebGLContext;

interface IGRenderer
{
    function bind(p_context:GWebGLContext, p_reinitialize:Bool):Void;
	
	function push():Void;
	
	function clear():Void;
}