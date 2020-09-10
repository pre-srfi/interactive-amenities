# SRFI nnn: Interactive amenities

by Lassi Kortela

# Status

Early Draft

# Abstract

This SRFI defines some basic amenities that are useful when working
interactively with Scheme: how to access documentation and other help;
browse command history; exit nested REPLs; call the single-stepping
and profiling facilities; study memory use; and access the source or
compiled code for definitions. Where possible the facilities are
borrowed from Common Lisp.

# Issues

# Rationale

Common Lisp specifies a number of functions meant mainly for
interactive use at the _read-eval-print loop_ (REPL). Some Scheme
implementations such as Chez Scheme and Gambit have adopted some of
them. This SRFI specifies a full set in the hopes of wider adoption.
Aligning with Common Lisp makes sense because the users of both
languages have similar needs for REPL work. People who use both
languages will also have an easier time if procedures have the same
names and semantics.

Common Lisp's **describe** and **inspect** were left out of this SRFI
because they are similar to the **help** procedure defined here and
their names are somewhat confusing. CL's **describe** is also
extensible via the Common Lisp Object System (CLOS). Scheme does not
come standard with such a system, which would raise the question of
whether and how to let users extend **describe**.

# Specification

### REPL presentation

#### Version banner

Before entering the top-level REPL, the Scheme implementation shall
display a one-line banner starting with its title (which may use
uppercase letters and spaces) and version number. The banner may also
display other information, possibly on subsequent lines. The banner
may use color codes and other text attributes if the implementation
detects that the REPL is connected to a terminal.

If the REPL is started with an implementation-defined _quiet_ mode or
option, the banner does not need to be displayed.

#### Line editing

If the REPL can detect that it is running in a terminal, it enables
line editing. The line editor must support the following features:

* History
* Parenthesis matching

and the following Emacs-style key bindings:

* Control+A - move cursor to beginning of line
* Control+B - or left arrow - move cursor one character left
* Control+E - move cursor to end of line
* Control+F - or right arrow - move cursor one character right
* Control+L - clear screen
* Control+N or down arrow - next history entry
* Control+P or up arrow - previous history entry
* Escape+B - move cursor one word backward
* Escape+F - move cursor one word forward

If the line editor supports configuration, the user or system
administrator may have configured different key bindings (e.g.
behavior similar to the Unix text editor **vi**). The line editor does
not need to follow the above requirements if it has been configured to
do otherwise.

#### Prompt indicator

A nested REPL shall have a prompt indicator that displays the nesting
level.

A prompt that does not accept Scheme expressions (e.g. a debugger,
inspector or confirmation prompt) shall have a prompt indicator
different from the indicator of a Scheme REPL.

### REPL building blocks

(**repl** [_eval_ [_write_ [_read_]]])

Invoke an implementation-dependent read-eval-print loop (REPL). The
loop reads a datum representing an expression or definition using
_read_, evaluates it using _eval_, and prints any resulting values
using _write_. These actions are repeated until an end-of-file object
is read.

By default, _eval_ is **repl-eval**, _write_ is **repl-write**, and
_read_ is **repl-read**. These procedure arguments are ordered by the
likelihood that users will want to replace them, not the order in
which **repl** calls them. Whenever any of them is omitted or `#f`,
the default is used. Allowing these defaults to be individually
overridden means that other languages implemented on top of Scheme can
make use of the host implementation's REPL smarts, whatever those may
be. The write argument should respect **current-output-port** and the
read argument should respect **current-input-port** if it makes sense
to do so.

(**repl-read**)

This procedure is implementation-dependent, but has the general effect
of reading a datum from the current input port, possibly with some
additional features.

(**repl-write** _obj_)

This procedure is implementation-dependent, but has the general effect
of writing a datum to the current output port, possibly with some
additional features.

(**repl-eval** _obj_)

This procedure is implementation dependent, but is similar to `(lambda
(x) (eval x (interaction-environment)))`. In addition, _obj_ may be a
definition that extends the interaction environment. There may be
other implementation-dependent features.

#### More customization

The REPL normally displays a prompt before reading an expression. This
SRFI also mandates that the REPL support line editing in typical
conditions. Any means of customizing the prompt and the line editor
are implementation-defined.

It is suggested, but not required, that settings affecting the
behavior of **repl-read**, **repl-write** and **repl-eval** be
implemented as parameter objects accessible from a library that is
imported into the default interaction environment.

### REPL state

#### One-letter definitions

The implementation's default interaction environment shall not define
any one-letter identifiers, nor any identifiers starting with one
letter followed only by decimal digits. Those are reserved for users.

#### REPL history

Each form successfully read in by the REPL is preserved in a _history
entry_. The entry stores both the unevaluated form and any values that
were produced by evaluating the form. When a form is successfully read
but not successfully evaluated, a history entry is made but no values
are stored in that entry. If the exception object is available, it is
stored in the entry. An entry may additionally store
implementation-defined information.

(**history-form** [_x_]) => object +
(**history-value** [_x_]) => object or `#f` +
(**history-values** [_x_]) => list of zero or more objects +
(**history-exception** [_x_]) => exception object or `#f`

These procedures get information from a history entry.
**history-form** gets the form read in, **history-value** gets the
primary value (or `#f` if there were no values), and
**history-values** gets the full list of all values (or the empty list
if there were no values). **history-exception** gets the exception
object for an evaluation that caused an error (or `#f` if evaluation
succeeded or the exception object cannot be retrieved).

One simple representation for a history entry is a `(form . values)`
pair. Then **history-form** gets the **car**, **history-value** gets
the **cadr**, and **history-values** gets the **cdr**. Exception
objects are not stored in this representation.

When a history entry is given as the argument, these procedures get
information from that entry. For a nonnegative exact integer argument
_n_ they use the _n_'th latest history entry where `0` is the latest
one, `1` is the one before that, etc. When the argument is omitted or
`#f`, it's the same as giving `0`.

(**history** [_n_])

This procedure returns a list of the last _n_ history entries for the
current REPL. The list is ordered so that the latest entry is last, so
e.g. `(last (history))` gets the latest history entry. If there are
fewer than _n_ entries in the history, it returns all the entries
there are. If _n_ is omitted or `#f`, the default is 10. If _n_ is
`#t`, the entire history is returned.

It is undefined whether or not:

* mutating the returned list mutates the history itself

* histories from prior REPL sessions are concatenated into the history
  of the current session

* concurrent REPLs use a shared history or separate histories

The implementation is free to throw out old entries from the history
once it gets too big but supporting a large history is encouraged. The
implementation is free to define more procedures for working with
history.

#### Exiting the REPL

(**exit**)

With no arguments, exit the Scheme implementation from within any
level of REPL nesting. The details of exiting are unspecified in this
SRFI. This definition of the **exit** procedure is intended to be
fully compatible with its definitions in R6RS, R7RS and future Scheme
standards.

Behavior with arguments is undefined in this SRFI.

(**top-level**)

With no arguments, exit and any all nested REPLs, returning to the
top-level REPL. If the implementation supports more than one
concurrent stack of nested REPLs, returns to the top of the current
stack, leaving other stacks intact.

Behavior with arguments is undefined in this SRFI.

Patterned after Emacs Lisp.

### General interactive amenities

#### Opening an editor

(**ed** [_x_ [_library_]])

Open an interactive editor (or when an editor is not available, a
viewer).

If _x_ is missing of `#f`, open the default editor. If the editor is
in the background, bring it to the foreground in its current state. If
it is not running, start it up and bring it to the foreground.

If _x_ is a string (or a pathname, in Scheme implementations that have
pathname objects), open that file in an appropriate editor. Other open
files may be closed (asking to save them first) or may remain open
concurrently.

If _x_ a symbol, edits the definition of that identifier in the
current interaction environment if possible. One approach is to open
the source file containing the definition, at the line number of the
definition if possible.

On Unix the default editor is typically the text editor denoted by the
`EDITOR` environment variable. However the editor does not need to
come from that variable, and can even be a structural editor instead
of a text editor. The implementation may also opt to use a built-in
editor if it has one instead of starting an external editing program.

The implementation is free to use different editors and viewers for
different types of files or objects, perhaps selectively relying on
the Unix `open` command or Windows file associations for some file
types. One potential example is for an implementation with an image
data type to open an image editor when _x_ is an image. A bytevector
_x_ could be opened in a hex editor. The implementation may provide
build-time and/or run-time configuration options to set which editor
is used and with what options. On Unix, it is suggested that the
implementation have a `set-environment-variable` procedure and that
the text editor is configured by changing the value of `EDITOR` with
it, but this is not mandatory.

Patterned after Common Lisp.

#### Bug report

(**bug-report**)

Display information that is likely to be useful to copy and paste into
a bug report. The implementor knows best what is useful but likely
candidates are operating system and library versions, hardware
architecture as well as run-time and build-time configuration options.

The display should also say where and how to submit the report. Giving
the URL of a web page containing detailed instructions is probably the
best alternative at the time of writing. The traditional Unix workflow
of opening a text editor to write an email is no longer preferred by
most users and the `mail` command is often not properly configured.

The procedure shall not automatically send any information over the
network without the user's consent.

The procedure may take optional arguments that are not specified in
this SRFI.

#### Online help

(**help** [_thing_ [_kind_ [_place_]]])

Display online help.

With no arguments, display a capsule summary of how to find more help
and how to get out of situations that confuse newbies. This display
can contain e.g.:

* The URL for the implementation's website.
* The URL for the user's manual or documentation index.
* Quick guide on how to get more detailed help in the REPL.
* How to load source code.
* If there is a debugger, how to enter and exit it.
* How to exit Scheme.

With one argument, if the object *is not* a symbol or string, display
help or information about that object if possible. This can be as
simple as displaying the type or **write** representation of the
object if there is nothing better that can be shown.

With one argument, if the object **is** a symbol or a string, use it
as an identifier and display help about the definition of that
identifier in the current interaction environment.

With two arguments, the second argument is a symbol stating the _kind_
of thing to get help with. The values of _kind_ specified in this SRFI
are `binding`, `library`, `record`, `feature` and `topic`. The
implementation may optionally support as many other _kind_ values as
is useful. `binding` is meant for variables, procedures and macros
bound with _define_, _define-syntax_, etc. `library`, `record` and
`feature` are hopefully self-explanatory. `topic` is meant for general
"how-to" topics or parts of the system, such as the REPL, the debugger
or the GC.

If _kind_ is omitted or `#f`, the implementation should try `binding`
and optionally one or more other kinds. If only one _kind_ has a
matching _thing_, then it should display help for that thing. If more
than one _kind_ matches _thing_, then it should show a list of more
precise `(help ...)` commands that the user can copy and paste into
the REPL to get help with a particular _kind_ of _thing_ .

The optional third argument _place_ can be used to find help for
things that are not accessible from the current interaction
environment. For `binding`, _place_ is the library name.

Help does not have to be in English. The implementation can provide
help in more than one language; this SRFI does not specify how and
when the language can be changed. Implementations do not need to
provide comprehensive help, and do not need to have help accessible in
all configurations.

(**apropos** _key_ [_kind_ [_place_]])

(**apropos-list** _key_ [_kind_ [_place_]])

These procedures search for things named like _key_. The
implementation must accept string and symbol keys, using them for a
case-insensitive substring match. It may optionally accept other types
of keys for implementation-defined searches. The **apropos** procedure
displays the search results in a user-friendly manner, whereas
**apropos-list** returns them in a fresh list. The _kind_ and _place_
arguments work as for the **help** procedure. Giving a zero-length
string or the symbol with a zero-length name produces no matches.

Patterned after Common Lisp. Emacs Lisp also has several apropos
commands.

#### Debugging tools

(**room**)

Display information about the Scheme implementation's current memory
usage and memory management status (for example, heap sizes and
garbage collection cycles).

Without arguments the display should be a useful summary that fits on
a typical screen. The implementation may support optional arguments
that tailor what information is displayed and where.

Patterned after Common Lisp.

(**threads**)

Display information about the green threads, operating system threads
and operating system processes managed by the implementation.
Information about subprocesses may or may not be included.

Without arguments the display should be a useful summary that fits on
a typical screen.The implementation may support optional arguments
that tailor what information is displayed and where.

(**imports**) => list of library names

Return a fresh list of all library names imported into the current
interaction environment. Mutating the list must not alter the current
import set.

(**time** _form_) => result*

Evaluate _form_ and display how much time it took in seconds and
fractional seconds. Return any values produced by the evaluation.

It is undefined whether or not this works in a nested REPL.

Patterned after Common Lisp.

(**step** _form_) => result*

Run an interactive single-stepper through the evaluation of _form_.
Return any values resulting from the evaluation. If the implementation
does not support single-stepping or if this particular form cannot be
single-stepped right now, raise an error.

It is undefined whether or not this works in a nested REPL.

Patterned after Common Lisp.

(**trace** [symbol ...]) => list of symbols

With no arguments, return a fresh list of symbols naming the
procedures that are currently being traced. The list is sorted by
applying `string<` to the symbol names. If the implementation does not
support tracing then the list is always empty. Mutating the list must
not alter the trace set.

When one or more arguments are given, all of them must be symbols
corresponding to identifiers bounds to procedures in the current
interaction environment. The procedure ensures that tracing is enabled
for all of the named procedures. If this is not possible, an error is
raised and the trace set is not modified. If the implementation does
not supports tracing at all, giving one or more arguments always
raises an error. The return value is the list of arguments.

It is undefined whether or not this works in a nested REPL.

Patterned after Common Lisp.

(**untrace** [_symbol_ ...]) => list of symbols

With no arguments, untrace any and all currently traced procedures.

When one or more arguments are given, all of them must be symbols. The
procedure ensures that none of those procedures are traced. If
non-existent procedures or identifiers bound to non-procedures are
named, ignore those and silently succeed.

The return value is a fresh list of symbols naming all procedures that
were traced but no longer are as a result of this call. The list is
sorted by applying `string<` to the symbol names.

It is undefined whether or not this works in a nested REPL.

Patterned after Common Lisp.

(**disassemble** _proc_)

If _proc_ is a compiled procedure, display the bytecode or machine
code implementing it. Typically both the raw hexadecimal code and a
symbolic disassembly are shown side by side, but this is not
mandatory. Can also display other information about the procedure.
_proc_ can be a procedure object or a symbol naming a procedure; if it
is a symbol then the corresponding identifier is looked up in the
current interaction environment.

Patterned after Common Lisp.

## Implementation

Due to the nature of the topic, the implementation is necessarily
deeply system-dependent. A sample implementation is not provided since
there are almost no portable aspects.

```
(define history '())

(define (history-push form values)
  (set! history (cons (cons form values) history)))

(define (history-get x proc)
  (cond ((pair? x) (proc x))
        ((eqv? #f x) (history-get 0 proc))
        ((and (integer? x) (>= x 0) (< x (length history)))
         (history-get (list-ref history x) proc))
        (else #f)))

(define (history-form (x #f))
  (history-get x car))

(define (history-value (x #f))
  (history-get x cadr))

(define (history-values (x #f))
  (history-get x cdr))

(define (history-exception (x #f))
  #f)
```

# Acknowledgements

John Cowan designed and specified the REPL building block procedures.
He also provided valuable feedback which clarified the scope and
organization of the SRFI.

The Common Lisp standard provided a solid and time-tested foundation
that lets us avoid re-inventing the wheel.

# References

# Copyright

Copyright (C) Lassi Kortela (2019).

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
