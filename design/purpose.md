# REQ-purpose
> These are the design documents. For user documentation
see the project's [README][artifact].

The goal of artifact is to be a simple, linkable and trackable design
documentation tool for everybody.

This may seem trivial, but it's not. A useful design doc tool must have *at least*
the following characteristics:
- Allow simple linking of requirements -> specifications -> tests.
- Easily link to source code (through the source documentation) to determine
  completeness.
- Be revision controllable (text based).
- Have a unix-like command line interface for interacting with your design docs.
- Have a web-ui for viewing and editing rendered documents.
- Provide interop functionality like subcommand and data export for integration
  with external tools and plugins.
- Be scalable to any size of project (i.e. fast+cached).

These features will empower developers to track their own design docs and make
it possible for them to use their design docs to provide documentation and
guidance for contributors and teamates.

[artifact]: https://github.com/vitiral/artifact

# Design Architecture
The design of artifact is split into several sub-modules

- [[REQ-data]]: the "data" module, which acts as a filesystem database for CRUD
  operations on the user's artifacts.
- [[SPC-cli]]: The CLI interface. Artifact always aims to be a "developer first" tool, and
  having a full featured CLI with search+lint+export commands is one of the ways it
  accomplishes that goal.
- [[REQ-frontend]]: the webui frontend module, which is one of the main ways that
  users actually use artifact.


# REQ-web
partof: REQ-purpose
###
The web interface for artifact should be designed to behave very similar to the
CLI/text based interface, except it should take advantage of everything that a web
interface can.

Main attributes:
- Works directly on the file system. Any database introduced should only be used for improving performance (invisible to the user).
- [[.secure]]: this is definitely TODO, not sure how it will be accomplished ATM. Probably just require non-local host hosting to require a password and use HTTPS (nothing crazy).
- Fast for _single users and small groups_. Explicitly not designed as a whole org editing portal, users are encouraged to make small changes and use existing code review tools for changing design docs.

# Architecture
The basic architecture of the web UI is split into two components:
- [[.backend]]: this will be a simple json-rpc server which uses the [[REQ-data]] crate
  to do all of it's heavy lifting. [[REQ-data]] will ensure data consistency and error
  handling.
- [[REQ-frontend]]: the frontend will be a single page application which accomplishes
  a majority of the goals of artifact, including real-time feedback, graphing and
  visualization of requirements. It and the CLI are the two major "user facing" components of artifact.

# TST-unit
done: "done per specification."
partof:
- SPC-name
- SPC-read-family
- SPC-read-impl
- SPC-artifact
###

Several low level specifications can be covered almost completely with unit
and fuzz testing ([[TST-fuzz]]) testing.

In order for an item to consider itself "unit tested" it must:
- test boundary conditions
- test error conditions
- test "sanity" use cases (standard use cases)


# Implementations
- [[.raw_name]]
- [[.name]]
- [[.family]]: this also inclused auto partofs as well as collapsing/expanding
  partof.
- [[.read_impl]]
- [[.artifact]]

# TST-fuzz
done: "done per specification."
partof:
- SPC-name
- SPC-read-family
- SPC-read-impl
- SPC-artifact
###

All data objects shall be designed from the beginning to be fuzz tested, so
that even complex "projects" can be built up with random collections of
artifacts in differing states.

Obviously this will also allow for fast fuzz testing of the smaller objects themselves.

The major workhorse here will be the [quickcheck][1] library. The following datatypes
will have `Abitrary` implemented for them and releated tests performed against them:
- `Name` (and by extension `Partof`)
- `InvalidName`
- `RawArtifact`
  - `Done`
  - `CodeRef`
  - `CodeLoc`
  - `Text`
- `RawCodeLoc`: simply a file with given code references inserted at random.
- `HashMap<Name, RawArtifact>`
- etc.

Fuzz testing will then involve the following:
- positive fuzz tests: it should handle all generated cases that are expected
  to work.
- negative fuzz tests: it should handle all generated cacses that are expected
  to fail properly.

[1]: https://docs.rs/quickcheck/0.4.2/quickcheck/

# Implementations
- [[.raw_name]]
- [[.name]]
- [[.family]]
- [[.read_impl]]
- [[.artifact]]
