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

module log4d.appender.file;

// Description ---------------------------------------------------------------

// Imports -------------------------------------------------------------------

import std.logger;
import std.stdio;
import log4d.appender;
import log4d.logger;

// Defines -------------------------------------------------------------------

// Globals -------------------------------------------------------------------

// Classes -------------------------------------------------------------------

/**
 * The FileAppender writes to a file.
 */
public class FileAppender : Appender {

    /// Filename
    private string filename;

    /// File reference
    private File file;

    /**
     * Public constructor
     */
    public this() {
    }

    /**
     * Release any resources used by this appender, e.g. close a file,
     * terminate a socket connection, etc.
     */
    override public void shutdown() {
	if (file.isOpen()) {
	    file.close();
	}
    }

    /**
     * Set a property from the config file.
     *
     * Params:
     *    name = name of property to set
     *    value = value of property to set
     */
    override public void setProperty(string name, string value) {
	super.setProperty(name, value);
	if (name == "filename") {
	    filename = value;
	    // TODO: mode
	    file = File(filename, "a");
	    // TODO: flush
	}
    }

    /**
     * Subclasses must implement logging function.
     *
     * Params:
     *    logger = logger that generated the message
     *    message = the message parameters
     */
    override public void log(Log4DLogger logger, Logger.LogEntry message) {
	if (filter !is null) {
	    if (!filter.ok(logger, message)) {
		return;
	    }
	}
	if (layout !is null) {
	    auto rendered = layout.render(logger, message);
	    file.write(rendered);
	} else {
	    auto rendered = message.msg ~ "\n";
	    file.write(rendered);
	}
    }

}

// Functions -----------------------------------------------------------------
