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
    property SkipNonEssentialFrameworks := false;
    property SkipSwift := false;
    property SwiftOnly := false;

    property SkipHI := false;

    property SkipMacOS := false;
    property SkipMacCatalyst := false;
    property SkipDriverKit := false;
    property SkipIOS := false;
    property SkipTvOS := false;
    property SkipWatchOS := false;
    property SkipDevice := false;
    property SkipSimulator := false;

    property DontClean := false;
    property GenerateCode := false;

    method ImportMacOSSDK();
    begin
      //GenerateCode("macOS", Darwin.macOSVersion);
      //exit;
      if not SkipMacOS then begin
        ImportSDK("macOS", Darwin.macOSVersion);
        CreateSDKZip("macOS", Darwin.macOSVersion);
      end;
    end;

    method ImportMacCatalyst();
    begin
      if not SkipMacCatalyst then begin
        ImportSDK("Mac Catalyst", Darwin.iOSVersion) RootSDK("macOS", Darwin.macOSVersion);
        CreateSDKZip("Mac Catalyst", Darwin.iOSVersion);
      end;
    end;

    method ImportDriverKitSDK();
    begin
      if not SkipDriverKit then begin
        ImportSDK("DriverKit", Darwin.DriverKitVersion);
        CreateSDKZip("DriverKit", Darwin.DriverKitVersion);
      end;
    end;

    method ImportIOSSDK();
    begin
      if not SkipIOS then begin
        if not SkipDevice then
          ImportSDK("iOS", Darwin.iOSVersion, false);
        if not SkipSimulator then
          ImportSDK("iOS", Darwin.iOSVersion, true);
        CreateSDKZip("iOS", Darwin.iOSVersion);
      end;
    end;

    method ImportTvOSSDK();
    begin
      if not SkipTvOS then begin
        if not SkipDevice then
          ImportSDK("tvOS", Darwin.tvOSVersion, false);
        if not SkipSimulator then
          ImportSDK("tvOS", Darwin.tvOSVersion, true);
        CreateSDKZip("tvOS", Darwin.tvOSVersion);
      end;
    end;

    method ImportWatchOSSDK();
    begin
      if not SkipWatchOS then begin
        if not SkipDevice then
          ImportSDK("watchOS", Darwin.watchOSVersion, false);
        if not SkipSimulator then
          ImportSDK("watchOS", Darwin.watchOSVersion, true);
        CreateSDKZip("watchOS", Darwin.watchOSVersion);
      end;
    end;

    method ImportSDK(aName: String; aVersion: String; aSimulator: Boolean := false) RootSDK(aRootSDKName: String := nil; aRootSDKVersion: String := nil);
    begin
      writeLn($"Import {aName} {aVersion} {if aSimulator then "Simulator"}");

      var lShortVersion := Darwin.ShortVersion(aVersion);
      var lInternalVersion := if aName = "watchOS" then Darwin.iOSVersion else aVersion;
      var lInternalShortVersion := Darwin.ShortVersion(lInternalVersion);
      var lSdkFolder := Darwin.SdkFolderInXcode(aName, coalesce(aRootSDKVersion, lShortVersion), aSimulator);

      var lArchitectures := case aName of
        "macOS": Darwin.macOSArchitectures;
        "Mac Catalyst": Darwin.MacCatalystArchitectures;
        "DriverKit": Darwin.DriverKitArchitectures;
        "iOS": if aSimulator then Darwin.iOSSimulatorArchitectures else Darwin.iOSArchitectures;
        "tvOS": if aSimulator then Darwin.tvOSSimulatorArchitectures else Darwin.tvOSArchitectures;
        "watchOS": if aSimulator then Darwin.watchOSSimulatorArchitectures else Darwin.watchOSArchitectures;
      end;

      method DefinesForVersion(v: String): String;
      begin
        var lEnvironmentVersionDefine := case aName of
          "macOS": Darwin.macOSEnvironmentVersionDefine;
          "Mac Catalyst": Darwin.iOSEnvironmentVersionDefine;
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
      if lTargetFolder.FolderExists and not DontClean then
        Folder.Delete(lTargetFolder);

      var lFrameworksFolders := new List<String>(Path.Combine(lSdkFolder, "System", "Library", "Frameworks"));
      case aName of
        "Mac Catalyst": lFrameworksFolders.Insert(0, Path.Combine(lSdkFolder, "System", "iOSSupport", "System", "Library", "Frameworks")); // add as first!!
        "DriverKit": lFrameworksFolders.ReplaceAt(0, Path.Combine(lSdkFolder, "System", "DriverKit", "System", "Library", "Frameworks"));
      end;

      var lUsrLibFolders :=  new List<String>(Path.Combine(lSdkFolder, "usr", "lib"));
      case aName of
        "Mac Catalyst": lUsrLibFolders.Add(      Path.Combine(lSdkFolder, "System", "iOSSupport", "usr", "lib")); // add as second!!!
        "DriverKit": lUsrLibFolders.ReplaceAt(0, Path.Combine(lSdkFolder, "System", "DriverKit", "usr", "lib"));
        else ;
      end;

      var lUsrIncludeFolder := case aName of
        //"Mac Catalyst": Path.Combine(lSdkFolder, "System", "iOSSupport", "usr", "include");
        "DriverKit": Path.Combine(lSdkFolder, "System", "DriverKit", "usr", "include");
        else Path.Combine(lSdkFolder, "usr", "include");
      end;

      if not SkipDeploymentTargets then begin
        for each (a, nil) in lArchitectures do begin
          for each d in Darwin.DeploymentTargets(aName, a.Arch):Split(";") do begin
            if d.CompareVersionTripleTo(aVersion) < 0 then begin
              if not assigned(a.MinimumDeploymentTarget) or (a.MinimumDeploymentTarget.CompareVersionTripleTo(d) ≤ 0) then begin
                var lDefines := a.Defines+";"+DefinesForVersion(d);

                // below code is "doProcessDeploymentTargetSDK(options.version, deploymentVersion, options.sdkFolder, architectures[a], defines, targetFolder, options.forceIncludes);"

                var lTargetFolderForArch := Path.Combine(lTargetFolder, a.Arch);
                Folder.Create(lTargetFolderForArch);
                if not Darwin.Toffee and not SkipSwift then
                  Folder.Create(Path.Combine(lTargetFolderForArch, "Swift"));

                var lFrameworks := new List<String>("Foundation", "Security"); // iOS Simulator requires this from rtl/objc. We wont actually *use* the generated file

                RunHeaderImporterForSDK(lSdkFolder)
                                   Name(aName)
                      FrameworksFolders(lFrameworksFolders)
                          UsrLibFolders(lUsrLibFolders)
                       UsrIncludeFolder(lUsrIncludeFolder)
                                Version(lInternalVersion)
                          VersionString(aVersion+$" ({d})")
                           Architecture(a)
                             Frameworks(lFrameworks)
                                Defines(lDefines)
                           OutputFolder(lTargetFolderForArch);

                File.Move(Path.Combine(lTargetFolderForArch, "rtl.fx"), Path.Combine(lTargetFolderForArch, $"rtl-{d}.fx"));
                for each f in Folder.GetFiles(lTargetFolderForArch) do
                  if (f.PathExtension = ".fx") and (not f.LastPathComponent.StartsWith("rtl")) then
                    File.Delete(f);
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
          Folder.Create(lTargetFolderForArch);
          if not Darwin.Toffee and not SkipSwift then
            Folder.Create(Path.Combine(lTargetFolderForArch, "Swift"));

          var lFrameworks := new List<String>();
          for each f2 in lFrameworksFolders do begin
            for each f in Folder.GetSubfolders(f2) do begin
              if f.PathExtension = ".framework" then begin
                var lFrameworkName := f.LastPathComponentWithoutExtension;

                if SkipNonEssentialFrameworks and (lFrameworkName not in Darwin.EssentialFrameworks) then begin
                  writeLn($"Skipping {lFrameworkName}, it's non-essential");
                  continue;
                end;

                if not lFrameworks.Contains(lFrameworkName) and not Darwin.IsInBlacklist(Darwin.FrameworksBlackList, lFrameworkName, lShortVersion, a) then
                  lFrameworks.Add(lFrameworkName);
              end;
            end;
          end;

          RunHeaderImporterForSDK(lSdkFolder)
                             Name(aName)
                FrameworksFolders(lFrameworksFolders)
                    UsrLibFolders(lUsrLibFolders)
                 UsrIncludeFolder(lUsrIncludeFolder)
                          Version(lInternalVersion)
                          RootSDK(if assigned(aRootSDKName) then aRootSDKName+" "+aRootSDKVersion else nil)
                    VersionString(aVersion)
                     Architecture(a)
                       Frameworks(lFrameworks)
                          Defines(lDefines)
                     OutputFolder(lTargetFolderForArch);
        end;
      end;

      MergeOrFlatten(lTargetFolder, lArchitectures.Select(a -> a[0]).ToList());
      MergeSwift(lTargetFolder);
      //codegen(targetFolder);

      if GenerateCode then
        GenerateCode(aName, aVersion);

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

      var lKnownFiles := new List<String>;
      for each a in aArchitectures do begin
        var fx := Folder.GetFiles(Path.Combine(aTargetFolder, a.Arch)).Where(f -> f.PathExtension = ".fx").Select(f -> f.LastPathComponent).ToList();
        lKnownFiles.Add(fx);

        if Path.Combine(aTargetFolder, a.Arch, "Swift").FolderExists then begin
          Folder.Create(Path.Combine(aTargetFolder, "Swift"));
          fx := Folder.GetFiles(Path.Combine(aTargetFolder, a.Arch, "Swift")).Where(f -> f.PathExtension = ".fx").Select(f -> Path.Combine("Swift", f.LastPathComponent)).ToList();
          lKnownFiles.Add(fx);
        end;
      end;

      for each f in lKnownFiles.Distinct do begin
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
            if f2.FileExists then begin
              File.CopyTo(f2, Path.Combine(aTargetFolder, f2.LastPathComponent));
              writeLn($"Copy {f2}");
            end;
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

      var lSwiftSubfolder := Path.Combine(lSubfolder, "Swift");
      if lSwiftSubfolder.FolderExists then begin
        Folder.Create(Path.Combine(aTargetFolder, "Swift"));
        for each f in Folder.GetFiles(lSwiftSubfolder).Where(f -> f.PathExtension = ".fx") do
          File.Move(f, Path.Combine(aTargetFolder, "Swift", f.LastPathComponent));
      end;

      Folder.Delete(lSubfolder);
    end;

    method MergeSwift(aTargetFolder: String);
    begin
      var lSwiftFolder := Path.Combine(aTargetFolder, "Swift");
      if lSwiftFolder.FolderExists then begin
        for each f in Folder.GetFiles(lSwiftFolder) do begin
          if Path.Combine(aTargetFolder, f.LastPathComponent).FileExists then
            {no-op, real merge will happen later}
          else
            File.Move(f, Path.Combine(aTargetFolder, f.LastPathComponent));
        end;
        if Folder.GetFiles(lSwiftFolder).Count = 0 then
          Folder.Delete(lSwiftFolder);
      end;
    end;

    //
    //
    //

    method RunHeaderImporterForSDK(aSDKFolder: String)
                              Name(aName: String)
                 FrameworksFolders(aFrameworksFolders: List<String>)
                     UsrLibFolders(aUsrLibFolders: List<String>)
                  UsrIncludeFolder(aUsrIncludeFolder: String)
                           Version(aVersion: String)
                           RootSDK(aRootSDK: String := nil)
                     VersionString(aVersionString: String)
                      Architecture(aArchitecture: Architecture)
                        Frameworks(aFrameworks: ImmutableList<String>)
                           Defines(aDefines: String)
                      OutputFolder(aOutputFolder: String);
    begin
      var lShortVersion := Darwin.ShortVersion(aVersion);
      var lDeploymentTargetsOnly := (aFrameworks.Count > 5); // bit of a hack, for now

      var lTargetString := aArchitecture.Triple;
      if length(aArchitecture.CpuType) > 0 then
        lTargetString := lTargetString+";"+aArchitecture.CpuType;

      const ImportDefsJson_String = '[ {"Name": "dyld_stub_binder", "Library": "/usr/lib/libSystem.B.dylib", "Version": "81395766,65536" }, {"Name": "__Unwind_Resume", "Library": "/usr/lib/system/libunwind.dylib", "Version": "2294784,0"}, {"Name": "_stack_chk_fail", "Library": "/usr/lib/system/libsystem_c.dylib", "Version": "83413012,0"}, {"Name": "____toupper_l", "Library": "/usr/lib/system/libsystem_c.dylib", "Version": "83413012,0"}, {"Name": "____tolower_l", "Library": "/usr/lib/system/libsystem_c.dylib", "Version": "83413012,0"}, {"Name": "__DefaultRuneLocale", "Library": "/usr/lib/system/libsystem_c.dylib", "Version": "83413012,0"}, {"Name": "_strtoul", "Library": "/usr/lib/system/libsystem_c.dylib", "Version": "83413012,0"}, {"Name": "__dyld_image_count", "Library": "/usr/lib/system/libdyld.dylib", "Version": "40633088,0"}, {"Name": "_abort", "Library": "/usr/lib/system/libsystem_c.dylib", "Version": "83413012,0"}, {"Name": "__dyld_bind_fully_image_containing_address", "Library": "/usr/lib/system/libdyld.dylib", "Version": "40633088,0"}, {"Name": "_pthread_atfork", "Library": "/usr/lib/system/libsystem_pthread.dylib", "Version": "21678110,0"}, {"Name": "_pthread_setcancelstate", "Library": "/usr/lib/system/libsystem_pthread.dylib", "Version": "21678110,0"}, {"Name": "__setjmp", "Library": "/usr/lib/system/libsystem_platform.dylib", "Version": "11651079,0"}, {"Name": "_task_set_exception_ports", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_atoi", "Library": "/usr/lib/system/libsystem_c.dylib", "Version": "83413012,0"}, {"Name": "_atol", "Library": "/usr/lib/system/libsystem_c.dylib", "Version": "83413012,0"}, {"Name": "_sysctl", "Library": "/usr/lib/system/libsystem_c.dylib", "Version": "83413012,0"}, {"Name": "_bcopy", "Library": "/usr/lib/system/libsystem_c.dylib", "Version": "83413012,0"}, {"Name": "_pthread_get_stackaddr_np", "Library": "/usr/lib/system/libsystem_pthread.dylib", "Version": "21678110,0"}, {"Name": "_get_end", "Library": "/usr/lib/system/libmacho.dylib", "Version": "59899904,0"}, {"Name": "_vm_protect", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_write", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_pthread_join", "Library": "/usr/lib/system/libsystem_pthread.dylib", "Version": "21678110,0"}, {"Name": "_mach_task_self_", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_clock", "Library": "/usr/lib/system/libsystem_c.dylib", "Version": "83413012,0"}, {"Name": "_thread_get_state", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_pthread_attr_getdetachstate", "Library": "/usr/lib/system/libsystem_pthread.dylib", "Version": "21678110,0"}, {"Name": "_exc_server", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_mach_port_allocate", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_mach_port_insert_right", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_get_etext", "Library": "/usr/lib/system/libmacho.dylib", "Version": "59899904,0"}, {"Name": "_mach_thread_self", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_task_threads", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_exception_raise_state_identity", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_exception_raise", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_thread_resume", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "__dyld_register_func_for_add_image", "Library": "/usr/lib/system/libdyld.dylib", "Version": "40633088,0"}, {"Name": "__dyld_get_image_header", "Library": "/usr/lib/system/libdyld.dylib", "Version": "40633088,0"}, {"Name": "_thread_suspend", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_mach_error_string", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_snprintf", "Library": "/usr/lib/system/libsystem_c.dylib", "Version": "83413012,0"}, {"Name": "_exception_raise_state", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_pthread_attr_init", "Library": "/usr/lib/system/libsystem_pthread.dylib", "Version": "21678110,0"}, {"Name": "_vm_deallocate", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_getpagesize", "Library": "/usr/lib/system/libsystem_c.dylib", "Version": "83413012,0"}, {"Name": "_vsnprintf", "Library": "/usr/lib/system/libsystem_c.dylib", "Version": "83413012,0"}, {"Name": "_signal", "Library": "/usr/lib/system/libsystem_c.dylib", "Version": "83413012,0"}, {"Name": "_pthread_attr_destroy", "Library": "/usr/lib/system/libsystem_pthread.dylib", "Version": "21678110,0"}, {"Name": "_thread_set_state", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_munmap", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_task_get_exception_ports", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_mmap", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_mach_msg", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "__dyld_get_image_name", "Library": "/usr/lib/system/libdyld.dylib", "Version": "40633088,0"}, {"Name": "__dyld_register_func_for_remove_image", "Library": "/usr/lib/system/libdyld.dylib", "Version": "40633088,0"}, {"Name": "_thread_info", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_getsectbynamefromheader_64", "Library": "/usr/lib/system/libmacho.dylib", "Version": "59899904,0"}, {"Name": "_mach_port_deallocate", "Library": "/usr/lib/system/libsystem_kernel.dylib", "Version": "321374407,0"}, {"Name": "_pthread_attr_setdetachstate", "Library": "/usr/lib/system/libsystem_pthread.dylib", "Version": "21678110,0"}]';
      var lImportDefsJson := JsonDocument.FromString(ImportDefsJson_String).Root;

      var lToolchainFolder := Path.GetFullPath(Path.Combine(aSDKFolder, "..", "..", "..",  "..", "..", "Toolchains", "XcodeDefault.xctoolchain"));

      method FixSSDKPath(aPath: String): String;
      begin
        result := aPath;
        if result.StartsWith(aSDKFolder) then
          result := "{sdk}/"+result.Substring(length(aSDKFolder)).TrimStart(['/','\']);
      end;

      method FixToolchainPath(aPath: String): String;
      begin
        result := aPath;
        if result.StartsWith(lToolchainFolder) then
          result := "{toolchain}/"+result.Substring(length(lToolchainFolder)).TrimStart(['/','\']);
      end;

      var lJsonImports := new JsonArray();
      for each f in aFrameworks.OrderBy(f -> f.ToLowerInvariant) do begin

        var lFrameworkJson := new JsonObject();
        lFrameworkJson["Name"] := f;
        lFrameworkJson["Framework"] := true;
        lFrameworkJson["Prefix"] := "";
        if f = "Foundation" then
          lFrameworkJson["DropPrefixes"] := new JsonArray(["NS"]);
        if f = "Cocoa" then
          lFrameworkJson["DepFx"] := new JsonArray(["Foundation", "AppKit", "CoreGraphics", "CoreFoundation"])
        else if f in ["AppKit", "UIKit"] then
          lFrameworkJson["DepFx"] := new JsonArray(["Foundation", "CoreGraphics", "CoreFoundation"]);

        var lFrameworkFolder := aFrameworksFolders.Select(f2 -> Path.Combine(f2, f+".framework")).Where(f2 -> f2.FolderExists).FirstOrDefault;
        if assigned(lFrameworkFolder) then begin
          lFrameworkJson["FrameworkPath"] := FixSSDKPath(lFrameworkFolder);
          var lSwiftInterfaces := Folder.GetFiles(lFrameworkFolder, true).Where(f2 -> f2.PathExtension = ".swiftinterface").ToList;
          if lSwiftInterfaces.Count > 0 then begin
            if f.StartsWith("_") /*and f.EndsWith("_SwiftUI")*/ then begin
              lFrameworkJson["SwiftHelperFramework"] := true;
              if Darwin.Toffee or SkipSwift then
                continue;
            end;
            if Darwin.Toffee then begin
              writeLn($"Skipping {f.LastPathComponentWithoutExtension} for Toffee, it's a Swift Framework");
              continue;
            end
            else if SkipSwift then begin
              writeLn($"Skipping {f.LastPathComponentWithoutExtension}, it's a Swift Framework");
              continue;
            end
            else if Darwin.Island then begin
              lFrameworkJson["Swift"] := true;
              var lPath := Path.Combine(lFrameworkFolder, "Modules", $"{f}.swiftmodule");
              if lPath.FolderExists then
                lFrameworkJson["SwiftModule"] := FixSSDKPath(lPath);
              lPath := Path.Combine(lPath, $"{aArchitecture.Arch}.swiftinterface");
              if lPath.FileExists then
                lFrameworkJson["SwiftInterface"] := FixSSDKPath(lPath);
            end;
          end
          else begin
            if SwiftOnly then
              continue;
          end;
          var lApiNotes := Path.Combine(lFrameworkFolder, "Headers", f.LastPathComponentWithoutExtension+".apinotes");
          if lApiNotes.FileExists then
            lFrameworkJson["APINotes"] := new JsonArray(FixSSDKPath(lApiNotes));

          var lHelperFrameworks := aFrameworks.Where(f2 -> f2.StartsWith($"_{f}_")).ToList;
          if not SwiftOnly and (lHelperFrameworks.Count > 0) then begin
            var lSwiftHelperFrameworks := new JsonArray;
            for each h in lHelperFrameworks do begin
              lFrameworkFolder := aFrameworksFolders.Select(f2 -> Path.Combine(f2, h+".framework")).Where(f2 -> f2.FolderExists).FirstOrDefault;
              if assigned(lFrameworkFolder) then
                lSwiftHelperFrameworks.Add(new JsonStringValue(FixSSDKPath(lFrameworkFolder)));
            end;
            if lSwiftHelperFrameworks.Count > 0 then
            lFrameworkJson["SwiftHelperFrameworks"] := lSwiftHelperFrameworks;
          end;

        end;

        lJsonImports.Add(lFrameworkJson);
      end;

      if not SwiftOnly then begin
        if not lDeploymentTargetsOnly then begin

          var lDevFrameworksFolder := Path.GetFullPath(Path.Combine(aSDKFolder, "..", "..", "Library", "Frameworks"));
          if lDevFrameworksFolder.FolderExists then begin
            for each f in Folder.GetSubfolders(lDevFrameworksFolder).Where(f -> f.PathExtension = ".framework") do begin
              var lFrameworkJson := new JsonObject();
              lFrameworkJson["Name"] := f.LastPathComponentWithoutExtension;
              lFrameworkJson["Framework"] := true;
              lFrameworkJson["Prefix"] := "";
              lFrameworkJson["FrameworkPath"] := FixSSDKPath(f);
              // todo: duope Swift check from above
              lJsonImports.Add(lFrameworkJson);
            end;
          end;

        end;

      end;

      if not SkipSwift then begin

        if Darwin.Island then begin
          var lKnownShadowFrameworks := new List<String>;
          for each ul in aUsrLibFolders.Reverse do begin // for Mac Catalyst, iOSSupport is last, so check that first
            var lSwiftPath := Path.Combine(ul, "swift");
            if lSwiftPath.FolderExists then begin
              for each f in Folder.GetSubfolders(lSwiftPath).Where(f -> f.PathExtension = ".swiftmodule") do begin

                var lName := f.LastPathComponentWithoutExtension;
                if lKnownShadowFrameworks.Contains(lName) then // untested logic, only keep one of each, for Mac Cataltsy;
                  continue;
                lKnownShadowFrameworks.Add(lName);

                var lShadowFrameworkJson := new JsonObject();
                lShadowFrameworkJson["Name"] := Path.Combine("Swift", lName);
                if aFrameworks.Contains(lName) then
                  lShadowFrameworkJson["Shadows"] := lName;
                lShadowFrameworkJson["Swift"] := true;

                lShadowFrameworkJson["SwiftModule"] := FixSSDKPath(f);

                var lPath := Path.Combine(f, $"{aArchitecture.Arch}.swiftinterface");
                if lPath.FileExists then begin
                  lShadowFrameworkJson["SwiftInterface"] := FixSSDKPath(lPath);
                end
                else begin
                  var lArch := aArchitecture.Arch;
                  if aArchitecture.Arch = "arm64" then
                    lArch := lArch+"e";
                  lPath := Path.Combine(f, $"{lArch}.swiftinterface");
                  if lPath.FileExists then begin
                    lShadowFrameworkJson["SwiftInterface"] := FixSSDKPath(lPath);
                  end
                  else begin
                    var lOsName := case aName of
                      "Mac Catalyst": "ios-macabi";
                      else aName.ToLower;
                    end;
                    lPath := Path.Combine(f, $"{lArch}-apple-{lOsName}.swiftinterface");
                    if lPath.FileExists then
                      lShadowFrameworkJson["SwiftInterface"] := FixSSDKPath(lPath);
                  end;
                end;

                lPath := Path.Combine(lSwiftPath, $"libswift{lName}.tbd");
                if lPath.FileExists then
                  lShadowFrameworkJson["SwiftTbd"] := FixSSDKPath(lPath);

                lJsonImports.Add(lShadowFrameworkJson);
              end;
            end;
          end;
        end;

      end;

      if not SwiftOnly then begin

        var lApiNotesJson := new JsonArray();
        for each f in Folder.GetFiles(aUsrIncludeFolder, true).Where(f -> f.PathExtension = ".apinotes") do
          lApiNotesJson.Add(FixSSDKPath(f));
        if lToolchainFolder.FolderExists then
          for each f in Folder.GetFiles(lToolchainFolder, true).Where(f -> f.PathExtension = ".apinotes") do
            lApiNotesJson.Add(FixToolchainPath(f));

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
        if lApiNotesJson.Count > 0 then
          lRtlFramework["APINotes"] := lApiNotesJson;
        lJsonImports.Add(lRtlFramework);

      end;

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

      if length(aArchitecture.Environment) > 0 then
        (lJson["Defines"] as JsonArray).Add("target_environment="+aArchitecture.Environment);
      (lJson["Defines"] as JsonArray).Add("target_vendor="+coalesce(aArchitecture.Vendor, "apple"):ToLower);
      (lJson["Defines"] as JsonArray).Add("target_os="+coalesce(aArchitecture.OS, aArchitecture.SDKName):ToLower);
      (lJson["Defines"] as JsonArray).Add("target_arch="+aArchitecture.Arch);

      lJson["VirtualFiles"] := new JsonObject();
      lJson["VirtualFiles"]["os/availibility.h"] := "#include <os/availability.h>";

      var lSuffix := "";
      if SkipSwift then
        lSuffix := "noswift-"
      else if SwiftOnly then
        lSuffix := "swiftonly-";

      var lJsonName := $"import-{Darwin.Mode}-{aArchitecture.DisplaySDKName}{if aArchitecture.Simulator then "-Simulator" else ""}-{aVersionString}-{lSuffix}{aOutputFolder.LastPathComponent}.json";
      lJsonName := Path.Combine(SDKsBaseFolder, lJsonName);
      File.WriteText(lJsonName, lJsonDocument.ToString());

      if SkipHI then begin
        writeLn(lJsonDocument);
        exit;
      end;

      if Debug then
        writeLn(lJsonDocument);

      var aClangIncludeFolder: String;
      var aClangBaseFolder := Path.Combine(Darwin.DeveloperFolder, "Toolchains/XcodeDefault.xctoolchain/usr/lib/clang");
      if aClangBaseFolder.FolderExists then begin
        for each f in Folder.GetSubfolders(aClangBaseFolder) do begin
          if Path.Combine(f, "include").FolderExists then begin
            aClangIncludeFolder := Path.Combine(f, "include");
            break;
          end;
        end;
      end;

      var lArgs := new List<String>;
      lArgs.Add("import");
      lArgs.Add($"--json={lJsonName}");
      lArgs.Add($"--sdk={aSDKFolder}");
      lArgs.Add($"--toolchain={lToolchainFolder}");
      lArgs.Add("-o", aOutputFolder);

      lArgs.Add($"-i", aUsrIncludeFolder);
      if assigned(aClangIncludeFolder) then
        lArgs.Add($"-i", aClangIncludeFolder);
      for each f in aFrameworksFolders do
        lArgs.Add($"-f", f);
      lArgs.Add($"-i", SDKsBaseFolder);

      //if assigned(aRootSDK) then begin
        //var lBaseFXFolder := Path.Combine(Path.GetParentDirectory(Path.GetParentDirectory(aOutputFolder)), aRootSDK);
        //lArgs.Add($"-x", lBaseFXFolder);
      //end;

      if Darwin.Island and SwiftOnly then begin
        var lBaseFXFolder := Path.GetParentDirectory(aOutputFolder);
        var lSdkName := lBaseFXFolder.LastPathComponent;

        if not SkipSwift and not SwiftOnly then begin
          var lDownloadsSDKs := Path.Combine(Environment.UserApplicationSupportFolder, "RemObjects Software", "EBuild", "SDKs", "Island", "Darwin");
          if Path.Combine(lBaseFXFolder, "rtl.fx").FileExists then
            lArgs.Add($"-x", lBaseFXFolder)
          else if Path.Combine(IslandPaths.Instance.SdkFolder, "Darwin", lSdkName).FolderExists then
            lArgs.Add($"-x", Path.Combine(IslandPaths.Instance.SdkFolder, "Darwin", lSdkName))
          else if Path.Combine(lDownloadsSDKs, lSdkName).FolderExists then
            lArgs.Add($"-x", Path.Combine(lDownloadsSDKs, lSdkName));
        end;

        // Island.fx is always needed for Swift
        var lIsSimulator := lSdkName.EndsWith("Simulator");
        if lSdkName.StartsWith("Mac Catalyst") then begin
          lSdkName := lSdkName.SubstringToLastOccurrenceOf(" ");
        end
        else begin
          lSdkName := lSdkName.SubstringToFirstOccurrenceOf(" ");
          if lIsSimulator then
            lSdkName := lSdkName+" Simulator";
        end;

        var lReferenceFolder := Path.Combine(ElementsPaths.Instance.ElementsBinFolder, "References", "Island", lSdkName, aOutputFolder.LastPathComponent);
        if lReferenceFolder.FolderExists then
          lArgs.Add($"-x", lReferenceFolder)
        else
          writeLn("WARNING! path to matching Island.fx file was not found.");
      end;

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

      for each f in aUsrLibFolders do
      lArgs.Add($"--libpath="+f);

      if Debug then
        lArgs.Add("--debug");

      RunHI(lArgs) SDKFolder(aSDKFolder);
      File.Delete(lJsonName);

      //if (doDeleteJsonFiles)
        //file.remove(jsonName);
      //}
    end;

    //
    //
    //

    method GenerateCode(aName: String; aVersion: String);
    begin
      var lShortVersion := Darwin.ShortVersion(aVersion);
      var lTargetFolderName := aName+" "+lShortVersion;
      var lTargetFolder := Path.Combine(SDKsBaseFolder, lTargetFolderName);

      var lCodeFolder := Path.Combine(lTargetFolder, "Source");
      Folder.Create(lCodeFolder);
      for each f in Folder.GetFiles(lTargetFolder).Where(f -> f.PathExtension = ".fx") do begin
        RunHI(new List<String>("codegen", f, Path.Combine(lCodeFolder, f.LastPathComponentWithoutExtension+".pas"), "Oxygene"));
        RunHI(new List<String>("codegen", f, Path.Combine(lCodeFolder, f.LastPathComponentWithoutExtension+".cs"), "Hydrogene"));
        RunHI(new List<String>("codegen", f, Path.Combine(lCodeFolder, f.LastPathComponentWithoutExtension+".swift"), "Silver"));
        RunHI(new List<String>("codegen", f, Path.Combine(lCodeFolder, f.LastPathComponentWithoutExtension+".java"), "Iodine"));
      end;
    end;

    method CreateSDKZip(aName: String; aVersion: String);
    begin
      if SkipHI then
        exit;
      //aName := if aName = "macOS" then Darwin.NameForMacOS(aVersion) else aName;

      var lShortVersion := Darwin.ShortVersion(aVersion);
      var lSuffix := if lShortVersion ≠ aVersion then "("+aVersion+")" else "";
      if length(Darwin.BetaSuffix) > 0 then begin
        lSuffix := (lSuffix+" "+Darwin.BetaSuffix).Trim;
      end;
      if length(lSuffix) > 0 then
        lSuffix := " - "+lSuffix;

      if defined("ECHOES") and CreateZips then begin
        var lTargetFolderName := aName+" "+lShortVersion;
        var lTargetFolderName2 := lTargetFolderName+" Simulator";

        var lTargetFolder := Path.Combine(SDKsBaseFolder, lTargetFolderName);
        var lTargetFolder2 := Path.Combine(SDKsBaseFolder, lTargetFolderName2);

        Folder.Create(Path.Combine(SDKsBaseFolder, "__CI2Shared"));
        Folder.Create(Path.Combine(SDKsBaseFolder, "__Public"));

        var lTargetZipName := Path.Combine(SDKsBaseFolder, "__CI2Shared", lTargetFolderName)+".zip";
        var lTargetZipName3 := Path.Combine(SDKsBaseFolder, "__CI2Shared", lTargetFolderName)+" Simulator.zip";
        var lTargetZipName2 := Path.Combine(SDKsBaseFolder, "__Public", lTargetFolderName)+lSuffix+".zip";
        writeLn($"Creating {lTargetZipName}");
        CreateZip(lTargetFolder, lTargetZipName);
        if aName in ["macOS", "Mac Catalyst"] then begin
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