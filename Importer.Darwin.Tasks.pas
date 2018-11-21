namespace HI2;

uses
  RemObjects.Elements.Basics;

type
  Importer = public partial class
  public

    //method ImportXcode10_2();
    //begin
      //Darwin.DeveloperFolder := "/Users/mh/Applications/Xcode-10.1.app/Contents/Developer";
      //Darwin.macOSVersion := "10.14.1";
      //Darwin.iOSVersion := "12.1";
      //Darwin.tvOSVersion := "12.1";
      //Darwin.watchOSVersion := "5.1";
      //Darwin.BetaSuffix := "Beta 1";

      //ImportIOSSDK();
      //ImportMacOSSDK();
      //ImportTvOSSDK();
      //ImportWatchOSSDK();
    //end;

    method ImportXcode10_1();
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

    method ImportXcode10_0();
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

    method ImportXcode94();
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