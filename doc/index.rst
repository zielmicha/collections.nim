=========
collections.nim
=========

Introduction
=========

*collections.nim* is a collections of utilities and datastructures for Nim language.
*collections.nim* consists of several mostly independent modules.


Language extensions
=========

- ``collections/lang`` (`API docs <api/collections/lang.html>`_)

  Various procs that should be part of ``system`` module.

- ``collections/misc`` (`API docs <api/collections/misc.html>`_)

  Various procs missing from stdlib modules.

- ``collections/iface`` (`API docs <api/collections/iface.html>`_)

  Implements support for Go-like interfaces.

- ``collections/macrotool`` (`API docs <api/collections/macrotool.html>`_)

  Useful tools for writing macros.

- ``collections/pprint`` (`API docs <api/collections/pprint.html>`_)

  Convert objects to readable representation (like ``repr``).

- ``collections/weakref`` (`API docs <api/collections/weakref.html>`_)

  Support for weak references.

Utilities
=========

- ``collections/iterate`` (`API docs <api/collections/iterate.html>`_)

  Implements various methods that operate on sequences.

- ``collections/bytes`` (`API docs <api/collections/bytes.html>`_)

  Do various things to byte strings.

- ``collections/random`` (`API docs <api/collections/random.html>`_)

  Generate randomness.


Data structures
=========

- ``collections/queue`` (`API docs <api/collections/queue.html>`_)

  A queue.

- ``collections/views`` (`API docs <api/collections/views.html>`_)

  Unsafe view representing part of an array.

- ``collections/weaktable`` (`API docs <api/collections/weaktable.html>`_)

  Table that which values are weak references.
