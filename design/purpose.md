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
The web interface for artifact should be designed to behave very similar to the 
CLI/text based interface, except it should take advantage of everything that a web
interface can.

# Architecture
The basic architecture of the web UI is split into two components:
- [[.backend]]: this will be a simple json-rpc server which uses the [[REQ-data]] crate
  to do all of it's heavy lifting. [[REQ-data]] will ensure data consistency and error
  handling.
- [[REQ-frontend]]: the frontend will be a single page application which accomplishes
  a majority of the goals of artifact, including real-time feedback, graphing and
  visualization of requirements. It and the CLI are the two major "user facing" components of artifact.