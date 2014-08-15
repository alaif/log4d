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

import log4d.appender;
import log4d.logger;
import core.sync.mutex;
import std.logger;

// Defines -------------------------------------------------------------------

// Globals -------------------------------------------------------------------

// Classes -------------------------------------------------------------------

/**
 * LogManager configures / manages the entire Log4D subsystem.
 */
public class LogManager {

    /// Mutex used by getLogger()
    private Mutex mutex;

    /// Singleton instance
    __gshared private LogManager instance;

    /// List of loggers by category
    private Log4DLogger[string] loggers;

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

	// Setup the root logger with default INFO level
	auto rootLogger = getLogger(Log4DLogger.ROOT_LOGGER, LogLevel.info);
    }

    /**
     * Factory method to retrieve a Logger instance.  It will create one if
     * it does not already exist.
     *
     * Params:
     *    name = logger name, used as a global unique key
     *    logLevel = LogLevel.info/debug/...
     *
     * Returns:
     *    logger instance
     */
    public Log4DLogger getLogger(string name, LogLevel logLevel = LogLevel.all) {
	Log4DLogger logger;
	synchronized (mutex) {
	    if (name in loggers) {
		logger = loggers[name];
	    } else {
		logger = new Log4DLogger(name, logLevel);
		loggers[name] = logger;
	    }
	}
	return logger;
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
     * Initialize Log4D system.
     *
     * Params:
     *    configFilename = name of a file to read the configuration from
     */
    public void init(string configFilename) {
	// Redirect stdlog to Log4D
	stdlog = getLogger(Log4DLogger.ROOT_LOGGER);

	// TODO - read from the file


    }

}

// Functions -----------------------------------------------------------------

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
 * Factory method to retrieve a Logger instance.  It will create one if it
 * does not already exist.
 *
 * Params:
 *    name = logger name, used as a global unique key
 *    logLevel = LogLevel.info/debug/...
 *
 * Returns:
 *    logger instance
 */
public Log4DLogger getLogger(string name, LogLevel logLevel = LogLevel.all) {
    return LogManager.getInstance().getLogger(name, logLevel);
}
