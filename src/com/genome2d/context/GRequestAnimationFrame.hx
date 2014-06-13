/*
* 	Genome2D - GPU 2D framework utilizing Molehill API
*
*	Copyright 2011 Peter Stefcek. All rights reserved.
*
*	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
*/
package com.genome2d.context;

import js.html.Document;

class GRequestAnimationFrame {

	public static function request(method:Dynamic):Void {
			
		var requestAnimationFrame:Dynamic = 			
			untyped window.requestAnimationFrame || 
			untyped window.webkitRequestAnimationFrame || 
			untyped window.mozRequestAnimationFrame || 
			untyped window.oRequestAnimationFrame || 
			untyped window.msRequestAnimationFrame || 
			
			function (method:Dynamic, ?element:Document):Void {
				untyped window.setTimeout (method, 1000 / 60);
			}
		
		requestAnimationFrame(method);	
	}
}