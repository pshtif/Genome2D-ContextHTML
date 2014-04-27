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
            case "mousemove":
                type = MOUSE_MOVE;
            case "mousedown":
                type = MOUSE_DOWN;
            case "mouseup":
                type = MOUSE_UP;
        }

        return type;
    }
}
