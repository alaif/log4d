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
import std.regex;
import std.string;
import log4d.config;
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
     * Set a filter property.  All filters support AcceptOnMatch.
     *
     * Params:
     *    name = name of property to set
     *    value = value of property to set
     */
    public void setProperty(string name, string value) {
	if (name == "AcceptOnMatch") {
	    switch (toLower(value)) {
	    case "false":
		acceptOnMatch = false;
		break;
	    case "off":
		acceptOnMatch = false;
		break;
	    case "0":
		acceptOnMatch = false;
		break;
	    case "no":
		acceptOnMatch = false;
		break;
	    default:
		// Anything else is true
		acceptOnMatch = true;
		break;
	    }
	}
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
	if (className == "log4d.filter.LevelRange") {
	    return new LevelRange();
	}
	if (className == "log4d.filter.StringMatch") {
	    return new StringMatch();
	}
	assert(0, className ~ " not found");
    }
}

/**
 * LevelMatch matches against one specific logging level, specified in the
 * logging configuration file by LevelToMatch.
 */
public class LevelMatch : Filter {

    /// The log level to match on
    public LogLevel levelToMatch = LogLevel.info;

    /**
     * Set a property from the config file.
     *
     * Params:
     *    name = name of property to set
     *    value = value of property to set
     */
    override public void setProperty(string name, string value) {
	super.setProperty(name, value);
	if (name == "LevelToMatch") {
	    levelToMatch = levelFromString(value);
	}
    }

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

/**
 * LevelRange matches an inclusive range of logging levels, specified in the
 * logging configuration file by LevelMin and LevelMax.
 */
public class LevelRange : Filter {

    /// The minimum log level to match on
    public LogLevel levelMin = LogLevel.all;

    /// The minimum log level to match on
    public LogLevel levelMax = LogLevel.off;

    /**
     * Set a property from the config file.
     *
     * Params:
     *    name = name of property to set
     *    value = value of property to set
     */
    override public void setProperty(string name, string value) {
	super.setProperty(name, value);
	if (name == "LevelMin") {
	    levelMin = levelFromString(value);
	}
	if (name == "LevelMax") {
	    levelMax = levelFromString(value);
	}
    }

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
	if ((message.logLevel >= levelMin) &&
	    (message.logLevel <= levelMax) &&
	    (acceptOnMatch == true)
	) {
	    return true;
	}
	if (!((message.logLevel >= levelMin) &&
		(message.logLevel <= levelMax)) &&
	    (acceptOnMatch == false)
	) {
	    return true;
	}
	return false;
    }
}

/**
 * StringMatch matches the logged message text against a regex, specified in
 * the logging configuration file by StringToMatch.
 */
public class StringMatch : Filter {

    /// The string to match on
    public auto stringToMatch = regex(".*");

    /**
     * Set a property from the config file.
     *
     * Params:
     *    name = name of property to set
     *    value = value of property to set
     */
    override public void setProperty(string name, string value) {
	super.setProperty(name, value);
	if (name == "StringToMatch") {
	    stringToMatch = regex(value);
	}
    }

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
	bool matched = false;
	auto mat = match(message.msg, stringToMatch);
	if (mat) {
	    matched = true;
	}

	if ((matched == true) && (acceptOnMatch == true)) {
	    return true;
	}
	if ((matched == false) && (acceptOnMatch == false)) {
	    return true;
	}
	return false;
    }
}

// Functions -----------------------------------------------------------------
