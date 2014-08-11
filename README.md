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

The goal is to be capable of applying a Log4j or Log4perl
initialization file against a D-based application and have it behave
in the same way.


Roadmap
-------

This is a work in progress.  Many tasks remain before calling this
version 1.0:

- [ ] log4d.conf (non-XML) reader/parser
- [ ] Plug into std.logger (after logger reference is included in LoggerPayload)
  - [ ] getLogger()
- [ ] init_and_watch()
- [ ] Appenders:
  - [ ] File
    - [ ] Stdio
    - [ ] XMLFile
    - [ ] Rotate option (equivalent to FileRotate)
  - [ ] Syslog
  - [ ] (**contributor needed**) Windows event viewer
  - [ ] vibe.core.log
  - [ ] Email

Wishlist
--------

- [ ] More appenders
  - [ ] Database (need to find stable database layer)
- [ ] XML file configuration
- [ ] LogStash integration

