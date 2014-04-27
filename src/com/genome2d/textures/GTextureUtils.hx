/*
* 	Genome2D - GPU 2D framework utilizing Molehill API
*
*	Copyright 2011 Peter Stefcek. All rights reserved.
*
*	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
*/
package com.genome2d.textures;

class GTextureUtils
{
	static public function isValidTextureSize(p_size:Int):Bool {
		return (getNextValidTextureSize(p_size) == p_size);
	}
	
	static public function getNextValidTextureSize(p_size:Int):Int {
		var size:Int = 1;
		while (p_size > size) size*=2;
		return size;
	}
	
	static public function getPreviousValidTextureSize(p_size:Int):Int {
		return getNextValidTextureSize(p_size)>>1;
	}
	
	static public function getNearestValidTextureSize(p_size:Int):Int {
		var previous:Int = getPreviousValidTextureSize(p_size);
		var next:Int = getNextValidTextureSize(p_size);
		
		return (p_size-previous < next-p_size) ? previous : next; 
	}
}