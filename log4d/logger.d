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

import std.regex;
import std.string;
import std.logger;
import log4d.appender;
import log4d.config;

// Defines -------------------------------------------------------------------

// Globals -------------------------------------------------------------------

// Classes -------------------------------------------------------------------

/**
 * The Log4DLogger interfaces the client-side API (std.logger) to the Log4D
 * system of appenders, filters, and layouts.
 */
public class Log4DLogger : Logger {

    /// The root logger name
    public static const string ROOT_LOGGER = "rootLogger";

    /// The name (category) of this Log4DLogger
    public string name;

    /// The appenders to write to.  If empty, go up the logger name (category) heirarchy.
    public Appender [] appenders;

    /**
     * Add an Appender to write to.
     *
     * Params:
     *    appender = Appender to add
     */
    public void addAppender(Appender appender) {
	appenders ~= appender;
    }

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
     * Find my parent logger in the heirarchy of loggers.
     *
     * Returns:
     *    parent logger
     */
    public Log4DLogger parent() {
	assert(name != ROOT_LOGGER);

	auto parentName = name;

	// Perl-style match, use '::' as delimiter
	auto regPerl = ctRegex!(`^(.*)::((?!::).*)$`);

	// Normal match, use '.' as delimiter
	auto regNormal = ctRegex!(`^(.*)\.([^\.]*)$`);

	auto reg = regNormal;
	if (indexOf(name, "::") >= 0) {
	    reg = regPerl;
	}

	while (parentName != ROOT_LOGGER) {
	    // std.stdio.stdout.writefln("%s", parentName);
	    auto mat = matchFirst(parentName, reg);
	    if (mat) {
		parentName = mat.captures[1];
	    } else {
		parentName = ROOT_LOGGER;
	    }
	    if (LogManager.getInstance().hasLogger(parentName)) {
		return LogManager.getInstance().getLogger(parentName);
	    }
	}
	// Should never get here
	assert(0, "Did not find parent logger name");
    }
    unittest {
	auto log = getLogger("this.is.a.logger.name", LogLevel.info);
	auto log2 = getLogger("this.is", LogLevel.info);
	assert(log2 is log.parent());
	assert(log2.parent().name == "rootLogger");
	log2 = getLogger("this::is::a::logger::name", LogLevel.info);
	log = getLogger("this::is::a", LogLevel.error);
	assert(log is log2.parent());
	log = new Log4DLogger("this.is:a.logger:name", LogLevel.info);
	assert(Log4DLogger.ROOT_LOGGER == log.parent().name);
    }

    /**
     * Send a LogEntry to the correct appender(s).
     *
     * Params:
     *    payload = all information associated with call to log function.
     */
    override void writeLogMsg(ref LogEntry payload) {
	if (appenders.length > 0) {
	    foreach (appender; appenders) {
		// std.stdio.stdout.writefln("[log] %x appender.log(%s)", appender.toHash(), payload.msg);
		appender.log(this, payload);
	    }
	} else {
	    if (name != ROOT_LOGGER) {
		parent().writeLogMsg(this, payload);
	    }
	}
    }

    /**
     * Send a LogEntry to the correct appender(s).
     *
     * Params:
     *    logger = the original logger called by the client
     *    payload = all information associated with call to log function.
     */
    private void writeLogMsg(Log4DLogger logger, ref LogEntry payload) {
	if (appenders.length > 0) {
	    foreach (appender; appenders) {
		// std.stdio.stdout.writefln("[parent] %x appender.log(%s)", appender.toHash(), payload.msg);
		appender.log(logger, payload);
	    }
	} else {
	    if (name != ROOT_LOGGER) {
		parent().writeLogMsg(logger, payload);
	    }
	}
    }

}

// Functions -----------------------------------------------------------------
