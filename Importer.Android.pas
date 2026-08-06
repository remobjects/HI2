namespace RemObjects.Elements.HI2;

uses
  RemObjects.Elements.Basics,
  RemObjects.Elements.Fx,
  RemObjects.Elements.RTL;

type
  AndroidSDKArchitecture = private class
  public
    constructor(aName: not nullable String;
                aLibraryTriple: not nullable String;
                aTargetString: not nullable String;
                aClangTarget: not nullable String;
                aBuiltinsName: not nullable String;
                aAtomicFolder: not nullable String;
                aTarget: FxCpuTarget);
    begin
      Name := aName;
      LibraryTriple := aLibraryTriple;
      TargetString := aTargetString;
      ClangTarget := aClangTarget;
      BuiltinsName := aBuiltinsName;
      AtomicFolder := aAtomicFolder;
      Target := aTarget;
    end;

    property Name: not nullable String; readonly;
    property LibraryTriple: not nullable String; readonly;
    property TargetString: not nullable String; readonly;
    property ClangTarget: not nullable String; readonly;
    property BuiltinsName: not nullable String; readonly;
    property AtomicFolder: not nullable String; readonly;
    property Target: FxCpuTarget; readonly;
  end;

  Importer = public partial class
  private

    method AndroidArchitecture(aName: not nullable String): not nullable AndroidSDKArchitecture;
    begin
      case aName.ToLowerInvariant of
        "arm64-v8a":
          result := new AndroidSDKArchitecture("arm64-v8a", "aarch64-linux-android", "aarch64-linux-android", "aarch64-linux-android", "aarch64", "aarch64", FxCpuTarget.arm64);
        "armeabi-v7a":
          result := new AndroidSDKArchitecture("armeabi-v7a", "arm-linux-androideabi", "armv7a-linux-androideabi", "armv7a-linux-androideabi", "arm", "arm", FxCpuTarget.armv7);
        "x86":
          result := new AndroidSDKArchitecture("x86", "i686-linux-android", "i686-linux-android", "i686-linux-android", "i686", "i386", FxCpuTarget.i386);
        "x86_64":
          result := new AndroidSDKArchitecture("x86_64", "x86_64-linux-android", "x86_64-linux-android", "x86_64-linux-android", "x86_64", "x86_64", FxCpuTarget.x86_64);
        else
          raise new Exception($"Unsupported Android SDK architecture '{aName}'. Supported names are arm64-v8a, armeabi-v7a, x86, and x86_64.");
      end;
    end;

    method AndroidNDKIsComplete(aFolder: not nullable String): Boolean;
    begin
      result := Path.Combine(aFolder, "source.properties").FileExists and
                Path.Combine(aFolder, "meta", "platforms.json").FileExists and
                Path.Combine(aFolder, "toolchains", "llvm", "prebuilt", "linux-x86_64", "sysroot", "usr", "include", "stdio.h").FileExists;
    end;

    method FindAndroidNDK(aRoot: not nullable String): nullable String;
    begin
      if AndroidNDKIsComplete(aRoot) then
        exit aRoot;
      for each lFolder in Folder.GetSubfolders(aRoot).OrderBy(aPath -> aPath) do
        if AndroidNDKIsComplete(lFolder) then
          exit lFolder;
    end;

    method PrepareAndroidNDK(out aMountedRoot: nullable String): not nullable String;
    begin
      aMountedRoot := nil;
      if length(AndroidNDKFolder) > 0 then
        exit RequireIslandSDKFolder(AndroidNDKFolder, "Android NDK folder");

      AndroidNDKArchive := RequireIslandSDKFile(AndroidNDKArchive, "Android NDK archive");
      var lExtractedRoot: nullable String;
      case Environment.OS of
        OperatingSystem.macOS: begin
            var lImageBase := Path.Combine(AndroidIntermediateFolder, "Android NDK "+AndroidNDKRelease);
            var lImagePath := lImageBase+".sparseimage";
            if lImagePath.FileExists and not AndroidReuseNDK then
              File.Delete(lImagePath);
            if not lImagePath.FileExists then begin
              Log($"Creating case-sensitive Android NDK image at {lImagePath}.");
              RunIslandSDKTool("/usr/bin/hdiutil",
                               new List<String>("create", "-size", "8g", "-type", "SPARSE", "-fs", "Case-sensitive APFS", "-volname", "Elements Android NDK "+AndroidNDKRelease, lImageBase),
                               AndroidIntermediateFolder);
            end;

            var lMountPoint := Path.Combine("/private/tmp", "ElementsAndroidNDK-"+System.Guid.NewGuid.ToString("N"));
            Folder.Create(lMountPoint);
            RunIslandSDKTool("/usr/bin/hdiutil",
                             new List<String>("attach", lImagePath, "-mountpoint", lMountPoint, "-nobrowse", "-noautoopen"),
                             AndroidIntermediateFolder);
            aMountedRoot := lMountPoint;
            var lExisting := FindAndroidNDK(lMountPoint);
            if AndroidReuseNDK and assigned(lExisting) then begin
              Log($"Reusing cached Android NDK {AndroidNDKRelease}.");
              exit lExisting as not nullable;
            end;

            Log($"Extracting Android NDK {AndroidNDKRelease} onto the case-sensitive image.");
            RunIslandSDKTool("/usr/bin/unzip", new List<String>("-q", AndroidNDKArchive, "-d", lMountPoint), AndroidIntermediateFolder);
            lExtractedRoot := FindAndroidNDK(lMountPoint);
          end;
        OperatingSystem.Linux: begin
            var lRoot := Path.Combine(AndroidIntermediateFolder, "Android NDK "+AndroidNDKRelease);
            var lExisting := if lRoot.FolderExists then FindAndroidNDK(lRoot) else nil;
            if AndroidReuseNDK and assigned(lExisting) then begin
              Log($"Reusing cached Android NDK {AndroidNDKRelease}.");
              exit lExisting as not nullable;
            end;
            if lRoot.FolderExists then
              System.IO.Directory.Delete(lRoot, true);
            Folder.Create(lRoot);
            RunIslandSDKTool("/usr/bin/unzip", new List<String>("-q", AndroidNDKArchive, "-d", lRoot), AndroidIntermediateFolder);
            lExtractedRoot := FindAndroidNDK(lRoot);
          end;
        else
          raise new Exception("Android SDK import is supported on Linux and macOS.");
      end;

      if not assigned(lExtractedRoot) then
        raise new Exception($"The Android NDK could not be found after extracting '{AndroidNDKArchive}'.");
      result := lExtractedRoot as not nullable;
    end;

    method DetachAndroidNDK(aMountedRoot: nullable String);
    begin
      if not assigned(aMountedRoot) then
        exit;
      RunIslandSDKTool("/usr/bin/hdiutil", new List<String>("detach", "-force", aMountedRoot), AndroidIntermediateFolder);
      if aMountedRoot.FolderExists then
        Folder.Delete(aMountedRoot);
    end;

    method AndroidNDKRevision(aNDKRoot: not nullable String): not nullable String;
    begin
      var lProperties := RequireIslandSDKFile(Path.Combine(aNDKRoot, "source.properties"), "Android NDK source properties");
      for each lLine in File.ReadLines(lProperties) do
        if lLine.StartsWith("Pkg.Revision = ") then
          exit lLine.Substring(length("Pkg.Revision = ")).Trim as not nullable;
      raise new Exception($"Pkg.Revision is missing from '{lProperties}'.");
    end;

    method AndroidNDKMaximumAPI(aNDKRoot: not nullable String): Integer;
    begin
      var lMetadata := JsonObject.FromString(File.ReadText(RequireIslandSDKFile(Path.Combine(aNDKRoot, "meta", "platforms.json"), "Android NDK platform metadata")));
      result := lMetadata["max"]:IntegerValue as Integer;
    end;

    method AndroidNDKMinimumAPI(aNDKRoot: not nullable String): Integer;
    begin
      var lMetadata := JsonObject.FromString(File.ReadText(RequireIslandSDKFile(Path.Combine(aNDKRoot, "meta", "platforms.json"), "Android NDK platform metadata")));
      result := lMetadata["min"]:IntegerValue as Integer;
    end;

    method AndroidPrebuiltFolder(aNDKRoot: not nullable String): not nullable String;
    begin
      result := RequireIslandSDKFolder(Path.Combine(aNDKRoot, "toolchains", "llvm", "prebuilt", "linux-x86_64"), "Android NDK LLVM prebuilt folder");
    end;

    method AndroidClangVersionFolder(aPrebuilt: not nullable String): not nullable String;
    begin
      var lRoot := RequireIslandSDKFolder(Path.Combine(aPrebuilt, "lib", "clang"), "Android NDK Clang resource folder");
      for each lFolder in Folder.GetSubfolders(lRoot).OrderByDescending(aPath -> aPath) do
        if Path.Combine(lFolder, "include", "stddef.h").FileExists then
          exit lFolder as not nullable;
      raise new Exception($"Clang builtin headers were not found below '{lRoot}'.");
    end;

    method AndroidIncludeFolders(aPrebuilt: not nullable String;
                                 aArchitecture: not nullable AndroidSDKArchitecture): not nullable List<String>;
    begin
      var lSysroot := RequireIslandSDKFolder(Path.Combine(aPrebuilt, "sysroot"), "Android NDK sysroot");
      result := new List<String>;
      result.Add(RequireIslandSDKFolder(Path.Combine(lSysroot, "usr", "include"), "Android NDK headers"));
      result.Add(RequireIslandSDKFolder(Path.Combine(lSysroot, "usr", "include", aArchitecture.LibraryTriple), $"Android {aArchitecture.Name} headers"));
      // Prefer Bionic's public headers. Clang's resource headers deliberately
      // use include_next for hosted equivalents; putting them first causes old
      // HeaderImporter versions to resolve include_next back to the same file.
      result.Add(RequireIslandSDKFolder(Path.Combine(AndroidClangVersionFolder(aPrebuilt), "include"), "Android NDK Clang headers"));
    end;

    method AndroidHeaderPatternExists(aPattern: not nullable String;
                                      aIncludeFolders: not nullable ImmutableList<String>): Boolean;
    begin
      var lRelativePath := aPattern.Replace('/', Path.DirectorySeparatorChar).Replace('\\', Path.DirectorySeparatorChar);
      for each lIncludeFolder in aIncludeFolders do begin
        if not (lRelativePath.Contains("*") or lRelativePath.Contains("?")) then begin
          if Path.Combine(lIncludeFolder, lRelativePath).FileExists then
            exit true;
          continue;
        end;

        var lDirectory := Path.GetParentDirectory(lRelativePath);
        var lPattern := Path.GetFileName(lRelativePath);
        var lSearchFolder := if length(lDirectory) = 0 then lIncludeFolder else Path.Combine(lIncludeFolder, lDirectory);
        if lSearchFolder.FolderExists and (System.IO.Directory.GetFiles(lSearchFolder, lPattern).Length > 0) then
          exit true;
      end;
    end;

    method FilterAndroidHeaderList(aSource: nullable JsonArray;
                                   aIncludeFolders: not nullable ImmutableList<String>;
                                   aArchitecture: not nullable AndroidSDKArchitecture): not nullable JsonArray;
    begin
      result := new JsonArray;
      if not assigned(aSource) then
        exit;
      for each lItem in aSource do begin
        var lHeader := lItem:StringValue;
        // linux/a.out.h includes an architecture asm/a.out.h which the NDK
        // only publishes for its x86 targets.
        if (lHeader = "linux/a.out.h") and
           (aArchitecture.Name not in ["x86", "x86_64"]) then
          continue;
        // The 32-bit Arm UAPI set does not publish asm/kvm.h.
        if (lHeader = "linux/kvm.h") and
           (aArchitecture.Name = "armeabi-v7a") then
          continue;
        if AndroidHeaderPatternExists(lHeader, aIncludeFolders) then
          result.Add(lHeader)
        else if Debug then
          Log($"Skipping Android header no longer present: {lHeader}");
      end;
    end;

    method PrepareAndroidConfiguration(aTemplateName: not nullable String;
                                       aOutputName: not nullable String;
                                       aArchitecture: not nullable AndroidSDKArchitecture;
                                       aNDKRevision: not nullable String;
                                       aIncludeFolders: not nullable ImmutableList<String>): not nullable String;
    begin
      var lConfigFolder := AndroidRTLConfigFolder;
      if length(lConfigFolder) = 0 then
        lConfigFolder := Path.Combine(FrameworksFolder, "Island", "Custom Jsons");
      lConfigFolder := RequireIslandSDKFolder(lConfigFolder, "Android import configuration folder");

      var lTemplatePath := RequireIslandSDKFile(Path.Combine(lConfigFolder as not nullable, aTemplateName), $"Android configuration '{aTemplateName}'");
      var lConfiguration := JsonObject.FromString(File.ReadText(lTemplatePath));
      lConfiguration["TargetString"] := aArchitecture.TargetString;
      lConfiguration["Version"] := AndroidAPILevel;
      lConfiguration["SDKVersionString"] := aNDKRevision;
      lConfiguration["Platform"] := "Android";

      var lDefines := lConfiguration["Defines"] as JsonArray;
      if not assigned(lDefines) then begin
        lDefines := new JsonArray;
        lConfiguration["Defines"] := lDefines;
      end;
      lDefines.Add("__ANDROID_API__="+AndroidAPILevel);
      lDefines.Add("__ANDROID_MIN_SDK_VERSION__="+AndroidAPILevel);
      lDefines.Add("__BIONIC__=1");

      var lImports := lConfiguration["Imports"] as JsonArray;
      if not assigned(lImports) or (lImports.Count = 0) then
        raise new Exception($"Android configuration '{lTemplatePath}' has no imports.");
      for each lImportValue in lImports do begin
        var lImport := lImportValue as JsonObject;
        if not assigned(lImport) then
          raise new Exception($"Android configuration '{lTemplatePath}' contains an invalid import.");
        lImport["Files"] := FilterAndroidHeaderList(lImport["Files"] as JsonArray, aIncludeFolders, aArchitecture);
        lImport["IndirectFiles"] := FilterAndroidHeaderList(lImport["IndirectFiles"] as JsonArray, aIncludeFolders, aArchitecture);
        var lFiles := lImport["Files"] as JsonArray;
        if not assigned(lFiles) or (lFiles.Count = 0) then
          raise new Exception($"Android import '{lImport["Name"]:StringValue}' has no primary headers for {aArchitecture.Name}.");
        if aOutputName = "rtl" then
          lImport["DepLibs"] := new JsonArray("libclang_rt.builtins.a", "libatomic.a");
      end;

      var lConfigurationPath := Path.Combine(AndroidIntermediateFolder, $"android-{aOutputName}-{aArchitecture.Name}-{AndroidAPILevel}.json");
      File.WriteText(lConfigurationPath, lConfiguration.ToString);
      result := lConfigurationPath as not nullable;
    end;

    method RunAndroidHeaderImport(aConfiguration: not nullable String;
                                  aOutputFolder: not nullable String;
                                  aPrebuilt: not nullable String;
                                  aArchitecture: not nullable AndroidSDKArchitecture;
                                  aIncludeFolders: not nullable ImmutableList<String>;
                                  aRTLReference: nullable String := nil);
    begin
      var lArguments := new List<String>;
      lArguments.Add("import");
      lArguments.Add($"--json={aConfiguration}");
      lArguments.Add($"--sdkversion={AndroidAPILevel}");
      lArguments.Add("-o", aOutputFolder);
      if length(aRTLReference) > 0 then
        lArguments.Add("-x", RequireIslandSDKFile(aRTLReference, $"Android {aArchitecture.Name} RTL FX reference"));
      for each lIncludeFolder in aIncludeFolders do
        lArguments.Add("-i", lIncludeFolder);
      lArguments.Add($"--libpath={RequireIslandSDKFolder(Path.Combine(aPrebuilt, "sysroot", "usr", "lib", aArchitecture.LibraryTriple, AndroidAPILevel), $"Android {aArchitecture.Name} API {AndroidAPILevel} libraries")}");
      if Debug then
        lArguments.Add("--debug");
      RunHI(lArguments) SDKFolder(aPrebuilt);
    end;

    method AndroidSQLiteBuildIsComplete(aFolder: not nullable String;
                                        aArchitectures: not nullable ImmutableList<AndroidSDKArchitecture>): Boolean;
    begin
      if not Path.Combine(aFolder, "sqlite3.h").FileExists then
        exit false;
      for each lArchitecture in aArchitectures do
        if not Path.Combine(aFolder, lArchitecture.Name, "sqlite3.a").FileExists then
          exit false;
      result := true;
    end;

    method BuildAndroidSQLite(aArchitectures: not nullable ImmutableList<AndroidSDKArchitecture>): not nullable String;
    begin
      result := Path.Combine(AndroidIntermediateFolder as not nullable, "SQLite "+AndroidSQLiteVersion) as not nullable;
      if AndroidReuseSQLite and AndroidSQLiteBuildIsComplete(result, aArchitectures) then begin
        Log($"Reusing cached SQLite {AndroidSQLiteVersion} Android libraries.");
        exit;
      end;

      AndroidNDKArchive := RequireIslandSDKFile(AndroidNDKArchive, "Android NDK archive used to build SQLite");
      AndroidSQLiteArchive := RequireIslandSDKFile(AndroidSQLiteArchive, "SQLite amalgamation archive");
      if result.FolderExists then
        System.IO.Directory.Delete(result, true);
      Folder.Create(result);

      var lScript := "set -eu; apt-get update >/dev/null; DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends unzip >/dev/null; mkdir -p /work; unzip -q /inputs/ndk.zip -d /work; unzip -q /inputs/sqlite.zip -d /work; NDK=$(find /work -maxdepth 1 -type d -name 'android-ndk-*' | head -n 1); SQLITE_C=$(find /work -maxdepth 3 -type f -name sqlite3.c | head -n 1); SQLITE_DIR=$(dirname $SQLITE_C); PREBUILT=$NDK/toolchains/llvm/prebuilt/linux-x86_64; cp $SQLITE_DIR/sqlite3.h /output/sqlite3.h; build_sqlite() { ABI=$1; TARGET=$2; mkdir -p /output/$ABI; $PREBUILT/bin/${TARGET}"+AndroidAPILevel+"-clang -Os -fPIC -DSQLITE_THREADSAFE=1 -DSQLITE_OMIT_LOAD_EXTENSION=1 -c $SQLITE_DIR/sqlite3.c -o /output/$ABI/sqlite3.o; $PREBUILT/bin/llvm-ar rcsD /output/$ABI/sqlite3.a /output/$ABI/sqlite3.o; rm /output/$ABI/sqlite3.o; }; build_sqlite arm64-v8a aarch64-linux-android; build_sqlite armeabi-v7a armv7a-linux-androideabi; build_sqlite x86 i686-linux-android; build_sqlite x86_64 x86_64-linux-android; chmod -R a+rwX /output";
      var lArguments := new List<String>("run", "--rm", "--platform", "linux/amd64",
                                         "--mount", $"type=bind,source={AndroidNDKArchive},target=/inputs/ndk.zip,readonly",
                                         "--mount", $"type=bind,source={AndroidSQLiteArchive},target=/inputs/sqlite.zip,readonly",
                                         "--mount", $"type=bind,source={result},target=/output",
                                         AndroidDockerImage, "/bin/bash", "-lc", lScript);
      Log($"Building SQLite {AndroidSQLiteVersion} for the Android NDK {AndroidNDKRelease} ABI set.");
      RunIslandSDKTool(ResolveDocker, lArguments, AndroidIntermediateFolder);
      if not AndroidSQLiteBuildIsComplete(result, aArchitectures) then
        raise new Exception($"SQLite Android build is incomplete at '{result}'.");
    end;

    method CopyAndroidRuntimeFiles(aPrebuilt: not nullable String;
                                   aArchitectureFolder: not nullable String;
                                   aArchitecture: not nullable AndroidSDKArchitecture);
    begin
      var lAPILibraries := RequireIslandSDKFolder(Path.Combine(aPrebuilt, "sysroot", "usr", "lib", aArchitecture.LibraryTriple, AndroidAPILevel), $"Android {aArchitecture.Name} API {AndroidAPILevel} libraries");
      var lClangRuntime := RequireIslandSDKFolder(Path.Combine(AndroidClangVersionFolder(aPrebuilt), "lib", "linux"), "Android NDK Clang runtime libraries");
      CopyIslandSDKFile(Path.Combine(lAPILibraries, "crtbegin_so.o"), Path.Combine(aArchitectureFolder, "crtbeginS.o"));
      CopyIslandSDKFile(Path.Combine(lAPILibraries, "crtend_so.o"), Path.Combine(aArchitectureFolder, "crtendS.o"));
      CopyIslandSDKFile(Path.Combine(lClangRuntime, "libclang_rt.builtins-"+aArchitecture.BuiltinsName+"-android.a"), Path.Combine(aArchitectureFolder, "libclang_rt.builtins.a"));
      CopyIslandSDKFile(Path.Combine(lClangRuntime, aArchitecture.AtomicFolder, "libatomic.a"), Path.Combine(aArchitectureFolder, "libatomic.a"));
    end;

    method ValidateAndroidFx(aPath: not nullable String;
                             aName: not nullable String;
                             aArchitecture: not nullable AndroidSDKArchitecture);
    begin
      RequireIslandSDKFile(aPath, $"Android {aArchitecture.Name} {aName}.fx");
      var lFx := new FxFile;
      using lStream := new System.IO.FileStream(aPath, System.IO.FileMode.Open, System.IO.FileAccess.Read, System.IO.FileShare.Read) do
        lFx.Read(lStream);
      if lFx.Name <> aName then
        raise new Exception($"Android {aArchitecture.Name} FX '{aPath}' is named '{lFx.Name}', expected '{aName}'.");
      if lFx.Platform <> "Android" then
        raise new Exception($"Android {aArchitecture.Name} FX '{aPath}' has platform '{lFx.Platform}', expected Android.");
      if (lFx.TargetDescriptors.Count <> 1) or (lFx.TargetDescriptors[0] <> aArchitecture.Target) then
        raise new Exception($"Android {aArchitecture.Name} FX '{aPath}' has the wrong CPU target.");
      if (lFx.Targets.Count <> 1) or (lFx.Targets[0].TargetString <> aArchitecture.TargetString) then
        raise new Exception($"Android {aArchitecture.Name} FX '{aPath}' has target string '{if lFx.Targets.Count = 0 then "<none>" else lFx.Targets[0].TargetString}', expected '{aArchitecture.TargetString}'.");
    end;

    method ValidateAndroidSDK(aSDKFolder: not nullable String;
                              aArchitectures: not nullable ImmutableList<AndroidSDKArchitecture>);
    begin
      for each lArchitecture in aArchitectures do begin
        var lArchitectureFolder := RequireIslandSDKFolder(Path.Combine(aSDKFolder, lArchitecture.Name), $"Android {lArchitecture.Name} SDK folder");
        ValidateAndroidFx(Path.Combine(lArchitectureFolder, "rtl.fx"), "rtl", lArchitecture);
        for each lFile in ["crtbeginS.o", "crtendS.o", "libclang_rt.builtins.a", "libatomic.a"] do
          RequireIslandSDKFile(Path.Combine(lArchitectureFolder, lFile), $"Android {lArchitecture.Name} {lFile}");
        for each lForbidden in ["gc.fx", "gc.lib", "libgc.a", "gdbserver", "sqlite3.fx", "sqlite3.a"] do
          if Path.Combine(lArchitectureFolder, lForbidden).FileExists or Path.Combine(lArchitectureFolder, lForbidden).FolderExists then
            raise new Exception($"Android {lArchitecture.Name} SDK must not contain '{lForbidden}'; GC and SQLite are packaged separately.");
      end;
    end;

    method ValidateAndroidSQLitePackage(aPlatformFolder: not nullable String;
                                        aArchitectures: not nullable ImmutableList<AndroidSDKArchitecture>);
    begin
      for each lArchitecture in aArchitectures do begin
        var lArchitectureFolder := RequireIslandSDKFolder(Path.Combine(aPlatformFolder, lArchitecture.Name), $"Android {lArchitecture.Name} SQLite package folder");
        ValidateAndroidFx(Path.Combine(lArchitectureFolder, "sqlite3.fx"), "sqlite3", lArchitecture);
        RequireIslandSDKFile(Path.Combine(lArchitectureFolder, "sqlite3.a"), $"Android {lArchitecture.Name} SQLite static library");
      end;
    end;

  public

    property AndroidOutputFolder: nullable String;
    property AndroidLibrariesOutputFolder: nullable String;
    property AndroidNDKFolder: nullable String;
    property AndroidNDKArchive: nullable String;
    property AndroidSQLiteArchive: nullable String;
    property AndroidNDKRelease := "r29";
    property AndroidAPILevel: nullable String;
    property AndroidSQLiteVersion := "3.53.4";
    property AndroidDockerImage := "ubuntu:24.04";
    property AndroidIntermediateFolder: nullable String;
    property AndroidRTLConfigFolder: nullable String;
    property AndroidArchitectures: List<String> := new List<String>; readonly;
    property AndroidReuseNDK := false;
    property AndroidReuseSQLite := false;

    method ImportAndroidSDK;
    begin
      if length(AndroidOutputFolder) = 0 then
        raise new Exception("AndroidOutputFolder must be set.");
      AndroidOutputFolder := Path.GetFullPath(AndroidOutputFolder);
      AndroidLibrariesOutputFolder := if length(AndroidLibrariesOutputFolder) > 0 then Path.GetFullPath(AndroidLibrariesOutputFolder) else Path.Combine(Path.GetParentDirectory(AndroidOutputFolder), "Libraries");
      AndroidIntermediateFolder := if length(AndroidIntermediateFolder) > 0 then Path.GetFullPath(AndroidIntermediateFolder) else Path.Combine(AndroidOutputFolder, "Import Configurations");
      HI := RequireIslandSDKFile(HI, "HeaderImporter executable");
      Folder.Create(AndroidOutputFolder);
      Folder.Create(AndroidLibrariesOutputFolder);
      Folder.Create(AndroidIntermediateFolder);

      var lArchitectures := new List<AndroidSDKArchitecture>;
      if AndroidArchitectures.Count = 0 then
        AndroidArchitectures.Add(["arm64-v8a", "armeabi-v7a", "x86", "x86_64"]);
      for each lName in AndroidArchitectures do begin
        var lArchitecture := AndroidArchitecture(lName);
        if lArchitectures.Any(aItem -> aItem.Name = lArchitecture.Name) then
          raise new Exception($"Android SDK architecture '{lArchitecture.Name}' was specified more than once.");
        lArchitectures.Add(lArchitecture);
      end;

      var lMountedRoot: nullable String;
      try
        var lNDKRoot := PrepareAndroidNDK(out lMountedRoot);
        if not AndroidNDKIsComplete(lNDKRoot) then
          raise new Exception($"Android NDK is incomplete at '{lNDKRoot}'.");
        var lNDKRevision := AndroidNDKRevision(lNDKRoot);
        var lMinimumAPI := AndroidNDKMinimumAPI(lNDKRoot);
        var lMaximumAPI := AndroidNDKMaximumAPI(lNDKRoot);
        if length(AndroidAPILevel) = 0 then
          AndroidAPILevel := lMaximumAPI.ToString;
        var lAPI := Convert.ToInt32(AndroidAPILevel);
        if (lAPI < lMinimumAPI) or (lAPI > lMaximumAPI) then
          raise new Exception($"Android API {lAPI} is outside NDK {AndroidNDKRelease}'s supported range {lMinimumAPI} through {lMaximumAPI}.");

        var lSDKFolder := Path.Combine(AndroidOutputFolder, "Android "+AndroidAPILevel);
        if lSDKFolder.FolderExists then
          System.IO.Directory.Delete(lSDKFolder, true);
        Folder.Create(lSDKFolder);
        var lSQLitePlatformFolder := Path.Combine(AndroidLibrariesOutputFolder, "SQLite", "Island", "Android");
        if lSQLitePlatformFolder.FolderExists then
          System.IO.Directory.Delete(lSQLitePlatformFolder, true);
        Folder.Create(lSQLitePlatformFolder);

        Log($"Importing Android API {AndroidAPILevel} from NDK {AndroidNDKRelease} ({lNDKRevision}) for {String.Join(", ", lArchitectures.Select(aArchitecture -> aArchitecture.Name).ToList)}.");
        var lPrebuilt := AndroidPrebuiltFolder(lNDKRoot);
        var lSQLiteFolder := BuildAndroidSQLite(lArchitectures);
        for each lNotice in ["NOTICE", "NOTICE.toolchain", "source.properties"] do
          CopyIslandSDKFile(Path.Combine(lNDKRoot, lNotice), Path.Combine(lSDKFolder, lNotice));
        File.WriteText(Path.Combine(lSQLitePlatformFolder, "SQLite Notice.txt"), $"SQLite {AndroidSQLiteVersion} is in the public domain. Source: https://www.sqlite.org/\n");

        for each lArchitecture in lArchitectures do begin
          var lArchitectureFolder := Path.Combine(lSDKFolder, lArchitecture.Name);
          Folder.Create(lArchitectureFolder);
          var lIncludeFolders := AndroidIncludeFolders(lPrebuilt, lArchitecture);
          var lRTLConfiguration := PrepareAndroidConfiguration("android-"+lArchitecture.Name+".json", "rtl", lArchitecture, lNDKRevision, lIncludeFolders);
          RunAndroidHeaderImport(lRTLConfiguration, lArchitectureFolder, lPrebuilt, lArchitecture, lIncludeFolders);
          var lRTLReference := Path.Combine(lArchitectureFolder, "rtl.fx");

          var lSQLiteArchitectureFolder := Path.Combine(lSQLitePlatformFolder, lArchitecture.Name);
          Folder.Create(lSQLiteArchitectureFolder);
          var lSQLiteIncludes := new List<String>(lIncludeFolders);
          lSQLiteIncludes.Insert(0, lSQLiteFolder);
          var lSQLiteConfiguration := PrepareAndroidConfiguration("android-"+lArchitecture.Name+"-sqlite3.json", "sqlite3", lArchitecture, lNDKRevision, lSQLiteIncludes);
          RunAndroidHeaderImport(lSQLiteConfiguration, lSQLiteArchitectureFolder, lPrebuilt, lArchitecture, lSQLiteIncludes, lRTLReference);
          CopyIslandSDKFile(Path.Combine(lSQLiteFolder, lArchitecture.Name, "sqlite3.a"), Path.Combine(lSQLiteArchitectureFolder, "sqlite3.a"));
          CopyAndroidRuntimeFiles(lPrebuilt, lArchitectureFolder, lArchitecture);
        end;

        ValidateAndroidSDK(lSDKFolder, lArchitectures);
        ValidateAndroidSQLitePackage(lSQLitePlatformFolder, lArchitectures);
        if CreateZips then begin
          CreateDeterministicIslandSDKZip(lSDKFolder,
                                          Path.Combine(AndroidOutputFolder, "__Public", Path.GetFileName(lSDKFolder)+".zip"));
          CreateIslandPlatformLibraryZip(AndroidLibrariesOutputFolder,
                                         AndroidIntermediateFolder,
                                         "SQLite",
                                         "Android",
                                         "Island-Android-sqlite.zip");
        end;
      finally
        DetachAndroidNDK(lMountedRoot);
      end;
    end;

    method RepackageAndroidSDK(aSDKFolder: not nullable String);
    begin
      var lSDKFolder := RequireIslandSDKFolder(aSDKFolder, "existing Android Island SDK folder");
      AndroidOutputFolder := Path.GetParentDirectory(lSDKFolder);
      AndroidLibrariesOutputFolder := if length(AndroidLibrariesOutputFolder) > 0 then Path.GetFullPath(AndroidLibrariesOutputFolder) else Path.Combine(Path.GetParentDirectory(AndroidOutputFolder), "Libraries");
      AndroidIntermediateFolder := if length(AndroidIntermediateFolder) > 0 then Path.GetFullPath(AndroidIntermediateFolder) else Path.Combine(AndroidOutputFolder, "Import Configurations");
      Folder.Create(AndroidLibrariesOutputFolder);
      Folder.Create(AndroidIntermediateFolder);

      var lArchitectures := new List<AndroidSDKArchitecture>;
      if AndroidArchitectures.Count = 0 then
        AndroidArchitectures.Add(["arm64-v8a", "armeabi-v7a", "x86", "x86_64"]);
      for each lName in AndroidArchitectures do begin
        var lArchitecture := AndroidArchitecture(lName);
        if lArchitectures.Any(aItem -> aItem.Name = lArchitecture.Name) then
          raise new Exception($"Android SDK architecture '{lArchitecture.Name}' was specified more than once.");
        lArchitectures.Add(lArchitecture);
      end;

      for each lArchitecture in lArchitectures do begin
        var lArchitectureFolder := RequireIslandSDKFolder(Path.Combine(lSDKFolder, lArchitecture.Name), $"Android {lArchitecture.Name} SDK folder");
        ValidateAndroidFx(Path.Combine(lArchitectureFolder, "sqlite3.fx"), "sqlite3", lArchitecture);
        RequireIslandSDKFile(Path.Combine(lArchitectureFolder, "sqlite3.a"), $"Android {lArchitecture.Name} SQLite static library");
      end;

      var lSQLitePlatformFolder := Path.Combine(AndroidLibrariesOutputFolder, "SQLite", "Island", "Android");
      if lSQLitePlatformFolder.FolderExists then
        System.IO.Directory.Delete(lSQLitePlatformFolder, true);
      Folder.Create(lSQLitePlatformFolder);
      var lSQLiteNotice := Path.Combine(lSDKFolder, "SQLite Notice.txt");
      if lSQLiteNotice.FileExists then begin
        CopyIslandSDKFile(lSQLiteNotice, Path.Combine(lSQLitePlatformFolder, "SQLite Notice.txt"));
        File.Delete(lSQLiteNotice);
      end;
      for each lArchitecture in lArchitectures do begin
        var lArchitectureFolder := Path.Combine(lSDKFolder, lArchitecture.Name);
        var lSQLiteArchitectureFolder := Path.Combine(lSQLitePlatformFolder, lArchitecture.Name);
        Folder.Create(lSQLiteArchitectureFolder);
        for each lFileName in ["sqlite3.fx", "sqlite3.a"] do begin
          var lSource := Path.Combine(lArchitectureFolder, lFileName);
          CopyIslandSDKFile(lSource, Path.Combine(lSQLiteArchitectureFolder, lFileName));
          File.Delete(lSource);
        end;
      end;

      ValidateAndroidSDK(lSDKFolder, lArchitectures);
      ValidateAndroidSQLitePackage(lSQLitePlatformFolder, lArchitectures);
      if CreateZips then begin
        CreateDeterministicIslandSDKZip(lSDKFolder,
                                        Path.Combine(AndroidOutputFolder, "__Public", Path.GetFileName(lSDKFolder)+".zip"));
        CreateIslandPlatformLibraryZip(AndroidLibrariesOutputFolder,
                                       AndroidIntermediateFolder,
                                       "SQLite",
                                       "Android",
                                       "Island-Android-sqlite.zip");
      end;
    end;

  end;

end.
