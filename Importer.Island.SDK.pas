namespace RemObjects.Elements.HI2;

uses
  RemObjects.Elements.RTL,
  System.IO.Compression,
  System.Security.Cryptography;

type
  Importer = public partial class
  private

    method RequireIslandSDKFile(aPath: nullable String; aDescription: not nullable String): not nullable String;
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

    method RequireIslandSDKFolder(aPath: nullable String; aDescription: not nullable String): not nullable String;
    begin
      if length(aPath) = 0 then
        raise new Exception($"{aDescription} was not specified.");
      var lPath := Path.GetFullPath(aPath as not nullable);
      if not lPath.FolderExists then
        raise new Exception($"{aDescription} was not found at '{lPath}'.");
      result := lPath as not nullable;
    end;

    method CopyIslandSDKFile(aSource: not nullable String; aDestination: not nullable String);
    begin
      RequireIslandSDKFile(aSource, "Island SDK input");
      Folder.Create(Path.GetParentDirectory(aDestination));
      if aDestination.FileExists then
        File.Delete(aDestination);
      System.IO.File.Copy(aSource, aDestination, false);
    end;

    method CopyIslandSDKFolder(aSource: not nullable String; aDestination: not nullable String);
    begin
      var lSource := RequireIslandSDKFolder(aSource, "Island SDK input folder");
      Folder.Create(aDestination);
      for each lSubfolder in Folder.GetSubfolders(lSource).OrderBy(aPath -> aPath) do
        CopyIslandSDKFolder(lSubfolder, Path.Combine(aDestination, Path.GetFileName(lSubfolder)));
      for each lFile in Folder.GetFiles(lSource).OrderBy(aPath -> aPath) do
        CopyIslandSDKFile(lFile, Path.Combine(aDestination, Path.GetFileName(lFile)));
    end;

    method RunIslandSDKTool(aExecutable: not nullable String;
                            aArguments: not nullable ImmutableList<String>;
                            aWorkingDirectory: not nullable String;
                            aLogCommand: Boolean := true);
    begin
      RequireIslandSDKFile(aExecutable, "Island SDK tool");
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
        raise new HIException($"Island SDK tool '{aExecutable}' failed with exit code {lExitCode}.");
      end;
    end;

    method IslandSDKRelativePath(aRoot: not nullable String; aPath: not nullable String): not nullable String;
    begin
      var lPrefix := aRoot;
      if not lPrefix.EndsWith(Path.DirectorySeparatorChar.ToString) then
        lPrefix := lPrefix+Path.DirectorySeparatorChar;
      if not aPath.StartsWith(lPrefix, false) then
        raise new Exception($"'{aPath}' is not below SDK root '{aRoot}'.");
      result := aPath.Substring(lPrefix.Length).Replace(Path.DirectorySeparatorChar, "/");
    end;

    method ConfigureIslandSDKZipEntry(aEntry: not nullable ZipArchiveEntry; aDirectory: Boolean);
    begin
      aEntry.LastWriteTime := new DateTimeOffset(1980, 1, 1, 0, 0, 0, System.TimeSpan.Zero);
      if aDirectory then
        aEntry.ExternalAttributes := (16877 shl 16) or 16
      else
        aEntry.ExternalAttributes := 33188 shl 16;
    end;

    method AddIslandSDKZipDirectory(aArchive: not nullable ZipArchive;
                                    aSDKRoot: not nullable String;
                                    aFolder: not nullable String;
                                    aArchivePath: not nullable String);
    begin
      var lDirectoryEntry := aArchive.CreateEntry(aArchivePath+"/", CompressionLevel.NoCompression);
      ConfigureIslandSDKZipEntry(lDirectoryEntry, true);

      for each lSubfolder in Folder.GetSubfolders(aFolder).OrderBy(aPath -> aPath) do
        AddIslandSDKZipDirectory(aArchive,
                                 aSDKRoot,
                                 lSubfolder,
                                 aArchivePath+"/"+Path.GetFileName(lSubfolder));

      for each lFile in Folder.GetFiles(aFolder).OrderBy(aPath -> aPath) do begin
        var lRelativePath := IslandSDKRelativePath(aSDKRoot, lFile);
        var lEntry := aArchive.CreateEntry(Path.GetFileName(aSDKRoot)+"/"+lRelativePath, CompressionLevel.Optimal);
        ConfigureIslandSDKZipEntry(lEntry, false);
        using lInput := new System.IO.FileStream(lFile, System.IO.FileMode.Open, System.IO.FileAccess.Read, System.IO.FileShare.Read) do
        using lOutput := lEntry.Open do
          lInput.CopyTo(lOutput);
      end;
    end;

    method IslandSDKSHA256(aPath: not nullable String): not nullable String;
    begin
      using lSHA := SHA256.Create do
      using lStream := new System.IO.FileStream(aPath, System.IO.FileMode.Open, System.IO.FileAccess.Read, System.IO.FileShare.Read) do
        result := BitConverter.ToString(lSHA.ComputeHash(lStream)).Replace("-", "").ToLowerInvariant as not nullable;
    end;

    method StageIslandSDKZipDirectory(aSDKRoot: not nullable String;
                                      aFolder: not nullable String;
                                      aStageFolder: not nullable String;
                                      aEntries: not nullable List<String>);
    begin
      for each lSubfolder in Folder.GetSubfolders(aFolder).OrderBy(aPath -> aPath) do
        StageIslandSDKZipDirectory(aSDKRoot, lSubfolder, aStageFolder, aEntries);

      for each lFile in Folder.GetFiles(aFolder).OrderBy(aPath -> aPath) do begin
        var lArchivePath := Path.GetFileName(aSDKRoot)+"/"+IslandSDKRelativePath(aSDKRoot, lFile);
        var lStagePath := Path.Combine(aStageFolder,
                                      lArchivePath.Replace("/", Path.DirectorySeparatorChar.ToString));
        Folder.Create(Path.GetParentDirectory(lStagePath));
        System.IO.File.Copy(lFile, lStagePath, true);
        System.IO.File.SetLastWriteTime(lStagePath,
                                        new System.DateTime(1980, 1, 1, 0, 0, 0, System.DateTimeKind.Local));
        aEntries.Add(lArchivePath);
      end;
    end;

    method CreateDeterministicIslandSDKZipWithSystemTools(aFolder: not nullable String;
                                                          aZipPath: not nullable String): not nullable String;
    begin
      var lZip := RequireIslandSDKFile("/usr/bin/zip", "macOS ZIP tool");
      var lUnzip := RequireIslandSDKFile("/usr/bin/unzip", "macOS ZIP validation tool");
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
      StageIslandSDKZipDirectory(aFolder, aFolder, lStageFolder, lEntries);
      if lEntries.Count = 0 then
        raise new Exception($"Cannot create an empty Island SDK ZIP from '{aFolder}'.");

      var lChmodArguments := new List<String>;
      lChmodArguments.Add("0644");
      for each lEntry in lEntries do
        lChmodArguments.Add(Path.Combine(lStageFolder,
                                         lEntry.Replace("/", Path.DirectorySeparatorChar.ToString)));
      RunIslandSDKTool("/bin/chmod", lChmodArguments, lStageFolder, false);

      var lZipArguments := new List<String>;
      lZipArguments.Add("-X");
      lZipArguments.Add("-q");
      lZipArguments.Add(lTemporaryPath);
      lZipArguments.Add(lEntries);
      Log($"Creating deterministic Island SDK ZIP with {lEntries.Count} files using {lZip}.");
      RunIslandSDKTool(lZip, lZipArguments, lStageFolder, false);
      var lValidationArguments := new List<String>;
      lValidationArguments.Add("-tqq");
      lValidationArguments.Add(lTemporaryPath);
      RunIslandSDKTool(lUnzip, lValidationArguments, lStageFolder);

      System.IO.Directory.Delete(lStageFolder, true);
      if aZipPath.FileExists then
        File.Delete(aZipPath);
      System.IO.File.Move(lTemporaryPath, aZipPath);
      Log($"Created {aZipPath}.");
      Log($"SHA-256: {IslandSDKSHA256(aZipPath)}");
      result := aZipPath;
    end;

    method CreateDeterministicIslandSDKZip(aFolder: not nullable String;
                                           aZipPath: not nullable String): not nullable String;
    begin
      Folder.Create(Path.GetParentDirectory(aZipPath));
      if Environment.OS = OperatingSystem.macOS then
        exit CreateDeterministicIslandSDKZipWithSystemTools(aFolder, aZipPath);

      var lTemporaryPath := aZipPath+".tmp";
      if lTemporaryPath.FileExists then
        File.Delete(lTemporaryPath);

      using lStream := new System.IO.FileStream(lTemporaryPath, System.IO.FileMode.CreateNew, System.IO.FileAccess.Write, System.IO.FileShare.None) do
      using lArchive := new ZipArchive(lStream, ZipArchiveMode.Create, false) do
        AddIslandSDKZipDirectory(lArchive,
                                 aFolder,
                                 aFolder,
                                 Path.GetFileName(aFolder));

      using lValidationStream := new System.IO.FileStream(lTemporaryPath, System.IO.FileMode.Open, System.IO.FileAccess.Read, System.IO.FileShare.Read) do
      using lValidationArchive := new ZipArchive(lValidationStream, ZipArchiveMode.Read, false) do begin
        if lValidationArchive.Entries.Count = 0 then
          raise new Exception($"Generated Island SDK ZIP '{lTemporaryPath}' is empty.");
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
      Log($"SHA-256: {IslandSDKSHA256(aZipPath)}");
      result := aZipPath;
    end;

  end;

end.
