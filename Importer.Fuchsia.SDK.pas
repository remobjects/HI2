namespace RemObjects.Elements.HI2;

uses
  RemObjects.Elements.Fx,
  RemObjects.Elements.RTL;

type
  Importer = public partial class
  private

    method FuchsiaTriple(aArchitecture: not nullable String): not nullable String;
    begin
      case aArchitecture of
        "x86_64": result := "x86_64-unknown-fuchsia";
        "arm64": result := "aarch64-unknown-fuchsia";
        else raise new Exception($"Unsupported Fuchsia SDK architecture '{aArchitecture}'.");
      end;
    end;

    method FuchsiaTarget(aArchitecture: not nullable String): FxCpuTarget;
    begin
      case aArchitecture of
        "x86_64": result := FxCpuTarget.x86_64;
        "arm64": result := FxCpuTarget.arm64;
        else raise new Exception($"Unsupported Fuchsia SDK architecture '{aArchitecture}'.");
      end;
    end;

    method FuchsiaIDKArchitecture(aArchitecture: not nullable String): not nullable String;
    begin
      // Raw Fuchsia IDKs use "x64" for the Intel target directory.
      case aArchitecture of
        "x86_64": result := "x64";
        "arm64": result := "arm64";
        else raise new Exception($"Unsupported Fuchsia SDK architecture '{aArchitecture}'.");
      end;
    end;

    method ResolveFuchsiaClangIncludeFolder(aClangFolder: not nullable String): not nullable String;
    begin
      var lClangRoot := RequireIslandSDKFolder(Path.Combine(aClangFolder, "lib", "clang"), "Fuchsia Clang resource folder");
      var lCandidates := Folder.GetSubfolders(lClangRoot)
                               .Select(aFolder -> Path.Combine(aFolder, "include"))
                               .Where(aFolder -> Path.Combine(aFolder, "stddef.h").FileExists and
                                                   Path.Combine(aFolder, "stdint.h").FileExists and
                                                   Path.Combine(aFolder, "unwind.h").FileExists)
                               .OrderBy(aFolder -> aFolder)
                               .ToList;
      if lCandidates.Count = 0 then
        raise new Exception($"Fuchsia Clang builtin headers were not found below '{lClangRoot}'.");
      if lCandidates.Count > 1 then
        raise new Exception($"Multiple Fuchsia Clang builtin-header folders were found below '{lClangRoot}': {String.Join(", ", lCandidates)}.");
      result := lCandidates[0] as not nullable;
    end;

    method FuchsiaRTLIncludeFolders(aArchitecture: not nullable String;
                                    aClangFolder: not nullable String): not nullable List<String>;
    begin
      result := new List<String>;
      var lIDKArchitecture := FuchsiaIDKArchitecture(aArchitecture);
      result.Add(RequireIslandSDKFolder(Path.Combine(FuchsiaIDKFolder, "arch", lIDKArchitecture, "sysroot", "include"), $"Fuchsia {aArchitecture} sysroot headers"));
      result.Add(ResolveFuchsiaClangIncludeFolder(aClangFolder));
      result.Add(RequireIslandSDKFolder(Path.Combine(FuchsiaIDKFolder, "pkg", "fdio", "include"), "Fuchsia fdio headers"));
    end;

    method FuchsiaRTLHeaders(aIncludeFolders: not nullable ImmutableList<String>): not nullable List<String>;
    begin
      result := new List<String>;
      var lSeen := new HashSet<String>;
      var lAllTypesHeader := "bits/alltypes.h";
      if not Path.Combine(aIncludeFolders[0], lAllTypesHeader).FileExists then
        raise new Exception($"Required Fuchsia system header '{lAllTypesHeader}' was not found in '{aIncludeFolders[0]}'.");
      lSeen.Add(lAllTypesHeader);
      result.Add(lAllTypesHeader);
      var lClangIncludeFolder := aIncludeFolders[1];
      for each lHeader in ["stddef.h", "stdarg.h", "stdint.h", "stdbool.h", "stdatomic.h", "stdalign.h", "stdnoreturn.h", "float.h", "unwind.h"] do begin
        if not Path.Combine(lClangIncludeFolder, lHeader).FileExists then begin
          if lHeader in ["stddef.h", "stdarg.h", "stdint.h", "stdbool.h", "stdatomic.h", "unwind.h"] then
            raise new Exception($"Required Fuchsia Clang header '{lHeader}' was not found in '{lClangIncludeFolder}'.");
          continue;
        end;
        if lSeen.Add(lHeader) then
          result.Add(lHeader);
      end;

      var lSysrootIncludeFolder := aIncludeFolders[0];
      for each lFile in Folder.GetFiles(lSysrootIncludeFolder, true)
                              .Where(aFile -> aFile.PathExtension.ToLowerInvariant = ".h")
                              .OrderBy(aFile -> aFile) do begin
        var lHeader := IslandSDKRelativePath(lSysrootIncludeFolder, lFile);
        if lHeader.StartsWith("bits/", true) or
           lHeader.StartsWith("llvm-libc-macros/", true) or
           lHeader.StartsWith("llvm-libc-types/", true) or
           (lHeader in [
             "zircon/device/audio.h", // Unconditionally includes C++ <cassert> and <cstdio>.
             "zircon/sanitizer.h", // Private sanitizer-runtime declarations use unsupported __typeof syntax.
             "zircon/syscalls-next.h", // Deliberately rejected by a stable API-level import.
             "zircon/testonly-syscalls.h"
           ]) then
          continue;
        if lSeen.Add(lHeader) then
          result.Add(lHeader);
      end;

      var lFdioIncludeFolder := aIncludeFolders[2];
      for each lFile in Folder.GetFiles(lFdioIncludeFolder, true)
                              .Where(aFile -> aFile.PathExtension.ToLowerInvariant = ".h")
                              .OrderBy(aFile -> aFile) do begin
        var lHeader := IslandSDKRelativePath(lFdioIncludeFolder, lFile);
        if lSeen.Add(lHeader) then
          result.Add(lHeader);
      end;
    end;

    method FuchsiaRTLIndirectHeaders(aArchitecture: not nullable String): not nullable List<String>;
    begin
      result := new List<String>;
      var lIDKArchitecture := FuchsiaIDKArchitecture(aArchitecture);
      var lSysrootIncludeFolder := RequireIslandSDKFolder(Path.Combine(FuchsiaIDKFolder, "arch", lIDKArchitecture, "sysroot", "include"), $"Fuchsia {aArchitecture} sysroot headers");
      var lGeneratedSyscallsFolder := RequireIslandSDKFolder(Path.Combine(lSysrootIncludeFolder, "zircon", "syscalls", "gen"), $"Fuchsia {aArchitecture} generated syscall declarations");
      result.Add(IslandSDKRelativePath(lSysrootIncludeFolder,
                                       RequireIslandSDKFile(Path.Combine(lGeneratedSyscallsFolder, "cdecls.inc"), $"Fuchsia {aArchitecture} stable syscall declarations")));
    end;

    method FuchsiaRTLDefines(aArchitecture: not nullable String;
                             aAPILevel: not nullable String): not nullable List<String>;
    begin
      result := new List<String>(
        "FUCHSIA=1", "Posix=1", "__Fuchsia__=1", "__Fuchsia_API_level__="+aAPILevel,
        "__Fuchsia_Compiler_ABI__=1", "!FUCHSIA_API_LEVEL_(level)=level",
        "!HEAD=4292870144", "!NEXT=4291821568", "!PLATFORM=4293918720",
        "!_Noreturn=", "!__LEAF_FN=", "__ELF__=1", "__LP64__=1", "_LP64=1",
        "__SIZEOF_POINTER__=8", "__SIZEOF_LONG__=8", "__SIZE_TYPE__=long unsigned int",
        "__PTRDIFF_TYPE__=long int", "__INT8_TYPE__=signed char", "__UINT8_TYPE__=unsigned char",
        "__INT16_TYPE__=short", "__UINT16_TYPE__=unsigned short", "__INT32_TYPE__=int",
        "__UINT32_TYPE__=unsigned int", "__INT64_TYPE__=long int",
        "__UINT64_TYPE__=long unsigned int", "__INTMAX_TYPE__=long int",
        "__UINTMAX_TYPE__=long unsigned int", "__INTPTR_TYPE__=long int",
        "__UINTPTR_TYPE__=long unsigned int", "__WCHAR_TYPE__=int",
        "__UINT_LEAST8_TYPE__=unsigned char", "__UINT_LEAST16_TYPE__=unsigned short",
        "__UINT_LEAST32_TYPE__=unsigned int", "__UINT_LEAST64_TYPE__=long unsigned int",
        "__INT_LEAST8_TYPE__=signed char", "__INT_LEAST16_TYPE__=short",
        "__INT_LEAST32_TYPE__=int", "__INT_LEAST64_TYPE__=long int",
        "__UINT_FAST8_TYPE__=unsigned char", "__UINT_FAST16_TYPE__=unsigned short",
        "__UINT_FAST32_TYPE__=unsigned int", "__UINT_FAST64_TYPE__=long unsigned int",
        "__INT_FAST8_TYPE__=signed char", "__INT_FAST16_TYPE__=short",
        "__INT_FAST32_TYPE__=int", "__INT_FAST64_TYPE__=long int",
        "__WINT_TYPE__=unsigned int", "__CHAR16_TYPE__=unsigned short",
        "__CHAR32_TYPE__=unsigned int", "__UINTPTR_MAX__=18446744073709551615UL",
        "!__UINT32_C(value)=value", "!__UINT64_C(value)=value",
        "__ATOMIC_RELAXED=0", "__ATOMIC_CONSUME=1",
        "__ATOMIC_ACQUIRE=2", "__ATOMIC_RELEASE=3", "__ATOMIC_ACQ_REL=4",
        "__ATOMIC_SEQ_CST=5", "__STDC__=1", "__STDC_VERSION__=201112L", "_GNU_SOURCE=1"
      );
      var lIDKArchitecture := FuchsiaIDKArchitecture(aArchitecture);
      var lAllTypesPath := RequireIslandSDKFile(Path.Combine(FuchsiaIDKFolder, "arch", lIDKArchitecture, "sysroot", "include", "bits", "alltypes.h"), $"Fuchsia {aArchitecture} all-types header");
      var lSeenNeeds := new HashSet<String>;
      for each lMatch: System.Text.RegularExpressions.Match in System.Text.RegularExpressions.Regex.Matches(File.ReadText(lAllTypesPath), "__NEED_[A-Za-z0-9_]+") do
        if lSeenNeeds.Add(lMatch.Value) then
          result.Add(lMatch.Value+"=1");
      case aArchitecture of
        "x86_64": result.Add(["__x86_64=1", "__x86_64__=1", "__amd64=1", "__amd64__=1", "__SSE__=1", "__SSE2__=1"]);
        "arm64": result.Add(["__aarch64__=1", "__AARCH64EL__=1", "__ARM_ARCH=8", "__ARM_ARCH_8A=1", "__ARM_64BIT_STATE=1"]);
        else raise new Exception($"Unsupported Fuchsia SDK architecture '{aArchitecture}'.");
      end;
    end;

    method CreateFuchsiaRTLConfiguration(aArchitecture: not nullable String;
                                         aSDKID: not nullable String;
                                         aAPILevel: not nullable String;
                                         aIncludeFolders: not nullable ImmutableList<String>): not nullable String;
    begin
      var lImport := new JsonObject;
      lImport["Name"] := "rtl";
      lImport["Framework"] := false;
      lImport["Prefix"] := "";
      lImport["Core"] := true;
      lImport["ForceNamespace"] := "rtl";
      lImport["Explicit"] := false;
      lImport["DepLibs"] := new JsonArray("libunwind.a");
      lImport["Files"] := new JsonArray(FuchsiaRTLHeaders(aIncludeFolders));
      lImport["IndirectFiles"] := new JsonArray(FuchsiaRTLIndirectHeaders(aArchitecture));

      var lConfiguration := JsonDocument.CreateObject;
      lConfiguration["TargetString"] := FuchsiaTriple(aArchitecture);
      lConfiguration["Version"] := aAPILevel+".0";
      lConfiguration["SDKVersionString"] := aSDKID;
      lConfiguration["Platform"] := "Fuchsia";
      lConfiguration["Island"] := true;
      lConfiguration["Imports"] := new JsonArray(lImport);
      lConfiguration["Defines"] := new JsonArray(FuchsiaRTLDefines(aArchitecture, aAPILevel));

      var lConfigurationPath := Path.Combine(FuchsiaIntermediateFolder, $"fuchsia-rtl-{aArchitecture}-{aSDKID}.json");
      File.WriteText(lConfigurationPath, lConfiguration.ToJsonString(JsonFormat.HumanReadable));
      result := lConfigurationPath as not nullable;
    end;

    method RunFuchsiaHeaderImport(aConfiguration: not nullable String;
                                  aOutputFolder: not nullable String;
                                  aArchitecture: not nullable String;
                                  aSDKID: not nullable String;
                                  aIncludeFolders: not nullable ImmutableList<String>);
    begin
      var lArchitectureFolder := Path.Combine(FuchsiaIDKFolder, "arch", FuchsiaIDKArchitecture(aArchitecture));
      var lArguments := new List<String>;
      lArguments.Add("import");
      lArguments.Add($"--json={aConfiguration}");
      lArguments.Add($"--sdkversion={aSDKID}");
      lArguments.Add("-o", aOutputFolder);
      for each lIncludeFolder in aIncludeFolders do
        lArguments.Add("-i", lIncludeFolder);
      lArguments.Add($"--libpath={RequireIslandSDKFolder(Path.Combine(lArchitectureFolder, "sysroot", "lib"), $"Fuchsia {aArchitecture} sysroot libraries")}");
      lArguments.Add($"--libpath={RequireIslandSDKFolder(Path.Combine(lArchitectureFolder, "lib"), $"Fuchsia {aArchitecture} IDK libraries")}");
      if Debug then
        lArguments.Add("--debug");
      RunHI(lArguments) SDKFolder(FuchsiaIDKFolder);
    end;

    method ValidateFuchsiaRTL(aPath: not nullable String;
                              aArchitecture: not nullable String);
    begin
      RequireIslandSDKFile(aPath, $"Fuchsia {aArchitecture} rtl.fx");
      var lFx := new FxFile;
      using lStream := new System.IO.FileStream(aPath, System.IO.FileMode.Open, System.IO.FileAccess.Read, System.IO.FileShare.Read) do
        lFx.Read(lStream);
      if lFx.Name <> "rtl" then
        raise new Exception($"Fuchsia {aArchitecture} runtime FX '{aPath}' is named '{lFx.Name}', expected 'rtl'.");
      if lFx.Platform <> "Fuchsia" then
        raise new Exception($"Fuchsia {aArchitecture} runtime FX '{aPath}' has platform '{lFx.Platform}', expected Fuchsia.");
      if (lFx.TargetDescriptors.Count <> 1) or (lFx.TargetDescriptors[0] <> FuchsiaTarget(aArchitecture)) then
        raise new Exception($"Fuchsia {aArchitecture} runtime FX '{aPath}' has the wrong CPU target.");
      if (lFx.Targets.Count <> 1) or (lFx.Targets[0].TargetString <> FuchsiaTriple(aArchitecture)) then
        raise new Exception($"Fuchsia {aArchitecture} runtime FX '{aPath}' has target string '{if lFx.Targets.Count = 0 then "<none>" else lFx.Targets[0].TargetString}', expected '{FuchsiaTriple(aArchitecture)}'.");

      var lTarget := lFx.Targets.Single;
      for each lTypeName in [
        "__struct_timespec", "locale_t", "mode_t", "pid_t", "pthread_t", "uint32_t", "uint64_t",
        "zx_handle_t", "zx_channel_call_args_t", "zx_channel_call_etc_args_t",
        "zx_handle_disposition_t", "zx_handle_info_t", "zx_port_packet_t"
      ] do
        if not lTarget.NamedTypes.Any(aType -> (aType.Name = "rtl."+lTypeName) and (aType.Visibility = FxMemberVisibility.Public) and (aType.Type >= 0)) then
          raise new Exception($"Fuchsia {aArchitecture} runtime FX is missing public type 'rtl.{lTypeName}'.");

      var lGlobalName := lTarget.NamedTypes.FirstOrDefault(aType -> aType.Name = "rtl.__Global");
      if not assigned(lGlobalName) or (lGlobalName.Type < 0) then
        raise new Exception($"Fuchsia {aArchitecture} runtime FX has no public global scope.");
      var lGlobalType := lTarget.Types[lGlobalName.Type] as FxDefinitionType;
      if not assigned(lGlobalType) then
        raise new Exception($"Fuchsia {aArchitecture} runtime FX global scope has an invalid type.");
      for each lMemberName in [
        "_Unwind_Resume", "nl_langinfo_l",
        "zx_channel_call", "zx_channel_call_etc", "zx_channel_create",
        "zx_channel_read", "zx_channel_read_etc", "zx_channel_write", "zx_channel_write_etc",
        "zx_handle_close", "zx_handle_replace", "zx_object_wait_async",
        "zx_port_cancel", "zx_port_create", "zx_port_queue", "zx_port_wait",
        "fdio_service_connect", "zx_take_startup_handle", "zx_thread_self"
      ] do
        if not lGlobalType.Members.Any(aMember -> (aMember.Name = lMemberName) and (aMember.Visibility = FxMemberVisibility.Public)) then
          raise new Exception($"Fuchsia {aArchitecture} runtime FX is missing public member 'rtl.{lMemberName}'.");
      if not lTarget.DependentLibraries.Contains("libunwind.a") then
        raise new Exception($"Fuchsia {aArchitecture} runtime FX does not depend on libunwind.a.");
    end;

    method ResolveFuchsiaBuiltins(aClangFolder: not nullable String; aArchitecture: not nullable String): not nullable String;
    begin
      var lSuffix := Path.Combine("lib", FuchsiaTriple(aArchitecture), "libclang_rt.builtins.a");
      var lCandidates := Folder.GetFiles(Path.Combine(aClangFolder, "lib", "clang"), true)
                               .Where(aFile -> aFile.EndsWith(lSuffix, false))
                               .OrderBy(aFile -> aFile)
                               .ToList;
      if lCandidates.Count = 0 then
        raise new Exception($"Clang builtins for {aArchitecture} were not found below '{aClangFolder}'.");
      if lCandidates.Count > 1 then
        raise new Exception($"Multiple Clang builtins archives for {aArchitecture} were found below '{aClangFolder}': {String.Join(", ", lCandidates)}.");
      result := RequireIslandSDKFile(lCandidates[0], $"Clang builtins for {aArchitecture}");
    end;

    method AssembleFuchsiaArchitecture(aArchitecture: not nullable String;
                                       aSDKID: not nullable String;
                                       aAPILevel: not nullable String;
                                       aSDKFolder: not nullable String);
    begin
      var lIslandRTLFolder := RequireIslandSDKFolder(FuchsiaIslandRTLFolder, "Fuchsia IslandRTL output folder");
      var lIDKArchitectureFolder := Path.Combine(FuchsiaIDKFolder, "arch", FuchsiaIDKArchitecture(aArchitecture));
      var lTargetFolder := Path.Combine(aSDKFolder, aArchitecture);
      var lClangFolder := RequireIslandSDKFolder(FuchsiaClangFolder, "Fuchsia Clang folder");
      var lClangRuntimeFolder: nullable String;
      if length(FuchsiaClangRuntimeFolder) > 0 then
        lClangRuntimeFolder := RequireIslandSDKFolder(FuchsiaClangRuntimeFolder, "Fuchsia Clang runtime folder");
      for each lGCFile in ["gc.fx", "libgc.a"] do begin
        var lStaleGCPath := Path.Combine(lTargetFolder, lGCFile);
        if lStaleGCPath.FileExists then
          File.Delete(lStaleGCPath);
      end;

      var lIncludeFolders := FuchsiaRTLIncludeFolders(aArchitecture, lClangFolder);
      var lConfiguration := CreateFuchsiaRTLConfiguration(aArchitecture, aSDKID, aAPILevel, lIncludeFolders);
      var lRTLFxPath := Path.Combine(lTargetFolder, "rtl.fx");
      if lRTLFxPath.FileExists then
        File.Delete(lRTLFxPath);
      RunFuchsiaHeaderImport(lConfiguration, lTargetFolder, aArchitecture, aSDKID, lIncludeFolders);
      ValidateFuchsiaRTL(lRTLFxPath, aArchitecture);

      CopyIslandSDKFile(Path.Combine(lIDKArchitectureFolder, "sysroot", "lib", "Scrt1.o"),
                         Path.Combine(lTargetFolder, "Scrt1.o"));
      CopyIslandSDKFile(Path.Combine(lIDKArchitectureFolder, "lib", "libfdio.so"),
                         Path.Combine(lTargetFolder, "libfdio.so"));
      CopyIslandSDKFile(Path.Combine(lIDKArchitectureFolder, "sysroot", "lib", "libzircon.so"),
                         Path.Combine(lTargetFolder, "libzircon.so"));
      CopyIslandSDKFile(Path.Combine(lIslandRTLFolder, aArchitecture, "Island.a"),
                         Path.Combine(lTargetFolder, "Island.a"));
      CopyIslandSDKFile(Path.Combine(lIDKArchitectureFolder, "sysroot", "dist", "lib", "ld.so.1"),
                         Path.Combine(lTargetFolder, "ld.so.1"));
      CopyIslandSDKFile(Path.Combine(lIDKArchitectureFolder, "dist", "libfdio.so"),
                         Path.Combine(lTargetFolder, "dist", "libfdio.so"));
      if assigned(lClangRuntimeFolder) then
        CopyIslandSDKFile(Path.Combine(lClangRuntimeFolder, aArchitecture, "libunwind.a"),
                           Path.Combine(lTargetFolder, "libunwind.a"))
      else begin
        CopyIslandSDKFile(Path.Combine(lClangFolder, "lib", FuchsiaTriple(aArchitecture), "libunwind.a"),
                           Path.Combine(lTargetFolder, "libunwind.a"));
      end;
      CopyIslandSDKFile(Path.Combine(lIslandRTLFolder, aArchitecture, "Island.fx"),
                         Path.Combine(lTargetFolder, "Island.fx"));
      CopyIslandSDKFile(Path.Combine(lIDKArchitectureFolder, "sysroot", "lib", "libc.so"),
                         Path.Combine(lTargetFolder, "libc.so"));
      if assigned(lClangRuntimeFolder) then
        CopyIslandSDKFile(Path.Combine(lClangRuntimeFolder, aArchitecture, "libclang_rt.builtins.a"),
                           Path.Combine(lTargetFolder, "libclang_rt.builtins.a"))
      else begin
        CopyIslandSDKFile(ResolveFuchsiaBuiltins(lClangFolder, aArchitecture),
                           Path.Combine(lTargetFolder, "libclang_rt.builtins.a"));
      end;
    end;

    method ValidateFuchsiaSDK(aSDKFolder: not nullable String);
    begin
      var lRequired := [
        "Scrt1.o", "libfdio.so", "libzircon.so", "Island.a", "ld.so.1",
        "dist/libfdio.so", "libunwind.a", "rtl.fx", "Island.fx",
        "libc.so", "libclang_rt.builtins.a"
      ];
      for each lArchitecture in ["x86_64", "arm64"] do begin
        var lArchitectureFolder := Path.Combine(aSDKFolder, lArchitecture);
        for each lRelativePath in lRequired do
          RequireIslandSDKFile(Path.Combine(lArchitectureFolder, lRelativePath),
                               $"Fuchsia {lArchitecture} SDK entry '{lRelativePath}'");
        for each lGCFile in ["gc.fx", "libgc.a"] do
          if Path.Combine(lArchitectureFolder, lGCFile).FileExists then
            raise new Exception($"Fuchsia {lArchitecture} SDK must not contain '{lGCFile}'; GC is packaged separately.");
        if Folder.GetFiles(lArchitectureFolder).Where(aFile -> aFile.PathExtension = ".fx").Count <= lRequired.Where(aFile -> aFile.PathExtension = ".fx").Count then
          raise new Exception($"Fuchsia {lArchitecture} SDK contains no imported FIDL .fx files.");
      end;
    end;

    method CreateFuchsiaSDKZip(aSDKFolder: not nullable String): not nullable String;
    begin
      var lPublicFolder := Path.Combine(FuchsiaOutputFolder, "__Public");
      result := CreateDeterministicIslandSDKZip(aSDKFolder,
                                                Path.Combine(lPublicFolder, Path.GetFileName(aSDKFolder)+".zip"));
    end;

  public

    property AssembleFuchsiaRuntime := false;
    property FuchsiaIslandRTLFolder: nullable String;
    property FuchsiaClangFolder: nullable String;
    property FuchsiaClangRuntimeFolder: nullable String;

    method AssembleFuchsiaSDK(aSDKID: not nullable String;
                              aAPILevel: not nullable String;
                              aSDKFolder: not nullable String): nullable String;
    begin
      if SkipFidlBindingImport then
        raise new Exception("--assemble-sdk cannot be combined with --ir-only.");

      HI := RequireIslandSDKFile(HI, "HeaderImporter executable");
      Log($"Assembling Fuchsia Island SDK {aSDKID}.");
      AssembleFuchsiaArchitecture("x86_64", aSDKID, aAPILevel, aSDKFolder);
      AssembleFuchsiaArchitecture("arm64", aSDKID, aAPILevel, aSDKFolder);
      ValidateFuchsiaSDK(aSDKFolder);
      if CreateZips then
        result := CreateFuchsiaSDKZip(aSDKFolder);
    end;

  end;

end.
