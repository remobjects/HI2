# HI2

## Fuchsia IDK

HI2 can turn a raw Fuchsia IDK into an Elements Island SDK. The FIDL stage
discovers libraries from the IDK manifest, compiles their sources to `fidlc`
JSON IR, and converts the IR to real Elements `.fx` files:

```text
HI2 fuchsia <idk-folder> <platform-output-folder> [--intermediate=<folder>] [--api=<level>] [--fidlc=<path>] [--docker=<path>] [--fidlc-docker-image=<image>] [--stable-only] [--reuse-ir] [--ir-only] [library ...]
```

When no library names are supplied, all FIDL libraries in the IDK are imported;
`--stable-only` restricts this to the stable surface. Explicitly requested
libraries automatically include their dependencies. Dependencies are resolved
from the IDK metadata and passed to `fidlc` in dependency-first order. On Linux,
HI2 selects the host-compatible `fidlc`. On
macOS, it runs the IDK's Linux x64 `fidlc` automatically through Docker using
the `ubuntu:24.04` image. `--fidlc` provides an explicit compiler-path override,
`--docker` provides an explicit Docker executable override, and
`--fidlc-docker-image` overrides the container image. HI2 resolves Docker to an
absolute executable path before launching it.

The `--ir-only` option stops after producing `fidlc` JSON IR. Otherwise HI2
passes the IR directly to the FIDL importer in `RemObjects.Elements.dll` and
writes architecture-specific `.fx` files under
`<platform-output-folder>/Fuchsia <sdk-id>/x64` and
`<platform-output-folder>/Fuchsia <sdk-id>/arm64`. Fuchsia import does not
launch `HeaderImporter.exe`. By default, IR and the import manifest are stored
under `<platform-output-folder>/FIDL IR/<sdk-id>`; `--intermediate` overrides
that location. `--reuse-ir` reuses existing per-library IR files, which is
useful when iterating on `.fx` conversion.

When building HI2 against an unmerged Elements worktree, set
`ElementsRootFolder` to that worktree's absolute path so HI2 references the
matching Elements importer implementation. The property defaults to the
sibling `../Elements` checkout.

### Complete Island SDK

Pass `--assemble-sdk` and the runtime inputs to add the non-FIDL parts of the
SDK and create the canonical ZIP:

```text
HI2 fuchsia <idk-folder> <output-folder> \
  --assemble-sdk \
  --runtime-fx=<folder> \
  --islandrtl=<folder> \
  --clang=<folder>
```

The input folders have explicit contracts:

- `--runtime-fx` contains `x64/rtl.fx` and its `arm64` counterpart.
- `--islandrtl` contains `x64/Island.a`, `x64/Island.fx`, and their `arm64`
  counterparts.
- `--clang` is a Fuchsia Clang toolchain. It supplies `libunwind.a` and
  `libclang_rt.builtins.a`.

`--clang-runtime=<folder>` can replace `--clang` when the compiler itself is
not needed. The folder must contain `x64/libunwind.a`,
`x64/libclang_rt.builtins.a`, and their `arm64` counterparts.

The assembler copies the matching IDK sysroot startup object, libc, Zircon,
loader, and fdio libraries; adds the runtime metadata, IslandRTL, unwind, and
compiler runtime artifacts; validates both architectures; and writes:

```text
<output-folder>/Fuchsia <sdk-id>/
<output-folder>/__Public/Fuchsia <sdk-id>.zip
```

This matches the `Frameworks/Island/Darwin` layout when `output-folder` is
`Frameworks/Island/Fuchsia`.

### Separate GC package

GC is not part of the SDK archive. Add `--assemble-gc` to create the separate
Fuchsia GC package that is overlaid by the libraries installer:

```text
HI2 fuchsia <idk-folder> <platform-output-folder> \
  --reuse-ir \
  --assemble-gc \
  --runtime-fx=<folder> \
  --gc-x64=<file> \
  --gc-arm64=<file>
```

`--runtime-fx` supplies `x64/gc.fx` and `arm64/gc.fx`. Build the x64 and arm64
archives from the GC repository first so upstream CMake remains the single
source-file manifest:

```text
./build-remobjects-fuchsia.sh \
  --idk <idk-folder> \
  --toolchain <fuchsia-clang-folder> \
  --api <level>
```

Pass the resulting
`out/remobjects-gc/Fuchsia/x64/Release/libgc.a` and arm64 counterpart through
`--gc-x64` and `--gc-arm64`. HI2 does not compile GC sources.

By default, with an SDK platform output of `Frameworks/Island/Fuchsia`, GC is
written in the existing sibling-package pattern:

```text
Frameworks/Island/GC/Fuchsia/Fuchsia <sdk-id>/{x64,arm64}/
Frameworks/Island/GC/Fuchsia.zip
```

`--gc-output=<folder>` overrides the `Frameworks/Island/GC/Fuchsia` folder.

The ZIP has a canonical root folder, sorted entries, fixed timestamps and
permissions, CRC validation, and a logged SHA-256. Re-running with identical
inputs produces the same archive bytes. On macOS, HI2 uses the absolute system
`zip` and `unzip` tools so packaging also works under Fire's bundled arm64 Mono;
Linux uses the managed ZIP implementation. This applies to both the SDK and GC
archives. Pass `--no-zip` to stop after assembling and validating their folders.
