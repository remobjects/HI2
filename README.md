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

## Linux SDK

HI2 generates the Linux Island SDK from an official Ubuntu container image:

```text
HI2 linux <platform-output-folder> \
  [--ubuntu-version=26.04] \
  [--docker-image=ubuntu:26.04] \
  [--docker=<absolute-path>] \
  [--architectures=x86_64,arm64] \
  [--rtl-config-folder=<folder>] \
  [--intermediate=<folder>] \
  [--header-importer=<absolute-path>] \
  [--reuse-sysroots] [--no-zip]
```

The default import captures the current Ubuntu 26.04 development packages for
glibc, GCC builtin headers, GTK 3, and SQLite for both x86_64 and arm64. It
filters the checked-in Linux RTL, GTK, and SQLite configurations against the
actual headers in each architecture's sysroot. `rtl.fx` is generated first;
GTK and SQLite are then imported with an explicit reference to it. The SQLite
static library is copied beside `sqlite3.fx`.

Ubuntu contains case-distinct Linux headers which cannot be represented on a
normal case-insensitive macOS volume. On macOS, HI2 therefore creates a sparse
case-sensitive APFS image below the intermediate folder and mounts it at a
temporary path. Docker writes each sysroot to a tar archive in an ordinary
transfer folder, and the host extracts that archive onto the image. The image
is detached after import and may be reused with `--reuse-sysroots`. Linux hosts
use an ordinary intermediate directory.

The generated layout is:

```text
<platform-output-folder>/Ubuntu 26.04/x86_64/
<platform-output-folder>/Ubuntu 26.04/arm64/
<platform-output-folder>/__Public/Ubuntu 26.04.zip
```

The ZIP is deterministic and contains no GC. `gc.fx`, `gc.lib`, and `libgc.a`
are rejected because collectors are distributed through the separate GC
package. The legacy armv6 SDK surface is intentionally not regenerated: modern
Ubuntu publishes x86_64 and arm64 development environments, while armv6 remains
available only through older SDKs.

## Android SDK

HI2 generates a native Android Island SDK from an official stable NDK and an
official SQLite amalgamation:

```text
HI2 android <platform-output-folder> \
  (--ndk=<extracted-ndk-folder> | --ndk-archive=<android-ndk-r29-linux.zip>) \
  --sqlite-archive=<sqlite-amalgamation-3530400.zip> \
  [--ndk-release=r29] [--api=35] [--sqlite-version=3.53.4] \
  [--architectures=arm64-v8a,armeabi-v7a,x86,x86_64] \
  [--rtl-config-folder=<folder>] [--intermediate=<folder>] \
  [--header-importer=<absolute-path>] [--mono=<absolute-path>] \
  [--docker=<absolute-path>] \
  [--docker-image=ubuntu:24.04] [--reuse-ndk] [--reuse-sqlite] [--no-zip]
```

When `--api` is omitted, the importer selects the NDK metadata's maximum native
API level. The four default ABIs are the NDK's supported default set; removed
`armeabi` and non-default `riscv64` are not advertised. On macOS, archive
extraction uses a reusable case-sensitive APFS sparse image because the NDK
contains case-distinct Linux headers.

`--mono` explicitly selects the managed runtime used to launch
`HeaderImporter.exe`. This is useful on Apple silicon, where a universal or
arm64 Mono avoids Rosetta memory-management failures during the large RTL
header import.

SQLite is rebuilt from the selected amalgamation in an amd64 Linux container
with the NDK's Clang wrappers. Each architecture receives freshly imported
`rtl.fx` and `sqlite3.fx`, the static SQLite library, modern compiler-rt
builtins and `libatomic`, and the NDK shared-library CRT objects under the
legacy names expected by the Elements Android linker. Obsolete `gdbserver` and
all GC files are excluded. The deterministic ZIP is written as:

```text
<platform-output-folder>/Android 35/<abi>/
<platform-output-folder>/__Public/Android 35.zip
```
