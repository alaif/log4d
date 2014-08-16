/**
 * Log4D - industrial strength logging for D.
 *
 * Version: $Id$
 *
 * Author: Kevin Lamonte, <a href="mailto:kevin.lamonte@gmail.com">kevin.lamonte@gmail.com</a>
 *
 * License: Boost1.0
 *
 *     Copyright (C) 2014  Kevin Lamonte
 *
 * Boost Software License - Version 1.0 - August 17th, 2003
 *
 * Permission is hereby granted, free of charge, to any person or
 * organization obtaining a copy of the software and accompanying
 * documentation covered by this license (the "Software") to use, reproduce,
 * display, distribute, execute, and transmit the Software, and to prepare
 * derivative works of the Software, and to permit third-parties to whom the
 * Software is furnished to do so, all subject to the following:
 *
 * The copyright notices in the Software and this entire statement, including
 * the above license grant, this restriction and the following disclaimer,
 * must be included in all copies of the Software, in whole or in part, and
 * all derivative works of the Software, unless such copies or derivative
 * works are solely in the form of machine-executable object code generated
 * by a source language processor.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
 * SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
 * FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR
 * OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
 * USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

module log4d.appender.screen;

// Description ---------------------------------------------------------------

// Imports -------------------------------------------------------------------

import std.logger;
import log4d.appender;
import log4d.logger;

// Defines -------------------------------------------------------------------

// Globals -------------------------------------------------------------------

// Classes -------------------------------------------------------------------

/**
 * The Screen appender writes to stdout/stderr.
 */
public class Screen : Appender {

    /// If true, render to stdout.  Otherwise, render to stderr.
    public bool stdout = true;

    /**
     * Public constructor
     */
    public this() {
    }

    /**
     * Subclasses must implement logging function.
     *
     * Params:
     *    logger = logger that generated the message
     *    message = the message parameters
     */
    override public void log(Logger logger, Logger.LogEntry message) {
	if (filter !is null) {
	    if (!filter.ok(logger, message)) {
		return;
	    }
	}
	auto rendered = layout.render(logger, message);
	if (stdout == true) {
	    std.stdio.stdout.writeln(rendered);
	} else {
	    std.stdio.stderr.writeln(rendered);
	}
    }

}

// Functions -----------------------------------------------------------------
