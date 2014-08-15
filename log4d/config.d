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

import log4d.logger;
import core.sync.mutex;
import std.logger;

// Defines -------------------------------------------------------------------

// Globals -------------------------------------------------------------------

// Classes -------------------------------------------------------------------

/**
 * Log4DManager configures / manages the entire Log4D subsystem.
 */
public class Log4DManager {

    /// Mutex used by getLogger()
    private Mutex mutex;

    /// Singleton instance
    __gshared private Log4DManager instance;

    /// List of loggers by category
    private Log4DLogger[string] loggers;

    /// TODO: List of appenders
    // private Appender[] appenders;

    /**
     * Obtain the singleton instance, creating it if needed.
     *
     * Returns:
     *    singleton instance
     */
    public static Log4DManager getInstance() {
	synchronized {
	    if (instance is null) {
		instance = new Log4DManager();
	    }
	}
	return instance;
    }

    /**
     * Singleton constructor
     */
    private this() {
	mutex = new Mutex();
    }

/+
    /**
     * Create the global instance
     */
    static this() {
	Log4D = new Log4DManager();
    }
+/

    /**
     * Factory method to retrieve instance.  It will create one if it does
     * not already exist.
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

}

// Functions -----------------------------------------------------------------

/**
 * Factory method to retrieve instance.  It will create one if it does
 * not already exist.
 *
 * Params:
 *    name = logger name, used as a global unique key
 *    logLevel = LogLevel.info/debug/...
 *
 * Returns:
 *    logger instance
 */
public Log4DLogger getLogger(string name, LogLevel logLevel = LogLevel.all) {
    return Log4DManager.getInstance().getLogger(name, logLevel);
}
