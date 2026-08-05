namespace RemObjects.Elements.HI2;

uses
  RemObjects.Elements.RTL;

type
  Importer = public partial class
  private

    method FuchsiaTriple(aArchitecture: not nullable String): not nullable String;
    begin
      case aArchitecture of
        "x64": result := "x86_64-unknown-fuchsia";
        "arm64": result := "aarch64-unknown-fuchsia";
        else raise new Exception($"Unsupported Fuchsia SDK architecture '{aArchitecture}'.");
      end;
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
                                       aAPILevel: not nullable String;
                                       aSDKFolder: not nullable String);
    begin
      var lRuntimeFxFolder := RequireIslandSDKFolder(FuchsiaRuntimeFxFolder, "Fuchsia runtime .fx folder");
      var lIslandRTLFolder := RequireIslandSDKFolder(FuchsiaIslandRTLFolder, "Fuchsia IslandRTL output folder");
      var lIDKArchitectureFolder := Path.Combine(FuchsiaIDKFolder, "arch", aArchitecture);
      var lTargetFolder := Path.Combine(aSDKFolder, aArchitecture);
      var lClangRuntimeFolder: nullable String;
      if length(FuchsiaClangRuntimeFolder) > 0 then
        lClangRuntimeFolder := RequireIslandSDKFolder(FuchsiaClangRuntimeFolder, "Fuchsia Clang runtime folder");
      for each lGCFile in ["gc.fx", "libgc.a"] do begin
        var lStaleGCPath := Path.Combine(lTargetFolder, lGCFile);
        if lStaleGCPath.FileExists then
          File.Delete(lStaleGCPath);
      end;

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
        var lClangFolder := RequireIslandSDKFolder(FuchsiaClangFolder, "Fuchsia Clang folder");
        CopyIslandSDKFile(Path.Combine(lClangFolder, "lib", FuchsiaTriple(aArchitecture), "libunwind.a"),
                           Path.Combine(lTargetFolder, "libunwind.a"));
      end;
      CopyIslandSDKFile(Path.Combine(lRuntimeFxFolder, aArchitecture, "rtl.fx"),
                         Path.Combine(lTargetFolder, "rtl.fx"));
      CopyIslandSDKFile(Path.Combine(lIslandRTLFolder, aArchitecture, "Island.fx"),
                         Path.Combine(lTargetFolder, "Island.fx"));
      CopyIslandSDKFile(Path.Combine(lIDKArchitectureFolder, "sysroot", "lib", "libc.so"),
                         Path.Combine(lTargetFolder, "libc.so"));
      if assigned(lClangRuntimeFolder) then
        CopyIslandSDKFile(Path.Combine(lClangRuntimeFolder, aArchitecture, "libclang_rt.builtins.a"),
                           Path.Combine(lTargetFolder, "libclang_rt.builtins.a"))
      else begin
        var lClangFolder := RequireIslandSDKFolder(FuchsiaClangFolder, "Fuchsia Clang folder");
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
      for each lArchitecture in ["x64", "arm64"] do begin
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
    property FuchsiaRuntimeFxFolder: nullable String;
    property FuchsiaIslandRTLFolder: nullable String;
    property FuchsiaClangFolder: nullable String;
    property FuchsiaClangRuntimeFolder: nullable String;

    method AssembleFuchsiaSDK(aSDKID: not nullable String;
                              aAPILevel: not nullable String;
                              aSDKFolder: not nullable String): nullable String;
    begin
      if SkipFidlBindingImport then
        raise new Exception("--assemble-sdk cannot be combined with --ir-only.");

      Log($"Assembling Fuchsia Island SDK {aSDKID}.");
      AssembleFuchsiaArchitecture("x64", aAPILevel, aSDKFolder);
      AssembleFuchsiaArchitecture("arm64", aAPILevel, aSDKFolder);
      ValidateFuchsiaSDK(aSDKFolder);
      if CreateZips then
        result := CreateFuchsiaSDKZip(aSDKFolder);
    end;

  end;

end.
