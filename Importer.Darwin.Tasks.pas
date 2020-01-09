namespace RemObjects.Elements.HI2;

uses
  RemObjects.Elements.Basics;

type
  Importer = public partial class
  public

    property FrameworksFolder: String;

    method ImportSDKs;
    begin
      //SkipDeploymentTargets := true;
      ImportToffeeSDKs;
      ImportIslandSDKs;
    end;

    //
    //
    //

    method ImportToffeeSDKs;
    begin
      Darwin.Toffee := true;
      Darwin.Island := false;
      BaseFolder := Path.Combine(FrameworksFolder, "Toffee");
      ImportCurrentXcode();
    end;

    method ImportIslandSDKs;
    begin
      Darwin.Toffee := false;
      Darwin.Island := true;
      BaseFolder := Path.Combine(FrameworksFolder, "Island");
      ImportCurrentXcode();
    end;

    method ImportCurrentXcode;
    begin
      ImportXcode11_3;
    end;

    method ImportAllXcodes;
    begin
      ImportXcode10_3;
      ImportXcode10_2;
      ImportXcode10_1;
      ImportXcode10_0;
      ImportXcode9_4;
    end;

    //
    //
    //

    //method ImportXcode11_NEXT_Beta(aBeta: Integer);
    //begin
      //Darwin.DeveloperFolder := $"/Users/mh/Applications/Xcode-11.2-Beta{aBeta}.app/Contents/Developer";
      //Darwin.macOSVersion := "10.15";
      //Darwin.iOSVersion := "13.2";
      //Darwin.tvOSVersion := "13.2";
      //Darwin.watchOSVersion := "6.1";
      //Darwin.DriverKitVersion := "19.0";
      //Darwin.BetaSuffix := $"Xcode 11.2 Beta {aBeta}";

      //ImportMacOSSDK();
      //ImportIOSSDK();
      //ImportUIKitForMac();
      //ImportTvOSSDK();
      //ImportWatchOSSDK();

      ////ImportDriverKitSDK();
    //end;

    method ImportXcode11_3;
    begin
      Darwin.DeveloperFolder := $"/Users/mh/Applications/Xcode-11.3-GM.app/Contents/Developer";
      Darwin.macOSVersion := "10.15";
      Darwin.iOSVersion := "13.2";
      Darwin.tvOSVersion := "13.2";
      Darwin.watchOSVersion := "6.1";
      Darwin.DriverKitVersion := "19.0";
      Darwin.BetaSuffix := $"Xcode 11.3";

      ImportMacOSSDK();
      ImportIOSSDK();
      ImportUIKitForMac();
      ImportTvOSSDK();
      ImportWatchOSSDK();

      //ImportDriverKitSDK();
    end;

    method ImportXcode11_2;
    begin
      Darwin.DeveloperFolder := $"/Users/mh/Applications/Xcode-11.2.1-GM.app/Contents/Developer";
      Darwin.macOSVersion := "10.15";
      Darwin.iOSVersion := "13.2";
      Darwin.tvOSVersion := "13.2";
      Darwin.watchOSVersion := "6.1";
      Darwin.DriverKitVersion := "19.0";
      Darwin.BetaSuffix := $"Xcode 11.2.1";

      ImportMacOSSDK();
      ImportIOSSDK();
      ImportUIKitForMac();
      ImportTvOSSDK();
      ImportWatchOSSDK();

      //ImportDriverKitSDK();
    end;

    method ImportXcode11_1;
    begin
      Darwin.DeveloperFolder := $"/Users/mh/Applications/Xcode-11.1-GM.app/Contents/Developer";
      Darwin.macOSVersion := "10.15";
      Darwin.iOSVersion := "13.1";
      Darwin.tvOSVersion := "13.0";
      Darwin.watchOSVersion := "6.0";
      Darwin.DriverKitVersion := "19.0";
      Darwin.BetaSuffix := $"Xcode 11.1";

      ImportMacOSSDK();
      ImportIOSSDK();
      ImportUIKitForMac();
      ImportTvOSSDK();
      ImportWatchOSSDK();

      //ImportDriverKitSDK();
    end;

    method ImportXcode11;
    begin
      Darwin.DeveloperFolder := $"/Users/mh/Applications/Xcode-11.1-GM.app/Contents/Developer";
      Darwin.macOSVersion := "10.15";
      Darwin.iOSVersion := "13.0";
      Darwin.tvOSVersion := "13.0";
      Darwin.watchOSVersion := "6.0";
      Darwin.DriverKitVersion := "19.0";
      Darwin.BetaSuffix := $"Xcode 11.1";

      ImportMacOSSDK();
      ImportIOSSDK();
      ImportUIKitForMac();
      ImportTvOSSDK();
      ImportWatchOSSDK();

      //ImportDriverKitSDK();
    end;

    method ImportXcode10_3;
    begin
      Darwin.DeveloperFolder := "/Users/mh/Applications/Xcode-10.3.app/Contents/Developer";
      Darwin.macOSVersion := "10.14.6";
      Darwin.iOSVersion := "12.4";
      Darwin.tvOSVersion := "12.4";
      Darwin.watchOSVersion := "5.3";
      Darwin.BetaSuffix := "";

      ImportMacOSSDK();
      ImportIOSSDK();
      ImportTvOSSDK();
      ImportWatchOSSDK();
    end;

    method ImportXcode10_2;
    begin
      Darwin.DeveloperFolder := "/Users/mh/Applications/Xcode-10.2.app/Contents/Developer";
      Darwin.macOSVersion := "10.14.4";
      Darwin.iOSVersion := "12.2";
      Darwin.tvOSVersion := "12.2";
      Darwin.watchOSVersion := "5.2";
      Darwin.BetaSuffix := "";

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