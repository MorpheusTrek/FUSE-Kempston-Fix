# FUSE (ZX Spectrum) joystick fix for MiaUI on the Anbernic RG35XX

## Use

Start a ZX Spectrum game from the FUSE pak. The stick/d-pad and A/B now act as
a **Kempston** joystick, and **Select** opens/closes the on-screen keyboard.

The type is also a normal core option:

* **Quick Menu → Core Options → Joystick Type (Port 1)**
  (`none`, `cursor`, `kempston`, `sinclair 1`, `sinclair 2`, `timex 1`,
  `timex 2`, `fuller`; default `kempston`).
* In a config file the key is `fuse_joypad_type`, and the old lines some
  `FUSE.pak` configs already carry finally do something:

  ```
  fuse_joypad_type = kempston
  ```

Changing it takes effect immediately, even in a running game.

## Rollback

```sh
adb shell "cp /userdata/Cores/fuse_libretro.so.stock /userdata/Cores/fuse_libretro.so"
```

## Build from source

Needs `git`, `make` and an ARM hard-float toolchain
(Debian/Ubuntu: `sudo apt install build-essential git gcc-arm-linux-gnueabihf`).

```sh
./build.sh
```

The script fetches the pinned upstream commit
(`e997e2bc32c888348f862f69f2c53babfedf7791`, 2026-09-26), applies
`fuse-joypad-type.patch`, and builds with the new `platform=rg35xx` target.
The result is `build/fuse-libretro/fuse_libretro.so`.

Equivalent manual build:

```sh
git clone https://github.com/libretro/fuse-libretro.git
cd fuse-libretro
git checkout e997e2bc32c888348f862f69f2c53babfedf7791
patch -p1 < ../fuse-joypad-type.patch
make -f Makefile.libretro platform=rg35xx \
     CC=arm-linux-gnueabihf-gcc CXX=arm-linux-gnueabihf-g++ -j"$(nproc)"
```

(`src/version.c` is generated from `git rev-parse HEAD`, so the tree has to be
a git checkout, not a plain zip extract.)

## What the patch changes

`fuse-joypad-type.patch` touches two files:

**`Makefile.libretro`** — adds an `rg35xx` platform block
(`-marm -march=armv7-a -mfpu=neon-fp16 -mfloat-abi=hard -mtune=cortex-a9`,
NEON, `-DARM`).

**`src/libretro.c`**

1. New core option `fuse_joypad_type`, "Joystick Type (Port 1)", exposed both
   through the v2 core-option definitions and the legacy `retro_variable`
   list so old frontends see it too. Value order deliberately matches
   `libspectrum_joystick_type` (`0..7`), which is what `coreopt()` returns.
2. `retro_set_controller_port_device()`: `RETRO_DEVICE_AUTO_CFG` no longer
   returns early on port 0 — it substitutes the option's device and falls
   through to the normal wiring, so the port really becomes a joystick.
   `RETRO_DEVICE_NONE` now also clears `joystick_1_output`.
3. `update_variables()` re-reads the option and re-applies it while the core
   is running.

## License

The patch modifies FUSE / fuse-libretro, which is distributed under the
**GNU GPL v3** (see `LICENSE`). The patched core and the prebuilt binary in
`dist/` are therefore GPL v3 as well.
