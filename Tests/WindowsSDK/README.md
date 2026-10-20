# Windows SDK ARM64EC checks

Build `Inspect.elements` with a coherent Elements Core compiler and set
`CompilerBin` to that compiler directory. Run the resulting
`WindowsSdkCheck.dll` with the SDK root as its sole argument. It validates all
four CPU identities/triples, the WinRT-to-RTL dependency, ARM64 versus EC
CONTEXT fields, and the GetTickCount DLL import.

`Consumer.elements` is a compile-only native probe. Set `SDKRoot` to the
regenerated SDK and `IslandDeclarations` to matching EC Island metadata. Until
the EC IslandRTL is available, the Elements `arm64ec_backend/GenerateFixture`
bootstrap can supply **declaration-only** Island metadata. This does not reuse
native ARM64 code or establish runtime/GC support. Do not distribute that
bootstrap metadata as an EC runtime.

Verify the consumer object is COFF ARM64EC, the generated IR returns 1232 for
`ContextSize`, `ReadStack` loads the Rsp field at offset 152, and `Tick` calls
`GetTickCount`. Keep the emitted archive as a compile check; it is not a linked
application. A real executable test additionally needs the separately built
EC IslandRTL and GC.
