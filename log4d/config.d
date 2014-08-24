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

module log4d.config;

// Description ---------------------------------------------------------------

// Imports -------------------------------------------------------------------

import core.sync.mutex;
import std.conv;
import std.exception;
import std.file;
import std.logger;
import std.stdio;
import std.string;
import log4d.appender;
import log4d.filter;
import log4d.layout;
import log4d.logger;

// Defines -------------------------------------------------------------------

// Globals -------------------------------------------------------------------

// Classes -------------------------------------------------------------------

/**
 * LogManager configures / manages the entire Log4D subsystem.
 */
public class LogManager {

    /// Mutex used by getLogger()
    public Mutex mutex;

    /// Singleton instance
    __gshared private LogManager instance;

    /// The special root logger
    private Log4DLogger rootLogger;

    /// List of loggers by category
    private Log4DLogger[string] loggers;

    /// If true, an init function has been called
    public bool initialized = false;

    /// If true, one cannot call an init function again
    public bool initLocked = false;

    /**
     * Obtain the singleton instance, creating it if needed.
     *
     * Returns:
     *    singleton instance
     */
    public static LogManager getInstance() {
	synchronized {
	    if (instance is null) {
		instance = new LogManager();
	    }
	}
	return instance;
    }

    /**
     * Singleton constructor
     */
    private this() {
	mutex = new Mutex();

	// Setup the root logger with default DEBUG/TRACE level
	rootLogger = new Log4DLogger(Log4DLogger.ROOT_LOGGER, true, LogLevel.trace);
    }

    /**
     * Reset all the logLevels of the defined loggers
     */
    public void determineLogLevels() {
	synchronized (mutex) {
	    foreach (logger; loggers) {
		logger.resetParent();
		logger.determineLogLevel();
	    }
	}
    }

    /**
     * Factory method to retrieve a Logger instance.  It will create one if
     * it does not already exist.
     *
     * By default the logLevel is inherited from the parent logger.  Set
     * hasLogLevel to true to break the inheritance and make this Logger (and
     * all its children) use a different LogLevel.
     *
     * Params:
     *    name = logger name, used as a global unique key
     *    hasLogLevel = if true, do not inherit the logLevel from the parent
     *    logLevel = LogLevel.info/debug/...
     *
     * Returns:
     *    logger instance
     */
    public Log4DLogger getLogger(string name, bool hasLogLevel = false,
	LogLevel logLevel = LogLevel.trace) {

	Log4DLogger logger;
	synchronized (mutex) {
	    if (name in loggers) {
		logger = loggers[name];
	    } else {
		logger = new Log4DLogger(name, hasLogLevel, logLevel);
		loggers[name] = logger;
		foreach (logger; loggers) {
		    logger.resetParent();
		}
		if (hasLogLevel == true) {
		    determineLogLevels();
		}
	    }
	}
	return logger;
    }

    /**
     * Factory method to retrieve the root Logger instance.
     *
     * Returns:
     *    logger instance
     */
    public Log4DLogger getRootLogger() {
	assert(rootLogger !is null);
	return rootLogger;
    }

    /**
     * Check if a Logger with this name is defined.
     *
     * Params:
     *    name = logger name, used as a global unique key
     *
     * Returns:
     *    true if a logger with this name exists
     */
    public bool hasLogger(string name) {
	synchronized (mutex) {
	    if (name in loggers) {
		return true;
	    }
	}
	return false;
    }

    /**
     * Perform "easy" initialization of Log4D: one rootLogger logging
     * everything to a Screen appender.
     */
    public void easyInit() {
	initFromString(q{
log4d.rootLogger              = TRACE, CONSOLE
log4d.appender.CONSOLE        = log4d.appender.Screen
log4d.appender.CONSOLE.layout = log4d.layout.SimpleLayout
});
    }

    /**
     * Initialize Log4D system.
     *
     * Params:
     *    configFilename = name of a file to read the configuration from
     */
    public void init(string configFilename) {
	initFromString(readText(configFilename));
    }

    /**
     * Initialize Log4D system.  Subsequent calls to any of the init
     * functions will throw an exception.
     *
     * Params:
     *    configFilename = name of a file to read the configuration from
     */
    public void initOnce(string configFilename) {
	initFromString(readText(configFilename));
	initLocked = true;
    }

    /**
     * Initialize Log4D system.
     *
     * Params:
     *    configData = contents of a configuration file
     */
    public void initFromString(string configData) {
	enforce(initLocked == false, "initOnce() has already been called");

	// For the re-init case, we just shutdown all the appenders and
	// re-run everything else as normal.
	foreach (logger; loggers) {
	    foreach (appender; logger.appenders) {
		appender.shutdown();
	    }
	    logger.appenders.length = 0;
	}
	foreach (appender; getRootLogger().appenders) {
	    appender.shutdown();
	}
	getRootLogger().appenders.length = 0;

	// Redirect stdlog to Log4D
	stdlog = getRootLogger();

	// List of appenders by name
	Appender[string] appenders;

	// List of appenders to add to the root logger
	bool rootAppendersToAdd[string];

	// List of appenders to add to non-root logger
	string [] loggerAppendersToAdd[string];

	size_t lineNumber = 0;
	foreach (line; splitLines(configData)) {
	    lineNumber++;
	    line = strip(line);
	    if (line.length == 0) {
		continue;
	    }
	    if (line[0] == '#') {
		continue;
	    }
	    auto tokens = split(line, "=");
	    if (tokens.length == 2) {
		auto key	= to!string(strip(tokens[0]));
		auto value	= to!string(strip(tokens[1]));

		// stdout.writefln("Key: %s", key);
		// stdout.writefln("   : %s", value);

		auto keyTokens = split(key, ".");
		// stdout.writefln("   --> %s", keyTokens);

		// Look for <log4X>.<something>
		if (keyTokens.length < 2) {
		    stderr.writefln("Error in config line %d: unknown directive \'%s\'",
			lineNumber, line);
		    continue;
		}

		// Check for supported logging directives
		switch (toLower(keyTokens[0])) {
		case "log4d":
		    break;
		case "log4j":
		    break;
		case "log4perl":
		    break;
		default:
		    stderr.writefln("Error in config line %d: unknown directive \'%s\'",
			lineNumber, line);
		    continue;
		}

		switch (keyTokens[1]) {
		case "rootLogger":
		    // Looking for <LEVEL>, <appender 1> [, <appender 2> ]...
		    auto appenderTokens = split(value, ",");
		    // stdout.writefln("   --> %s", appenderTokens);
		    if (appenderTokens.length < 2) {
			stderr.writefln("Error in config line %d: unknown directive \'%s\'",
			    lineNumber, line);
			continue;
		    }
		    getRootLogger().setLogLevel(levelFromString(strip(appenderTokens[0])));
		    foreach (a; appenderTokens[1 .. $]) {
			rootAppendersToAdd[strip(a)] = true;
		    }
		    // stdout.writefln("  rootAppendersToAdd: %s", rootAppendersToAdd);
		    break;

		case "appender":
		    if (keyTokens.length == 3) {
			// <log4X>.<appender>.<appender name> = <classname>
			auto newAppender = Appender.getAppender(value);
			appenders[keyTokens[2]] = newAppender;
		    } else if (keyTokens.length == 4) {
			// <log4X>.<appender>.<appender name>.<property> = <value>
			auto appender = appenders[keyTokens[2]];
			if (!appender) {
			    stderr.writefln("Error in config line %d: appender \'%s\' is not defined",
				lineNumber, keyTokens[2]);
			    continue;
			}
			switch (keyTokens[3]) {
			case "layout":
			    appender.layout = Layout.getLayout(value);
			    break;
			case "filter":
			    appender.filter = Filter.getFilter(value);
			    break;
			default:
			    appender.setProperty(keyTokens[3], value);
			    break;
			}
		    } else if (keyTokens.length == 5) {
			// <log4X>.<appender>.<appender name>.<level|filter>.<property> = <value>
			auto appender = appenders[keyTokens[2]];
			if (!appender) {
			    stderr.writefln("Error in config line %d: appender \'%s\' is not defined",
				lineNumber, keyTokens[2]);
			    continue;
			}
			switch (keyTokens[3]) {
			case "layout":
			    if (!appender.layout) {
				stderr.writefln("Error in config line %d: Layout for appender \'%s\' is not defined",
				    lineNumber, keyTokens[2]);
				continue;
			    }
			    appender.layout.setProperty(keyTokens[4], value);
			    break;
			case "filter":
			    if (!appender.filter) {
				stderr.writefln("Error in config line %d: Filter for appender \'%s\' is not defined",
				    lineNumber, keyTokens[2]);
				continue;
			    }
			    appender.filter.setProperty(keyTokens[4], value);
			    break;
			default:
			    stderr.writefln("Error in config line %d: unknown appender property \'%s\'",
				lineNumber, keyTokens[3] ~ "." ~ keyTokens[4]);
			    continue;
			}
		    }
		    break;

		case "logger":
		    // <log4X>.<logger>.<my.logger.name> = <LEVEL>, <appender 1> [, <appender 2> ]...
		    auto loggerName = join(keyTokens[2 .. $], ".");
		    auto logger = getLogger(loggerName);

		    auto appenderTokens = split(value, ",");
		    // stdout.writefln("   --> %s", appenderTokens);
		    if (appenderTokens.length < 2) {
			stderr.writefln("Error in config line %d: unknown directive \'%s\'",
			    lineNumber, line);
			continue;
		    }
		    logger.setLogLevel(levelFromString(strip(appenderTokens[0])));
		    foreach (a; appenderTokens[1 .. $]) {
			loggerAppendersToAdd[strip(a)] ~= logger.name;
		    }
		    // stdout.writefln("  rootAppendersToAdd: %s", rootAppendersToAdd);
		    break;

		default:
		    stderr.writefln("Error in config line %d: unknown directive \'%s\'",
			lineNumber, line);
		    break;
		}

	    }

	} // foreach (line; splitLines(configData))

	// Tie up all the appenders and loggers
	foreach (appenderName; appenders.keys) {
	    if (appenderName in rootAppendersToAdd) {
		// stdout.writefln("  rootLogger add appender: %s", appenderName);
		getRootLogger().addAppender(appenders[appenderName]);
	    }
	}
	foreach (appenderName; loggerAppendersToAdd.keys) {
	    foreach (loggerName; loggerAppendersToAdd[appenderName]) {
		// stdout.writefln("  logger %s add appender: %s", loggerName, appenderName);
		getLogger(loggerName).addAppender(appenders[appenderName]);
	    }
	}

	initialized = true;
    }

}

// Functions -----------------------------------------------------------------

/**
 * Perform "easy" initialization of Log4D: one rootLogger logging
 * everything to a Screen appender.
 */
public void easyInit() {
    LogManager.getInstance().easyInit();
}

/**
 * Initialize Log4D system.
 *
 * Params:
 *    configFilename = name of a file to read the configuration from
 */
public void init(string configFilename) {
    LogManager.getInstance().init(configFilename);
}

/**
 * Initialize Log4D system.  Subsequent calls to any of the init functions
 * will throw an exception.
 *
 * Params:
 *    configFilename = name of a file to read the configuration from
 */
public void initOnce(string configFilename) {
    LogManager.getInstance().initOnce(configFilename);
}

/**
 * Factory method to retrieve the root Logger instance.
 *
 * Returns:
 *    logger instance
 */
public Log4DLogger getRootLogger() {
    return LogManager.getInstance().getRootLogger();
}

/**
 * Factory method to retrieve a Logger instance.  It will create one if it
 * does not already exist.
 *
 * By default the logLevel is inherited from the parent logger.  Set
 * hasLogLevel to true to break the inheritance and make this Logger (and all
 * its children) use a different LogLevel.
 *
 *
 * Params:
 *    name = logger name, used as a global unique key
 *    hasLogLevel = if true, do not inherit the logLevel from the parent
 *    logLevel = LogLevel.info/debug/...
 *
 * Returns:
 *    logger instance
 */
public Log4DLogger getLogger(string name, bool hasLogLevel = false,
    LogLevel logLevel = LogLevel.trace) {

    return LogManager.getInstance().getLogger(name, hasLogLevel, logLevel);
}

/**
 * Convert a string to a LogLevel
 *
 * Params:
 *    levelString = "info", "trace", ...
 *
 * Returns:
 *    the corresponding LogLevel
 */
public LogLevel levelFromString(string levelString) {
    switch (toLower(levelString)) {
    case "all":
	return LogLevel.all;
    case "debug":
	return LogLevel.trace;
    case "trace":
	return LogLevel.trace;
    case "info":
	return LogLevel.info;
    case "warning":
	return LogLevel.warning;
    case "error":
	return LogLevel.error;
    case "critical":
	return LogLevel.critical;
    case "fatal":
	return LogLevel.fatal;
    case "off":
	return LogLevel.off;
    default:
	return LogLevel.off;
    }
}
