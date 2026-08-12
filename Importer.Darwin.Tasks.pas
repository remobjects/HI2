namespace RemObjects.Elements.HI2;

uses
  RemObjects.Elements.Basics;

type
  Importer = public partial class
  public

    method SetSpecificXcode;
    begin
      XcodeVersion := "27.0";
      XcodeBeta := 5;
      //XcodeName := "RC";
    end;

    property XcodeVersion: String;
    property XcodeBeta: Integer;
    property XcodeName: String;

    method ImportCurrentXcode;
    begin
      ImportXcode(XcodeVersion) Beta(XcodeBeta) Name(XcodeName);
    end;

    method ImportSDKs;
    begin
      //Debug := true;
      //SkipHI := true;

      //GenerateCode := true;
      //DontDeleteJson := true;

      //SkipDeploymentTargets := true;
      //SkipNonEssentialFrameworks := true;

      //SkipDevice := true;
      //SkipSimulator := true;

      //SkipMacOS := true;
      //SkipMacCatalyst := true;
      //SkipIOS := true;
      //SkipTvOS := true;
      //SkipWatchOS := true;
      //SkipVisionOS := true;

      //SwiftTbdSymbolModules.Add("FoundationModels");
      //SwiftTbdSymbolModules.Add("WidgetKit");

      //
      // do not change these below this line!
      //
      ImportCocoaSDKs;
      //ImportSwiftSDKs;
    end;

    property FrameworksFolder: String;

    //
    //
    //

    method ImportIslandSDKs;
    begin
      BaseFolder := Path.Combine(FrameworksFolder, "Island");
      ImportCurrentXcode();
    end;

    method ImportCocoaSDKs;
    begin
      SwiftOnly := false;
      SkipSwift := true;
      ImportIslandSDKs;
    end;

    method ImportSwiftSDKs;
    begin
      DontClean := true;
      SkipDeploymentTargets := true;
      SwiftOnly := true;
      SkipSwift := false;
      SwiftDumpJsonFolder := Path.Combine(FrameworksFolder, "Island", "Darwin", "Swift Dumps");
      //SwiftTbdSymbolModules.Add("CreateML");
      //SwiftTbdSymbolModules.Add("FoundationModels");
      ImportIslandSDKs;
    end;

    //
    //
    //

    method ImportXcode(aVersion: String) Beta(aBeta: nullable Integer := nil) Name(aName: nullable String:= nil);
    begin

      method FindXcode(aApplicationsFolder: String): String;
      begin
        if assigned(aBeta) then begin
          Darwin.DeveloperFolder := $"{aApplicationsFolder}/Xcode-{aVersion}-Beta{aBeta}.app/Contents/Developer";
          Darwin.BetaSuffix := $"Xcode {aVersion} Beta {aBeta}";
        end
        else if assigned(aName) then begin
          Darwin.DeveloperFolder := $"{aApplicationsFolder}/Xcode-{aVersion}-{aName}.app/Contents/Developer";
          Darwin.BetaSuffix := $"Xcode {aVersion} {aName}";
        end
        else begin
          Darwin.DeveloperFolder := $"{aApplicationsFolder}/Xcode-{aVersion}.app/Contents/Developer";
          Darwin.BetaSuffix := $"Xcode {aVersion}";
        end;
      end;

      if ApplicationsFolder:FolderExists then
        FindXcode(ApplicationsFolder);
      if not Darwin.DeveloperFolder.FolderExists then
        FindXcode(Path.Combine(Environment.UserHomeFolder, "Applications"));
      if not Darwin.DeveloperFolder.FolderExists then
        FindXcode("/Applications");

      if not Darwin.DeveloperFolder.FolderExists then
        raise new Exception("The specified Xcode version was not found.");

      Darwin.LoadVersionsFromXcode();

      ImportMacOSSDK();
      ImportMacCatalyst();
      ImportIOSSDK();
      ImportTvOSSDK();
      ImportWatchOSSDK();
      ImportVisionOSSDK();

      //ImportDriverKitSDK();
    end;

  end;

end.