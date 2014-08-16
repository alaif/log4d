Log4D
=====

This library contains a Log4j/Log4perl-like logging system for the D language.


License
-------

This library is licensed under the Boost License 1.0.  See the file
LICENSE-1.0 for the full license text.


Usage
-----

The library is currently under initial development, usage patterns are
still being worked on.

In general the API will mirror Log4perl as much as possible.  The goal
is to be capable of applying a Log4j, Log4perl, or the Delphi-language
Log4D initialization file against a D-based application and have it
behave in exactly the same way.


Roadmap
-------

This is a work in progress.  Many tasks remain before calling this
version 1.0:

- [ ] log4d.conf (non-XML) reader/parser
  - [ ] init()
  - [ ] init_and_watch()
- [ ] Layouts:
  - [ ] PatternLayout
- [ ] Filters
  - [ ] LevelRange
  - [ ] StringMatch
- [ ] Appenders:
  - [ ] Alias Log4perl and Log4j appenders to Log4D class names
  - [ ] Screen
    - [ ] ECMA backend
    - [ ] Win32Console backend
  - [ ] File
    - [ ] Stdout/Stderr
    - [ ] Rotate option (equivalent to FileRotate)
  - [ ] Syslog
  - [ ] (**contributor needed**) Windows event viewer
  - [ ] vibe.core.log
  - [ ] Email

Wishlist
--------

- [ ] XMLLayout (use same field/attrs as Log::Log4perl::Layout::XMLLayout)
- [ ] Boolean Filter
- [ ] More appenders
  - [ ] Database (need to find stable database layer)
- [ ] XML file configuration
- [ ] NDC/MDC implementation
- [ ] LogStash integration

