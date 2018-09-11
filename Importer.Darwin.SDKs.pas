namespace HI2;

uses
  RemObjects.Elements.Basics;

type
  Importer = public partial class
  public
  protected
  public

    property FXBaseFolder: String; // MUST BE SET!

    method ImportXcode10Beta();
    begin
      Darwin.DeveloperFolder := '/Users/mh/Applications/Xcode-10Beta6.app/Contents/Developer';
      Darwin.macOSVersion := '10.14';
      Darwin.iOSVersion := '12.0';
      Darwin.tvOSVersion := '12.0';
      Darwin.watchOSVersion := '5.0';

      ImportMacOSSDK();
      //ImportIOSSDK();
      //ImportWatchOSSDK();
      //ImportTvOSSDK();
    end;

    method ImportMacOSSDK();
    begin
      ImportSDK("macOS", Darwin.macOSVersion);
    end;

    method ImportSDK(aName: String; aVersion: String; aSimulator: Boolean := false);
    begin

      //var lShortVersion := Darwin.ShortVersion(aVersion);
      var lInternalVersion := if aName = "watchOS" then Darwin.iOSVersion else aVersion;
      var lSdkFolder := Darwin.SdkFolderInXcode(aName, aVersion, aSimulator);

      var lArchitectures := case aName of
        "macOS": Darwin.macOSArchitectures;
      end;

      var lDeploymentTargets := case aName of
        "macOS": Darwin.macOSDeploymentTargets;
      end;

      method DefinesForVersion(v: String): String;
      begin
        var lEnvironmentVersionDefine := case aName of
          "macOS": Darwin.macOSEnvironmentVersionDefine
        end;
        lEnvironmentVersionDefine := lEnvironmentVersionDefine+"="+Darwin.CalculateIntegerVersion(aName, aVersion);
        var lDefines := lEnvironmentVersionDefine;
        if Darwin.Toffee then
          lDefines := lDefines+";"+Darwin.ExtraDefinesToffee
        else if Darwin.Island then
          lDefines := lDefines+";"+Darwin.ExtraDefinesIsland;
      end;

      // below code is "processSDK()"

      var lTargetFolderName := aName+" "+aVersion;
      if aSimulator then
        lTargetFolderName := lTargetFolderName+" Simulator";

      var lTargetFolder := Path.Combine(FXBaseFolder, lTargetFolderName);
      Folder.Delete(lTargetFolder);

      var lFrameworksFolder := Path.Combine(lSdkFolder, "System", "Library", "Frameworks");

      //if (doBuildDeploymentTargets)
      for each d in lDeploymentTargets.Split(";") do begin
        if d.CompareVersionTripleTo(aVersion) < 0 then begin
          for each (a, nil) in lArchitectures do begin
            if not assigned(a.MinimumDeploymentTarget) or (a.MinimumDeploymentTarget.CompareVersionTripleTo(d) ≤ 0) then begin
              var lDefines := a.Defines+";"+DefinesForVersion(d);

              // below code is "doProcessDeploymentTargetSDK(options.version, deploymentVersion, options.sdkFolder, architectures[a], defines, targetFolder, options.forceIncludes);"

              var lTargetFolderForArch := Path.Combine(lTargetFolder, a.Triple);
              Folder.create(lTargetFolderForArch);

              var lFrameworks := new List<String>("Foundation", "Security"); // iOS Simulator requires this from rtl/objc. We wont actually *use* the generated file

              ////runHeaderImporterForSDK({
                //platform: architecture.triple,
                //outputpath: targetFolder,
                //defines: defines,
                //includeBlackList: includeBlackList,
                //includepaths: [expand('$(sdkFolder)/usr/include')],
                //frameworkpaths: [frameworksFolder],
                //frameworks: frameworks,
                //version: version,
                //versionString: __shortVersion(version)+' ('+deploymentVersion+')',
                //architecture: architecture,
                //forceIncludes: forceIncludes,
                //rtlFiles: __buildRtlFilesList(version, architecture),
                //indirectRtlFiles: indirectRtlFiles
              ////}, '-i ./');

              File.Move(Path.combine(lTargetFolderForArch, "rtl.fx"), Path.combine(lTargetFolderForArch, $"rtl-{d}.fx"));
              file.Delete(Path.combine(lTargetFolderForArch, "Foundation.fx"));
              file.Delete(Path.combine(lTargetFolderForArch, "Security.fx"));
            end;
          end;
        end;
      end;


      // main target
      for each (a, nil) in lArchitectures do begin
        if not assigned(a.MinimumTargetSDK) or (a.MinimumTargetSDK.CompareVersionTripleTo(aVersion) ≤ 0) then begin
          var lDefines := a.Defines+";"+DefinesForVersion(aVersion);

          // below code is "doProcessSDK(options.internalVersion, options.version, options.sdkFolder,  architectures[a], defines, targetFolder, options.forceIncludes);"

          var lTargetFolderForArch := Path.Combine(lTargetFolder, a.Triple);
          Folder.create(lTargetFolderForArch);

          var lFrameworks := new List<String>();
          for each f in Folder.GetSubfolders(lFrameworksFolder) do begin
            if f.PathExtension = ".framework" then begin
              var lFrameworkName := f.LastPathComponentWithoutExtension;
              if not IsBlacklisted(lFrameworkName, Darwin.FrameworksBlackList, aName, aVersion, a.Triple) then
                lFrameworks.Add(f);
            end;
          end;

          //runHeaderImporterForSDK({
            //platform: architecture.triple,
            //outputpath: targetFolder,
            //defines: defines,
            //includeBlackList: includeBlackList,
            //includepaths: [expand('$(sdkFolder)/usr/include')],
            //frameworkpaths: [frameworksFolder],
            //frameworks: frameworks,
            //version: lInternalVersion,
            //versionString: __shortVersion(versionString),
            //architecture: architecture,
            //forceIncludes: forceIncludes,
            //rtlFiles: __buildRtlFilesList(version, architecture),
            //indirectRtlFiles: indirectRtlFiles
          //}, '-i ./');
        end;
      end;
      //mergeOrFlatten(targetFolder, architectures);
      //codegen(targetFolder);

      //var lForceIncldes := case aName of
        //"macOS": Darwin.forceIncludes_macOS
      //end;


      //folder.create("$(fxBaseFolder)/__CI2Shared/");
      //folder.create("$(fxBaseFolder)/__Public/");
      //aName := if aName = "macOS" then Darwin.NameForMacOS(aVersion) else aName;
      //zip.compress("$(fxBaseFolder)/__CI2Shared/$(name) $(shortVersion).zip", "$(fxBaseFolder)", "$(name) $(shortVersion)/*.*");
      //file.copy("$(fxBaseFolder)/__CI2Shared/$(name) $(shortVersion).zip", "$(fxBaseFolder)/__Public/$(name) $(shortVersion).zip");

    end;

    method IsBlacklisted(aItem: String; aBlackList: array of String; aSDKName: String; aVersion: String; aTriple: String): Boolean;
    begin
      result := false;
    end;

  end;

end.