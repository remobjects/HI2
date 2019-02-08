namespace HI2;

uses
  RemObjects.Elements.Basics;

type
  Importer = public partial class
  public

    method ImportCurrentXcode;
    begin
      ImportXcode10_2;
    end;

    method ImportAllXcodes;
    begin
      ImportXcode10_2;
      ImportXcode10_1;
      ImportXcode10_0;
      ImportXcode9_4;
    end;

    method ImportXcode10_2;
    begin
      Darwin.DeveloperFolder := "/Users/mh/Applications/Xcode-10.2-Beta2.app/Contents/Developer";
      Darwin.macOSVersion := "10.14.4";
      Darwin.iOSVersion := "12.2";
      Darwin.tvOSVersion := "12.2";
      Darwin.watchOSVersion := "5.2";
      Darwin.BetaSuffix := "Beta 2";

      ImportMacOSSDK();
      ImportIOSSDK();
      ImportTvOSSDK();
      ImportWatchOSSDK();
    end;

    method ImportXcode10_1;
    begin
      Darwin.DeveloperFolder := "/Users/mh/Applications/Xcode-10.1.app/Contents/Developer";
      Darwin.macOSVersion := "10.14.1";
      Darwin.iOSVersion := "12.1";
      Darwin.tvOSVersion := "12.1";
      Darwin.watchOSVersion := "5.1";
      Darwin.BetaSuffix := "";

      ImportMacOSSDK();
      ImportIOSSDK();
      ImportTvOSSDK();
      ImportWatchOSSDK();
    end;

    method ImportXcode10_0;
    begin
      Darwin.DeveloperFolder := "/Users/mh/Applications/Xcode-10.app/Contents/Developer";
      Darwin.macOSVersion := "10.14.0";
      Darwin.iOSVersion := "12.0";
      Darwin.tvOSVersion := "12.0";
      Darwin.watchOSVersion := "5.0";
      Darwin.BetaSuffix := "";

      ImportMacOSSDK();
      ImportIOSSDK();
      ImportTvOSSDK();
      ImportWatchOSSDK();
    end;

    method ImportXcode9_4;
    begin
      Darwin.DeveloperFolder := "/Users/mh/Applications/Xcode-9.4.app/Contents/Developer";
      Darwin.macOSVersion := "10.13.5";
      Darwin.iOSVersion := "11.4";
      Darwin.tvOSVersion := "11.4";
      Darwin.watchOSVersion := "4.3";

      ImportMacOSSDK();
      ImportIOSSDK();
      ImportTvOSSDK();
      ImportWatchOSSDK();
    end;

  end;

end.