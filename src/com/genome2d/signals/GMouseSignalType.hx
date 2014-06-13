/*
* 	Genome2D - GPU 2D framework utilizing Molehill API
*
*	Copyright 2011 Peter Stefcek. All rights reserved.
*
*	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
*/
package com.genome2d.signals;

class GMouseSignalType {
    inline static public var MOUSE_DOWN:String = "mouseDown";
    inline static public var MOUSE_MOVE:String = "mouseMove";
    inline static public var MOUSE_UP:String = "mouseUp";
    inline static public var MOUSE_OVER:String = "mouseOver";
    inline static public var MOUSE_OUT:String = "mouseOut";
    inline static public var RIGHT_MOUSE_DOWN:String = "rightmousedown";
    inline static public var RIGHT_MOUSE_UP:String = "rightmouseup";

    inline static public function fromNative(p_nativeType:String):String {
        var type:String = "";
        switch (p_nativeType) {
            case "mousemove" | "touchmove":
                type = MOUSE_MOVE;
            case "mousedown" | "touchstart":
                type = MOUSE_DOWN;
            case "mouseup" | "touchend":
                type = MOUSE_UP;
        }

        return type;
    }
}
