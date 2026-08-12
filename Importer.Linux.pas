namespace RemObjects.Elements.HI2;

uses
  RemObjects.Elements.Basics,
  RemObjects.Elements.Fx,
  RemObjects.Elements.RTL;

type
  LinuxSDKArchitecture = private class
  public
    constructor(aName: not nullable String;
                aDockerPlatform: not nullable String;
                aGNUTriplet: not nullable String;
                aTargetString: not nullable String;
                aTarget: FxCpuTarget;
                aDefines: not nullable ImmutableList<String>);
    begin
      Name := aName;
      DockerPlatform := aDockerPlatform;
      GNUTriplet := aGNUTriplet;
      TargetString := aTargetString;
      Target := aTarget;
      Defines := aDefines;
    end;

    property Name: not nullable String; readonly;
    property DockerPlatform: not nullable String; readonly;
    property GNUTriplet: not nullable String; readonly;
    property TargetString: not nullable String; readonly;
    property Target: FxCpuTarget; readonly;
    property Defines: not nullable ImmutableList<String>; readonly;
  end;

  Importer = public partial class
  private

    method LinuxArchitecture(aName: not nullable String): not nullable LinuxSDKArchitecture;
    begin
      case aName.ToLowerInvariant of
        "x86_64", "x64", "amd64":
          result := new LinuxSDKArchitecture("x86_64",
                                             "linux/amd64",
                                             "x86_64-linux-gnu",
                                             "x86_64-linux-gnu",
                                             FxCpuTarget.x86_64,
                                             // These describe HeaderImporter's supported GNU C surface,
                                             // not the GCC package used to supply builtin headers. Claiming
                                             // GCC 15 exposes IEC-60559 _Float32 declarations it cannot parse.
                                             new List<String>("__unix__=1", "__x86_64=1", "__linux=1", "__unix=1", "__linux__=1", "__GNUC__=4", "__GNUC_MINOR__=8", "__amd64=1", "__LP64__=1", "unix=1", "__ELF__=1", "__x86_64__=1", "linux=1", "__SSE2__=1", "__amd64__=1", "__SSE__=1", "_LP64=1", "__STDC__=1", "_GCC_LIMITS_H_", "Linux", "x86_64", "Posix", "_GNU_SOURCE=1", "__SIZEOF_POINTER__=8", "__SIZEOF_LONG__=8", "__SIZE_TYPE__=long long unsigned int"));
        "arm64", "aarch64":
          result := new LinuxSDKArchitecture("arm64",
                                             "linux/arm64",
                                             "aarch64-linux-gnu",
                                             "aarch64-linux-gnu",
                                             FxCpuTarget.arm64,
                                             new List<String>("__unix__=1", "__aarch64__=1", "__linux=1", "__unix=1", "__linux__=1", "__GNUC__=4", "__GNUC_MINOR__=8", "__LP64__=1", "unix=1", "__ELF__=1", "linux=1", "_LP64=1", "__STDC__=1", "_GCC_LIMITS_H_", "Linux", "aarch64", "arm64", "Posix", "_GNU_SOURCE=1", "__SIZEOF_POINTER__=8", "__SIZEOF_LONG__=8", "__SIZE_TYPE__=long long unsigned int"));
        else
          raise new Exception($"Unsupported Linux SDK architecture '{aName}'. Supported names are x86_64 and arm64.");
      end;
    end;

    method PrepareLinuxSysrootRoot(out aDetachWhenDone: Boolean): not nullable String;
    begin
      aDetachWhenDone := false;
      case Environment.OS of
        OperatingSystem.Linux: begin
            result := Path.Combine(LinuxIntermediateFolder, "Sysroots") as not nullable;
            Folder.Create(result);
          end;
        OperatingSystem.macOS: begin
            var lImageBase := Path.Combine(LinuxIntermediateFolder, $"Ubuntu {LinuxUbuntuVersion} Sysroots");
            var lImagePath := lImageBase+".sparseimage";
            // Give every import a private mountpoint. The reusable image stays
            // below the intermediate folder, but is never exposed to Docker.
            var lMountPoint := Path.Combine("/private/tmp", "ElementsLinuxSDK-"+System.Guid.NewGuid.ToString("N"));
            if not lImagePath.FileExists then begin
              Log($"Creating case-sensitive Linux sysroot image at {lImagePath}.");
              RunIslandSDKTool("/usr/bin/hdiutil",
                               new List<String>("create", "-size", "6g", "-type", "SPARSE", "-fs", "Case-sensitive APFS", "-volname", $"Elements Ubuntu {LinuxUbuntuVersion} Sysroots", lImageBase),
                               LinuxIntermediateFolder);
            end;
            Folder.Create(lMountPoint);
            RunIslandSDKTool("/usr/bin/hdiutil",
                             new List<String>("attach", lImagePath, "-mountpoint", lMountPoint, "-nobrowse", "-noautoopen"),
                             LinuxIntermediateFolder);
            aDetachWhenDone := true;
            result := lMountPoint as not nullable;
          end;
        else
          raise new Exception("Linux SDK import is supported on Linux and macOS. macOS uses Docker plus a case-sensitive APFS sysroot image.");
      end;
    end;

    method DetachLinuxSysrootRoot(aRoot: not nullable String);
    begin
      // HeaderImporter has finished traversing the image. Force-detach makes
      // one-shot cleanup reliable even if macOS still has filesystem handles.
      RunIslandSDKTool("/usr/bin/hdiutil", new List<String>("detach", "-force", aRoot), LinuxIntermediateFolder);
      if aRoot.FolderExists then
        Folder.Delete(aRoot);
    end;

    method LinuxSysrootIsComplete(aRoot: not nullable String;
                                  aArchitecture: not nullable LinuxSDKArchitecture): Boolean;
    begin
      var lRoot := Path.Combine(aRoot, aArchitecture.Name);
      result := Path.Combine(lRoot, "packages.txt").FileExists and
                Path.Combine(lRoot, "gtk-cflags.txt").FileExists and
                Path.Combine(lRoot, "usr", "include", "stdio.h").FileExists and
                Path.Combine(lRoot, "usr", "lib", aArchitecture.GNUTriplet, "libsqlite3.a").FileExists and
                Path.Combine(lRoot, "usr", "lib", "gcc", aArchitecture.GNUTriplet).FolderExists;
    end;

    method ExportLinuxSysroot(aRoot: not nullable String;
                              aArchitecture: not nullable LinuxSDKArchitecture);
    begin
      if LinuxReuseSysroots and LinuxSysrootIsComplete(aRoot, aArchitecture) then begin
        Log($"Reusing cached Ubuntu {LinuxUbuntuVersion} {aArchitecture.Name} sysroot.");
        exit;
      end;

      var lArchitectureRoot := Path.Combine(aRoot, aArchitecture.Name);
      if lArchitectureRoot.FolderExists then
        System.IO.Directory.Delete(lArchitectureRoot, true);
      Folder.Create(lArchitectureRoot);

      var lDockerImage := if length(LinuxDockerImage) > 0 then LinuxDockerImage else "ubuntu:"+LinuxUbuntuVersion;
      var lTransferFolder := Path.Combine(LinuxIntermediateFolder, "Docker Transfer");
      Folder.Create(lTransferFolder);
      var lArchive := Path.Combine(lTransferFolder, aArchitecture.Name+".tar");
      if lArchive.FileExists then
        File.Delete(lArchive);
      var lScript := $"set -eu; apt-get update >/dev/null; DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends libc6-dev gcc libgtk-3-dev libsqlite3-dev pkg-config >/dev/null; mkdir -p /capture/usr/include /capture/usr/lib/{aArchitecture.GNUTriplet} /capture/usr/lib/gcc/{aArchitecture.GNUTriplet}; cp -a /usr/include/. /capture/usr/include/; cp -a /usr/lib/{aArchitecture.GNUTriplet}/. /capture/usr/lib/{aArchitecture.GNUTriplet}/; cp -a /usr/lib/gcc/{aArchitecture.GNUTriplet}/. /capture/usr/lib/gcc/{aArchitecture.GNUTriplet}/; pkg-config --cflags-only-I gtk+-3.0 > /capture/gtk-cflags.txt; dpkg-query -W libc6-dev gcc libgtk-3-dev libsqlite3-dev pkg-config > /capture/packages.txt; tar -C /capture -cf /elements-transfer/{aArchitecture.Name}.tar .";
      var lArguments := new List<String>("run", "--rm", "--platform", aArchitecture.DockerPlatform,
                                         "--mount", $"type=bind,source={lTransferFolder},target=/elements-transfer",
                                         lDockerImage, "/bin/bash", "-lc", lScript);
      Log($"Capturing Ubuntu {LinuxUbuntuVersion} {aArchitecture.Name} headers and libraries from {lDockerImage}.");
      RunIslandSDKTool(ResolveDocker, lArguments, LinuxIntermediateFolder);
      RequireIslandSDKFile(lArchive, $"Ubuntu {LinuxUbuntuVersion} {aArchitecture.Name} sysroot archive");
      RunIslandSDKTool("/usr/bin/tar", new List<String>("-xf", lArchive, "-C", lArchitectureRoot), LinuxIntermediateFolder);
      File.Delete(lArchive);
      if not LinuxSysrootIsComplete(aRoot, aArchitecture) then
        raise new Exception($"Ubuntu {LinuxUbuntuVersion} {aArchitecture.Name} sysroot export is incomplete at '{lArchitectureRoot}'.");
    end;

    method LinuxPackageVersion(aSysroot: not nullable String;
                               aPackage: not nullable String): not nullable String;
    begin
      var lManifest := RequireIslandSDKFile(Path.Combine(aSysroot, "packages.txt"), "Linux sysroot package manifest");
      for each lLine in File.ReadLines(lManifest) do begin
        var lParts := lLine.Replace(#9, " ").Split(" ", true);
        if (lParts.Count >= 2) and ((lParts[0] = aPackage) or lParts[0].StartsWith(aPackage+":")) then
          exit lParts[1] as not nullable;
      end;
      raise new Exception($"Package '{aPackage}' is missing from Linux sysroot manifest '{lManifest}'.");
    end;

    method LinuxGCCIncludeFolder(aSysroot: not nullable String;
                                 aArchitecture: not nullable LinuxSDKArchitecture): not nullable String;
    begin
      var lGCCRoot := RequireIslandSDKFolder(Path.Combine(aSysroot, "usr", "lib", "gcc", aArchitecture.GNUTriplet), $"Linux {aArchitecture.Name} GCC headers");
      var lHeader := Folder.GetFiles(lGCCRoot, true).FirstOrDefault(aFile -> Path.GetFileName(aFile) = "stddef.h");
      if not assigned(lHeader) then
        raise new Exception($"GCC's stddef.h was not found below '{lGCCRoot}'.");
      result := Path.GetParentDirectory(lHeader) as not nullable;
    end;

    method LinuxIncludeFolders(aSysroot: not nullable String;
                               aArchitecture: not nullable LinuxSDKArchitecture): not nullable List<String>;
    begin
      result := new List<String>;
      result.Add(RequireIslandSDKFolder(Path.Combine(aSysroot, "usr", "include"), $"Linux {aArchitecture.Name} headers"));
      result.Add(RequireIslandSDKFolder(Path.Combine(aSysroot, "usr", "include", aArchitecture.GNUTriplet), $"Linux {aArchitecture.Name} multiarch headers"));
      result.Add(LinuxGCCIncludeFolder(aSysroot, aArchitecture));

      var lFlagsPath := RequireIslandSDKFile(Path.Combine(aSysroot, "gtk-cflags.txt"), "GTK include manifest");
      for each lFlag in File.ReadText(lFlagsPath).Replace(#10, " ").Replace(#13, " ").Replace(#9, " ").Split(" ", true) do begin
        if not lFlag.StartsWith("-I") then
          continue;
        var lContainerPath := lFlag.Substring(2);
        if not lContainerPath.StartsWith("/usr/") then
          raise new Exception($"Unexpected GTK include path '{lContainerPath}' in '{lFlagsPath}'.");
        var lHostPath := Path.Combine(aSysroot, lContainerPath.Substring(1).Replace('/', Path.DirectorySeparatorChar));
        RequireIslandSDKFolder(lHostPath, $"GTK include path '{lContainerPath}'");
        if not result.Contains(lHostPath) then
          result.Add(lHostPath);
      end;
    end;

    method LinuxHeaderPatternExists(aPattern: not nullable String;
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

    method FilterLinuxHeaderList(aSource: nullable JsonArray;
                                 aIncludeFolders: not nullable ImmutableList<String>): not nullable JsonArray;
    begin
      result := new JsonArray;
      if not assigned(aSource) then
        exit;
      for each lItem in aSource do begin
        var lHeader := lItem:StringValue;
        if LinuxHeaderPatternExists(lHeader, aIncludeFolders) then
          result.Add(lHeader)
        else if Debug then
          Log($"Skipping Linux header no longer present: {lHeader}");
      end;
    end;

    method PrepareLinuxConfiguration(aTemplateName: not nullable String;
                                     aOutputName: not nullable String;
                                     aArchitecture: not nullable LinuxSDKArchitecture;
                                     aPackageVersion: not nullable String;
                                     aIncludeFolders: not nullable ImmutableList<String>): not nullable String;
    begin
      var lConfigFolder := LinuxRTLConfigFolder;
      if length(lConfigFolder) = 0 then
        lConfigFolder := Path.Combine(FrameworksFolder, "Island", "Custom Jsons");
      lConfigFolder := RequireIslandSDKFolder(lConfigFolder, "Linux import configuration folder");

      var lTemplatePath := RequireIslandSDKFile(Path.Combine(lConfigFolder as not nullable, aTemplateName), $"Linux configuration '{aTemplateName}'");
      var lConfiguration := JsonObject.FromString(File.ReadText(lTemplatePath));
      lConfiguration["TargetString"] := aArchitecture.TargetString;
      lConfiguration["Version"] := LinuxUbuntuVersion;
      lConfiguration["SDKVersionString"] := aPackageVersion;
      lConfiguration["Platform"] := "Linux";
      lConfiguration["Defines"] := new JsonArray(aArchitecture.Defines);

      var lImports := lConfiguration["Imports"] as JsonArray;
      if not assigned(lImports) or (lImports.Count = 0) then
        raise new Exception($"Linux configuration '{lTemplatePath}' has no imports.");
      for each lImportValue in lImports do begin
        var lImport := lImportValue as JsonObject;
        if not assigned(lImport) then
          raise new Exception($"Linux configuration '{lTemplatePath}' contains an invalid import.");
        var lSourceFiles := lImport["Files"] as JsonArray;
        var lSourceIndirectFiles := lImport["IndirectFiles"] as JsonArray;
        var lFiles := FilterLinuxHeaderList(lSourceFiles, aIncludeFolders);
        var lIndirectFiles := FilterLinuxHeaderList(lSourceIndirectFiles, aIncludeFolders);
        lImport["Files"] := lFiles;
        lImport["IndirectFiles"] := lIndirectFiles;
        if lFiles.Count = 0 then
          raise new Exception($"Linux import '{lImport["Name"]:StringValue}' has no primary headers in the Ubuntu {LinuxUbuntuVersion} {aArchitecture.Name} sysroot.");

        if (aTemplateName = "linux-x86_64-sqlite3.json") and (aArchitecture.Name = "arm64") then begin
          var lImportDefinitions := lImport["ImportDefs"] as JsonArray;
          if assigned(lImportDefinitions) then
            for each lDefinitionValue in lImportDefinitions do begin
              var lDefinition := lDefinitionValue as JsonObject;
              if assigned(lDefinition) and (lDefinition["Version"]:StringValue = "GLIBC_2.2.5") then
                lDefinition["Version"] := "GLIBC_2.17";
            end;
        end;
      end;

      var lConfigurationPath := Path.Combine(LinuxIntermediateFolder, $"linux-{aOutputName}-{aArchitecture.Name}-{LinuxUbuntuVersion}.json");
      File.WriteText(lConfigurationPath, lConfiguration.ToString);
      result := lConfigurationPath as not nullable;
    end;

    method RunLinuxHeaderImport(aConfiguration: not nullable String;
                                aOutputFolder: not nullable String;
                                aSysroot: not nullable String;
                                aArchitecture: not nullable LinuxSDKArchitecture;
                                aIncludeFolders: not nullable ImmutableList<String>;
                                aRTLReference: nullable String := nil);
    begin
      var lArguments := new List<String>;
      lArguments.Add("import");
      lArguments.Add($"--json={aConfiguration}");
      lArguments.Add($"--sdkversion={LinuxUbuntuVersion}");
      lArguments.Add("-o", aOutputFolder);
      if length(aRTLReference) > 0 then
        lArguments.Add("-x", RequireIslandSDKFile(aRTLReference, $"Linux {aArchitecture.Name} RTL FX reference"));
      for each lIncludeFolder in aIncludeFolders do
        lArguments.Add("-i", lIncludeFolder);
      lArguments.Add($"--libpath={RequireIslandSDKFolder(Path.Combine(aSysroot, "usr", "lib", aArchitecture.GNUTriplet), $"Linux {aArchitecture.Name} libraries")}");
      if Debug then
        lArguments.Add("--debug");
      RunHI(lArguments) SDKFolder(aSysroot);
    end;

    method CopyLinuxSQLiteLibrary(aSysroot: not nullable String;
                                  aOutputFolder: not nullable String;
                                  aArchitecture: not nullable LinuxSDKArchitecture);
    begin
      var lSource := RequireIslandSDKFile(Path.Combine(aSysroot, "usr", "lib", aArchitecture.GNUTriplet, "libsqlite3.a"), $"Linux {aArchitecture.Name} SQLite static library");
      CopyIslandSDKFile(lSource, Path.Combine(aOutputFolder, "sqlite3.a"));
    end;

    method ValidateLinuxFx(aPath: not nullable String;
                           aName: not nullable String;
                           aArchitecture: not nullable LinuxSDKArchitecture);
    begin
      RequireIslandSDKFile(aPath, $"Linux {aArchitecture.Name} {aName}.fx");
      var lFx := new FxFile;
      using lStream := new System.IO.FileStream(aPath, System.IO.FileMode.Open, System.IO.FileAccess.Read, System.IO.FileShare.Read) do
        lFx.Read(lStream);
      if lFx.Name <> aName then
        raise new Exception($"Linux {aArchitecture.Name} FX '{aPath}' is named '{lFx.Name}', expected '{aName}'.");
      if lFx.PlatformType <> FxPlatformType.Linux then
        raise new Exception($"Linux {aArchitecture.Name} FX '{aPath}' has platform '{lFx.Platform}', expected Linux.");
      if (lFx.TargetDescriptors.Count <> 1) or (lFx.TargetDescriptors[0] <> aArchitecture.Target) then
        raise new Exception($"Linux {aArchitecture.Name} FX '{aPath}' has the wrong CPU target.");
      if (lFx.Targets.Count <> 1) or (lFx.Targets[0].TargetString <> aArchitecture.TargetString) then
        raise new Exception($"Linux {aArchitecture.Name} FX '{aPath}' has target string '{if lFx.Targets.Count = 0 then "<none>" else lFx.Targets[0].TargetString}', expected '{aArchitecture.TargetString}'.");
    end;

    method ValidateLinuxRTLSurface(aPath: not nullable String;
                                   aArchitecture: not nullable LinuxSDKArchitecture);
    begin
      var lFx := new FxFile;
      using lStream := new System.IO.FileStream(aPath, System.IO.FileMode.Open, System.IO.FileAccess.Read, System.IO.FileShare.Read) do
        lFx.Read(lStream);
      var lTarget := lFx.Targets.Single;

      for each lTypeName in ["__struct_tm", "__struct__IO_FILE", "locale_t", "int64_t", "uint8_t", "uint16_t", "uint32_t", "uint64_t", "uintptr_t", "FILE", "timer_t", "sigval_t", "time_t"] do
        if not lTarget.NamedTypes.Any(aType -> (aType.Name = "rtl."+lTypeName) and (aType.Visibility = FxMemberVisibility.Public) and (aType.Type >= 0)) then
          raise new Exception($"Linux {aArchitecture.Name} RTL FX is missing public type 'rtl.{lTypeName}'.");

      var lGlobalName := lTarget.NamedTypes.FirstOrDefault(aType -> aType.Name = "rtl.__Global");
      if not assigned(lGlobalName) or (lGlobalName.Type < 0) then
        raise new Exception($"Linux {aArchitecture.Name} RTL FX has no public global scope.");
      var lGlobalType := lTarget.Types[lGlobalName.Type] as FxDefinitionType;
      if not assigned(lGlobalType) then
        raise new Exception($"Linux {aArchitecture.Name} RTL FX global scope has an invalid type.");
      for each lMemberName in ["towlower", "towupper", "stat", "stat64", "fstat", "fstat64", "lstat", "lstat64"] do
        if not lGlobalType.Members.Any(aMember -> (aMember.Name = lMemberName) and (aMember.Visibility = FxMemberVisibility.Public)) then
          raise new Exception($"Linux {aArchitecture.Name} RTL FX is missing public member 'rtl.{lMemberName}'.");

      var lSchedName := lTarget.NamedTypes.First(aType -> aType.Name = "rtl.__struct_sched_param");
      var lSchedType := lTarget.Types[lSchedName.Type] as FxDefinitionType;
      if not assigned(lSchedType) or not lSchedType.Members.Any(aMember -> (aMember.Name = "sched_priority") and (aMember.Visibility = FxMemberVisibility.Public)) then
        raise new Exception($"Linux {aArchitecture.Name} RTL FX is missing public member 'rtl.__struct_sched_param.sched_priority'.");

      var lFabsf := lGlobalType.Members.FirstOrDefault(aMember -> (aMember.Name = "fabsf") and (aMember.Visibility = FxMemberVisibility.Public));
      if not assigned(lFabsf) or (lFabsf.Parameters.Count <> 1) or
         not (lTarget.Types[lFabsf.Type] is FxForeignType) or
         (FxForeignType(lTarget.Types[lFabsf.Type]).ForeignName <> "RemObjects.Elements.System.Single") or
         not (lTarget.Types[lFabsf.Parameters[0].Type] is FxForeignType) or
         (FxForeignType(lTarget.Types[lFabsf.Parameters[0].Type]).ForeignName <> "RemObjects.Elements.System.Single") then
        raise new Exception($"Linux {aArchitecture.Name} RTL FX has an invalid 'rtl.fabsf' signature; expected Single -> Single.");

      for each lDefineName in ["SIGKILL", "SIGEV_THREAD", "_UA_SEARCH_PHASE", "_UA_CLEANUP_PHASE", "_UA_HANDLER_FRAME", "_UA_FORCE_UNWIND"] do
        if not lTarget.Defines.Any(aDefine -> aDefine.Name = lDefineName) then
          raise new Exception($"Linux {aArchitecture.Name} RTL FX is missing public define 'rtl.{lDefineName}'.");
    end;

    method ValidateLinuxSDK(aSDKFolder: not nullable String;
                            aArchitectures: not nullable ImmutableList<LinuxSDKArchitecture>);
    begin
      var lFxNames := new List<String>("rtl", "atk", "cairo", "gdk", "glib", "pango", "gtk");
      for each lArchitecture in aArchitectures do begin
        var lArchitectureFolder := Path.Combine(aSDKFolder, lArchitecture.Name);
        for each lName in lFxNames do
          ValidateLinuxFx(Path.Combine(lArchitectureFolder, lName+".fx"), lName, lArchitecture);
        ValidateLinuxRTLSurface(Path.Combine(lArchitectureFolder, "rtl.fx"), lArchitecture);
        for each lForbidden in ["gc.fx", "gc.lib", "libgc.a", "sqlite3.fx", "sqlite3.a"] do
          if Path.Combine(lArchitectureFolder, lForbidden).FileExists then
            raise new Exception($"Linux {lArchitecture.Name} SDK must not contain '{lForbidden}'; GC and SQLite are packaged separately.");
      end;
    end;

    method ValidateLinuxSQLitePackage(aPlatformFolder: not nullable String;
                                      aArchitectures: not nullable ImmutableList<LinuxSDKArchitecture>);
    begin
      for each lArchitecture in aArchitectures do begin
        var lArchitectureFolder := Path.Combine(aPlatformFolder, lArchitecture.Name);
        ValidateLinuxFx(Path.Combine(lArchitectureFolder, "sqlite3.fx"), "sqlite3", lArchitecture);
        RequireIslandSDKFile(Path.Combine(lArchitectureFolder, "sqlite3.a"), $"Linux {lArchitecture.Name} SQLite static library");
      end;
    end;

  public

    property LinuxOutputFolder: nullable String;
    property LinuxLibrariesOutputFolder: nullable String;
    property LinuxUbuntuVersion := "26.04";
    property LinuxDockerImage: nullable String;
    property LinuxIntermediateFolder: nullable String;
    property LinuxRTLConfigFolder: nullable String;
    property LinuxArchitectures: List<String> := new List<String>; readonly;
    property LinuxReuseSysroots := false;

    method ImportLinuxSDK;
    begin
      if length(LinuxOutputFolder) = 0 then
        raise new Exception("LinuxOutputFolder must be set.");
      LinuxOutputFolder := Path.GetFullPath(LinuxOutputFolder);
      LinuxLibrariesOutputFolder := if length(LinuxLibrariesOutputFolder) > 0 then Path.GetFullPath(LinuxLibrariesOutputFolder) else Path.Combine(Path.GetParentDirectory(LinuxOutputFolder), "Libraries");
      LinuxIntermediateFolder := if length(LinuxIntermediateFolder) > 0 then Path.GetFullPath(LinuxIntermediateFolder) else Path.Combine(LinuxOutputFolder, "Import Configurations", "Ubuntu "+LinuxUbuntuVersion);
      HI := RequireIslandSDKFile(HI, "HeaderImporter executable");
      Folder.Create(LinuxOutputFolder);
      Folder.Create(LinuxLibrariesOutputFolder);
      Folder.Create(LinuxIntermediateFolder);

      var lArchitectures := new List<LinuxSDKArchitecture>;
      if LinuxArchitectures.Count = 0 then
        LinuxArchitectures.Add(["x86_64", "arm64"]);
      for each lName in LinuxArchitectures do begin
        var lArchitecture := LinuxArchitecture(lName);
        if lArchitectures.Any(aItem -> aItem.Name = lArchitecture.Name) then
          raise new Exception($"Linux SDK architecture '{lArchitecture.Name}' was specified more than once.");
        lArchitectures.Add(lArchitecture);
      end;

      var lSDKFolder := Path.Combine(LinuxOutputFolder, "Ubuntu "+LinuxUbuntuVersion);
      if lSDKFolder.FolderExists then
        System.IO.Directory.Delete(lSDKFolder, true);
      Folder.Create(lSDKFolder);
      var lSQLitePlatformFolder := Path.Combine(LinuxLibrariesOutputFolder, "SQLite", "Island", "Ubuntu");
      if lSQLitePlatformFolder.FolderExists then
        System.IO.Directory.Delete(lSQLitePlatformFolder, true);
      Folder.Create(lSQLitePlatformFolder);

      var lDetachSysroot := false;
      var lSysrootRoot := PrepareLinuxSysrootRoot(out lDetachSysroot);
      try
        Log($"Importing Ubuntu {LinuxUbuntuVersion} for {String.Join(", ", lArchitectures.Select(aArchitecture -> aArchitecture.Name).ToList)}.");
        // Capture every architecture before native import so package acquisition
        // is complete and the reusable sysroot cache remains coherent.
        for each lArchitecture in lArchitectures do
          ExportLinuxSysroot(lSysrootRoot, lArchitecture);

        for each lArchitecture in lArchitectures do begin
          var lSysroot := Path.Combine(lSysrootRoot, lArchitecture.Name);
          var lPackageVersion := LinuxPackageVersion(lSysroot, "libc6-dev");
          var lIncludeFolders := LinuxIncludeFolders(lSysroot, lArchitecture);
          var lArchitectureFolder := Path.Combine(lSDKFolder, lArchitecture.Name);
          Folder.Create(lArchitectureFolder);

          var lRTLConfiguration := PrepareLinuxConfiguration("linux-x86_64.json", "rtl", lArchitecture, lPackageVersion, lIncludeFolders);
          RunLinuxHeaderImport(lRTLConfiguration, lArchitectureFolder, lSysroot, lArchitecture, lIncludeFolders);
          var lRTLReference := Path.Combine(lArchitectureFolder, "rtl.fx");

          var lGTKConfiguration := PrepareLinuxConfiguration("linux-gtk-x86_64.json", "gtk", lArchitecture, lPackageVersion, lIncludeFolders);
          RunLinuxHeaderImport(lGTKConfiguration, lArchitectureFolder, lSysroot, lArchitecture, lIncludeFolders, lRTLReference);

          var lSQLiteArchitectureFolder := Path.Combine(lSQLitePlatformFolder, lArchitecture.Name);
          Folder.Create(lSQLiteArchitectureFolder);
          var lSQLiteConfiguration := PrepareLinuxConfiguration("linux-x86_64-sqlite3.json", "sqlite3", lArchitecture, lPackageVersion, lIncludeFolders);
          RunLinuxHeaderImport(lSQLiteConfiguration, lSQLiteArchitectureFolder, lSysroot, lArchitecture, lIncludeFolders, lRTLReference);
          CopyLinuxSQLiteLibrary(lSysroot, lSQLiteArchitectureFolder, lArchitecture);

          for each lGCFile in ["gc.fx", "gc.lib", "libgc.a"] do begin
            var lGCPath := Path.Combine(lArchitectureFolder, lGCFile);
            if lGCPath.FileExists then
              File.Delete(lGCPath);
          end;
        end;
      finally
        if lDetachSysroot then
          DetachLinuxSysrootRoot(lSysrootRoot);
      end;

      ValidateLinuxSDK(lSDKFolder, lArchitectures);
      ValidateLinuxSQLitePackage(lSQLitePlatformFolder, lArchitectures);
      if CreateZips then begin
        CreateDeterministicIslandSDKZip(lSDKFolder,
                                        Path.Combine(LinuxOutputFolder, "__Public", Path.GetFileName(lSDKFolder)+".zip"));
        CreateIslandPlatformLibraryZip(LinuxLibrariesOutputFolder,
                                       LinuxIntermediateFolder,
                                       "SQLite",
                                       "Ubuntu",
                                       "Island-Linux-sqlite.zip");
      end;
    end;

    method RepackageLinuxSDK(aSDKFolder: not nullable String);
    begin
      var lSDKFolder := RequireIslandSDKFolder(aSDKFolder, "existing Linux Island SDK folder");
      LinuxOutputFolder := Path.GetParentDirectory(lSDKFolder);
      LinuxLibrariesOutputFolder := if length(LinuxLibrariesOutputFolder) > 0 then Path.GetFullPath(LinuxLibrariesOutputFolder) else Path.Combine(Path.GetParentDirectory(LinuxOutputFolder), "Libraries");
      LinuxIntermediateFolder := if length(LinuxIntermediateFolder) > 0 then Path.GetFullPath(LinuxIntermediateFolder) else Path.Combine(LinuxOutputFolder, "Import Configurations", Path.GetFileName(lSDKFolder));
      Folder.Create(LinuxLibrariesOutputFolder);
      Folder.Create(LinuxIntermediateFolder);

      var lArchitectures := new List<LinuxSDKArchitecture>;
      if LinuxArchitectures.Count = 0 then
        LinuxArchitectures.Add(["x86_64", "arm64"]);
      for each lName in LinuxArchitectures do begin
        var lArchitecture := LinuxArchitecture(lName);
        if lArchitectures.Any(aItem -> aItem.Name = lArchitecture.Name) then
          raise new Exception($"Linux SDK architecture '{lArchitecture.Name}' was specified more than once.");
        lArchitectures.Add(lArchitecture);
      end;

      for each lArchitecture in lArchitectures do begin
        var lArchitectureFolder := RequireIslandSDKFolder(Path.Combine(lSDKFolder, lArchitecture.Name), $"Linux {lArchitecture.Name} SDK folder");
        ValidateLinuxFx(Path.Combine(lArchitectureFolder, "sqlite3.fx"), "sqlite3", lArchitecture);
        RequireIslandSDKFile(Path.Combine(lArchitectureFolder, "sqlite3.a"), $"Linux {lArchitecture.Name} SQLite static library");
      end;

      var lSQLitePlatformFolder := Path.Combine(LinuxLibrariesOutputFolder, "SQLite", "Island", "Ubuntu");
      if lSQLitePlatformFolder.FolderExists then
        System.IO.Directory.Delete(lSQLitePlatformFolder, true);
      Folder.Create(lSQLitePlatformFolder);
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

      ValidateLinuxSDK(lSDKFolder, lArchitectures);
      ValidateLinuxSQLitePackage(lSQLitePlatformFolder, lArchitectures);
      if CreateZips then begin
        CreateDeterministicIslandSDKZip(lSDKFolder,
                                        Path.Combine(LinuxOutputFolder, "__Public", Path.GetFileName(lSDKFolder)+".zip"));
        CreateIslandPlatformLibraryZip(LinuxLibrariesOutputFolder,
                                       LinuxIntermediateFolder,
                                       "SQLite",
                                       "Ubuntu",
                                       "Island-Linux-sqlite.zip");
      end;
    end;

  end;

end.
