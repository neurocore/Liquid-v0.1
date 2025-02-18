# Liquid v0.1

This is an UCI-compliant chess engine written in D language. It based on magic bitboards and works with principal variation search. Key features are simplicity and stability.

# Purpose

- **Learning dlang**. This language is well known for its powerful meta-programming, we'll see how it can be used for simplifying codebase. Also i want to test how GC would affect such highly performant app as chess engine.

- **Self challenge**. Whole codebase was written by me (with few exceptions like PST-table builder from Fruit), it contains some borrowings from my old engine Eia, but i am trying to build it from the scratch where I can.

- **A springboard for experimentation**. There are a bunch of techniques I wanted to implement, one of these is NNUE, but since it considered ready-to-go solution, it doesn't seem so attractive anymore. In the future, I would like to set my sights on formal logic, start from solving etudes which are always been a tough nut to crack. *It feels like engines need some orchestrator on the top of system.*

# Pre-requisites

Get any available D lang compiler [here](https://dlang.org/download.html), including dmd, ldc or dmc. No special parameters needed.

# Compilation

Project contains these batch scripts for windows users:

- `build.bat`  - debug build && run
- `deploy.bat` - release build && run

# Using

For more convenient work with engine please consider using chess GUI such as Arena. Also you can run it just in console (prefer debug version for move verbosity).

## UCI

As was mentioned above, engine supports UCI protocol, not fully, here is a list of exceptions:

-  `register` - has no effect since it's free
-  `ponderhit` - no ponder implemented

## CLI

-  `perft [number]` - performance test at certain depth
-  `bench [filename]` - testing benchmark based on solving problems from EPD file
