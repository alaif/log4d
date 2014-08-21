Log4D
=====

Log4D is a logging system that behaves similarly to Log4perl and
Log4j.  Log4D uses std.logger as the front end, but routes messages to
appenders which have filters and layouts.  In general the API strives
to mirror Log4perl as much as possible.  A near-term goal is to be
capable of applying a Log4j, Log4perl, or the Delphi-language Log4D
initialization file against a D-based application and have it behave
in exactly the same way.


License
-------

This library is licensed under the Boost License 1.0.  See the file
LICENSE-1.0 for the full license text.


Usage
-----

Using Log4D on the client side is straightforward:

```D
import log4d;

void main(string [] args) {
    Log4D.init("/path/to/logger.conf");
    auto log = Log4D.getLogger("my.component.name");

    log.info("This message will show up in the appenders specified in the configuration file");
}
```

On the backend, Log4D is controlled by a configuration file that looks
very similar to a Log4perl file.  An example is below:

```

# This config file puts two appenders on the root logger.  The CONSOLE
# appender will emit messages directly to stdout, which has a filter to
# only show messages at INFO and above.  The LOGFILE appender writes
# to "test.log", and doesn't filter anything.  Both appenders use a
# PatternLayout to do printf-like formatting of the available logging
# fields.
log4d.rootLogger              = TRACE, CONSOLE, LOGFILE

log4d.appender.CONSOLE        = log4d.appender.Screen
log4d.appender.CONSOLE.layout = log4d.layout.PatternLayout
log4d.appender.CONSOLE.layout.ConversionPattern = %d %p{1} %c %m%n
log4d.appender.CONSOLE.filter          = log4d.filter.LevelRange
log4d.appender.CONSOLE.filter.LevelMin = info
log4d.appender.CONSOLE.filter.LevelMax = off

log4d.appender.LOGFILE          = log4d.appender.File
log4d.appender.LOGFILE.filename = test.log
log4d.appender.LOGFILE.layout   = log4d.layout.PatternLayout
log4d.appender.LOGFILE.layout.ConversionPattern = %d %p{1} %c %m%n

```


Roadmap
-------

This is a work in progress.  Many tasks remain before calling this
version 1.0:

- [ ] log4d.conf (non-XML) reader/parser
  - [ ] init() - allow re-init
    - [ ] specify logger/category level and appender
  - [ ] init_once()
  - [ ] init_and_watch()
- [ ] PatternLayout:
  - [ ] %T A stack trace of functions called
  - [ ] %d{...} Current date in customized format
- [ ] Appenders:
  - [ ] Alias Log4perl and Log4j appenders to Log4D class names
  - [ ] Screen
    - [ ] ECMA backend
    - [ ] Win32Console backend
  - [ ] File
    - [ ] mode
    - [ ] autoflush
    - [ ] umask
    - [ ] create_at_logtime
    - [ ] header_text
    - [ ] mkpath, mkpath_umask
    - [ ] Rotate option (equivalent to FileRotate)
  - [ ] Syslog
  - [ ] --contributor needed-- Windows event viewer
  - [ ] vibe.core.log
  - [ ] Email
  - [ ] Throttle (takes an appender and throttles repeat output)
  - [ ] DebugBuffer (takes an appender and shows the previous X
	debug+ messages before each error message)

Wishlist
--------

- [ ] XMLLayout (use same field/attrs as Log::Log4perl::Layout::XMLLayout)
- [ ] Boolean Filter
- [ ] More appenders
  - [ ] Database (need to find stable database layer)
- [ ] XML file configuration
- [ ] NDC/MDC implementation
- [ ] LogStash integration
