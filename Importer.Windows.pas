namespace RemObjects.Elements.HI2;

uses
  RemObjects.Elements.Basics,
  RemObjects.Elements.Fx,
  RemObjects.Elements.RTL;

type
  WindowsSDKLayout = private class
  public
    constructor(aSDKRoot: not nullable String;
                aIncludeRoot: not nullable String;
                aLibraryRoot: not nullable String;
                aVersion: not nullable String);
    begin
      SDKRoot := aSDKRoot;
      IncludeRoot := aIncludeRoot;
      LibraryRoot := aLibraryRoot;
      Version := aVersion;
    end;

    property SDKRoot: not nullable String; readonly;
    property IncludeRoot: not nullable String; readonly;
    property LibraryRoot: not nullable String; readonly;
    property Version: not nullable String; readonly;
  end;

  WindowsSDKArchitecture = private class
  public
    constructor(aName: not nullable String;
                aMicrosoftName: not nullable String;
                aTargetString: not nullable String;
                aTarget: FxCpuTarget;
                aCOFFMachine: UInt16;
                aDefines: not nullable ImmutableList<String>);
    begin
      Name := aName;
      MicrosoftName := aMicrosoftName;
      TargetString := aTargetString;
      Target := aTarget;
      COFFMachine := aCOFFMachine;
      Defines := aDefines;
    end;

    property Name: not nullable String; readonly;
    property MicrosoftName: not nullable String; readonly;
    property TargetString: not nullable String; readonly;
    property Target: FxCpuTarget; readonly;
    property COFFMachine: UInt16; readonly;
    property Defines: not nullable ImmutableList<String>; readonly;
  end;

  Importer = public partial class
  private

    method ResolveWindowsSDKLayout: not nullable WindowsSDKLayout;
    begin
      var lSDKRoot := RequireIslandSDKFolder(WindowsSDKFolder, "Windows SDK folder");
      var lContentRoot := lSDKRoot;
      if not Path.Combine(lContentRoot, "Include").FolderExists then begin
        lContentRoot := Path.Combine(lSDKRoot, "c");
        if not Path.Combine(lContentRoot, "Include").FolderExists then
          raise new Exception($"'{lSDKRoot}' is neither an installed Windows SDK nor a merged Microsoft.Windows.SDK.CPP NuGet package. Expected an Include folder at the root or below 'c'.");
      end;

      var lIncludeContainer := Path.Combine(lContentRoot, "Include");
      var lVersion := WindowsSDKVersion;
      if length(lVersion) = 0 then begin
        var lVersions := Folder.GetSubfolders(lIncludeContainer)
                              .Select(aFolder -> Path.GetFileName(aFolder))
                              .Where(aVersion -> aVersion.IsValidVersionTriple)
                              .ToSortedList((b, a) -> a.CompareVersionTripleTo(b));
        if lVersions.Count = 0 then
          raise new Exception($"No versioned Windows SDK include folder was found below '{lIncludeContainer}'.");
        lVersion := lVersions[0];
      end;

      var lIncludeRoot := Path.Combine(lIncludeContainer, lVersion as not nullable);
      RequireIslandSDKFolder(lIncludeRoot, $"Windows SDK {lVersion} include folder");

      var lLibraryRoot := Path.Combine(lContentRoot, "Lib", lVersion as not nullable);
      if not lLibraryRoot.FolderExists then
        lLibraryRoot := lContentRoot;
      if not Path.Combine(lLibraryRoot, "um").FolderExists then
        raise new Exception($"Windows SDK {lVersion} UM import libraries were not found below '{lLibraryRoot}'. For NuGet input, extract the matching architecture packages into the same root as Microsoft.Windows.SDK.CPP.");
      if not Path.Combine(lLibraryRoot, "ucrt").FolderExists then
        raise new Exception($"Windows SDK {lVersion} UCRT import libraries were not found below '{lLibraryRoot}'. For NuGet input, extract the matching architecture packages into the same root as Microsoft.Windows.SDK.CPP.");

      result := new WindowsSDKLayout(lSDKRoot, lIncludeRoot, lLibraryRoot, lVersion as not nullable);
    end;

    method ResolveWindowsMSVCIncludeFolder: not nullable String;
    begin
      var lMSVCRoot := RequireIslandSDKFolder(WindowsMSVCFolder, "MSVC tools or include folder");
      if Path.Combine(lMSVCRoot, "vcruntime.h").FileExists then
        exit lMSVCRoot;

      var lIncludeFolder := Path.Combine(lMSVCRoot, "include");
      if Path.Combine(lIncludeFolder, "vcruntime.h").FileExists then
        exit lIncludeFolder as not nullable;

      var lToolsFolder := Path.Combine(lMSVCRoot, "VC", "Tools", "MSVC");
      if lToolsFolder.FolderExists then
        lMSVCRoot := lToolsFolder;

      var lVersions := Folder.GetSubfolders(lMSVCRoot)
                            .Where(aFolder -> Path.Combine(aFolder, "include", "vcruntime.h").FileExists)
                            .Select(aFolder -> Path.GetFileName(aFolder))
                            .Where(aVersion -> aVersion.IsValidVersionTriple)
                            .ToSortedList((b, a) -> a.CompareVersionTripleTo(b));
      if lVersions.Count = 0 then
        raise new Exception($"MSVC's vcruntime.h was not found below '{lMSVCRoot}'. Pass --msvc=<folder> for the MSVC include folder, a versioned MSVC tools folder, or the Visual Studio root.");
      result := Path.Combine(lMSVCRoot, lVersions[0], "include") as not nullable;
    end;

    method ResolveWindowsNetFxIncludeFolder: not nullable String;
    begin
      var lNetFxRoot := WindowsNetFxSDKFolder;
      if length(lNetFxRoot) = 0 then begin
        var lSDKRoot := RequireIslandSDKFolder(WindowsSDKFolder, "Windows SDK folder");
        lNetFxRoot := Path.Combine(Path.GetParentDirectory(lSDKRoot), "NETFXSDK");
      end;
      lNetFxRoot := RequireIslandSDKFolder(lNetFxRoot, ".NET Framework SDK folder");

      if Path.Combine(lNetFxRoot, "cor.h").FileExists then
        exit lNetFxRoot as not nullable;

      var lIncludeFolder := Path.Combine(lNetFxRoot, "Include", "um");
      if Path.Combine(lIncludeFolder, "cor.h").FileExists then
        exit lIncludeFolder as not nullable;

      var lVersions := Folder.GetSubfolders(lNetFxRoot)
                            .Where(aFolder -> Path.Combine(aFolder, "Include", "um", "cor.h").FileExists)
                            .OrderByDescending(aFolder -> Path.GetFileName(aFolder), StringComparer.OrdinalIgnoreCase)
                            .ToList;
      if lVersions.Count = 0 then
        raise new Exception($"The .NET Framework SDK header 'cor.h' was not found below '{lNetFxRoot}'. Pass --netfx-sdk=<folder> for an SDK root such as Windows Kits\\NETFXSDK\\4.8.1 or its Include\\um folder.");
      result := Path.Combine(lVersions[0], "Include", "um") as not nullable;
    end;

    method WindowsArchitecture(aName: not nullable String): not nullable WindowsSDKArchitecture;
    begin
      case aName.ToLowerInvariant of
        "i386", "x86":
          result := new WindowsSDKArchitecture("i386",
                                               "x86",
                                               "i686-pc-windows-msvc",
                                               FxCpuTarget.i386,
                                               $014c,
                                               new List<String>("_X86_", "WINVER=0x0A00", "__LITTLE_ENDIAN__", "_MSC_VER=1700", "_WIN32", "_M_IX86=600", "WINDOWS", "i386", "_INTEGRAL_MAX_BITS=64", "UNICODE", "STRICT", "_WINSOCKAPI_", "target_arch=x86", "target_vendor=pc", "target_os=windows"));
        "x86_64", "x64":
          result := new WindowsSDKArchitecture("x86_64",
                                               "x64",
                                               "x86_64-pc-windows-msvc",
                                               FxCpuTarget.x86_64,
                                               $8664,
                                               new List<String>("CPU64", "_X86_64_", "_WIN64", "WINVER=0x0A00", "__LITTLE_ENDIAN__", "_MSC_VER=1700", "_WIN32", "_M_X64", "_M_AMD64", "WINDOWS", "x86_64", "_INTEGRAL_MAX_BITS=64", "UNICODE", "STRICT", "_WINSOCKAPI_", "target_arch=x86_64", "target_vendor=pc", "target_os=windows"));
        "arm64", "aarch64":
          result := new WindowsSDKArchitecture("arm64",
                                               "arm64",
                                               "arm64-pc-windows-msvc",
                                               FxCpuTarget.arm64,
                                               $aa64,
                                               new List<String>("CPU64", "_ARM64_", "_WIN64", "WINVER=0x0A00", "__LITTLE_ENDIAN__", "_MSC_VER=1700", "_WIN32", "_M_ARM64", "WINDOWS", "arm64", "_INTEGRAL_MAX_BITS=64", "UNICODE", "STRICT", "_WINSOCKAPI_", "target_arch=arm64", "target_vendor=pc", "target_os=windows"));
        else
          raise new Exception($"Unsupported Windows SDK architecture '{aName}'. Supported names are i386, x86_64, and arm64.");
      end;
    end;

    method ResolveWindowsArchitectures: not nullable List<WindowsSDKArchitecture>;
    begin
      if WindowsArchitectures.Count = 0 then
        WindowsArchitectures.Add(["i386", "x86_64", "arm64"]);
      result := new List<WindowsSDKArchitecture>;
      for each lName in WindowsArchitectures do begin
        var lArchitecture := WindowsArchitecture(lName);
        if result.Any(aItem -> aItem.Name = lArchitecture.Name) then
          raise new Exception($"Windows SDK architecture '{lArchitecture.Name}' was specified more than once.");
        result.Add(lArchitecture);
      end;
    end;

    method WindowsIncludeFolders(aLayout: not nullable WindowsSDKLayout;
                                 aMSVCIncludeFolder: not nullable String;
                                 aNetFxIncludeFolder: nullable String): not nullable List<String>;
    begin
      result := new List<String>;
      result.Add(RequireIslandSDKFolder(Path.Combine(aLayout.IncludeRoot, "ucrt"), "Windows UCRT headers"));
      result.Add(RequireIslandSDKFolder(Path.Combine(aLayout.IncludeRoot, "um"), "Windows UM headers"));
      result.Add(RequireIslandSDKFolder(Path.Combine(aLayout.IncludeRoot, "shared"), "Windows shared headers"));
      result.Add(RequireIslandSDKFolder(Path.Combine(aLayout.IncludeRoot, "winrt"), "Windows Runtime headers"));
      result.Add(aMSVCIncludeFolder);
      if length(aNetFxIncludeFolder) > 0 then
        result.Add(aNetFxIncludeFolder as not nullable);
    end;

    method WindowsHeaderNames(aIncludeFolders: not nullable ImmutableList<String>): not nullable HashSet<String>;
    begin
      result := new HashSet<String>;
      for each lIncludeFolder in aIncludeFolders do
        for each lHeader in Folder.GetFiles(lIncludeFolder, true).Where(aFile -> aFile.PathExtension.ToLowerInvariant = ".h") do begin
          result.Add(Path.GetFileName(lHeader).ToLowerInvariant);
          result.Add(IslandSDKRelativePath(lIncludeFolder, lHeader).ToLowerInvariant);
        end;
    end;

    method FilterWindowsHeaderList(aSource: nullable JsonArray;
                                   aAvailableHeaders: not nullable HashSet<String>): not nullable JsonArray;
    begin
      result := new JsonArray;
      if not assigned(aSource) then
        exit;
      for each lItem in aSource do begin
        var lHeader := lItem:StringValue;
        if aAvailableHeaders.Contains(lHeader.Replace("\\", "/").ToLowerInvariant) or aAvailableHeaders.Contains(Path.GetFileName(lHeader).ToLowerInvariant) then
          result.Add(lHeader)
        else if Debug then
          Log($"Skipping Windows header no longer present in this SDK/toolchain: {lHeader}");
      end;
    end;

    method CreateWindowsRTLConfiguration(aArchitecture: not nullable WindowsSDKArchitecture;
                                         aLayout: not nullable WindowsSDKLayout;
                                         aAvailableHeaders: not nullable HashSet<String>;
                                         aIntermediateFolder: not nullable String): not nullable String;
    begin
      var lConfigFolder := WindowsRTLConfigFolder;
      if length(lConfigFolder) = 0 then
        lConfigFolder := Path.Combine(FrameworksFolder, "Island", "Custom Jsons");
      lConfigFolder := RequireIslandSDKFolder(lConfigFolder, "Windows RTL configuration folder");

      var lTemplateName := if aArchitecture.Name = "i386" then "windows-i386.json" else "windows-x86_64.json";
      var lTemplatePath := RequireIslandSDKFile(Path.Combine(lConfigFolder as not nullable, lTemplateName), $"Windows RTL configuration '{lTemplateName}'");
      var lConfiguration := JsonObject.FromString(File.ReadText(lTemplatePath));
      lConfiguration["TargetString"] := aArchitecture.TargetString;
      lConfiguration["Version"] := "10.0";
      lConfiguration["SDKVersionString"] := aLayout.Version;
      lConfiguration["Platform"] := "Windows";
      lConfiguration["Defines"] := new JsonArray(aArchitecture.Defines);

      var lImports := lConfiguration["Imports"] as JsonArray;
      if not assigned(lImports) or (lImports.Count <> 1) then
        raise new Exception($"Windows RTL configuration '{lTemplatePath}' must contain exactly one import.");
      var lImport := lImports[0] as JsonObject;
      if not assigned(lImport) then
        raise new Exception($"Windows RTL configuration '{lTemplatePath}' contains an invalid import.");
      var lSourceFiles := lImport["Files"] as JsonArray;
      var lSourceIndirectFiles := lImport["IndirectFiles"] as JsonArray;
      var lFiles := FilterWindowsHeaderList(lSourceFiles, aAvailableHeaders);
      var lIndirectFiles := FilterWindowsHeaderList(lSourceIndirectFiles, aAvailableHeaders);
      lImport["Files"] := lFiles;
      lImport["IndirectFiles"] := lIndirectFiles;
      Log($"Windows {aArchitecture.Name} RTL configuration retained {lFiles.Count}/{coalesce(lSourceFiles:Count, 0)} primary and {lIndirectFiles.Count}/{coalesce(lSourceIndirectFiles:Count, 0)} indirect headers.");
      if (lImport["Files"] as JsonArray).Count = 0 then
        raise new Exception($"Windows RTL configuration '{lTemplatePath}' has no headers present in SDK {aLayout.Version}.");

      var lConfigPath := Path.Combine(aIntermediateFolder, $"windows-{aArchitecture.Name}-{aLayout.Version}.json");
      File.WriteText(lConfigPath, lConfiguration.ToString);
      result := lConfigPath as not nullable;
    end;

    method CreateWindowsRuntimeConfiguration(aArchitecture: not nullable WindowsSDKArchitecture;
                                             aLayout: not nullable WindowsSDKLayout;
                                             aIntermediateFolder: not nullable String;
                                             aRTLConfiguration: not nullable String): not nullable String;
    begin
      var lWinRTFolder := Path.Combine(aLayout.IncludeRoot, "winrt");
      // These are C++ implementation/helper surfaces, not C ABI declarations. The
      // corresponding entries in the previously shipped winrt.fx were empty.
      var lHeaders := Folder.GetFiles(lWinRTFolder, false)
                           .Where(aFile -> aFile.PathExtension.ToLowerInvariant = ".h")
                           .Where(aFile -> not (Path.GetFileName(aFile).ToLowerInvariant in ["wrl.h",
                                                                                           "roparameterizediid.h",
                                                                                           "windows.graphics.effects.interop.h",
                                                                                           "windows.graphics.interop.h",
                                                                                           "windows.ui.composition.interop.h"]))
                           .Select(aFile -> IslandSDKRelativePath(lWinRTFolder, aFile))
                           .OrderBy(aFile -> aFile, StringComparer.OrdinalIgnoreCase)
                           .ToList;
      if lHeaders.Count = 0 then
        raise new Exception($"No Windows Runtime headers were found below '{lWinRTFolder}'.");

      var lImport := JsonDocument.CreateObject;
      lImport["Name"] := "winrt";
      lImport["Framework"] := false;
      lImport["Prefix"] := "";
      lImport["Core"] := false;
      lImport["ForceNamespace"] := "rtl.winrt";
      lImport["Explicit"] := true;
      lImport["Files"] := new JsonArray;
      lImport["IndirectFiles"] := new JsonArray(lHeaders);
      lImport["DepFx"] := new JsonArray(["rtl"]);

      // Windows.h supplies the declarations and SAL definitions expected by several
      // otherwise non-self-contained WinRT headers. This matches the synthetic root
      // used for the currently shipped winrt.fx while discovering its dependents fresh.
      var lImportSpec := new StringBuilder;
      lImportSpec.AppendLine("#include <Windows.h>");
      for each lHeader in lHeaders do
        lImportSpec.AppendLine($"#include <{lHeader}>");
      lImport["ImportSpec"] := lImportSpec.ToString;

      var lConfiguration := JsonObject.FromString(File.ReadText(aRTLConfiguration));
      var lDefines := lConfiguration["Defines"] as JsonArray;
      var lImports := lConfiguration["Imports"] as JsonArray;
      if not assigned(lDefines) or not assigned(lImports) then
        raise new Exception($"Windows RTL configuration '{aRTLConfiguration}' is missing Defines or Imports.");
      lDefines.Add("interface=struct");
      lImports.Add(lImport);

      var lConfigPath := Path.Combine(aIntermediateFolder, $"windows-combined-{aArchitecture.Name}-{aLayout.Version}.json");
      File.WriteText(lConfigPath, lConfiguration.ToString);
      result := lConfigPath as not nullable;
    end;

    method RunWindowsHeaderImport(aConfiguration: not nullable String;
                                  aOutputFolder: not nullable String;
                                  aLayout: not nullable WindowsSDKLayout;
                                  aArchitecture: not nullable WindowsSDKArchitecture;
                                  aIncludeFolders: not nullable ImmutableList<String>);
    begin
      var lArguments := new List<String>;
      lArguments.Add("import");
      lArguments.Add($"--json={aConfiguration}");
      lArguments.Add($"--sdkversion={aLayout.Version}");
      lArguments.Add("-o", aOutputFolder);
      for each lIncludeFolder in aIncludeFolders do
        lArguments.Add("-i", lIncludeFolder);

      var lUMLibraryFolder := RequireIslandSDKFolder(Path.Combine(aLayout.LibraryRoot, "um", aArchitecture.MicrosoftName), $"Windows {aArchitecture.Name} UM import libraries");
      var lUCRTLibraryFolder := RequireIslandSDKFolder(Path.Combine(aLayout.LibraryRoot, "ucrt", aArchitecture.MicrosoftName), $"Windows {aArchitecture.Name} UCRT import libraries");
      lArguments.Add($"--libpath={lUMLibraryFolder}");
      lArguments.Add($"--libpath={lUCRTLibraryFolder}");
      if Debug then
        lArguments.Add("--debug");
      RunHI(lArguments) SDKFolder(aLayout.SDKRoot);
    end;

    method CopyWindowsSupportFiles(aArchitecture: not nullable WindowsSDKArchitecture;
                                   aOutputFolder: not nullable String);
    begin
      for each lGCFile in ["gc.fx", "gc.lib", "libgc.a"] do begin
        var lPath := Path.Combine(aOutputFolder, lGCFile);
        if lPath.FileExists then
          File.Delete(lPath);
      end;

      if length(WindowsSupportFilesFolder) = 0 then
        exit;
      var lSourceFolder := Path.Combine(RequireIslandSDKFolder(WindowsSupportFilesFolder, "Windows supplemental SDK files folder"), aArchitecture.Name);
      if not lSourceFolder.FolderExists then
        raise new Exception($"Windows supplemental SDK files for {aArchitecture.Name} were not found at '{lSourceFolder}'.");
      for each lFileName in ["java.fx"] do
        CopyIslandSDKFile(Path.Combine(lSourceFolder, lFileName), Path.Combine(aOutputFolder, lFileName));
    end;

    method ValidateWindowsFx(aPath: not nullable String;
                             aName: not nullable String;
                             aArchitecture: not nullable WindowsSDKArchitecture);
    begin
      RequireIslandSDKFile(aPath, $"Windows {aArchitecture.Name} {aName}.fx");
      var lFx := new FxFile;
      using lStream := new System.IO.FileStream(aPath, System.IO.FileMode.Open, System.IO.FileAccess.Read, System.IO.FileShare.Read) do
        lFx.Read(lStream);
      if lFx.Name <> aName then
        raise new Exception($"Windows {aArchitecture.Name} FX '{aPath}' is named '{lFx.Name}', expected '{aName}'.");
      if lFx.PlatformType <> FxPlatformType.Windows then
        raise new Exception($"Windows {aArchitecture.Name} FX '{aPath}' has platform '{lFx.Platform}', expected Windows.");
      if (lFx.TargetDescriptors.Count <> 1) or (lFx.TargetDescriptors[0] <> aArchitecture.Target) then
        raise new Exception($"Windows {aArchitecture.Name} FX '{aPath}' has the wrong CPU target.");
      if (lFx.Targets.Count <> 1) or (lFx.Targets[0].TargetString <> aArchitecture.TargetString) then
        raise new Exception($"Windows {aArchitecture.Name} FX '{aPath}' has target string '{if lFx.Targets.Count = 0 then "<none>" else lFx.Targets[0].TargetString}', expected '{aArchitecture.TargetString}'.");
    end;

    method ValidateWindowsSDK(aSDKFolder: not nullable String;
                              aArchitectures: not nullable ImmutableList<WindowsSDKArchitecture>);
    begin
      for each lArchitecture in aArchitectures do begin
        var lArchitectureFolder := Path.Combine(aSDKFolder, lArchitecture.Name);
        ValidateWindowsFx(Path.Combine(lArchitectureFolder, "rtl.fx"), "rtl", lArchitecture);
        if ImportWindowsRuntime then
          ValidateWindowsFx(Path.Combine(lArchitectureFolder, "winrt.fx"), "winrt", lArchitecture);
        for each lStandaloneFile in ["gc.fx", "gc.lib", "libgc.a", "sqlite3.fx", "sqlite3.lib"] do
          if Path.Combine(lArchitectureFolder, lStandaloneFile).FileExists then
            raise new Exception($"Windows {lArchitecture.Name} SDK must not contain '{lStandaloneFile}'; GC and SQLite are packaged separately.");
      end;
    end;

    method RemoveWindowsStandaloneLibraries(aSDKFolder: not nullable String;
                                             aArchitectures: not nullable ImmutableList<WindowsSDKArchitecture>);
    begin
      for each lArchitecture in aArchitectures do begin
        var lArchitectureFolder := RequireIslandSDKFolder(Path.Combine(aSDKFolder, lArchitecture.Name), $"Windows {lArchitecture.Name} SDK architecture folder");
        for each lFileName in ["gc.fx", "gc.lib", "libgc.a", "sqlite3.fx", "sqlite3.lib"] do begin
          var lPath := Path.Combine(lArchitectureFolder, lFileName);
          if lPath.FileExists then begin
            File.Delete(lPath);
            Log($"Removed standalone library artifact '{lPath}' from the Windows SDK.");
          end;
        end;
      end;
    end;

  public

    property WindowsSDKFolder: nullable String;
    property WindowsOutputFolder: nullable String;
    property WindowsMSVCFolder: nullable String;
    property WindowsNetFxSDKFolder: nullable String;
    property WindowsSDKVersion: nullable String;
    property WindowsIntermediateFolder: nullable String;
    property WindowsRTLConfigFolder: nullable String;
    property WindowsSupportFilesFolder: nullable String;
    property WindowsArchitectures: List<String> := new List<String>; readonly;
    property ImportWindowsRuntime := true;

    method ImportWindowsSDK;
    begin
      WindowsOutputFolder := Path.GetFullPath(WindowsOutputFolder);
      WindowsIntermediateFolder := if length(WindowsIntermediateFolder) > 0 then Path.GetFullPath(WindowsIntermediateFolder) else Path.Combine(WindowsOutputFolder, "Import Configurations");
      HI := RequireIslandSDKFile(HI, "HeaderImporter executable");
      Folder.Create(WindowsOutputFolder);
      Folder.Create(WindowsIntermediateFolder);

      var lLayout := ResolveWindowsSDKLayout;
      var lMSVCIncludeFolder := ResolveWindowsMSVCIncludeFolder;
      var lNetFxIncludeFolder: nullable String;
      if ImportWindowsRuntime then
        lNetFxIncludeFolder := ResolveWindowsNetFxIncludeFolder;
      var lIncludeFolders := WindowsIncludeFolders(lLayout, lMSVCIncludeFolder, lNetFxIncludeFolder);
      var lAvailableHeaders := WindowsHeaderNames(lIncludeFolders);
      var lArchitectures := ResolveWindowsArchitectures;

      var lSDKFolder := Path.Combine(WindowsOutputFolder, "Windows "+lLayout.Version);
      if lSDKFolder.FolderExists then
        System.IO.Directory.Delete(lSDKFolder, true);
      Folder.Create(lSDKFolder);

      Log($"Importing Windows SDK {lLayout.Version} for {String.Join(", ", lArchitectures.Select(aArchitecture -> aArchitecture.Name).ToList)}.");
      for each lArchitecture in lArchitectures do begin
        var lArchitectureFolder := Path.Combine(lSDKFolder, lArchitecture.Name);
        Folder.Create(lArchitectureFolder);
        var lConfiguration := CreateWindowsRTLConfiguration(lArchitecture, lLayout, lAvailableHeaders, WindowsIntermediateFolder);
        if ImportWindowsRuntime then
          lConfiguration := CreateWindowsRuntimeConfiguration(lArchitecture, lLayout, WindowsIntermediateFolder, lConfiguration);
        RunWindowsHeaderImport(lConfiguration, lArchitectureFolder, lLayout, lArchitecture, lIncludeFolders);
        CopyWindowsSupportFiles(lArchitecture, lArchitectureFolder);
      end;

      ValidateWindowsSDK(lSDKFolder, lArchitectures);
      if CreateZips then
        CreateDeterministicIslandSDKZip(lSDKFolder,
                                        Path.Combine(WindowsOutputFolder, "__Public", Path.GetFileName(lSDKFolder)+".zip"));
    end;

    method RepackageWindowsSDK(aSDKFolder: not nullable String);
    begin
      var lSDKFolder := RequireIslandSDKFolder(aSDKFolder, "Existing Windows Island SDK folder");
      var lArchitectures := ResolveWindowsArchitectures;
      RemoveWindowsStandaloneLibraries(lSDKFolder, lArchitectures);
      ValidateWindowsSDK(lSDKFolder, lArchitectures);
      if CreateZips then
        CreateDeterministicIslandSDKZip(lSDKFolder,
                                        Path.Combine(Path.GetParentDirectory(lSDKFolder), "__Public", Path.GetFileName(lSDKFolder)+".zip"));
    end;

  end;

end.
