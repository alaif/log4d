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

module log4d.layout;

// Description ---------------------------------------------------------------

// Imports -------------------------------------------------------------------

import core.thread;
import std.array;
import std.datetime;
import std.format;
import std.logger;
import std.string;
import std.socket;
import log4d.config;
import log4d.logger;

// Defines -------------------------------------------------------------------

// Globals -------------------------------------------------------------------

// Classes -------------------------------------------------------------------

/**
 * A Layout is responsible for rendering the data of a log message to a
 * string.
 */
public abstract class Layout {

    /**
     * Subclasses must implement rendering function.
     *
     * Params:
     *    logger = logger that generated the message
     *    message = the message parameters
     *
     * Returns:
     *    string that is ready to be emitted by the Appender
     */
    public string render(Log4DLogger logger, Logger.LogEntry message);

    /**
     * Protected constructor for subclasses.
     */
    protected this() {
    }

    /**
     * Subclasses must implement property setter.
     *
     * Params:
     *    name = name of property to set
     *    value = value of property to set
     */
    public void setProperty(string name, string value) {
    }

    /**
     * Public constructor finds subclass by name.
     *
     * Params:
     *    className = name of subclass to return
     */
    static public Layout getLayout(string className) {
	if (className == "log4d.layout.SimpleLayout") {
	    return new SimpleLayout();
	}
	if (className == "log4d.layout.PatternLayout") {
	    return new PatternLayout();
	}
	assert(0, className ~ " not found");
    }
}

/**
 * SimpleLayout renders a message as "<LogLevel> - <message>"
 */
public class SimpleLayout : Layout {

    /**
     * Set a property from the config file.
     *
     * Params:
     *    name = name of property to set
     *    value = value of property to set
     */
    override public void setProperty(string name, string value) {
	super.setProperty(name, value);
    }

    /**
     * Render the message
     *
     * Params:
     *    logger = logger that generated the message
     *    message = the message parameters
     *
     * Returns:
     *    string that is ready to be emitted by the Appender
     */
    override public string render(Log4DLogger logger, Logger.LogEntry message) {
	auto writer = appender!string();
	formattedWrite(writer, "%s", message.logLevel);
	return toUpper(writer.data) ~ " - " ~ message.msg ~ "\n";
    }
}

/**
 * PatternLayout renders a message using printf-style formatting for fields.
 * The property ConversionPattern is used to specify a format string.  The
 * following formats are available:
 *
 *  %c Category of the logging event (logger name)
 *  %C The module name (NOT class name) at the logging call site
 *  %d Current date in yyyy/MM/dd hh:mm:ss format
 *  %d{...} Current date in customized format (see below)
 *  %F The filename at the logging call site
 *  %H The system hostname (as determined by std.socket.Socket.hostName)
 *  %l The "pretty function name" at the logging call site
 *  %L Line number at the logging call site
 *  %m The message to be logged
 *  %M Function name at the logging call site
 *  %n Newline (OS-independent)
 *  %p Priority (LogLevel) of the logging event (%p{1} shows the first letter)
 *  %P Process ID (PID) of the caller's process
 *  %r Number of milliseconds elapsed from program start to logging event
       (as determined by std.datetime.Clock.currAppTick)
 *  %R Number of milliseconds elapsed from last logging event to current
 *     logging event
 *  %t Thread ID of the caller's thread
 *  %T A stack trace of functions called
 *  %% A literal percent sign '%'
 *
 */
public class PatternLayout : Layout {

    /// The format string defaults to SimpleLayout
    private string conversionPattern = "%p - %m";

    /// Shared time since last call to render()
    private static __gshared TickDuration lastLogTime;

    /// The pieces of the formatted message
    private Token [] tokens;

    /**
     * PatternLayout.render() basically pieces together a string out of a
     * list of these token types.
     */
    private abstract class Token {
	/**
	 * Produce the string representation.
	 *
	 * Params:
	 *    logger = logger that generated the message
	 *    message = the message parameters
	 *
	 * Returns:
	 *    string that is ready to be appended in PatternLayout.render()
	 */
	public string render(Log4DLogger logger, Logger.LogEntry message);
    }

    /**
     * A string literal (stuff between the format tokens)
     */
    private class StringToken : Token {

	/// The string to show in render()
	private string literal;

	/**
	 * Public constructor
	 *
	 * Params:
	 *    literal = the string to render()
	 */
	public this(string literal) {
	    this.literal = literal;
	}

	/**
	 * Produce the string representation.
	 *
	 * Params:
	 *    logger = logger that generated the message
	 *    message = the message parameters
	 *
	 * Returns:
	 *    string that is ready to be appended in PatternLayout.render()
	 */
	override public string render(Log4DLogger logger, Logger.LogEntry message) {
	    return literal;
	}
    }

    /**
     * A format token has both a qualified placeholder field and an optional
     * braces field.
     */
    private abstract class FormatToken : Token {

	/// The printf part of the format.  Example: "%0.4c{2}", this
	/// would be "0.4".
	protected string printf;

	/// The braces part of the format  Example: "%0.4c{2}", this
	/// would be "2".
	protected string braces;

	/**
	 * Some subclasses change printf/braces in a different way.  Let them
	 * use an empty constructor.
	 */
	protected this() {
	}

	/**
	 * Public constructor
	 *
	 * Params:
	 *    printf = the printf part of the format
	 *    braces = the optional braces part
	 */
	public this(string printf, string braces) {
	    this.printf = printf;
	    this.braces = braces;
	}
    }

    /**
     * Format for the logger level: %p
     */
    private class LogLevelToken : FormatToken {

	/**
	 * Public constructor
	 *
	 * Params:
	 *    printf = the printf part of the format
	 *    braces = the optional braces part
	 */
	public this(string printf, string braces) {
	    this.braces = braces;
	    if (printf.length > 0) {
		this.printf = "%" ~ printf ~ "s";
	    }
	}

	/**
	 * Produce "INFO" or "I" depending on braces.
	 *
	 * Params:
	 *    message = the message parameters
	 *
	 * Returns:
	 *    string that is ready to be appended in PatternLayout.render()
	 */
	private string logLevelString(Logger.LogEntry message) {
	    if (braces == "1") {
		final switch (message.logLevel) {
		case LogLevel.all:
		    return "A";
		case LogLevel.trace:
		    return "T";
		case LogLevel.info:
		    return "I";
		case LogLevel.warning:
		    return "W";
		case LogLevel.error:
		    return "E";
		case LogLevel.critical:
		    return "C";
		case LogLevel.fatal:
		    return "F";
		case LogLevel.off:
		    return "O";
		}
	    }

	    final switch (message.logLevel) {
	    case LogLevel.all:
		return "ALL";
	    case LogLevel.trace:
		return "TRACE";
	    case LogLevel.info:
		return "INFO";
	    case LogLevel.warning:
		return "WARNING";
	    case LogLevel.error:
		return "ERROR";
	    case LogLevel.critical:
		return "CRITICAL";
	    case LogLevel.fatal:
		return "FATAL";
	    case LogLevel.off:
		return "OFF";
	    }
	}

	/**
	 * Produce the string representation.
	 *
	 * Params:
	 *    logger = logger that generated the message
	 *    message = the message parameters
	 *
	 * Returns:
	 *    string that is ready to be appended in PatternLayout.render()
	 */
	override public string render(Log4DLogger logger, Logger.LogEntry message) {
	    auto str = logLevelString(message);
	    if (printf.length > 0) {
		auto writer = appender!string();
		formattedWrite(writer, printf, str);
		return writer.data;
	    }
	    return str;
	}
    }

    /**
     * Format for the date: %D
     *
     * TODO: %d{<SimpleDateFormat spec>}
     */
    private class DateToken : FormatToken {

	/**
	 * Public constructor
	 *
	 * Params:
	 *    printf = the printf part of the format
	 *    braces = the optional braces part
	 */
	public this(string printf, string braces) {
	    super(printf, braces);
	}

	/**
	 * Produce the string representation.
	 *
	 * Params:
	 *    logger = logger that generated the message
	 *    message = the message parameters
	 *
	 * Returns:
	 *    string that is ready to be appended in PatternLayout.render()
	 */
	override public string render(Log4DLogger logger, Logger.LogEntry message) {
	    auto writer = appender!string();
	    if (braces == "ABSOLUTE") {
		// HH:mm:ss,SSS
		formattedWrite(writer, "%02d:%02d:%02d,%03d",
		    message.timestamp.hour,
		    message.timestamp.minute,
		    message.timestamp.second,
		    message.timestamp.fracSec.msecs);
	    } else if (braces == "ISO8601") {
		// yyyy/MM/DD HH:mm:ss,SSS
		formattedWrite(writer, "%04d/%02d/%02d %02d:%02d:%02d,%03d",
		    message.timestamp.year,
		    message.timestamp.month,
		    message.timestamp.day,
		    message.timestamp.hour,
		    message.timestamp.minute,
		    message.timestamp.second,
		    message.timestamp.fracSec.msecs);
	    } else if (braces == "DATE") {

		// This is ripped out of std.datetime.  monthToString() is
		// not public, boo.
		immutable string[12] shortMonthNames = [ "Jan", "Feb", "Mar",
		    "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov",
		    "Dec" ];

		// dd MMM yyyy HH:mm:ss,SSS
		formattedWrite(writer, "%02d %s %04d %02d:%02d:%02d,%03d",
		    message.timestamp.day,
		    // monthToString(message.timestamp.month),
		    shortMonthNames[message.timestamp.month - Month.jan],
		    message.timestamp.year,
		    message.timestamp.hour,
		    message.timestamp.minute,
		    message.timestamp.second,
		    message.timestamp.fracSec.msecs);
	    } else {
		// Default: yyyy/MM/DD HH:mm:ss
		formattedWrite(writer, "%04d/%02d/%02d %02d:%02d:%02d",
		    message.timestamp.year,
		    message.timestamp.month,
		    message.timestamp.day,
		    message.timestamp.hour,
		    message.timestamp.minute,
		    message.timestamp.second);
	    }
	    return writer.data;
	}
    }

    /**
     * Format for the log message: %m
     */
    private class MessageToken : FormatToken {

	/**
	 * Public constructor
	 *
	 * Params:
	 *    printf = the printf part of the format
	 *    braces = the optional braces part
	 */
	public this(string printf, string braces) {
	    this.braces = braces;
	    if (printf.length > 0) {
		this.printf = "%" ~ printf ~ "s";
	    }
	}

	/**
	 * Produce the string representation.
	 *
	 * Params:
	 *    logger = logger that generated the message
	 *    message = the message parameters
	 *
	 * Returns:
	 *    string that is ready to be appended in PatternLayout.render()
	 */
	override public string render(Log4DLogger logger, Logger.LogEntry message) {
	    if (printf.length > 0) {
		auto writer = appender!string();
		formattedWrite(writer, printf, message.msg);
		return writer.data;
	    }
	    return message.msg;
	}
    }

    /**
     * Format for the logger name: %c
     *
     * TODO: %c{1}, %c{2}, ...
     */
    private class LoggerNameToken : FormatToken {

	/**
	 * Public constructor
	 *
	 * Params:
	 *    printf = the printf part of the format
	 *    braces = the optional braces part
	 */
	public this(string printf, string braces) {
	    this.braces = braces;
	    if (printf.length > 0) {
		this.printf = "%" ~ printf ~ "s";
	    }
	}

	/**
	 * Produce the string representation.
	 *
	 * Params:
	 *    logger = logger that generated the message
	 *    message = the message parameters
	 *
	 * Returns:
	 *    string that is ready to be appended in PatternLayout.render()
	 */
	override public string render(Log4DLogger logger, Logger.LogEntry message) {
	    if (printf.length > 0) {
		auto writer = appender!string();
		formattedWrite(writer, printf, logger.name);
		return writer.data;
	    }
	    return logger.name;
	}
    }

    /**
     * Format for the module name: %C
     */
    private class ModuleNameToken : FormatToken {

	/**
	 * Public constructor
	 *
	 * Params:
	 *    printf = the printf part of the format
	 *    braces = the optional braces part
	 */
	public this(string printf, string braces) {
	    this.braces = braces;
	    if (printf.length > 0) {
		this.printf = "%" ~ printf ~ "s";
	    }
	}

	/**
	 * Produce the string representation.
	 *
	 * Params:
	 *    logger = logger that generated the message
	 *    message = the message parameters
	 *
	 * Returns:
	 *    string that is ready to be appended in PatternLayout.render()
	 */
	override public string render(Log4DLogger logger, Logger.LogEntry message) {
	    if (printf.length > 0) {
		auto writer = appender!string();
		formattedWrite(writer, printf, message.moduleName);
		return writer.data;
	    }
	    return message.moduleName;
	}
    }

    /**
     * Format for the function name: %F
     *
     * TODO: %F{1}, %F{2}, ...
     */
    private class FileNameToken : FormatToken {

	/**
	 * Public constructor
	 *
	 * Params:
	 *    printf = the printf part of the format
	 *    braces = the optional braces part
	 */
	public this(string printf, string braces) {
	    this.braces = braces;
	    if (printf.length > 0) {
		this.printf = "%" ~ printf ~ "s";
	    }
	}

	/**
	 * Produce the string representation.
	 *
	 * Params:
	 *    logger = logger that generated the message
	 *    message = the message parameters
	 *
	 * Returns:
	 *    string that is ready to be appended in PatternLayout.render()
	 */
	override public string render(Log4DLogger logger, Logger.LogEntry message) {
	    if (printf.length > 0) {
		auto writer = appender!string();
		formattedWrite(writer, printf, message.file);
		return writer.data;
	    }
	    return message.file;
	}
    }

    /**
     * Format for the pretty function name: %l
     */
    private class PrettyFunctionNameToken : FormatToken {

	/**
	 * Public constructor
	 *
	 * Params:
	 *    printf = the printf part of the format
	 *    braces = the optional braces part
	 */
	public this(string printf, string braces) {
	    this.braces = braces;
	    if (printf.length > 0) {
		this.printf = "%" ~ printf ~ "s";
	    }
	}

	/**
	 * Produce the string representation.
	 *
	 * Params:
	 *    logger = logger that generated the message
	 *    message = the message parameters
	 *
	 * Returns:
	 *    string that is ready to be appended in PatternLayout.render()
	 */
	override public string render(Log4DLogger logger, Logger.LogEntry message) {
	    if (printf.length > 0) {
		auto writer = appender!string();
		formattedWrite(writer, printf, message.prettyFuncName);
		return writer.data;
	    }
	    return message.prettyFuncName;
	}
    }

    /**
     * Format for the function name: %M
     *
     * TODO: %M{1}, %M{2}, ...
     */
    private class FunctionNameToken : FormatToken {

	/**
	 * Public constructor
	 *
	 * Params:
	 *    printf = the printf part of the format
	 *    braces = the optional braces part
	 */
	public this(string printf, string braces) {
	    this.braces = braces;
	    if (printf.length > 0) {
		this.printf = "%" ~ printf ~ "s";
	    }
	}

	/**
	 * Produce the string representation.
	 *
	 * Params:
	 *    logger = logger that generated the message
	 *    message = the message parameters
	 *
	 * Returns:
	 *    string that is ready to be appended in PatternLayout.render()
	 */
	override public string render(Log4DLogger logger, Logger.LogEntry message) {
	    if (printf.length > 0) {
		auto writer = appender!string();
		formattedWrite(writer, printf, message.funcName);
		return writer.data;
	    }
	    return message.funcName;
	}
    }

    /**
     * Format for the hostname: %H
     */
    private class HostnameToken : FormatToken {

	/// Determine hostname only once
	private __gshared string hostname = "";

	/**
	 * Public constructor
	 *
	 * Params:
	 *    printf = the printf part of the format
	 *    braces = the optional braces part
	 */
	public this(string printf, string braces) {
	    this.braces = braces;
	    if (printf.length > 0) {
		this.printf = "%" ~ printf ~ "s";
	    }

	    synchronized (LogManager.getInstance().mutex) {
		if (hostname.length == 0) {
		    hostname = Socket.hostName;
		}
	    }
	}

	/**
	 * Produce the string representation.
	 *
	 * Params:
	 *    logger = logger that generated the message
	 *    message = the message parameters
	 *
	 * Returns:
	 *    string that is ready to be appended in PatternLayout.render()
	 */
	override public string render(Log4DLogger logger, Logger.LogEntry message) {
	    if (printf.length > 0) {
		auto writer = appender!string();
		formattedWrite(writer, printf, hostname);
		return writer.data;
	    }
	    return hostname;
	}
    }

    /**
     * Format for the line number: %L
     */
    private class LineNumberToken : FormatToken {

	/**
	 * Public constructor
	 *
	 * Params:
	 *    printf = the printf part of the format
	 *    braces = the optional braces part
	 */
	public this(string printf, string braces) {
	    this.braces = braces;
	    this.printf = "%" ~ printf ~ "d";
	}

	/**
	 * Produce the string representation.
	 *
	 * Params:
	 *    logger = logger that generated the message
	 *    message = the message parameters
	 *
	 * Returns:
	 *    string that is ready to be appended in PatternLayout.render()
	 */
	override public string render(Log4DLogger logger, Logger.LogEntry message) {
	    auto writer = appender!string();
	    if (printf.length > 0) {
		formattedWrite(writer, printf, message.line);
	    } else {
		formattedWrite(writer, "%d", message.line);
	    }
	    return writer.data;
	}
    }

    /**
     * Format for the PID: %P
     */
    private class ProcessIDToken : FormatToken {

	/**
	 * Public constructor
	 *
	 * Params:
	 *    printf = the printf part of the format
	 *    braces = the optional braces part
	 */
	public this(string printf, string braces) {
	    this.braces = braces;
	    if (printf.length > 0) {
		this.printf = "%" ~ printf ~ "s";
	    }
	}

	/**
	 * Produce the string representation.
	 *
	 * Params:
	 *    logger = logger that generated the message
	 *    message = the message parameters
	 *
	 * Returns:
	 *    string that is ready to be appended in PatternLayout.render()
	 */
	override public string render(Log4DLogger logger, Logger.LogEntry message) {
	    auto writer = appender!string();
	    if (printf.length > 0) {
		formattedWrite(writer, printf, getpid());
	    } else {
		formattedWrite(writer, "%s", getpid());
	    }
	    return writer.data;
	}
    }

    /**
     * Format for the thread ID: %t
     */
    private class ThreadIDToken : FormatToken {

	/**
	 * Public constructor
	 *
	 * Params:
	 *    printf = the printf part of the format
	 *    braces = the optional braces part
	 */
	public this(string printf, string braces) {
	    this.braces = braces;
	    if (printf.length > 0) {
		this.printf = "%" ~ printf ~ "x";
	    }
	}

	/**
	 * Produce the string representation.
	 *
	 * Params:
	 *    logger = logger that generated the message
	 *    message = the message parameters
	 *
	 * Returns:
	 *    string that is ready to be appended in PatternLayout.render()
	 */
	override public string render(Log4DLogger logger, Logger.LogEntry message) {
	    auto writer = appender!string();
	    auto myThread = Thread.getThis();
	    if (printf.length > 0) {
		formattedWrite(writer, printf, myThread.toHash());
	    } else {
		formattedWrite(writer, "%x", myThread.toHash());
	    }
	    return writer.data;
	}
    }

    /**
     * Format for the time elapsed since the application was started: %r
     */
    private class AppMillisToken : FormatToken {

	/**
	 * Public constructor
	 *
	 * Params:
	 *    printf = the printf part of the format
	 *    braces = the optional braces part
	 */
	public this(string printf, string braces) {
	    this.braces = braces;
	    this.printf = "%" ~ printf ~ "d";
	}

	/**
	 * Produce the string representation.
	 *
	 * Params:
	 *    logger = logger that generated the message
	 *    message = the message parameters
	 *
	 * Returns:
	 *    string that is ready to be appended in PatternLayout.render()
	 */
	override public string render(Log4DLogger logger, Logger.LogEntry message) {
	    auto writer = appender!string();
	    if (printf.length > 0) {
		formattedWrite(writer, printf, Clock.currAppTick().to!("msecs", long)());
	    } else {
		formattedWrite(writer, "%d", Clock.currAppTick().to!("msecs", long)());
	    }
	    return writer.data;
	}
    }

    /**
     * Format for the time elapsed since the last logging call: %R
     */
    private class DiffMillisToken : FormatToken {

	/**
	 * Public constructor
	 *
	 * Params:
	 *    printf = the printf part of the format
	 *    braces = the optional braces part
	 */
	public this(string printf, string braces) {
	    this.braces = braces;
	    this.printf = "%" ~ printf ~ "d";
	}

	/**
	 * Produce the string representation.
	 *
	 * Params:
	 *    logger = logger that generated the message
	 *    message = the message parameters
	 *
	 * Returns:
	 *    string that is ready to be appended in PatternLayout.render()
	 */
	override public string render(Log4DLogger logger, Logger.LogEntry message) {
	    auto now = Clock.currSystemTick;
	    auto diffTime = now - lastLogTime;

	    auto writer = appender!string();
	    if (printf.length > 0) {
		formattedWrite(writer, printf, diffTime.to!("msecs", long));
	    } else {
		formattedWrite(writer, "%d", diffTime.to!("msecs", long));
	    }
	    return writer.data;
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
	if (name == "ConversionPattern") {
	    conversionPattern = value;
	    setupPattern();
	}
    }

    /**
     * Turn conversionPattern into a series of fixed strings and replaceable tokens.
     */
    private void setupPattern() {
	tokens.length = 0;

	enum State {
	    LITERAL,
	    PERCENT,
	    PRINTF,
	    BRACE,
	}
	State state = State.LITERAL;
	string printf = "";
	string braces = "";
	string literal = "";
	FormatToken printfToken;

	// Perform a line scan, locating printf-style tokens and string
	// literals.
	foreach (ch; conversionPattern) {
	    /+
	    std.stdio.stdout.writefln("state: %s ch '%s' literal '%s' printf '%s' braces '%s'",
		state, ch, literal, printf, braces);
	    +/

	    final switch (state) {
	    case State.LITERAL:
		if (ch == '%') {
		    state = State.PERCENT;
		    continue;
		}
		literal ~= ch;
		break;
	    case State.PERCENT:
		if (ch == '%') {
		    literal ~= '%';
		    state = State.LITERAL;
		    continue;
		}
		if (literal.length > 0) {
		    tokens ~= new StringToken(literal);
		    literal = "";
		}
		assert(printf.length == 0);
		state = State.PRINTF;
		goto case State.PRINTF;
	    case State.PRINTF:
		if ((ch >= '0') && (ch <= '9')) {
		    printf ~= ch;
		    continue;
		}
		if ((ch == '.') ||
		    (ch == '-') ||
		    (ch == '+')
		) {
		    printf ~= ch;
		    continue;
		}
		if (ch == '{') {
		    assert(braces.length == 0);
		    state = State.BRACE;
		    continue;
		}
		if (ch == '%') {
		    // Another printf token back-to-back
		    printf = "";
		    printfToken = null;
		    state = State.PERCENT;
		    continue;
		}

		if (printfToken !is null) {
		    assert(literal.length == 0);
		    state = State.LITERAL;
		    literal ~= ch;
		    printfToken = null;
		    continue;
		}

		if (ch == 'p') {
		    printfToken = new LogLevelToken(printf, braces);
		    printf = "";
		    tokens ~= printfToken;
		    continue;
		} else if (ch == 'c') {
		    printfToken = new LoggerNameToken(printf, braces);
		    printf = "";
		    tokens ~= printfToken;
		    continue;
		} else if (ch == 'C') {
		    printfToken = new ModuleNameToken(printf, braces);
		    printf = "";
		    tokens ~= printfToken;
		    continue;
		} else if (ch == 'd') {
		    printfToken = new DateToken(printf, braces);
		    printf = "";
		    tokens ~= printfToken;
		    continue;
		} else if (ch == 'F') {
		    printfToken = new FileNameToken(printf, braces);
		    printf = "";
		    tokens ~= printfToken;
		    continue;
		} else if (ch == 'H') {
		    printfToken = new HostnameToken(printf, braces);
		    printf = "";
		    tokens ~= printfToken;
		    continue;
		} else if (ch == 'l') {
		    printfToken = new PrettyFunctionNameToken(printf, braces);
		    printf = "";
		    tokens ~= printfToken;
		    continue;
		} else if (ch == 'L') {
		    printfToken = new LineNumberToken(printf, braces);
		    printf = "";
		    tokens ~= printfToken;
		    continue;
		} else if (ch == 'M') {
		    printfToken = new FunctionNameToken(printf, braces);
		    printf = "";
		    tokens ~= printfToken;
		    continue;
		} else if (ch == 'm') {
		    printfToken = new MessageToken(printf, braces);
		    printf = "";
		    tokens ~= printfToken;
		    continue;
		} else if (ch == 'n') {
		    tokens ~= new StringToken("\n");
		    printf = "";
		    state = State.LITERAL;
		    continue;
		} else if (ch == 'P') {
		    printfToken = new ProcessIDToken(printf, braces);
		    printf = "";
		    tokens ~= printfToken;
		    continue;
		} else if (ch == 'r') {
		    printfToken = new AppMillisToken(printf, braces);
		    printf = "";
		    tokens ~= printfToken;
		    continue;
		} else if (ch == 'R') {
		    printfToken = new DiffMillisToken(printf, braces);
		    printf = "";
		    tokens ~= printfToken;
		    continue;
		} else if (ch == 't') {
		    printfToken = new ThreadIDToken(printf, braces);
		    printf = "";
		    tokens ~= printfToken;
		    continue;
		}

		// Unknown printf specifier, abandon ship
		printf = "";
		state = State.LITERAL;
		break;

	    case State.BRACE:
		if (ch == '}') {
		    assert(printfToken !is null);
		    printfToken.braces = braces;
		    braces = "";
		    printf = "";
		    printfToken = null;
		    assert(literal.length == 0);
		    state = State.LITERAL;
		    continue;
		}
		braces ~= ch;
		break;
	    }
	}

	// At EOF, see what is left
	final switch (state) {
	case State.LITERAL:
	    if (literal.length > 0) {
		tokens ~= new StringToken(literal);
	    }
	    break;

	case State.PERCENT:
	    if (literal.length > 0) {
		tokens ~= new StringToken(literal);
	    }
	    break;

	case State.PRINTF:
	    // Nothing else to do here - tokens already has the printfToken
	    // if it was recognized.
	    break;

	case State.BRACE:
	    // Nothing to do here, printfToken.braces is incomplete so ignore it.
	    break;
	}
    }

    /**
     * Render the message
     *
     * Params:
     *    logger = logger that generated the message
     *    message = the message parameters
     *
     * Returns:
     *    string that is ready to be emitted by the Appender
     */
    override public string render(Log4DLogger logger, Logger.LogEntry message) {
	auto now = Clock.currSystemTick;
	auto writer = appender!string();

	foreach (t; tokens) {
	    writer.put(t.render(logger, message));
	}
	synchronized (LogManager.getInstance().mutex) {
	    lastLogTime = now;
	}

	return writer.data;
    }
}

// Functions -----------------------------------------------------------------
