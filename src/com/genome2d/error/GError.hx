package com.genome2d.error;
class GError {
    public function new(?p_message:String) {
        if (p_message == null) p_message = "Unspecified error.";
        throw p_message;
    }
}