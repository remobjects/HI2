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

GC is not part of the SDK archive, and HI2 does not build or package it. Build
and package the Fuchsia collector through the GC repository's release flow.
Fuchsia SDK assembly removes stale `gc.fx` and `libgc.a` files and rejects an
SDK if either artifact is present.

The SDK ZIP has a canonical root folder, sorted entries, fixed timestamps and
permissions, CRC validation, and a logged SHA-256. Re-running with identical
inputs produces the same archive bytes. On macOS, HI2 uses the absolute system
`zip` and `unzip` tools so packaging also works under Fire's bundled arm64 Mono;
Linux uses the managed ZIP implementation. Pass `--no-zip` to stop after
assembling and validating the SDK folder.

## Windows SDK

HI2 can generate a fresh Windows Island SDK from either an installed Windows
SDK or the official `Microsoft.Windows.SDK.CPP` NuGet packages:

```text
HI2 windows <windows-sdk-folder> <platform-output-folder> \
  --msvc=<folder> \
  [--netfx-sdk=<folder>] \
  [--sdk-version=<version>] \
  [--architectures=i386,x86_64,arm64] \
  [--rtl-config-folder=<folder>] \
  [--support-files=<folder>] \
  [--intermediate=<folder>] \
  [--header-importer=<absolute-path>] \
  [--skip-winrt] [--no-zip]
```

For NuGet input, extract `Microsoft.Windows.SDK.CPP` and each desired
architecture package (`.x86`, `.x64`, and `.arm64`) into one folder. The
packages merge below their common `c` directory. The Windows SDK does not
contain the MSVC CRT headers, so `--msvc` is required and may point to the MSVC
include folder, a versioned MSVC tools folder, or a Visual Studio root.

The Windows Runtime metadata headers also use CLR metadata declarations from
the .NET Framework SDK. On an installed Windows SDK layout, HI2 looks for the
sibling `Windows Kits\NETFXSDK` folder and selects the newest installed version.
For NuGet input or a non-Windows host, pass `--netfx-sdk` with the .NET Framework
SDK root, a versioned SDK folder, or its `Include\um` folder. This option is not
required with `--skip-winrt`.

The importer auto-selects the newest SDK version unless `--sdk-version` is
specified, generates `rtl.fx` and `winrt.fx` for every requested architecture,
validates their platform/CPU/target metadata, and writes:

```text
<platform-output-folder>/Windows <sdk-version>/
<platform-output-folder>/__Public/Windows <sdk-version>.zip
```

The checked-in Windows JSON files remain the curated compatibility surface for
the core `rtl.fx` import; headers removed from a newer SDK are skipped with a
diagnostic. `winrt.fx` is discovered fresh from the top-level Windows Runtime C
ABI headers in the selected SDK; C++-only WRL and implementation-helper headers
are excluded. RTL and WinRT are imported in one graph so the latter retains the
Windows preprocessor state and an explicit dependency on `rtl.fx`.
`--support-files` can copy existing `java.fx`, `sqlite3.fx`, and `sqlite3.lib`
files from per-architecture folders. GC is never copied into the SDK and stale
`gc.fx`, `gc.lib`, or `libgc.a` files are rejected.
