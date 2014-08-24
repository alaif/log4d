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
 *
 * Unlike standard std.logger Loggers, Log4DLoggers inherit their log level
 * from their parent logger if the level is not explicitly set.  However, due
 * to the setter for Logger.logLevel being declared final in std.logger.core,
 * one must use Log4DLogger.setLogLevel() to programmatically set a different
 * logLevel that the rootLogger's logLevel.  This only impacts programs that
 * set the logLevel's in D code, for loggers specified in the config file via
 * Log4D.init(filename) this is a non-issue.
 */
public class Log4DLogger : Logger {

    /// The root logger name
    public static const string ROOT_LOGGER = "rootLogger";

    /// The name (category) of this Log4DLogger
    public string name;

    /// The appenders to write to.  If empty, go up the logger name
    /// (category) heirarchy.
    public Appender [] appenders;

    /// A cached reference to my parent logger.
    private Log4DLogger myParent = null;

    /// If true, the log level was explicitly set.
    private bool hasLogLevel = false;

    /**
     * Explicitly set the log level such that it does not inherit from its
     * parent Log4DLogger.
     *
     * Params:
     *    logLevel = the new LogLevel to use
     */
    public void setLogLevel(LogLevel logLevel) {
	this.logLevel = logLevel;
	hasLogLevel = true;
	LogManager.getInstance().determineLogLevels();
    }

    /**
     * Unset the log level such that it inherits the log level from its
     * parent Log4DLogger.
     */
    public void unsetLogLevel() {
	this.logLevel = parent().logLevel;
	hasLogLevel = false;
	LogManager.getInstance().determineLogLevels();
    }

    /**
     * Figure out the appropriate log level for this logger, either one to
     * inherit from its parent Log4DLogger, or the level set on this
     * Log4DLogger.
     */
    public void determineLogLevel() {
	if (hasLogLevel == false) {
	    this.logLevel = parent().logLevel;
	}
    }

    /**
     * Figure out the appropriate parent logger for this logger.  This is a
     * performance thing so that parent() is not scanning every time.
     */
    public void resetParent() {
	myParent = null;
	parent();
    }

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
     *    hasLogLevel = if true, do not inherit the logLevel from the parent
     *    logLevel = initial logging level
     */
    public this(string name, bool hasLogLevel, LogLevel logLevel) {
	super(logLevel);
	this.hasLogLevel = hasLogLevel;
	this.name = name;
	if (hasLogLevel == false) {
	    this.logLevel = parent().logLevel;
	}
    }

    /**
     * Find my parent logger in the heirarchy of loggers.
     *
     * Returns:
     *    parent logger
     */
    public Log4DLogger parent() {
	assert(this !is LogManager.getInstance().getRootLogger());

	if (myParent !is null) {
	    return myParent;
	}

	auto parentName = name;

	// Perl-style match, use '::' as delimiter
	auto regPerl = ctRegex!(`^(.*)::((?!::).*)$`);

	// Normal match, use '.' as delimiter
	auto regNormal = ctRegex!(`^(.*)\.([^\.]*)$`);

	auto reg = regNormal;
	if (indexOf(name, "::") >= 0) {
	    reg = regPerl;
	}

	while (parentName != "") {
	    // std.stdio.stdout.writefln("1 parentName %s", parentName);
	    auto mat = matchFirst(parentName, reg);
	    // std.stdio.stdout.writefln("2 mat: %s", mat);
	    if (mat) {
		parentName = mat.captures[1];
		if (LogManager.getInstance().hasLogger(parentName)) {
		    myParent = LogManager.getInstance().getLogger(parentName);
		    return myParent;
		}
	    } else {
		myParent = LogManager.getInstance().getRootLogger();
		return myParent;
	    }
	}
	// Should never get here
	assert(0, "Did not find parent logger name");
    }
    unittest {
	auto log = getLogger("this.is.a.logger.name", false, LogLevel.warning);
	auto log2 = getLogger("this.is", true, LogLevel.info);
	assert(log.logLevel == log2.logLevel);
	assert(log.logLevel != LogManager.getInstance().getRootLogger().logLevel);
	assert(log2 is log.parent());
	assert(log2.parent().name == "rootLogger");
	log2 = getLogger("this::is::a::logger::name", false, LogLevel.info);
	log = getLogger("this::is::a", false, LogLevel.error);
	// std.stdio.stdout.writefln("log2.parent: %s", log2.parent().name);

	assert(log is log2.parent());
	assert(log.logLevel == log2.logLevel);
	assert(log.logLevel == LogManager.getInstance().getRootLogger().logLevel);
	log = new Log4DLogger("this.is:a.logger:name", false, LogLevel.info);
	assert(Log4DLogger.ROOT_LOGGER == log.parent().name);
	assert(LogManager.getInstance().getRootLogger() is log.parent());
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
