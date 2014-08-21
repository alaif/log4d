# Log4D Makefile
# $Id$
#
# License: Boost1.0
#
#     Copyright (C) 2014  Kevin Lamonte
#
# Boost Software License - Version 1.0 - August 17th, 2003
# 
# Permission is hereby granted, free of charge, to any person or
# organization obtaining a copy of the software and accompanying
# documentation covered by this license (the "Software") to use,
# reproduce, display, distribute, execute, and transmit the Software,
# and to prepare derivative works of the Software, and to permit
# third-parties to whom the Software is furnished to do so, all
# subject to the following:
# 
# The copyright notices in the Software and this entire statement,
# including the above license grant, this restriction and the
# following disclaimer, must be included in all copies of the
# Software, in whole or in part, and all derivative works of the
# Software, unless such copies or derivative works are solely in the
# form of machine-executable object code generated by a source
# language processor.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, TITLE AND
# NON-INFRINGEMENT. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR ANYONE
# DISTRIBUTING THE SOFTWARE BE LIABLE FOR ANY DAMAGES OR OTHER
# LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
# OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.

default:	all

.SUFFIXES: .o .d

LOG4D_SRC =	log4d/config.d log4d/logger.d log4d/package.d \
	log4d/appender/package.d log4d/appender/screen.d log4d/appender/file.d \
	log4d/layout/package.d \
	log4d/filter/package.d

STDLOGGER_SRC =	burner/logger/std/logger/package.d \
	burner/logger/std/logger/core.d \
	burner/logger/std/logger/filelogger.d \
	burner/logger/std/logger/multilogger.d \
	burner/logger/std/logger/nulllogger.d

DC = dmd
INC = -I@srcdir@ -Iburner/logger
DDOCDIR = ./ddoc
# DFLAGS = -w -wi $(INC) -release
DFLAGS = -w -wi -g $(INC) -debug -de -Dd$(DDOCDIR) -unittest
# LDLIBS = -L-lutil -defaultlib=libphobos2.so
# LDFLAGS = -shared -fPIC $(LDLIBS)
LDLIBS = -L-lutil
LDFLAGS = -lib -fPIC $(LDLIBS)

all:	test

test:	liblog4d.a stdlogger.a test.d
	$(DC) $(DFLAGS) $(LDLIBS) -oftest test.d liblog4d.a stdlogger.a

clean:
	rm stdlogger.a liblog4d.a core *.o test

liblog4d.a:	$(LOG4D_SRC)
	$(DC) $(DFLAGS) $(LDFLAGS) -ofliblog4d $(LOG4D_SRC)

stdlogger.a:	$(STDLOGGER_SRC)
	$(DC) $(DFLAGS) $(LDFLAGS) -ofstdlogger $(STDLOGGER_SRC)
