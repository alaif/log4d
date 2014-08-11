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

// Description ---------------------------------------------------------------

/* Logging to stdout/stderr.  The client code looks like this:
 *
 * string foo(in string bar) {
 *     in {
 *         log.enter("bar = %s", bar);
 *     }
 *     scope(success) {
 *        log.exit("%s", returnValue);
 *     }
 *     scope(failure) else {
 *        if (reallyBad) {
 *            throw log.exitException(new BadException(...));
 *        } else
 *            log.exitError("BadValueDEADBEEF!");
 *        }
 *     }
 *
 *     log.debug1("Doing stuff...");
 *
 *     ... do stuff ...
 *
 * }
 */

// Imports -------------------------------------------------------------------

import std.array;
import std.datetime;
import std.conv;
import std.stdio;
import std.format;

// Defines -------------------------------------------------------------------

// Globals -------------------------------------------------------------------

// Classes -------------------------------------------------------------------

enum Color {

    /// Black.  Bold + black = dark grey
    BLACK   = 0,

    /// Red
    RED     = 1,

    /// Green
    GREEN   = 2,

    /// Yellow.  Sometimes not-bold yellow is brown
    YELLOW  = 3,

    /// Blue
    BLUE    = 4,

    /// Magenta (purple)
    MAGENTA = 5,

    /// Cyan (blue-green)
    CYAN    = 6,

    /// White
    WHITE   = 7,
}

/**
 * This class has convenience methods for emitting output to ANSI
 * X3.64 / ECMA-48 type terminals e.g. xterm, linux, vt100, ansi.sys,
 * etc.
 */
public class ECMATerminal {

    /**
     * Create a SGR parameter sequence for a single color change.
     *
     * Params:
     *    color = one of the Color.WHITE, Color.BLUE, etc. constants
     *    foreground = if true, this is a foreground color
     *    header = if true, make the full header, otherwise just emit
     *    the color parameter e.g. "42;"
     *
     * Returns:
     *    the string to emit to an ANSI / ECMA-style terminal, e.g. "\033[42m"
     */
    public static string color(Color color, bool foreground,
	bool header = true) {

	uint ecmaColor = color;

	// Convert Color.* values to SGR numerics
	if (foreground == true) {
	    ecmaColor += 30;
	} else {
	    ecmaColor += 40;
	}

	auto writer = appender!string();
	if (header) {
	    formattedWrite(writer, "\033[%dm", ecmaColor);
	} else {
	    formattedWrite(writer, "%d;", ecmaColor);
	}
	return writer.data;
    }

    /**
     * Create a SGR parameter sequence for both foreground and
     * background color change.
     *
     * Params:
     *    foreColor = one of the Color.WHITE, Color.BLUE, etc. constants
     *    backColor = one of the Color.WHITE, Color.BLUE, etc. constants
     *    header = if true, make the full header, otherwise just emit
     *    the color parameter e.g. "31;42;"
     *
     * Returns:
     *    the string to emit to an ANSI / ECMA-style terminal, e.g. "\033[31;42m"
     */
    public static string color(Color foreColor, Color backColor,
	bool header = true) {

	uint ecmaForeColor = foreColor;
	uint ecmaBackColor = backColor;

	// Convert Color.* values to SGR numerics
	ecmaBackColor += 40;
	ecmaForeColor += 30;

	auto writer = appender!string();
	if (header) {
	    formattedWrite(writer, "\033[%d;%dm", ecmaForeColor, ecmaBackColor);
	} else {
	    formattedWrite(writer, "%d;%d;", ecmaForeColor, ecmaBackColor);
	}
	return writer.data;
    }

    /**
     * Create a SGR parameter sequence for foreground, background, and
     * several attributes.  This sequence first resets all attributes
     * to default, then sets attributes as per the parameters.
     *
     * Params:
     *    foreColor = one of the Color.WHITE, Color.BLUE, etc. constants
     *    backColor = one of the Color.WHITE, Color.BLUE, etc. constants
     *    bold = if true, set bold
     *    reverse = if true, set reverse
     *    blink = if true, set blink
     *    underline = if true, set underline
     *
     * Returns:
     *    the string to emit to an ANSI / ECMA-style terminal, e.g. "\033[0;1;31;42m"
     */
    public static string color(Color foreColor, Color backColor, bool bold,
	bool reverse, bool blink, bool underline) {

	uint ecmaForeColor = foreColor;
	uint ecmaBackColor = backColor;

	// Convert Color.* values to SGR numerics
	ecmaBackColor += 40;
	ecmaForeColor += 30;

	auto writer = appender!string();
	if        (  bold &&  reverse &&  blink && !underline ) {
	    writer.put("\033[0;1;7;5;");
	} else if (  bold &&  reverse && !blink && !underline ) {
	    writer.put("\033[0;1;7;");
	} else if ( !bold &&  reverse &&  blink && !underline ) {
	    writer.put("\033[0;7;5;");
	} else if (  bold && !reverse &&  blink && !underline ) {
	    writer.put("\033[0;1;5;");
	} else if (  bold && !reverse && !blink && !underline ) {
	    writer.put("\033[0;1;");
	} else if ( !bold &&  reverse && !blink && !underline ) {
	    writer.put("\033[0;7;");
	} else if ( !bold && !reverse &&  blink && !underline) {
	    writer.put("\033[0;5;");
	} else if (  bold &&  reverse &&  blink &&  underline ) {
	    writer.put("\033[0;1;7;5;4;");
	} else if (  bold &&  reverse && !blink &&  underline ) {
	    writer.put("\033[0;1;7;4;");
	} else if ( !bold &&  reverse &&  blink &&  underline ) {
	    writer.put("\033[0;7;5;4;");
	} else if (  bold && !reverse &&  blink &&  underline ) {
	    writer.put("\033[0;1;5;4;");
	} else if (  bold && !reverse && !blink &&  underline ) {
	    writer.put("\033[0;1;4;");
	} else if ( !bold &&  reverse && !blink &&  underline ) {
	    writer.put("\033[0;7;4;");
	} else if ( !bold && !reverse &&  blink &&  underline) {
	    writer.put("\033[0;5;4;");
	} else if ( !bold && !reverse && !blink &&  underline) {
	    writer.put("\033[0;4;");
	} else {
	    assert(!bold && !reverse && !blink && !underline);
	    writer.put("\033[0;");
	}
	formattedWrite(writer, "%d;%dm", ecmaForeColor, ecmaBackColor);
	return writer.data;
    }

    /**
     * Create a SGR parameter sequence for enabling reverse color.
     *
     * Params:
     *    on = if true, turn on reverse
     *
     * Returns:
     *    the string to emit to an ANSI / ECMA-style terminal, e.g. "\033[7m"
     */
    public static string reverse(bool on) {
	if (on) {
	    return "\033[7m";
	}
	return "\033[27m";
    }

    /**
     * Create a SGR parameter sequence to reset to defaults.
     *
     * Params:
     *    header = if true, make the full header, otherwise just emit
     *    the bare parameter e.g. "0;"
     *
     * Returns:
     *    the string to emit to an ANSI / ECMA-style terminal, e.g. "\033[0m"
     */
    public static string normal(bool header = true) {
	if (header) {
	    return "\033[0;37;40m";
	}
	return "0;37;40";
    }

    /**
     * Create a SGR parameter sequence for enabling boldface.
     *
     * Params:
     *    on = if true, turn on bold
     *    header = if true, make the full header, otherwise just emit
     *    the bare parameter e.g. "1;"
     *
     * Returns:
     *    the string to emit to an ANSI / ECMA-style terminal, e.g. "\033[1m"
     */
    public static string bold(bool on, bool header = true) {
	if (header) {
	    if (on) {
		return "\033[1m";
	    }
	    return "\033[22m";
	}
	if (on) {
	    return "1;";
	}
	return "22;";
    }

    /**
     * Create a SGR parameter sequence for enabling blinking text.
     *
     * Params:
     *    on = if true, turn on blink
     *    header = if true, make the full header, otherwise just emit
     *    the bare parameter e.g. "5;"
     *
     * Returns:
     *    the string to emit to an ANSI / ECMA-style terminal, e.g. "\033[5m"
     */
    public static string blink(bool on, bool header = true) {
	if (header) {
	    if (on) {
		return "\033[5m";
	    }
	    return "\033[25m";
	}
	if (on) {
	    return "5;";
	}
	return "25;";
    }

    /**
     * Create a SGR parameter sequence for enabling underline /
     * underscored text.
     *
     * Params:
     *    on = if true, turn on underline
     *
     * Returns:
     *    the string to emit to an ANSI / ECMA-style terminal, e.g. "\033[4m"
     */
    public static string underline(bool on) {
	if (on) {
	    return "\033[4m";
	}
	return "\033[24m";
    }

    /**
     * Clear the entire screen.  Because some terminals use back-color-erase,
     * set the color to white-on-black beforehand.
     *
     * Returns:
     *    the string to emit to an ANSI / ECMA-style terminal
     */
    public static string clearAll() {
	return "\033[0;37;40m\033[2J";
    }

    /**
     * Clear the line from the cursor (inclusive) to the end of the screen.
     * Because some terminals use back-color-erase, set the color to
     * white-on-black beforehand.
     *
     * Returns:
     *    the string to emit to an ANSI / ECMA-style terminal
     */
    public static string clearRemainingLine() {
	return "\033[0;37;40m\033[K";
    }

    /**
     * Clear the line up the cursor (inclusive).  Because some terminals use
     * back-color-erase, set the color to white-on-black beforehand.
     *
     * Returns:
     *    the string to emit to an ANSI / ECMA-style terminal
     */
    public static string clearPreceedingLine() {
	return "\033[0;37;40m\033[1K";
    }

    /**
     * Clear the line.  Because some terminals use back-color-erase, set the
     * color to white-on-black beforehand.
     *
     * Returns:
     *    the string to emit to an ANSI / ECMA-style terminal
     */
    public static string clearLine() {
	return "\033[0;37;40m\033[2K";
    }

    /**
     * Move the cursor to the top-left corner.
     *
     * Returns:
     *    the string to emit to an ANSI / ECMA-style terminal
     */
    public static string home() {
	return "\033[H";
    }

    /**
     * Move the cursor to (x, y).
     *
     * Params:
     *    x = column coordinate.  0 is the left-most column.
     *    y = row coordinate.  0 is the top-most row.
     *
     * Returns:
     *    the string to emit to an ANSI / ECMA-style terminal
     */
    public static string gotoXY(uint x, uint y) {
	auto writer = appender!string();
	formattedWrite(writer, "\033[%d;%dH", y + 1, x + 1);
	return writer.data;
    }

    /**
     * Tell (u)xterm that we want to receive mouse events based on
     * "Any event tracking" and UTF-8 coordinates.  See
     * http://invisible-island.net/xterm/ctlseqs/ctlseqs.html#Mouse%20Tracking
     *
     * Finally, this sets the alternate screen buffer.
     *
     * Params:
     *    on = if true, enable mouse report
     *
     * Returns:
     *    the string to emit to xterm
     */
    public static string mouse(bool on) {
	if (on) {
	    return "\033[?1003;1005h\033[?1049h";
	}
	return "\033[?1003;1005l\033[?1049l";
    }

}


/**
 * A LoggerOutput is responsible for sending a log message to a user-visible
 * location.
 */
public class LoggerOutput {

    /**
     * Convenience method to generate a timestamp string
     *
     * Params:
     *    colorize = if true, use SGR sequences to colorize the message fields
     *
     * Returns:
     *    timestamp string
     */
    private string timestamp(SysTime time, bool colorize = false) {
	static auto first = true;
	static SysTime oldTime;
	static string oldTimestring;
	static bool oldColorize;
	if ((oldTime != time) || (oldColorize != colorize) || (first == true)) {
	    first = false;
	    auto writer = appender!string();
	    auto formatString = appender!string();
	    if (colorize == true) {
		formattedWrite(formatString,
		    "%s[%s%%04d-%%02d-%%02d %%02d:%%02d:%%02d.%%03d%s]%s",
		    ECMATerminal.color(Color.BLUE, Color.BLACK, false, false, false, false),
		    ECMATerminal.color(Color.BLACK, Color.BLACK, true, false, false, false),
		    ECMATerminal.color(Color.BLUE, Color.BLACK, false, false, false, false),
		    ECMATerminal.normal()
		);
	    } else {
		formatString.put("[%04d-%02d-%02d %02d:%02d:%02d.%03d]");
	    }
	    formattedWrite(writer, formatString.data,
		time.year,
		time.month,
		time.day,
		time.hour,
		time.minute,
		time.second,
		time.fracSec.msecs);
	    oldTimestring = writer.data;
	    oldTime = time;
	    oldColorize = colorize;
	}
	return oldTimestring;
    }

    /**
     * Subclasses should override this to emit the message to the user.
     *
     * Params:
     *    logger = Logger which generated the message
     *    time = time at which the message was generated
     *    level = Logger.INFO/DEBUG1/etc.
     *    args = arguments to writef()
     */
    public void msg(T...)(Logger logger, SysTime time, Logger.Level level, T args) {
	auto writer = appender!string();
	formattedWrite(writer, args);
	emit(logger, time, level, writer.data);
    }

    /**
     * Subclasses should override this to emit the message to the user.
     *
     * Params:
     *    logger = Logger which generated the message
     *    time = time at which the message was generated
     *    level = Logger.INFO/DEBUG1/etc.
     *    msg = message to the user
     */
    abstract public void emit(Logger logger, SysTime time, Logger.Level level, string msg);

}

/**
 * FileLoggerOutput emits log messages to a file.
 */
public class FileLoggerOutput : LoggerOutput {

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
 * StdoutLoggerOutput emits log messages to stdout.
 */
public class StdoutLoggerOutput : FileLoggerOutput {

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

/**
 * Logger is the client-side API to the logging system.
 */
public class Logger {

    /**
     * <pre>
     * This struct encapsulates the various fields used by each logging level.
     *
     * Types of log messages:
     *   EMERGENCY      System unuseable
     *   ALERT          Immediate action needed
     *   CRITICAL       Critical condition
     *   ERROR          Error (unusual and requires intervention to continue)
     *   WARNING        Warning (unusual but might be able to continue)
     *   NOTIFY         Notification (important state change)
     *   INFO           Informational (regular logging)
     *   DEBUG1         Debug (light - important parameters)
     *   DEBUG2         Debug (moderate - outline major parts of functions)
     *   DEBUG3         Debug (insane - complete logging even inside loops)
     *   FUNC_ENTER     Debug (function enter)
     *   FUNC_EXIT      Debug (function exit)
     * </pre>
     */
    public struct Level {
	private int level;
	private string tag;
	private string name;
	private string ansiColor;
	this(int level, string tag, string name, string ansiColor) {
	    this.level = level;
	    this.tag = tag;
	    this.name = name;
	    this.ansiColor = ansiColor;
	}

	debug {
	    public static immutable Level FUNCTION   = Level(11,  "<>","function", ECMATerminal.normal());
	    public static immutable Level FUNC_ENTER = Level(11,  ">",    "enter", ECMATerminal.normal());
	    public static immutable Level FUNC_EXIT  = Level(11,  "<",     "exit", ECMATerminal.normal());
	    public static immutable Level DEBUG3     = Level(10, "D3",   "debug3", ECMATerminal.normal());
	    public static immutable Level DEBUG2     = Level( 9, "D2",   "debug2", ECMATerminal.normal());
	    public static immutable Level DEBUG1     = Level( 8, "D1",   "debug1", ECMATerminal.normal());
	}
	
	public static immutable Level INFO       = Level( 7,  "I",     "info", ECMATerminal.bold(true));
	public static immutable Level NOTIFY     = Level( 6, "**",   "notify", "\033[33;1m");
	public static immutable Level WARNING    = Level( 5,  "W",  "warning", "\033[33;1m");
	public static immutable Level ERROR      = Level( 4,  "E",    "error", "\033[31;1m");
	public static immutable Level CRITICAL   = Level( 3,  "!", "critical", "\033[31;1m");
	public static immutable Level ALERT      = Level( 2, "@@@ ALERT @@@", "alert", "\033[31;1;5m");
	public static immutable Level EMERGENCY  = Level( 1, "******** EMERGENCY!!! ********", "emergency", "\033[31;1;5m");

    };

    /// Default log level
    private static Level DEFAULT_LEVEL = Level.INFO;

    /// Log level
    public Level level;

    /// Logger name
    public string name;

    /// Global list of loggers
    static __gshared private Logger[string] loggers;

    /// Global list of logger outputs
    static __gshared private LoggerOutput[] loggerOutputs;

    /**
     * Private constructor
     *
     * Params:
     *    name = logger name, used as both a string to the user and a global unique key
     *    level = initial logging level
     */
    private this(string name, Level level) {
	this.name = name;
	this.level = level;
    }

    /**
     * Messaging function
     *
     * Params:
     *    level = Logger.Level.INFO/DEBUG/...
     *    args = arguments to writef()
     */
    private void msg(T...)(Level level, T args) nothrow {
	if (level.level > this.level.level) {
	    return;
	}
	try {
	    auto time = Clock.currTime(UTC());
	    foreach (output; loggerOutputs) {
		output.msg(this, time, level, args);
	    }
	} catch (Throwable t) {
	    try {
		// Try to emit to stderr
		stderr.writeln("LOGGING ERROR");
		stderr.writeln("-------------");
		stderr.writefln("%s", t.toString());
		stderr.writeln("-------------");
	    } catch (Throwable t2) {
		// We are seriously hosed and can't even emit our error
	    }
	    // Die
	    std.c.stdlib.exit(-1);
	}
    }

    /**
     * Factory method to retrieve instance.  It will create one if it does
     * not already exist.
     *
     * Params:
     *    name = logger name, used as a global unique key
     *    level = Logger.Level.INFO/DEBUG/...
     *
     * Returns:
     *    logger instance
     */
    synchronized static public Logger getLogger(string name, Level level = DEFAULT_LEVEL) {
	Logger logger;
	if (name in loggers) {
	    logger = loggers[name];
	} else {
	    logger = new Logger(name, level);
	    loggers[name] = logger;
	}
	return logger;
    }

    /**
     * Factory method to add a logger output destination
     *
     * Params:
     *    output = new logging destination
     */
    synchronized static public void addOutput(LoggerOutput output) {
	loggerOutputs ~= output;
    }

    /**
     * Set logging level
     *
     * Params:
     *    level = Logger.Level.INFO/DEBUG/...
     */
    public void setLevel(Level level) {
	this.level = level;
    }

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

    /**
     * Log a normal user message
     *
     * Params:
     *    args = arguments to writef
     */
    public void info(T...)(T args) nothrow {
	msg(Level.INFO, args);
    }

    /**
     * Log an important state change message
     *
     * Params:
     *    args = arguments to writef
     */
    public void notify(T...)(T args) nothrow {
	msg(Level.NOTIFY, args);
    }

    /**
     * Log a warning message.  Warnings typically mean that the
     * program has encountered an unusual situation but can still do
     * something.
     *
     * Params:
     *    args = arguments to writef
     */
    public void warning(T...)(T args) nothrow {
	msg(Level.WARNING, args);
    }

    /**
     * Log an error message.  The program has encountered an unusual
     * situation and cannot recover without outside intervention.
     *
     * Params:
     *    args = arguments to writef
     */
    public void error(T...)(T args) nothrow {
	msg(Level.ERROR, args);
    }

    /**
     * Log a critical error message.  The program has encountered an
     * unusual situation, cannot recover without outside intervention,
     * and this will affect the main purpose of the program.
     *
     * Params:
     *    args = arguments to writef
     */
    public void critical(T...)(T args) nothrow {
	msg(Level.CRITICAL, args);
    }

    /**
     * Log an error alert message.  The program needs outside
     * intervention immediately.
     *
     * Params:
     *    args = arguments to writef
     */
    public void alert(T...)(T args) nothrow {
	msg(Level.ALERT, args);
    }

    /**
     * Log an emergency message.  The program has encountered a fatal
     * error, must terminate, and is logging a message for post-mortem
     * analysis.
     *
     * Params:
     *    args = arguments to writef
     */
    public void emergency(T...)(T args) nothrow {
	msg(Level.EMERGENCY, args);
    }

}

// Functions -----------------------------------------------------------------

