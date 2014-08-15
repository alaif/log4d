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

module log4d.logger;

// Description ---------------------------------------------------------------

// Imports -------------------------------------------------------------------

import std.logger;

// Defines -------------------------------------------------------------------

// Globals -------------------------------------------------------------------

// Classes -------------------------------------------------------------------

/**
 * The Log4DLogger interfaces the client-side API (std.logger) to the Log4D
 * system of appenders, filters, and layouts.
 */
public class Log4DLogger : Logger {

    /// The name (category) of this Log4DLogger
    private string name;

    /**
     * Private constructor
     *
     * Params:
     *    name = logger name, used as both a string to the user and a global unique key
     *    logLevel = initial logging level
     */
    public this(string name, LogLevel logLevel) {
	super(logLevel);
	this.name = name;
    }

    /**
     * Send a LogEntry to the correct appender(s).
     *
     * Params:
     *    payload = All information associated with call to log function.
     */
    override void writeLogMsg(ref LogEntry payload) {
	// TODO: link the payload<-->this and pass to appender(s)
	std.stdio.stdout.writefln("LogEntry: %s", payload.msg);
    }

/+
    /**
     * Log a function enter event
     *
     * Params:
     *    args = arguments to writef
     */
    public void enter(T...)(T args) nothrow {
	debug {
	    msg(Level.FUNC_ENTER, args);
	}
    }

    /**
     * Log a function exit event
     *
     * Params:
     *    args = arguments to writef
     */
    public void exit(T...)(T args) nothrow {
	debug {
	    msg(Level.FUNC_EXIT, args);
	}
    }

    /**
     * Log an event at insane debug level
     *
     * Params:
     *    args = arguments to writef
     */
    public void debug3(T...)(T args) nothrow {
	debug {
	    msg(Level.DEBUG3, args);
	}
    }

    /**
     * Log an event at moderate debug level
     *
     * Params:
     *    args = arguments to writef
     */
    public void debug2(T...)(T args) nothrow {
	debug {
	    msg(Level.DEBUG2, args);
	}
    }

    /**
     * Log an event at light debug level
     *
     * Params:
     *    args = arguments to writef
     */
    public void debug1(T...)(T args) nothrow {
	debug {
	    msg(Level.DEBUG1, args);
	}
    }
+/

}

// Functions -----------------------------------------------------------------
