/*
* 	Genome2D - GPU 2D framework utilizing Molehill API
*
*	Copyright 2011 Peter Stefcek. All rights reserved.
*
*	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
*/
package com.genome2d.signals;

class GKeyboardSignal {
    public var keyCode:Int;

    public function new(p_keyCode:Int) {
        keyCode = p_keyCode;
    }
}
