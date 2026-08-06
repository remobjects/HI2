namespace RemObjects.Elements.HI2;

uses
  RemObjects.Elements.RTL;

type
  Importer = public partial class
  private

    method IslandDarwinLibraryPlatforms: not nullable List<String>;
    begin
      result := new List<String>(
        "Mac Catalyst",
        "macOS",
        "iOS",
        "iOS Simulator",
        "tvOS",
        "tvOS Simulator",
        "visionOS",
        "visionOS Simulator"
      );
    end;

    method PackageIslandDarwinLibrary(aSourceIslandFolder: not nullable String;
                                      aLibrariesOutputFolder: not nullable String;
                                      aPackageName: not nullable String;
                                      aFileName: not nullable String;
                                      aArchiveName: not nullable String);
    begin
      var lPackageIslandFolder := Path.Combine(aLibrariesOutputFolder, aPackageName, "Island");
      var lStageIslandFolder := Path.Combine(aLibrariesOutputFolder,
                                             "Import Configurations",
                                             "Darwin Libraries",
                                             aPackageName,
                                             "Island");
      if lStageIslandFolder.FolderExists then
        System.IO.Directory.Delete(lStageIslandFolder, true);
      Folder.Create(lStageIslandFolder);

      var lPlatforms := IslandDarwinLibraryPlatforms;
      for each lPlatform in lPlatforms do begin
        var lExistingPlatformFolder := Path.Combine(lPackageIslandFolder, lPlatform);
        if lExistingPlatformFolder.FolderExists then
          System.IO.Directory.Delete(lExistingPlatformFolder, true);
      end;

      var lFileCount := 0;
      for each lPlatform in lPlatforms do begin
        var lSourcePlatformFolder := Path.Combine(aSourceIslandFolder, lPlatform);
        if not lSourcePlatformFolder.FolderExists then
          continue;
        for each lArchitectureFolder in Folder.GetSubfolders(lSourcePlatformFolder).OrderBy(aPath -> aPath) do begin
          var lSource := Path.Combine(lArchitectureFolder, aFileName);
          if not lSource.FileExists then
            continue;
          var lArchitecture := Path.GetFileName(lArchitectureFolder);
          var lRelativePath := Path.Combine(lPlatform, lArchitecture, aFileName);
          CopyIslandSDKFile(lSource, Path.Combine(lPackageIslandFolder, lRelativePath));
          CopyIslandSDKFile(lSource, Path.Combine(lStageIslandFolder, lRelativePath));
          lFileCount := lFileCount+1;
        end;
      end;

      if lFileCount = 0 then
        raise new Exception($"Darwin library input '{aSourceIslandFolder}' contains no '{aFileName}' declarations for supported Island platforms.");

      Log($"Packaged {lFileCount} Darwin {aPackageName} declaration files.");
      if CreateZips then
        CreateDeterministicIslandSDKZip(lStageIslandFolder,
                                        Path.Combine(aLibrariesOutputFolder, "__Public", aArchiveName));
    end;

  public

    method PackageIslandDarwinLibraries(aSourceIslandFolder: not nullable String;
                                        aLibrariesOutputFolder: not nullable String);
    begin
      var lSource := RequireIslandSDKFolder(aSourceIslandFolder, "Island Darwin library import output folder");
      var lOutput := Path.GetFullPath(aLibrariesOutputFolder);
      Folder.Create(lOutput);

      PackageIslandDarwinLibrary(lSource, lOutput, "SQLite", "libsqlite3.fx", "Island-Darwin-sqlite.zip");
      PackageIslandDarwinLibrary(lSource, lOutput, "LibXML2", "libxml2.fx", "Island-Darwin-libxml2.zip");
      PackageIslandDarwinLibrary(lSource, lOutput, "ZLib", "libz.fx", "Island-Darwin-zlib.zip");
    end;

  end;

end.
