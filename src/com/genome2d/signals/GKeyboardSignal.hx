/*
 * 	Genome2D - 2D GPU Framework
 * 	http://www.genome2d.com
 *
 *	Copyright 2011-2014 Peter Stefcek. All rights reserved.
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
