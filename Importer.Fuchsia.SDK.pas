namespace RemObjects.Elements.HI2;

uses
  RemObjects.Elements.RTL,
  System.IO.Compression,
  System.Security.Cryptography;

type
  Importer = public partial class
  private

    method RequireFuchsiaFile(aPath: nullable String; aDescription: not nullable String): not nullable String;
    begin
      if length(aPath) = 0 then
        raise new Exception($"{aDescription} was not specified.");
      var lPath := Path.GetFullPath(aPath as not nullable);
      if not lPath.FileExists then
        raise new Exception($"{aDescription} was not found at '{lPath}'.");
      if File.Size(lPath) = 0 then
        raise new Exception($"{aDescription} is empty at '{lPath}'.");
      result := lPath as not nullable;
    end;

    method RequireFuchsiaFolder(aPath: nullable String; aDescription: not nullable String): not nullable String;
    begin
      if length(aPath) = 0 then
        raise new Exception($"{aDescription} was not specified.");
      var lPath := Path.GetFullPath(aPath as not nullable);
      if not lPath.FolderExists then
        raise new Exception($"{aDescription} was not found at '{lPath}'.");
      result := lPath as not nullable;
    end;

    method CopyFuchsiaSDKFile(aSource: not nullable String; aDestination: not nullable String);
    begin
      RequireFuchsiaFile(aSource, "Fuchsia SDK input");
      Folder.Create(Path.GetParentDirectory(aDestination));
      if aDestination.FileExists then
        File.Delete(aDestination);
      System.IO.File.Copy(aSource, aDestination, false);
    end;

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
      result := RequireFuchsiaFile(lCandidates[0], $"Clang builtins for {aArchitecture}");
    end;

    method RunFuchsiaTool(aExecutable: not nullable String;
                          aArguments: not nullable ImmutableList<String>;
                          aWorkingDirectory: not nullable String;
                          aLogCommand: Boolean := true);
    begin
      RequireFuchsiaFile(aExecutable, "Fuchsia build tool");
      if aLogCommand then
        Log(Process.StringForCommand(aExecutable) Parameters(aArguments));
      var lOutput := new StringBuilder;
      var lExitCode := Process.Run(aExecutable, aArguments.ToArray, nil, aWorkingDirectory, aLine -> begin
        lOutput.AppendLine(aLine);
        if Debug or assigned(LoggingCallback) then
          Log("  "+aLine);
      end, aLine -> begin
        lOutput.AppendLine(aLine);
        Log("  "+aLine);
      end);

      if lExitCode ≠ 0 then begin
        if not (Debug or assigned(LoggingCallback)) then
          Log(lOutput.ToString);
        raise new HIException($"Fuchsia build tool '{aExecutable}' failed with exit code {lExitCode}.");
      end;
    end;

    method ResolveFuchsiaGC(aArchitecture: not nullable String): not nullable String;
    begin
      var lExplicit := if aArchitecture = "x64" then FuchsiaGCX64Library else FuchsiaGCArm64Library;
      if length(lExplicit) > 0 then
        exit RequireFuchsiaFile(lExplicit, $"Fuchsia {aArchitecture} GC archive");
      raise new Exception($"Fuchsia {aArchitecture} GC archive was not specified. Build it with build-remobjects-fuchsia.sh in the GC repository, then pass --gc-x64 and --gc-arm64.");
    end;

    method AssembleFuchsiaArchitecture(aArchitecture: not nullable String;
                                       aAPILevel: not nullable String;
                                       aSDKFolder: not nullable String);
    begin
      var lRuntimeFxFolder := RequireFuchsiaFolder(FuchsiaRuntimeFxFolder, "Fuchsia runtime .fx folder");
      var lIslandRTLFolder := RequireFuchsiaFolder(FuchsiaIslandRTLFolder, "Fuchsia IslandRTL output folder");
      var lIDKArchitectureFolder := Path.Combine(FuchsiaIDKFolder, "arch", aArchitecture);
      var lTargetFolder := Path.Combine(aSDKFolder, aArchitecture);
      var lClangRuntimeFolder: nullable String;
      if length(FuchsiaClangRuntimeFolder) > 0 then
        lClangRuntimeFolder := RequireFuchsiaFolder(FuchsiaClangRuntimeFolder, "Fuchsia Clang runtime folder");
      for each lGCFile in ["gc.fx", "libgc.a"] do begin
        var lStaleGCPath := Path.Combine(lTargetFolder, lGCFile);
        if lStaleGCPath.FileExists then
          File.Delete(lStaleGCPath);
      end;

      CopyFuchsiaSDKFile(Path.Combine(lIDKArchitectureFolder, "sysroot", "lib", "Scrt1.o"),
                         Path.Combine(lTargetFolder, "Scrt1.o"));
      CopyFuchsiaSDKFile(Path.Combine(lIDKArchitectureFolder, "lib", "libfdio.so"),
                         Path.Combine(lTargetFolder, "libfdio.so"));
      CopyFuchsiaSDKFile(Path.Combine(lIDKArchitectureFolder, "sysroot", "lib", "libzircon.so"),
                         Path.Combine(lTargetFolder, "libzircon.so"));
      CopyFuchsiaSDKFile(Path.Combine(lIslandRTLFolder, aArchitecture, "Island.a"),
                         Path.Combine(lTargetFolder, "Island.a"));
      CopyFuchsiaSDKFile(Path.Combine(lIDKArchitectureFolder, "sysroot", "dist", "lib", "ld.so.1"),
                         Path.Combine(lTargetFolder, "ld.so.1"));
      CopyFuchsiaSDKFile(Path.Combine(lIDKArchitectureFolder, "dist", "libfdio.so"),
                         Path.Combine(lTargetFolder, "dist", "libfdio.so"));
      if assigned(lClangRuntimeFolder) then
        CopyFuchsiaSDKFile(Path.Combine(lClangRuntimeFolder, aArchitecture, "libunwind.a"),
                           Path.Combine(lTargetFolder, "libunwind.a"))
      else begin
        var lClangFolder := RequireFuchsiaFolder(FuchsiaClangFolder, "Fuchsia Clang folder");
        CopyFuchsiaSDKFile(Path.Combine(lClangFolder, "lib", FuchsiaTriple(aArchitecture), "libunwind.a"),
                           Path.Combine(lTargetFolder, "libunwind.a"));
      end;
      CopyFuchsiaSDKFile(Path.Combine(lRuntimeFxFolder, aArchitecture, "rtl.fx"),
                         Path.Combine(lTargetFolder, "rtl.fx"));
      CopyFuchsiaSDKFile(Path.Combine(lIslandRTLFolder, aArchitecture, "Island.fx"),
                         Path.Combine(lTargetFolder, "Island.fx"));
      CopyFuchsiaSDKFile(Path.Combine(lIDKArchitectureFolder, "sysroot", "lib", "libc.so"),
                         Path.Combine(lTargetFolder, "libc.so"));
      if assigned(lClangRuntimeFolder) then
        CopyFuchsiaSDKFile(Path.Combine(lClangRuntimeFolder, aArchitecture, "libclang_rt.builtins.a"),
                           Path.Combine(lTargetFolder, "libclang_rt.builtins.a"))
      else begin
        var lClangFolder := RequireFuchsiaFolder(FuchsiaClangFolder, "Fuchsia Clang folder");
        CopyFuchsiaSDKFile(ResolveFuchsiaBuiltins(lClangFolder, aArchitecture),
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
          RequireFuchsiaFile(Path.Combine(lArchitectureFolder, lRelativePath),
                             $"Fuchsia {lArchitecture} SDK entry '{lRelativePath}'");
        for each lGCFile in ["gc.fx", "libgc.a"] do
          if Path.Combine(lArchitectureFolder, lGCFile).FileExists then
            raise new Exception($"Fuchsia {lArchitecture} SDK must not contain '{lGCFile}'; GC is packaged separately.");
        if Folder.GetFiles(lArchitectureFolder).Where(aFile -> aFile.PathExtension = ".fx").Count <= lRequired.Where(aFile -> aFile.PathExtension = ".fx").Count then
          raise new Exception($"Fuchsia {lArchitecture} SDK contains no imported FIDL .fx files.");
      end;
    end;

    method FuchsiaRelativePath(aRoot: not nullable String; aPath: not nullable String): not nullable String;
    begin
      var lPrefix := aRoot;
      if not lPrefix.EndsWith(Path.DirectorySeparatorChar.ToString) then
        lPrefix := lPrefix+Path.DirectorySeparatorChar;
      if not aPath.StartsWith(lPrefix, false) then
        raise new Exception($"'{aPath}' is not below SDK root '{aRoot}'.");
      result := aPath.Substring(lPrefix.Length).Replace(Path.DirectorySeparatorChar, "/");
    end;

    method ConfigureFuchsiaZipEntry(aEntry: not nullable ZipArchiveEntry; aDirectory: Boolean);
    begin
      aEntry.LastWriteTime := new DateTimeOffset(1980, 1, 1, 0, 0, 0, System.TimeSpan.Zero);
      if aDirectory then
        aEntry.ExternalAttributes := (16877 shl 16) or 16
      else
        aEntry.ExternalAttributes := 33188 shl 16;
    end;

    method AddFuchsiaZipDirectory(aArchive: not nullable ZipArchive;
                                  aSDKRoot: not nullable String;
                                  aFolder: not nullable String;
                                  aArchivePath: not nullable String);
    begin
      var lDirectoryEntry := aArchive.CreateEntry(aArchivePath+"/", CompressionLevel.NoCompression);
      ConfigureFuchsiaZipEntry(lDirectoryEntry, true);

      for each lSubfolder in Folder.GetSubfolders(aFolder).OrderBy(aPath -> aPath) do
        AddFuchsiaZipDirectory(aArchive,
                               aSDKRoot,
                               lSubfolder,
                               aArchivePath+"/"+Path.GetFileName(lSubfolder));

      for each lFile in Folder.GetFiles(aFolder).OrderBy(aPath -> aPath) do begin
        var lRelativePath := FuchsiaRelativePath(aSDKRoot, lFile);
        var lEntry := aArchive.CreateEntry(Path.GetFileName(aSDKRoot)+"/"+lRelativePath, CompressionLevel.Optimal);
        ConfigureFuchsiaZipEntry(lEntry, false);
        using lInput := new System.IO.FileStream(lFile, System.IO.FileMode.Open, System.IO.FileAccess.Read, System.IO.FileShare.Read) do
        using lOutput := lEntry.Open do
          lInput.CopyTo(lOutput);
      end;
    end;

    method FuchsiaSHA256(aPath: not nullable String): not nullable String;
    begin
      using lSHA := SHA256.Create do
      using lStream := new System.IO.FileStream(aPath, System.IO.FileMode.Open, System.IO.FileAccess.Read, System.IO.FileShare.Read) do
        result := BitConverter.ToString(lSHA.ComputeHash(lStream)).Replace("-", "").ToLowerInvariant as not nullable;
    end;

    method StageFuchsiaZipDirectory(aSDKRoot: not nullable String;
                                    aFolder: not nullable String;
                                    aStageFolder: not nullable String;
                                    aEntries: not nullable List<String>);
    begin
      for each lSubfolder in Folder.GetSubfolders(aFolder).OrderBy(aPath -> aPath) do
        StageFuchsiaZipDirectory(aSDKRoot, lSubfolder, aStageFolder, aEntries);

      for each lFile in Folder.GetFiles(aFolder).OrderBy(aPath -> aPath) do begin
        var lArchivePath := Path.GetFileName(aSDKRoot)+"/"+FuchsiaRelativePath(aSDKRoot, lFile);
        var lStagePath := Path.Combine(aStageFolder,
                                      lArchivePath.Replace("/", Path.DirectorySeparatorChar.ToString));
        Folder.Create(Path.GetParentDirectory(lStagePath));
        System.IO.File.Copy(lFile, lStagePath, true);
        System.IO.File.SetLastWriteTime(lStagePath,
                                        new System.DateTime(1980, 1, 1, 0, 0, 0, System.DateTimeKind.Local));
        aEntries.Add(lArchivePath);
      end;
    end;

    method CreateDeterministicFuchsiaZipWithSystemTools(aFolder: not nullable String;
                                                        aZipPath: not nullable String): not nullable String;
    begin
      var lZip := RequireFuchsiaFile("/usr/bin/zip", "macOS ZIP tool");
      var lUnzip := RequireFuchsiaFile("/usr/bin/unzip", "macOS ZIP validation tool");
      var lTemporaryPath := aZipPath+".tmp.zip";
      var lLegacyTemporaryPath := aZipPath+".tmp";
      var lStageFolder := aZipPath+".stage";
      if lTemporaryPath.FileExists then
        File.Delete(lTemporaryPath);
      if lLegacyTemporaryPath.FileExists then
        File.Delete(lLegacyTemporaryPath);
      if lStageFolder.FolderExists then
        System.IO.Directory.Delete(lStageFolder, true);
      Folder.Create(lStageFolder);

      var lEntries := new List<String>;
      StageFuchsiaZipDirectory(aFolder, aFolder, lStageFolder, lEntries);
      if lEntries.Count = 0 then
        raise new Exception($"Cannot create an empty Fuchsia ZIP from '{aFolder}'.");

      var lChmodArguments := new List<String>;
      lChmodArguments.Add("0644");
      for each lEntry in lEntries do
        lChmodArguments.Add(Path.Combine(lStageFolder,
                                         lEntry.Replace("/", Path.DirectorySeparatorChar.ToString)));
      RunFuchsiaTool("/bin/chmod", lChmodArguments, lStageFolder, false);

      var lZipArguments := new List<String>;
      lZipArguments.Add("-X");
      lZipArguments.Add("-q");
      lZipArguments.Add(lTemporaryPath);
      lZipArguments.Add(lEntries);
      Log($"Creating deterministic Fuchsia ZIP with {lEntries.Count} files using {lZip}.");
      RunFuchsiaTool(lZip, lZipArguments, lStageFolder, false);
      var lValidationArguments := new List<String>;
      lValidationArguments.Add("-tqq");
      lValidationArguments.Add(lTemporaryPath);
      RunFuchsiaTool(lUnzip, lValidationArguments, lStageFolder);

      System.IO.Directory.Delete(lStageFolder, true);
      if aZipPath.FileExists then
        File.Delete(aZipPath);
      System.IO.File.Move(lTemporaryPath, aZipPath);
      Log($"Created {aZipPath}.");
      Log($"SHA-256: {FuchsiaSHA256(aZipPath)}");
      result := aZipPath;
    end;

    method CreateDeterministicFuchsiaZip(aFolder: not nullable String;
                                         aZipPath: not nullable String): not nullable String;
    begin
      Folder.Create(Path.GetParentDirectory(aZipPath));
      if Environment.OS = OperatingSystem.macOS then
        exit CreateDeterministicFuchsiaZipWithSystemTools(aFolder, aZipPath);

      var lTemporaryPath := aZipPath+".tmp";
      if lTemporaryPath.FileExists then
        File.Delete(lTemporaryPath);

      using lStream := new System.IO.FileStream(lTemporaryPath, System.IO.FileMode.CreateNew, System.IO.FileAccess.Write, System.IO.FileShare.None) do
      using lArchive := new ZipArchive(lStream, ZipArchiveMode.Create, false) do
        AddFuchsiaZipDirectory(lArchive,
                               aFolder,
                               aFolder,
                               Path.GetFileName(aFolder));

      using lValidationStream := new System.IO.FileStream(lTemporaryPath, System.IO.FileMode.Open, System.IO.FileAccess.Read, System.IO.FileShare.Read) do
      using lValidationArchive := new ZipArchive(lValidationStream, ZipArchiveMode.Read, false) do begin
        if lValidationArchive.Entries.Count = 0 then
          raise new Exception($"Generated Fuchsia ZIP '{lTemporaryPath}' is empty.");
        for each lEntry in lValidationArchive.Entries do
          if not lEntry.FullName.EndsWith("/") then begin
            using lInput := lEntry.Open do begin
              var lBuffer := new Byte[65536];
              while lInput.Read(lBuffer, 0, lBuffer.Length) > 0 do;
            end;
          end;
      end;

      if aZipPath.FileExists then
        File.Delete(aZipPath);
      System.IO.File.Move(lTemporaryPath, aZipPath);
      Log($"Created {aZipPath}.");
      Log($"SHA-256: {FuchsiaSHA256(aZipPath)}");
      result := aZipPath;
    end;

    method CreateFuchsiaSDKZip(aSDKFolder: not nullable String): not nullable String;
    begin
      var lPublicFolder := Path.Combine(FuchsiaOutputFolder, "__Public");
      result := CreateDeterministicFuchsiaZip(aSDKFolder,
                                              Path.Combine(lPublicFolder, Path.GetFileName(aSDKFolder)+".zip"));
    end;

  public

    property AssembleFuchsiaRuntime := false;
    property CreateFuchsiaGCPackage := false;
    property FuchsiaRuntimeFxFolder: nullable String;
    property FuchsiaIslandRTLFolder: nullable String;
    property FuchsiaGCX64Library: nullable String;
    property FuchsiaGCArm64Library: nullable String;
    property FuchsiaClangFolder: nullable String;
    property FuchsiaClangRuntimeFolder: nullable String;
    property FuchsiaGCOutputFolder: nullable String;

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

    method AssembleFuchsiaGC(aSDKID: not nullable String): nullable String;
    begin
      var lRuntimeFxFolder := RequireFuchsiaFolder(FuchsiaRuntimeFxFolder, "Fuchsia runtime .fx folder");
      if length(FuchsiaGCOutputFolder) = 0 then
        FuchsiaGCOutputFolder := Path.Combine(Path.GetParentDirectory(FuchsiaOutputFolder), "GC", "Fuchsia")
      else
        FuchsiaGCOutputFolder := Path.GetFullPath(FuchsiaGCOutputFolder);
      Folder.Create(FuchsiaGCOutputFolder);

      var lSDKFolder := Path.Combine(FuchsiaGCOutputFolder, "Fuchsia "+aSDKID);
      for each lArchitecture in ["x64", "arm64"] do begin
        var lArchitectureFolder := Path.Combine(lSDKFolder, lArchitecture);
        Folder.Create(lArchitectureFolder);
        CopyFuchsiaSDKFile(Path.Combine(lRuntimeFxFolder, lArchitecture, "gc.fx"),
                           Path.Combine(lArchitectureFolder, "gc.fx"));
        CopyFuchsiaSDKFile(ResolveFuchsiaGC(lArchitecture),
                           Path.Combine(lArchitectureFolder, "libgc.a"));
        RequireFuchsiaFile(Path.Combine(lArchitectureFolder, "gc.fx"),
                           $"Fuchsia {lArchitecture} GC metadata");
        RequireFuchsiaFile(Path.Combine(lArchitectureFolder, "libgc.a"),
                           $"Fuchsia {lArchitecture} GC archive");
        if Folder.GetFiles(lArchitectureFolder).Count ≠ 2 then
          raise new Exception($"Fuchsia {lArchitecture} GC package must contain exactly gc.fx and libgc.a.");
      end;

      Log($"Assembled separate Fuchsia GC package for {aSDKID}.");
      if CreateZips then
        result := CreateDeterministicFuchsiaZip(FuchsiaGCOutputFolder,
                                                Path.Combine(Path.GetParentDirectory(FuchsiaGCOutputFolder), "Fuchsia.zip"));
    end;

  end;

end.
