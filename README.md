# OSR
Open source experimental leaderboard for speedruns written in D and vibe.d


## How to compile
Install the D toolchain and your compiler of choice and run
```
dub
```
In the root of the directory, OSR should be compiled and run.
You'll need a mongodb instance running for OSR to work.

This is being developed and tested on Linux, your milage may vary on other platforms.


## Directory Structure
 * source/
   * api/ API definition and implementation
   * fe/ Frontend implementation