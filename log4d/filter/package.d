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

module log4d.filter;

// Description ---------------------------------------------------------------

// Imports -------------------------------------------------------------------

import std.logger;
import log4d.logger;

// Defines -------------------------------------------------------------------

// Globals -------------------------------------------------------------------

// Classes -------------------------------------------------------------------

/**
 * A Filter is responsible for deciding if a message should be emitted by an
 * Appender.
 */
public abstract class Filter {

    /// If true, then if the message matches this Filter it should be emitted
    /// by the Appender.
    public bool acceptOnMatch = true;

    /**
     * Subclasses must implement filtering function.
     *
     * Params:
     *    logger = logger that generated the message
     *    message = the message parameters
     *
     * Returns:
     *    if true, then this message should be emitted by the Appender, else suppress the message
     */
    public bool ok(Logger logger, Logger.LogEntry message);

    /**
     * Protected constructor for subclasses.
     */
    protected this() {
    }

    /**
     * Public constructor finds subclass by name.
     *
     * Params:
     *    className = name of subclass to return
     */
    static public Filter getFilter(string className) {
	if (className == "log4d.filter.LevelMatch") {
	    return new LevelMatch();
	}
	assert(0, className ~ " not found");
    }
}

/**
 * LevelMatch matches messages that 
 */
public class LevelMatch : Filter {

    /// The log level to match on
    public LogLevel levelToMatch = LogLevel.info;

    /**
     * Determine if this message should be emitted.
     *
     * Params:
     *    logger = logger that generated the message
     *    message = the message parameters
     *
     * Returns:
     *    if true, then this message should be emitted by the Appender, else suppress the message
     */
    override public bool ok(Logger logger, Logger.LogEntry message) {
	if ((message.logLevel == levelToMatch) && (acceptOnMatch == true)) {
	    return true;
	}
	if ((message.logLevel != levelToMatch) && (acceptOnMatch == false)) {
	    return true;
	}
	return false;
    }
}

// Functions -----------------------------------------------------------------

