/* web msfconsole (console.js)
 * Copyright (c) 2006 LMH <lmh@info-pull.com>
 * All Rights Reserved.
 * Inspired by Jesse Ruderman's Javascript Shell.
*/

var console_history = new Array();  // Commands history
var console_hindex  = 0;            // Index to current command history
var console_input;                  // Object to console input
var console_output;                 // Object to console output
var console_prompt;                 // Object to console prompt

function console_refocus() {
    console_input.blur();
    console_input.focus();
}

function console_printline(s, type) {
    if ((s=String(s))) {
        var n = document.createElement("div");
        n.appendChild(document.createTextNode(s));
        n.className = type;
        console_output.appendChild(n);
        return n;
    }
}

var prompt = 'msf> ';
var console_commands = {
    print : function print(s) {
        console_printline(s, "info");
    },
    clear: function clear() {
        var child_preserve = 3;
        while (console_output.childNodes[child_preserve]) 
            console_output.removeChild(console_output.childNodes[child_preserve]);
    }
}

function console_tabcomplete() {
    // TODO: get console_input.value, send to process_cmd with mode=tabcomplete
    // retrieve array of possible matches
    // put them to output container
    // done.
}

function console_execute() {
	if (console_commands[console_input.value]) {
		f = console_commands[console_input.value];
		alert(f);
	}
}

function console_update_output(req) {
	console_printline(req.responseText);
	console_input.focus();
}

function console_keydown(e) {

	if (e.keyCode == 8) {
		window.title = console_input.value;
	}

    if (e.keyCode == 13) {          // enter
        console_history.push(console_input.value);
        try { console_execute(); } catch(er) { alert(er); };
		
		new Ajax.Updater("console_update", document.location, {
			asynchronous:true,
			evalScripts:true,
			parameters:"cmd=" + escape(console_input.value),
			onComplete:console_update_output
		});	
	
		console_input.value = "";
		console_input.focus();
		console_prompt = prompt;
		return false;
		
    } else if (e.keyCode == 38) {   // up
        // TODO: place upper cmd in history on console_input.value
    } else if (e.keyCode == 40) {   // down
        // TODO: place lower cmd in history on console_input.value
    } else if (e.keyCode == 9) {   // tab
        console_tabcomplete();
        setTimeout(function() { console_refocus(); }, 0);
    }

}

function console_init() {

    console_input   = document.getElementById("console_input");
    console_output  = document.getElementById("console_output");
	console_prompt  = document.getElementById("console_prompt");
	
	console_prompt.value = prompt;
	console_input.focus();
    return true;
}

