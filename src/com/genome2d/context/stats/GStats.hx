/*
* 	Genome2D - GPU 2D framework utilizing Molehill API
*
*	Copyright 2011 Peter Stefcek. All rights reserved.
*
*	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
*/
package com.genome2d.context.stats;

import com.genome2d.context.IContext;
import js.html.Element;
import js.Browser;
import js.html.DivElement;
import js.html.Event;
import js.html.Document;

/**

**/
class GStats implements IStats
{
    static public var fps:Int = 0;
    static public var drawCalls:Int = 0;
    static public var nodeCount:Int = 0;
    static public var customStats:Array<String>;

    static public var x:Int = 0;
    static public var y:Int = 0;
    static public var scaleX:Float = 1;
    static public var scaleY:Float = 1;
    static public var visible:Bool = false;

    private var g2d_frames:Int = 0;
    private var g2d_previousTime:Float = 0;
    private var g2d_fpsText:DivElement;

    private var g2d_container:DivElement;
    private var g2d_fpsDiv:DivElement;

    public function new(p_canvas:Element) {
        g2d_previousTime = Date.now().getTime();
        fps = 0;

        g2d_container = Browser.document.createDivElement();
        g2d_container.id = 'stats';
        g2d_container.style.cssText = 'width:'+p_canvas.clientWidth+'px;opacity:0.9;cursor:pointer';
        g2d_container.style.position = "absolute";
        g2d_container.style.left = p_canvas.offsetLeft+'px';
        g2d_container.style.top = p_canvas.offsetTop+'px';

        g2d_fpsDiv = Browser.document.createDivElement();
        g2d_fpsDiv.id = 'fps';
        g2d_fpsDiv.style.cssText = 'padding:0 0 3px 3px;text-align:left;background-color:#002';
        g2d_container.appendChild( g2d_fpsDiv );

        g2d_fpsText = Browser.document.createDivElement();
        g2d_fpsText.id = 'fpsText';
        g2d_fpsText.style.cssText = 'color:#0ff;font-family:Helvetica,Arial,sans-serif;font-size:10px;font-weight:bold;line-height:15px';
        g2d_fpsText.innerHTML = 'FPS';
        g2d_fpsDiv.appendChild( g2d_fpsText );

        p_canvas.parentElement.appendChild(g2d_container);
    }

    public function render(p_context:IContext):Void {
        if (visible) {
            if (g2d_fpsDiv.parentElement == null) {
                g2d_container.appendChild(g2d_fpsDiv);
            }

            var time = Date.now().getTime();

            g2d_frames++;

            if ( time > g2d_previousTime + 1000 ) {
                fps = Math.round( ( g2d_frames * 1000 ) / ( time - g2d_previousTime ) );

                g2d_fpsText.textContent = 'FPS: ' + fps +" Drawcalls: " + drawCalls;
                g2d_previousTime = time;
                g2d_frames = 0;
            }
        } else {
            if (g2d_fpsDiv.parentElement != null) {
                g2d_container.removeChild(g2d_fpsDiv);
            }
        }
    }

    public function clear():Void {
        drawCalls = 0;
    }
}