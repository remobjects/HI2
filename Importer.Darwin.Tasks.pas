namespace RemObjects.Elements.HI2;

uses
  RemObjects.Elements.Basics;

type
  Importer = public partial class
  public

    method ImportCurrentXcode;
    begin
      ImportXcode("26.0") Beta(2);
      //ImportXcode("16.4") Name("RC");
      //ImportXcode("16.4");
    end;

    method ImportSDKs;
    begin
      //SwiftOnly := true;
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

      //
      // do not change these below this line!
      //
      SkipSwift := true;
      ImportIslandSDKs;

      exit;

      //
      // Do Swift Import
      //

      // do not change these!
      DontClean := true;
      SkipDeploymentTargets := true;
      SwiftOnly := true;
      SkipSwift := false;

      ImportIslandSDKs;
    end;

    property FrameworksFolder: String;

    //
    //
    //

    //method ImportToffeeSDKs;
    //begin
      //Darwin.Toffee := true;
      //Darwin.Island := false;
      //BaseFolder := Path.Combine(FrameworksFolder, "Toffee");
      //ImportCurrentXcode();
    //end;

    method ImportIslandSDKs;
    begin
      Darwin.Toffee := false;
      Darwin.Island := true;
      BaseFolder := Path.Combine(FrameworksFolder, "Island");
      ImportCurrentXcode();
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