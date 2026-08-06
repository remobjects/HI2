namespace RemObjects.Elements.HI2;

uses
  RemObjects.Elements.RTL,
  System.Text.RegularExpressions;

type
  Importer = public partial class
  private

    method ResolveSQLiteSourceFolder: not nullable String;
    begin
      var lRoot := RequireIslandSDKFolder(SQLiteSourceFolder, "SQLite amalgamation folder");
      if Path.Combine(lRoot, "sqlite3.c").FileExists and Path.Combine(lRoot, "sqlite3.h").FileExists then
        exit lRoot;

      var lCandidates := Folder.GetSubfolders(lRoot)
                              .Where(aFolder -> Path.Combine(aFolder, "sqlite3.c").FileExists and Path.Combine(aFolder, "sqlite3.h").FileExists)
                              .ToList;
      if lCandidates.Count <> 1 then
        raise new Exception($"SQLite amalgamation files sqlite3.c and sqlite3.h were not found directly below '{lRoot}' or one unambiguous child folder.");
      result := lCandidates[0] as not nullable;
    end;

    method SQLiteVersion(aSQLiteFolder: not nullable String): not nullable String;
    begin
      var lHeader := RequireIslandSDKFile(Path.Combine(aSQLiteFolder, "sqlite3.h"), "SQLite amalgamation header");
      var lMatch := Regex.Match(File.ReadText(lHeader), '#define\s+SQLITE_VERSION\s+"([^"]+)"');
      if not lMatch.Success then
        raise new Exception($"SQLITE_VERSION was not found in '{lHeader}'.");
      result := lMatch.Groups[1].Value as not nullable;
    end;

    method ResolveSQLiteClangCL: not nullable String;
    begin
      var lPath := SQLiteClang;
      if length(lPath) > 0 then begin
        lPath := Path.GetFullPath(lPath as not nullable);
        if lPath.FolderExists then
          lPath := Path.Combine(lPath, "clang-cl");
        exit RequireIslandSDKFile(lPath, "Windows SQLite clang-cl executable");
      end;

      for each lCandidate in ["/opt/homebrew/opt/llvm/bin/clang-cl", "/usr/local/opt/llvm/bin/clang-cl"] do
        if lCandidate.FileExists then
          exit lCandidate as not nullable;
      raise new Exception("Windows SQLite clang-cl was not found. Pass --clang=<absolute-path-or-LLVM-bin-folder>.");
    end;

    method ResolveSQLiteLLVMAr(aClangCL: not nullable String): not nullable String;
    begin
      var lPath := SQLiteLLVMAr;
      if length(lPath) > 0 then begin
        lPath := Path.GetFullPath(lPath as not nullable);
        if lPath.FolderExists then
          lPath := Path.Combine(lPath, "llvm-ar");
        exit RequireIslandSDKFile(lPath, "Windows SQLite llvm-ar executable");
      end;

      var lSibling := Path.Combine(Path.GetParentDirectory(aClangCL), "llvm-ar");
      if lSibling.FileExists then
        exit lSibling as not nullable;
      for each lCandidate in ["/opt/homebrew/opt/llvm/bin/llvm-ar", "/usr/local/opt/llvm/bin/llvm-ar"] do
        if lCandidate.FileExists then
          exit lCandidate as not nullable;
      raise new Exception("Windows SQLite llvm-ar was not found beside clang-cl. Pass --llvm-ar=<absolute-path-or-LLVM-bin-folder>.");
    end;

    method ValidateWindowsCOFFObject(aPath: not nullable String;
                                     aArchitecture: not nullable WindowsSDKArchitecture);
    begin
      RequireIslandSDKFile(aPath, $"Windows {aArchitecture.Name} SQLite COFF object");
      using lStream := new System.IO.FileStream(aPath, System.IO.FileMode.Open, System.IO.FileAccess.Read, System.IO.FileShare.Read) do begin
        var lLow := lStream.ReadByte;
        var lHigh := lStream.ReadByte;
        if (lLow < 0) or (lHigh < 0) then
          raise new Exception($"Windows {aArchitecture.Name} SQLite COFF object '{aPath}' is truncated.");
        var lMachine := UInt16(lLow or (lHigh shl 8));
        if lMachine <> aArchitecture.COFFMachine then
          raise new Exception($"Windows {aArchitecture.Name} SQLite COFF object '{aPath}' has machine 0x{lMachine.ToString('x4')}, expected 0x{aArchitecture.COFFMachine.ToString('x4')}.");
      end;
    end;

    method WindowsSQLiteShimSource: not nullable String;
    begin
      result := String.Join(Environment.LineBreak, new List<String>(
        "typedef __SIZE_TYPE__ sqlite3_island_size_t;",
        "",
        "void *sqlite3_island_memchr(const void *aBuffer, int aValue, sqlite3_island_size_t aLength)",
        "{",
        "  const unsigned char *lBuffer = (const unsigned char *)aBuffer;",
        "  unsigned char lValue = (unsigned char)aValue;",
        "  for (sqlite3_island_size_t i = 0; i < aLength; ++i)",
        "    if (lBuffer[i] == lValue)",
        "      return (void *)(lBuffer+i);",
        "  return (void *)0;",
        "}",
        "",
        "sqlite3_island_size_t sqlite3_island_strspn(const char *aString, const char *aAccepted)",
        "{",
        "  sqlite3_island_size_t lLength = 0;",
        "  for (; aString[lLength] != 0; ++lLength) {",
        "    const char *lCandidate = aAccepted;",
        "    while ((*lCandidate != 0) && (*lCandidate != aString[lLength]))",
        "      ++lCandidate;",
        "    if (*lCandidate == 0)",
        "      break;",
        "  }",
        "  return lLength;",
        "}",
        "",
        "sqlite3_island_size_t sqlite3_island_strcspn(const char *aString, const char *aRejected)",
        "{",
        "  sqlite3_island_size_t lLength = 0;",
        "  for (; aString[lLength] != 0; ++lLength) {",
        "    const char *lCandidate = aRejected;",
        "    while ((*lCandidate != 0) && (*lCandidate != aString[lLength]))",
        "      ++lCandidate;",
        "    if (*lCandidate != 0)",
        "      break;",
        "  }",
        "  return lLength;",
        "}",
        ""
      ));
    end;

    method BuildWindowsSQLiteLibrary(aArchitecture: not nullable WindowsSDKArchitecture;
                                     aSQLiteFolder: not nullable String;
                                     aSQLiteVersion: not nullable String;
                                     aClangCL: not nullable String;
                                     aLLVMAr: not nullable String;
                                     aIncludeFolders: not nullable ImmutableList<String>;
                                     aIntermediateFolder: not nullable String;
                                     aOutputFolder: not nullable String);
    begin
      var lBuildFolder := Path.Combine(aIntermediateFolder, "Windows", aSQLiteVersion, aArchitecture.Name);
      Folder.Create(lBuildFolder);
      var lObject := Path.Combine(lBuildFolder, "sqlite3.obj");
      var lShimSource := Path.Combine(lBuildFolder, "sqlite3_island_shims.c");
      var lShimObject := Path.Combine(lBuildFolder, "sqlite3_island_shims.obj");
      var lLibrary := Path.Combine(aOutputFolder, "sqlite3.lib");
      if lObject.FileExists then
        File.Delete(lObject);
      if lShimObject.FileExists then
        File.Delete(lShimObject);
      if lLibrary.FileExists then
        File.Delete(lLibrary);
      File.WriteText(lShimSource, WindowsSQLiteShimSource);

      var lCompilerArguments := new List<String>(
        $"--target={aArchitecture.TargetString}",
        "/nologo",
        "/c",
        "/Fo"+lObject,
        "/O2",
        "/Brepro",
        "/Zl",
        "/DNDEBUG",
        "/DSQLITE_THREADSAFE=1",
        "/DSQLITE_OMIT_SEH",
        "/D_WIN32_WINNT=0x0A00",
        "/Dmemchr=sqlite3_island_memchr",
        "/Dstrspn=sqlite3_island_strspn",
        "/Dstrcspn=sqlite3_island_strcspn",
        "-ffile-reproducible",
        $"/clang:-ffile-prefix-map={aSQLiteFolder}=.",
        "/clang:-fno-builtin-memchr",
        "-fms-compatibility-version=19.44"
      );
      for each lIncludeFolder in aIncludeFolders do
        lCompilerArguments.Add("-imsvc", lIncludeFolder);
      lCompilerArguments.Add("--", Path.Combine(aSQLiteFolder, "sqlite3.c"));
      Log($"Building SQLite {aSQLiteVersion} for Windows {aArchitecture.Name}.");
      RunIslandSDKTool(aClangCL, lCompilerArguments, aSQLiteFolder);
      ValidateWindowsCOFFObject(lObject, aArchitecture);

      var lShimArguments := new List<String>(
        $"--target={aArchitecture.TargetString}",
        "/nologo",
        "/c",
        "/Fo"+lShimObject,
        "/O2",
        "/Brepro",
        "/Zl",
        "/GS-",
        "-ffile-reproducible",
        $"/clang:-ffile-prefix-map={lBuildFolder}=.",
        "/clang:-fno-builtin"
      );
      lShimArguments.Add("--", lShimSource);
      RunIslandSDKTool(aClangCL, lShimArguments, lBuildFolder);
      ValidateWindowsCOFFObject(lShimObject, aArchitecture);

      RunIslandSDKTool(aLLVMAr, new List<String>("rcsD", lLibrary, lObject, lShimObject), lBuildFolder);
      RequireIslandSDKFile(lLibrary, $"Windows {aArchitecture.Name} SQLite static library");
    end;

  public

    property SQLiteSourceFolder: nullable String;
    property SQLiteOutputFolder: nullable String;
    property SQLiteWindowsDeclarationsFolder: nullable String;
    property SQLiteIntermediateFolder: nullable String;
    property SQLiteClang: nullable String;
    property SQLiteLLVMAr: nullable String;

    method BuildSQLitePackage;
    begin
      SQLiteOutputFolder := Path.GetFullPath(SQLiteOutputFolder);
      SQLiteIntermediateFolder := if length(SQLiteIntermediateFolder) > 0 then Path.GetFullPath(SQLiteIntermediateFolder) else Path.Combine(SQLiteOutputFolder, "Import Configurations", "SQLite");
      Folder.Create(SQLiteOutputFolder);
      Folder.Create(SQLiteIntermediateFolder);

      var lSQLiteFolder := ResolveSQLiteSourceFolder;
      var lSQLiteVersion := SQLiteVersion(lSQLiteFolder);
      var lClangCL := ResolveSQLiteClangCL;
      var lLLVMAr := ResolveSQLiteLLVMAr(lClangCL);
      var lLayout := ResolveWindowsSDKLayout;
      var lMSVCIncludeFolder := ResolveWindowsMSVCIncludeFolder;
      var lIncludeFolders := WindowsIncludeFolders(lLayout, lMSVCIncludeFolder, nil);
      var lArchitectures := ResolveWindowsArchitectures;
      var lDeclarationsFolder := RequireIslandSDKFolder(SQLiteWindowsDeclarationsFolder, "Windows SQLite declaration .fx folder");
      var lDeclarationStage := Path.Combine(SQLiteIntermediateFolder, "Declarations", "Windows");
      if lDeclarationStage.FolderExists then
        System.IO.Directory.Delete(lDeclarationStage, true);
      Folder.Create(lDeclarationStage);
      for each lArchitecture in lArchitectures do begin
        var lStagedDeclaration := Path.Combine(lDeclarationStage, lArchitecture.Name, "sqlite3.fx");
        CopyIslandSDKFile(Path.Combine(lDeclarationsFolder, lArchitecture.Name, "sqlite3.fx"), lStagedDeclaration);
        ValidateWindowsFx(lStagedDeclaration, "sqlite3", lArchitecture);
      end;

      var lPackageFolder := Path.Combine(SQLiteOutputFolder, "SQLite");
      var lIslandFolder := Path.Combine(lPackageFolder, "Island");
      var lWindowsFolder := Path.Combine(lIslandFolder, "Windows");
      if lWindowsFolder.FolderExists then
        System.IO.Directory.Delete(lWindowsFolder, true);
      Folder.Create(lWindowsFolder);

      Log($"Building standalone SQLite {lSQLiteVersion} package for Windows {String.Join(", ", lArchitectures.Select(aArchitecture -> aArchitecture.Name).ToList)}.");
      Log($"SQLite source SHA-256: {IslandSDKSHA256(Path.Combine(lSQLiteFolder, "sqlite3.c"))}");
      for each lArchitecture in lArchitectures do begin
        var lArchitectureFolder := Path.Combine(lWindowsFolder, lArchitecture.Name);
        Folder.Create(lArchitectureFolder);
        CopyIslandSDKFile(Path.Combine(lDeclarationStage, lArchitecture.Name, "sqlite3.fx"),
                          Path.Combine(lArchitectureFolder, "sqlite3.fx"));
        ValidateWindowsFx(Path.Combine(lArchitectureFolder, "sqlite3.fx"), "sqlite3", lArchitecture);
        BuildWindowsSQLiteLibrary(lArchitecture,
                                  lSQLiteFolder,
                                  lSQLiteVersion,
                                  lClangCL,
                                  lLLVMAr,
                                  lIncludeFolders,
                                  SQLiteIntermediateFolder as not nullable,
                                  lArchitectureFolder);
      end;

      if CreateZips then
        CreateDeterministicIslandSDKZip(lIslandFolder,
                                        Path.Combine(SQLiteOutputFolder, "__Public", "SQLite.zip"));
    end;

  end;

end.
