/*
* 	Genome2D - GPU 2D framework utilizing Molehill API
*
*	Copyright 2011 Peter Stefcek. All rights reserved.
*
*	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
*/
package com.genome2d.error;

class GError {
    public function new(?p_message:String) {
        if (p_message == null) p_message = "Unspecified error.";
        throw p_message;
    }
}