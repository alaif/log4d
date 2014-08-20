/**
 * Log4D - industrial strength logging for D - test program.
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

import log4d;

public void main(string [] args) {

    // Setup logging infrastructure
    Log4D.init("test.conf");
    auto logObject = Log4D.getLogger("my.test.logger");
    logObject.info("Hello from a logger obtained via getLogger() - info level");
    logObject.error("Hello from a logger obtained via getLogger() - error level");

    // Check easy logger
    log("Hello from the log() function - initial globalLogLevel");
    std.logger.globalLogLevel = LogLevel.warning;
    log("Hello from the log() function - warning globalLogLevel");

    stdlog.warning("Hello from stdlog - warning level");
    stdlog.error("ERROR from stdlog");

}
