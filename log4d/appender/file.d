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

import std.array;
import std.datetime;
import std.conv;
import std.stdio;
import std.format;

// Defines -------------------------------------------------------------------

// Globals -------------------------------------------------------------------

// Classes -------------------------------------------------------------------

/**
 * FileAppender emits log messages to a file.
 */
public class FileAppender : Appender {

    /// File to write to
    protected File output;

    /// If true, colorize output
    protected bool colorize = false;

    /**
     * Protected constructor for subclasses
     */
    protected this() {
    }

    /**
     * Public constructor
     *
     * Params:
     *    filename = filename to append to logging messages
     */
    public this(string filename) {
	output = File(filename, "a");
    }

    /**
     * Emit the message to the user.
     *
     * Params:
     *    logger = Logger which generated the message
     *    time = time at which the message was generated
     *    level = Logger.INFO/DEBUG1/etc.
     *    msg = message to the user
     */
    override public void emit(Logger logger, SysTime time, Logger.Level level, string msg) {
	debug {
	    if (colorize) {
		output.write(timestamp(time, colorize), ' ', logger.name, ' ',
		    level.ansiColor, level.tag, ' ');
		output.write(msg);
		output.writeln(ECMATerminal.normal());
	    } else {
		output.write(timestamp(time, colorize), ' ', logger.name, ' ', level.tag, ' ');
		output.writeln(msg);
	    }
	} else {
	    if (colorize) {
		output.write(timestamp(time, colorize), ' ', level.ansiColor, level.tag, ' ');
		output.writef(msg);
		output.writeln(ECMATerminal.normal());
	    } else {
		output.write(timestamp(time, colorize), ' ', level.tag, ' ');
		output.writefln(msg);
	    }
	}
	output.flush();
    }

}

/**
 * StdoutAppender emits log messages to stdout.
 */
public class StdoutAppender : FileAppender {

    /**
     * Public constructor
     *
     * Params:
     *    colorize = if true, use SGR colors
     */
    public this(bool colorize = true) {
	this.output = stdout;
	this.colorize = colorize;
    }
}

// Functions -----------------------------------------------------------------

