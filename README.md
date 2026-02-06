# Amstrad CPC Dev Template

Basic dev template for Amstrad CPC.

Dependencies:

  - `make`
  - `perl`
  - Rasm
  - iDSK
  - ACE-DL

## Instructions

### 1. Build rasm from source

[Grab it from here](https://github.com/EdouardBERGE/rasm)

### 2. Build iDSK from source

[Grab it from here](https://github.com/cpcsdk/idsk) - requires `cmake`

### 3. Install ACE-DL

[Grab it from here](https://roudoudou.com/ACE-DL/) then extract it somewhere.

### 4. Create tools directory

In this directory, place `rasm`, `idsk`, and an `ace` launcher script for ACE-DL, e.g.:

```bash
#!/bin/bash

# Update this to wherever you put ACE-DL
cd $HOME/projects/rtb/amsdev/ace-dl

./AceDL "$@"
```

### 5. Update Makefile

Set `TOOLS` to point at the tools directory created in step 4.

### 6. Run

```bash
make run
```


