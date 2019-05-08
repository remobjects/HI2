namespace RemObjects.Elements.HI2;

uses
  RemObjects.Elements.RTL,
  RemObjects.Elements.Basics;

type
  Importer = public partial class
  public
  protected
  public

    property SDKsBaseFolder: String read if Darwin.Island then Path.Combine(BaseFolder, "Darwin") else BaseFolder;

    property SkipDeploymentTargets := false;

    method ImportMacOSSDK();
    begin
      ImportSDK("macOS", Darwin.macOSVersion);
      CreateSDKZip("macOS", Darwin.macOSVersion);
    end;

    method ImportIOSSDK();
    begin
      ImportSDK("iOS", Darwin.iOSVersion, false);
      ImportSDK("iOS", Darwin.iOSVersion, true);
      CreateSDKZip("iOS", Darwin.iOSVersion);
    end;

    method ImportTvOSSDK();
    begin
      ImportSDK("tvOS", Darwin.tvOSVersion, false);
      ImportSDK("tvOS", Darwin.tvOSVersion, true);
      CreateSDKZip("tvOS", Darwin.tvOSVersion);
    end;

    method ImportWatchOSSDK();
    begin
      ImportSDK("watchOS", Darwin.watchOSVersion, false);
      ImportSDK("watchOS", Darwin.watchOSVersion, true);
      CreateSDKZip("watchOS", Darwin.watchOSVersion);
    end;

    method ImportSDK(aName: String; aVersion: String; aSimulator: Boolean := false);
    begin
      writeLn($"Import {aName} {aVersion} {if aSimulator then "Simulator"}");

      var lShortVersion := Darwin.ShortVersion(aVersion);
      var lInternalVersion := if aName = "watchOS" then Darwin.iOSVersion else aVersion;
      var lInternalShortVersion := Darwin.ShortVersion(lInternalVersion);
      var lSdkFolder := Darwin.SdkFolderInXcode(aName, lShortVersion, aSimulator);

      var lArchitectures := case aName of
        "macOS": Darwin.macOSArchitectures;
        "iOS": if aSimulator then Darwin.iOSSimulatorArchitectures else Darwin.iOSArchitectures;
        "tvOS": if aSimulator then Darwin.tvOSSimulatorArchitectures else Darwin.tvOSArchitectures;
        "watchOS": if aSimulator then Darwin.watchOSSimulatorArchitectures else Darwin.watchOSArchitectures;
      end;

      var lDeploymentTargets := case aName of
        "macOS": Darwin.macOSDeploymentTargets;
        "iOS": Darwin.iOSDeploymentTargets;
        "tvOS": Darwin.tvOSDeploymentTargets;
        "watchOS": Darwin.watchOSDeploymentTargets;
      end;

      method DefinesForVersion(v: String): String;
      begin
        var lEnvironmentVersionDefine := case aName of
          "macOS": Darwin.macOSEnvironmentVersionDefine;
          "iOS": Darwin.iOSEnvironmentVersionDefine;
          "tvOS": Darwin.tvOSEnvironmentVersionDefine;
          "watchOS": Darwin.watchOSEnvironmentVersionDefine;
        end;
        lEnvironmentVersionDefine := lEnvironmentVersionDefine+"="+Darwin.CalculateIntegerVersion(aName, lInternalShortVersion);
        var lDefines := lEnvironmentVersionDefine;
        if Darwin.Toffee then
          lDefines := lDefines+";"+Darwin.ExtraDefinesToffee
        else if Darwin.Island then
          lDefines := lDefines+";"+Darwin.ExtraDefinesIsland;
        result := lDefines;
      end;

      // below code is "processSDK()"

      var lTargetFolderName := aName+" "+lShortVersion;
      if aSimulator then
        lTargetFolderName := lTargetFolderName+" Simulator";

      var lTargetFolder := Path.Combine(SDKsBaseFolder, lTargetFolderName);
      if lTargetFolder.FolderExists then
        Folder.Delete(lTargetFolder);

      var lFrameworksFolder := Path.Combine(lSdkFolder, "System", "Library", "Frameworks");

      if not SkipDeploymentTargets then begin
        for each d in lDeploymentTargets.Split(";") do begin
          if d.CompareVersionTripleTo(aVersion) < 0 then begin
            for each (a, nil) in lArchitectures do begin
              if not assigned(a.MinimumDeploymentTarget) or (a.MinimumDeploymentTarget.CompareVersionTripleTo(d) ≤ 0) then begin
                var lDefines := a.Defines+";"+DefinesForVersion(d);

                // below code is "doProcessDeploymentTargetSDK(options.version, deploymentVersion, options.sdkFolder, architectures[a], defines, targetFolder, options.forceIncludes);"

                var lTargetFolderForArch := Path.Combine(lTargetFolder, a.Arch);
                Folder.create(lTargetFolderForArch);

                var lFrameworks := new List<String>("Foundation", "Security"); // iOS Simulator requires this from rtl/objc. We wont actually *use* the generated file

                RunHeaderImporterForSDK(lSdkFolder)
                                Version(lInternalVersion)
                          VersionString(aVersion+$" ({d})")
                           Architecture(a)
                             Frameworks(lFrameworks)
                                Defines(lDefines)
                           OutputFolder(lTargetFolderForArch);

                File.Move(Path.combine(lTargetFolderForArch, "rtl.fx"), Path.combine(lTargetFolderForArch, $"rtl-{d}.fx"));
                File.Delete(Path.combine(lTargetFolderForArch, "Foundation.fx"));
                File.Delete(Path.combine(lTargetFolderForArch, "Security.fx"));
              end;
            end;
          end;
        end;
      end;


      // main target
      for each (a, nil) in lArchitectures do begin
        if not assigned(a.MinimumTargetSDK) or (a.MinimumTargetSDK.CompareVersionTripleTo(aVersion) ≤ 0) then begin
          var lDefines := a.Defines+";"+DefinesForVersion(lInternalShortVersion);

          // below code is "doProcessSDK(options.internalVersion, options.version, options.sdkFolder,  architectures[a], defines, targetFolder, options.forceIncludes);"

          var lTargetFolderForArch := Path.Combine(lTargetFolder, a.Arch);
          Folder.create(lTargetFolderForArch);

          var lFrameworks := new List<String>();
          for each f in Folder.GetSubfolders(lFrameworksFolder) do begin
            if f.PathExtension = ".framework" then begin
              var lFrameworkName := f.LastPathComponentWithoutExtension;
              if not Darwin.IsInBlacklist(Darwin.FrameworksBlackList, lFrameworkName, lShortVersion, a) then
                lFrameworks.Add(lFrameworkName);
            end;
          end;

          RunHeaderImporterForSDK(lSdkFolder)
                          Version(lInternalVersion)
                    VersionString(aVersion)
                     Architecture(a)
                       Frameworks(lFrameworks)
                          Defines(lDefines)
                     OutputFolder(lTargetFolderForArch);
        end;
      end;

      MergeOrFlatten(lTargetFolder, lArchitectures.Select(a -> a[0]).ToList());
      //codegen(targetFolder);

      //var lForceIncldes := case aName of
        //"macOS": Darwin.forceIncludes_macOS
      //end;

    end;

    //
    //
    //

    method MergeOrFlatten(aTargetFolder: String; aArchitectures: ImmutableList<Architecture>);
    begin
      writeLn($"Merge or Flatten {aTargetFolder}");
      if aArchitectures.Count > 1 then
        Merge(aTargetFolder, aArchitectures)
      else if aArchitectures.Count = 1 then
        Flatten(aTargetFolder, aArchitectures.First);
    end;

    method Merge(aTargetFolder: String; aArchitectures: ImmutableList<Architecture>);
    begin
      var fx := Folder.GetFiles(Path.Combine(aTargetFolder, aArchitectures.First.Arch)).Where(f -> f.PathExtension = ".fx").Select(f -> f.LastPathComponent).ToList();

      for each f in fx do begin
        var lArgs := new List<String>;
        lArgs.Add("combine");
        lArgs.Add(Path.Combine(aTargetFolder, f));

        var lCount := 0;
        for each a in aArchitectures do begin
          var f2 := Path.Combine(aTargetFolder, a.Arch, f);
          if f2.FileExists then begin
            lArgs.Add(f2);
            inc(lCount);
          end;
        end;

        if lCount > 1 then begin
          RunHI(lArgs);
        end
        else begin
          for each a in aArchitectures do begin
            var f2 := Path.Combine(aTargetFolder, a.Arch, f);
            if f2.FileExists then
              File.CopyTo(f2, Path.Combine(aTargetFolder, f2.LastPathComponent));
          end;
        end;
      end;

      for each a in aArchitectures do
        Folder.Delete(Path.Combine(aTargetFolder, a.Arch));
    end;

    method Flatten(aTargetFolder: String; aArchitecture: Architecture);
    begin
      var lSubfolder := Path.Combine(aTargetFolder, aArchitecture.Arch);
      for each f in Folder.GetFiles(lSubfolder).Where(f -> f.PathExtension = ".fx") do
        File.Move(f, Path.Combine(aTargetFolder, f.LastPathComponent));
      Folder.Delete(lSubfolder);
    end;

    //
    //
    //

    method RunHeaderImporterForSDK(aSDKFolder: String)
                           Version(aVersion: String)
                     VersionString(aVersionString: String)
                      Architecture(aArchitecture: Architecture)
                        Frameworks(aFrameworks: ImmutableList<String>)
                           Defines(aDefines: String)
                      OutputFolder(aOutputFolder: String);
    begin
      var lShortVersion := Darwin.ShortVersion(aVersion);

      var lFrameworksFolder := Path.Combine(aSDKFolder, "System", "Library", "Frameworks");

      var lTargetString := aArchitecture.Triple;
      if length(aArchitecture.CpuType) > 0 then
      lTargetString := lTargetString+";"+aArchitecture.CpuType;

      const ImportDefsJson_String = '[ {"Name": "dyld_stub_binder", "Library": "/usr/lib/libSystem.B.dylib", "Version": "81395766,65536" }, {"Name": "__Unwind_Resume", "Library": "/usr/lib/system/libunwind.dylib", "Version": "2294784,0"}, {"Name": "_stack_chk_fail", "Library": "/usr/lib/system/libsystem_c.dylib", "Version": "83413012,0"}, {"Name": "____toupper_l", "Library": "/usr/lib/system/libsystem_c.dylib", "Version": "83413012,0"}, {"Name": "____tolower_l", "Library": "/usr/lib/system/libsystem_c.dylib", "Version": "83413012,0"}, {"Name": "__DefaultRuneLocale", "Library": "/usr/lib/system/libsystem_c.dylib", "Version": "83413012,0"}, {"Name": "_strtoul", "Library": "/usr/lib/system/libsystem_c.dylib", "Version": "83413012,0"}, {"Name": "__dyld_image_count", "Library": "/usr/lib/system/libdyld.dylib", "Version": "40633088,0"}, {"Name": "_abort", "Library": "/usr/lib/system/libsystem_c.dylib", "Version": "83413012,0"}, {"Name": "__dyld_bind_fully_image_containing_address", "Library": "/usr/lib/system/libdyld.dylib", "Version": "40633088,0"}, {"Name": "_pthread_atfork", "Library": "/usr/lib/system/introspection/libsystem_pthread.dylib", "Version": "21678110,0"}, {"Name": "_pthread_setcancelstate", "Library": "/usr/lib/system/introspection/libsystem_pthread.dylib", "Version": "21678110,0"}, {"Name": "__setjmp", "Library": "/usr/lib/system/libsystem_platform.dylib", "Version": "11651079,0"}, {"Name": "_task_set_exception_ports", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_atoi", "Library": "/usr/lib/system/libsystem_c.dylib", "Version": "83413012,0"}, {"Name": "_atol", "Library": "/usr/lib/system/libsystem_c.dylib", "Version": "83413012,0"}, {"Name": "_sysctl", "Library": "/usr/lib/system/libsystem_c.dylib", "Version": "83413012,0"}, {"Name": "_bcopy", "Library": "/usr/lib/system/libsystem_c.dylib", "Version": "83413012,0"}, {"Name": "_pthread_get_stackaddr_np", "Library": "/usr/lib/system/introspection/libsystem_pthread.dylib", "Version": "21678110,0"}, {"Name": "_get_end", "Library": "/usr/lib/system/libmacho.dylib", "Version": "59899904,0"}, {"Name": "_vm_protect", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_write", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_pthread_join", "Library": "/usr/lib/system/introspection/libsystem_pthread.dylib", "Version": "21678110,0"}, {"Name": "_mach_task_self_", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_clock", "Library": "/usr/lib/system/libsystem_c.dylib", "Version": "83413012,0"}, {"Name": "_thread_get_state", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_pthread_attr_getdetachstate", "Library": "/usr/lib/system/introspection/libsystem_pthread.dylib", "Version": "21678110,0"}, {"Name": "_exc_server", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_mach_port_allocate", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_mach_port_insert_right", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_get_etext", "Library": "/usr/lib/system/libmacho.dylib", "Version": "59899904,0"}, {"Name": "_mach_thread_self", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_task_threads", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_exception_raise_state_identity", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_exception_raise", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_thread_resume", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "__dyld_register_func_for_add_image", "Library": "/usr/lib/system/libdyld.dylib", "Version": "40633088,0"}, {"Name": "__dyld_get_image_header", "Library": "/usr/lib/system/libdyld.dylib", "Version": "40633088,0"}, {"Name": "_thread_suspend", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_mach_error_string", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_snprintf", "Library": "/usr/lib/system/libsystem_c.dylib", "Version": "83413012,0"}, {"Name": "_exception_raise_state", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_pthread_attr_init", "Library": "/usr/lib/system/introspection/libsystem_pthread.dylib", "Version": "21678110,0"}, {"Name": "_vm_deallocate", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_getpagesize", "Library": "/usr/lib/system/libsystem_c.dylib", "Version": "83413012,0"}, {"Name": "_vsnprintf", "Library": "/usr/lib/system/libsystem_c.dylib", "Version": "83413012,0"}, {"Name": "_signal", "Library": "/usr/lib/system/libsystem_c.dylib", "Version": "83413012,0"}, {"Name": "_pthread_attr_destroy", "Library": "/usr/lib/system/introspection/libsystem_pthread.dylib", "Version": "21678110,0"}, {"Name": "_thread_set_state", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_munmap", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_task_get_exception_ports", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_mmap", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_mach_msg", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "__dyld_get_image_name", "Library": "/usr/lib/system/libdyld.dylib", "Version": "40633088,0"}, {"Name": "__dyld_register_func_for_remove_image", "Library": "/usr/lib/system/libdyld.dylib", "Version": "40633088,0"}, {"Name": "_thread_info", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_getsectbynamefromheader_64", "Library": "/usr/lib/system/libmacho.dylib", "Version": "59899904,0"}, {"Name": "_mach_port_deallocate", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_pthread_attr_setdetachstate", "Library": "/usr/lib/system/introspection/libsystem_pthread.dylib", "Version": "21678110,0"}]';
      var lImportDefsJson := JsonDocument.FromString(ImportDefsJson_String).Root;


      var lJsonImports := new JsonArray();
      for each f in aFrameworks do begin
        var lFrameworkJson := new JsonObject();
        lFrameworkJson["Name"] := new JsonStringValue(f);
        lFrameworkJson["Framework"] := new JsonBooleanValue(true);
        lFrameworkJson["Prefix"] := "";
        if f = "Foundation" then
          lFrameworkJson["DropPrefixes"] := new JsonArray(["NS"]);
        if f = "Cocoa" then
          lFrameworkJson["DepFx"] := new JsonArray(["Foundation", "AppKit", "CoreGraphics", "CoreFoundation"])
        else if f in ["AppKit", "UIKit"] then
          lFrameworkJson["DepFx"] := new JsonArray(["Foundation", "CoreGraphics", "CoreFoundation"]);
        lJsonImports.Add(lFrameworkJson);
      end;

      var lRtlFramework := new JsonObject();
      lRtlFramework["Name"] := "rtl";
      lRtlFramework["Framework"] := false;
      lRtlFramework["Prefix"] := "";
      lRtlFramework["Core"] := true;
      lRtlFramework["ForceNamespace"] := "rtl";
      lRtlFramework["DropPrefixes"] := new JsonArray(["NS"]);
      lRtlFramework["Files"] := new JsonArray(Darwin.GetRTLFiles(lShortVersion, aArchitecture));
      lRtlFramework["IndirectFiles"] := new JsonArray(Darwin.GetIndirectRTLFiles(lShortVersion, aArchitecture));
      lRtlFramework["ImportDefs"] := lImportDefsJson;
      lJsonImports.Add(lRtlFramework);

      var lBlacklist := Darwin.FilterBlacklist(Darwin.IncludeHeaderBlackList.ToList(), lShortVersion, aArchitecture);
      //if (options.headerBlackList)
        //lBlacklist.Add(options.headerBlackList);

      var lJsonDocument := JsonDocument.CreateDocument();
      var lJson := lJsonDocument.Root;
      lJson["TargetString"] := lTargetString;
      lJson["Version"] := aVersion;
      lJson["SDKVersionString"] := aVersionString;
      lJson["Imports"] := lJsonImports;
      lJson["Defines"] := new JsonArray(aDefines.Split(";", true));
      lJson["Blacklist"] := new JsonArray(lBlacklist);
      lJson["ForceInclude"] := Darwin.GetForceIncludeFiles(lShortVersion, aArchitecture);
      lJson["Mobile"] := (aArchitecture.SDKName ≠ "macOS");
      lJson["Platform"] := if Darwin.Island then "Darwin" else aArchitecture.SDKName;
      lJson["SDKName"] := aArchitecture.SDKName;//if aArchitecture.SDKName = "macOS" then "OS X" else aArchitecture.SDKName;
      lJson["Island"] := Darwin.Island;
      var lOverride1 := new JsonObject(); lOverride1["Key"] := "objc/NSObject.h";      lOverride1["Value"] := "Foundation";
      var lOverride2 := new JsonObject(); lOverride2["Key"] := "objc/NSObjCRuntime.h"; lOverride2["Value"] := "Foundation";
      lJson["OverrideNamespace"] := new JsonArray([lOverride1, lOverride2]);

      lJson["VirtualFiles"] := new JsonObject();
      lJson["VirtualFiles"]["os/availibility.h"] := "#include <os/availability.h>";

      var lJsonName := $"import-{Darwin.Mode}-{aArchitecture.SDKName}{if aArchitecture.Simulator then "-Simulator"}-{aVersionString}-{aOutputFolder.LastPathComponent}.json";
      lJsonName := Path.Combine(SDKsBaseFolder, lJsonName);
      File.WriteText(lJsonName, lJsonDocument.ToString());

      if Debug then
        writeLn(lJsonDocument);

      var lArgs := new List<String>;
      lArgs.Add("import");
      lArgs.Add($"--json={lJsonName}");
      lArgs.Add("-o", aOutputFolder);

      lArgs.Add($"-i", Path.Combine(aSDKFolder, "usr", "include"));
      lArgs.Add($"-f", lFrameworksFolder);
      lArgs.Add($"-i", SDKsBaseFolder);

      //for each n in options.includepaths do
        //lArgs.Add("-i", n);
      //for each n in options.frameworkpaths do
        //lArgs.Add("-f", n);
      //for each n in options.nonframeworks do
        //lArgs.Add("-c", n);
      //for each n in options.link do
        //lArgs.Add("-l" , n);
      //if (more)
        //s += " "+more;

      lArgs.Add($"--libpath="+Path.Combine(aSDKFolder, "usr", "lib"));

      if Debug then
        lArgs.Add("--debug");

      RunHI(lArgs);

      //if (doDeleteJsonFiles)
        //file.remove(jsonName);
      //}
    end;

    //
    //
    //

    method CreateSDKZip(aName: String; aVersion: String);
    begin
      //aName := if aName = "macOS" then Darwin.NameForMacOS(aVersion) else aName;

      var lShortVersion := Darwin.ShortVersion(aVersion);
      var lSuffix := if lShortVersion ≠ aVersion then "("+aVersion+")" else "";
      if length(Darwin.BetaSuffix) > 0 then begin
        lSuffix := (lSuffix+" "+Darwin.BetaSuffix).Trim;
      end;
      if length(lSuffix) > 0 then
        lSuffix := " - "+lSuffix;

      var lTargetFolderName := aName+" "+lShortVersion;
      //var lTargetFolderName2 := lTargetFolderName+" Simulator";

      //var lTargetFolder := Path.Combine(SDKsBaseFolder, lTargetFolderName);
      //var lTargetFolder2 := Path.Combine(SDKsBaseFolder, lTargetFolderName2);

      if defined("ECHOES") and CreateZips then begin
        Folder.Create(Path.Combine(SDKsBaseFolder, "__CI2Shared"));
        Folder.Create(Path.Combine(SDKsBaseFolder, "__Public"));

        var lTargetZipName := Path.Combine(SDKsBaseFolder, "__CI2Shared", lTargetFolderName)+".zip";
        var lTargetZipName3 := Path.Combine(SDKsBaseFolder, "__CI2Shared", lTargetFolderName)+" Simulator.zip";
        var lTargetZipName2 := Path.Combine(SDKsBaseFolder, "__Public", lTargetFolderName)+lSuffix+".zip";
        writeLn($"Creating {lTargetZipName}");
        CreateZip(lTargetFolder, lTargetZipName);
        if aName = "macOS" then begin
          File.CopyTo(lTargetZipName, lTargetZipName2);
        end
        else begin
          writeLn($"Creating {lTargetZipName3}");
          CreateZip(lTargetFolder+" Simulator", lTargetZipName3);
          writeLn($"Creating {lTargetZipName2}");
          CreateZip([lTargetFolder, lTargetFolder2], lTargetZipName2);
        end;
      end;
    end;

    {$IF ECHOES}
    method CreateZip(aFolder: String; aZipFilePath: String);
    begin
      using lFile := new Ionic.Zip.ZipFile() do begin
        lFile.AddDirectory(aFolder, aFolder.LastPathComponent);
        lFile.Save(aZipFilePath);
      end;
    end;

    method CreateZip(aFolders: array of String; aZipFilePath: String);
    begin
      using lFile := new Ionic.Zip.ZipFile() do begin
        for each f in aFolders do
          lFile.AddDirectory(f, f.LastPathComponent);
        lFile.Save(aZipFilePath);
      end;
    end;
    {$ENDIF}

  end;

end.