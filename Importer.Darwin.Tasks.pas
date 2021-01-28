namespace RemObjects.Elements.HI2;

uses
  RemObjects.Elements.Basics;

type
  Importer = public partial class
  public

    property FrameworksFolder: String;

    method ImportSDKs;
    begin
      //GenerateCode := true;

      //SwiftOnly := true;
      SkipSwift := true;
      //Debug := true;

      //SkipDeploymentTargets := true;
      //SkipNonEssentialFrameworks := true;
      //SkipSimulator := true;
      //SkipMacOS := true;
      //SkipMacCatalyst := true;
      //SkipIOS := true;
      //SkipTvOS := true;
      //SkipWatchOS := true;

      ImportToffeeSDKs;
      ImportIslandSDKs;
    end;

    method ImportCurrentXcode;
    begin
      ImportXcode12_4;
      //ImportXcode12_2;
      //ImportXcode12_2_Beta(3);
      //ImportXcode12_1_1_GM;
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

    method ImportAllXcodes;
    begin
      ImportXcode11_6;
      ImportXcode10_3;
      ImportXcode10_2;
      ImportXcode10_1;
      ImportXcode10_0;
      ImportXcode9_4;
    end;

    //
    //
    //

    method ImportXcode12_4;
    begin
      Darwin.DeveloperFolder := $"{ApplicationsFolder}/Xcode-12.4-GM.app/Contents/Developer";
      Darwin.macOSVersion := "11.1";
      Darwin.iOSVersion := "14.4";
      Darwin.tvOSVersion := "14.3";
      Darwin.watchOSVersion := "7.3";
      Darwin.DriverKitVersion := "20.2";
      Darwin.BetaSuffix := $"Xcode 12.3";

      ImportMacOSSDK();
      ImportMacCatalyst();
      ImportIOSSDK();
      ImportTvOSSDK();
      ImportWatchOSSDK();

      //ImportDriverKitSDK();
    end;

    method ImportXcode12_3;
    begin
      Darwin.DeveloperFolder := $"{ApplicationsFolder}/Xcode-12.3.app/Contents/Developer";
      Darwin.macOSVersion := "11.1";
      Darwin.iOSVersion := "14.3";
      Darwin.tvOSVersion := "14.3";
      Darwin.watchOSVersion := "7.2";
      Darwin.DriverKitVersion := "20.0";
      Darwin.BetaSuffix := $"Xcode 12.3";

      ImportMacOSSDK();
      ImportMacCatalyst();
      ImportIOSSDK();
      ImportTvOSSDK();
      ImportWatchOSSDK();

      //ImportDriverKitSDK();
    end;

    method ImportXcode12_3_Beta(aBeta: Integer);
    begin
      Darwin.DeveloperFolder := $"{ApplicationsFolder}/Xcode-12.3-Beta{aBeta}.app/Contents/Developer";
      Darwin.macOSVersion := "11.1";
      Darwin.iOSVersion := "14.3";
      Darwin.tvOSVersion := "14.3";
      Darwin.watchOSVersion := "7.2";
      Darwin.DriverKitVersion := "20.0";
      Darwin.BetaSuffix := $"Xcode 12.3 Beta {aBeta}";

      ImportMacOSSDK();
      ImportMacCatalyst();
      ImportIOSSDK();
      ImportTvOSSDK();
      ImportWatchOSSDK();

      //ImportDriverKitSDK();
    end;

    method ImportXcode12_2;
    begin
      Darwin.DeveloperFolder := $"{ApplicationsFolder}/Xcode-12.2-GM.app/Contents/Developer";
      Darwin.macOSVersion := "11.0";
      Darwin.iOSVersion := "14.2";
      Darwin.tvOSVersion := "14.2";
      Darwin.watchOSVersion := "7.1";
      Darwin.DriverKitVersion := "20.0";
      Darwin.BetaSuffix := $"Xcode 12.2";

      ImportMacOSSDK();
      ImportMacCatalyst();
      ImportIOSSDK();
      ImportTvOSSDK();
      ImportWatchOSSDK();

      //ImportDriverKitSDK();
    end;

    method ImportXcode12_2_Beta(aBeta: Integer);
    begin
      Darwin.DeveloperFolder := $"{ApplicationsFolder}/Xcode-12.2-Beta{aBeta}.app/Contents/Developer";
      Darwin.macOSVersion := "11.0";
      Darwin.iOSVersion := "14.2";
      Darwin.tvOSVersion := "14.2";
      Darwin.watchOSVersion := "7.1";
      Darwin.DriverKitVersion := "20.0";
      Darwin.BetaSuffix := $"Xcode 12.2 Beta {aBeta}";

      ImportMacOSSDK();
      ImportMacCatalyst();
      ImportIOSSDK();
      ImportTvOSSDK();
      ImportWatchOSSDK();

      //ImportDriverKitSDK();
    end;

    method ImportXcode12_1_1_GM;
    begin
      Darwin.DeveloperFolder := $"{ApplicationsFolder}/Xcode-12.1.1-GM.app/Contents/Developer";
      Darwin.macOSVersion := "10.15";
      Darwin.iOSVersion := "14.2";
      Darwin.tvOSVersion := "14.2";
      Darwin.watchOSVersion := "7.1";
      Darwin.DriverKitVersion := "19.0";
      Darwin.BetaSuffix := $"Xcode 12.1.1";

      ImportMacOSSDK();
      //ImportMacCatalyst();
      ImportIOSSDK();
      ImportTvOSSDK();
      ImportWatchOSSDK();

      //ImportDriverKitSDK();
    end;

    method ImportXcode12_1_GM;
    begin
      Darwin.DeveloperFolder := $"{ApplicationsFolder}/Xcode-12.1-GM.app/Contents/Developer";
      Darwin.macOSVersion := "10.15";
      Darwin.iOSVersion := "14.1";
      Darwin.tvOSVersion := "14.0";
      Darwin.watchOSVersion := "7.0";
      Darwin.DriverKitVersion := "19.0";
      Darwin.BetaSuffix := $"Xcode 12.1";

      ImportMacOSSDK();
      //ImportMacCatalyst();
      ImportIOSSDK();
      ImportTvOSSDK();
      ImportWatchOSSDK();

      //ImportDriverKitSDK();
    end;

    method ImportXcode12_0_GM;
    begin
      Darwin.DeveloperFolder := $"{ApplicationsFolder}/Xcode-12-GM.app/Contents/Developer";
      Darwin.macOSVersion := "10.15";
      Darwin.iOSVersion := "14.0";
      Darwin.tvOSVersion := "14.0";
      Darwin.watchOSVersion := "7.0";
      Darwin.DriverKitVersion := "19.0";
      Darwin.BetaSuffix := $"Xcode 12.0";

      ImportMacOSSDK();
      //ImportMacCatalyst();
      ImportIOSSDK();
      ImportTvOSSDK();
      ImportWatchOSSDK();

      //ImportDriverKitSDK();
    end;

    //
    //
    //

    //method ImportXcode12_0_BetaWithArm(aBeta: Integer);
    //begin
      //Darwin.DeveloperFolder := $"{ApplicationsFolder}/Xcode-12-Beta{aBeta}-with-ARM.app/Contents/Developer";
      //Darwin.macOSVersion := "11.0";
      //Darwin.iOSVersion := "14.0";
      //Darwin.BetaSuffix := $"Xcode 12 Beta {aBeta}";
      //ImportMacOSSDK();
      //ImportIOSSDK();
      //ImportMacCatalyst();
    //end;

    //method ImportXcode12_0_Beta(aBeta: Integer);
    //begin
      //Darwin.DeveloperFolder := $"{ApplicationsFolder}/Xcode-12-Beta{aBeta}.app/Contents/Developer";
      //Darwin.macOSVersion := "11.0";
      //Darwin.iOSVersion := "14.0";
      //Darwin.tvOSVersion := "14.0";
      //Darwin.watchOSVersion := "7.0";
      //Darwin.DriverKitVersion := "20.0";
      //Darwin.BetaSuffix := $"Xcode 12 Beta {aBeta}";

      //ImportMacOSSDK();
      //ImportMacCatalyst();
      //ImportIOSSDK();
      //ImportTvOSSDK();
      //ImportWatchOSSDK();

      ////ImportDriverKitSDK();
    //end;

    method ImportXcode11_7;
    begin
      Darwin.DeveloperFolder := $"{ApplicationsFolder}/Xcode-11.7-GM.app/Contents/Developer";
      Darwin.macOSVersion := "10.15";
      Darwin.iOSVersion := "13.7";
      Darwin.tvOSVersion := "13.4";
      Darwin.watchOSVersion := "6.2";
      Darwin.DriverKitVersion := "19.0";
      Darwin.BetaSuffix := $"Xcode 11.7";

      ImportMacOSSDK();
      ImportIOSSDK();
      ImportMacCatalyst();
      ImportTvOSSDK();
      ImportWatchOSSDK();

      //ImportDriverKitSDK();
    end;

    //method ImportXcode11_7_Beta(aBeta: Integer);
    //begin
      //Darwin.DeveloperFolder := $"{ApplicationsFolder}/Xcode-11.7-Beta{aBeta}.app/Contents/Developer";
      //Darwin.macOSVersion := "10.15";
      //Darwin.iOSVersion := "13.7";
      //Darwin.tvOSVersion := "13.4";
      //Darwin.watchOSVersion := "6.2";
      //Darwin.DriverKitVersion := "19.0";
      //Darwin.BetaSuffix := $"Xcode 11.7 Beta {aBeta}";

      ////ImportMacOSSDK();
      //ImportMacCatalyst();
      //ImportIOSSDK();
      ////ImportTvOSSDK();
      ////ImportWatchOSSDK();

      ////ImportDriverKitSDK();
    //end;

    method ImportXcode11_6;
    begin
      Darwin.DeveloperFolder := $"{ApplicationsFolder}/Xcode-11.6-GM.app/Contents/Developer";
      Darwin.macOSVersion := "10.15";
      Darwin.iOSVersion := "13.6";
      Darwin.tvOSVersion := "13.4";
      Darwin.watchOSVersion := "6.2";
      Darwin.DriverKitVersion := "19.0";
      Darwin.BetaSuffix := $"Xcode 11.6";

      //ImportMacOSSDK();
      //ImportIOSSDK();
      //ImportMacCatalyst();
      ImportTvOSSDK();
      ImportWatchOSSDK();

      //ImportDriverKitSDK();
    end;

    method ImportXcode11_5;
    begin
      Darwin.DeveloperFolder := $"{ApplicationsFolder}/Xcode-11.5-GM.app/Contents/Developer";
      Darwin.macOSVersion := "10.15";
      Darwin.iOSVersion := "13.5";
      Darwin.tvOSVersion := "13.4";
      Darwin.watchOSVersion := "6.2";
      Darwin.DriverKitVersion := "19.0";
      Darwin.BetaSuffix := $"Xcode 11.5";

      ImportMacOSSDK();
      ImportIOSSDK();
      ImportMacCatalyst();
      ImportTvOSSDK();
      ImportWatchOSSDK();

      //ImportDriverKitSDK();
    end;

    method ImportXcode11_4;
    begin
      Darwin.DeveloperFolder := $"{ApplicationsFolder}/Xcode-11.4-GM.app/Contents/Developer";
      Darwin.macOSVersion := "10.15";
      Darwin.iOSVersion := "13.4";
      Darwin.tvOSVersion := "13.4";
      Darwin.watchOSVersion := "6.2";
      Darwin.DriverKitVersion := "19.0";
      Darwin.BetaSuffix := $"Xcode 11.4";

      ImportMacOSSDK();
      ImportIOSSDK();
      ImportMacCatalyst();
      ImportTvOSSDK();
      ImportWatchOSSDK();

      //ImportDriverKitSDK();
    end;

    method ImportXcode11_3;
    begin
      Darwin.DeveloperFolder := $"{ApplicationsFolder}/Xcode-11.3.1-GM.app/Contents/Developer";
      Darwin.macOSVersion := "10.15";
      Darwin.iOSVersion := "13.2";
      Darwin.tvOSVersion := "13.2";
      Darwin.watchOSVersion := "6.1";
      Darwin.DriverKitVersion := "19.0";
      Darwin.BetaSuffix := $"Xcode 11.3";

      ImportMacOSSDK();
      ImportIOSSDK();
      ImportMacCatalyst();
      ImportTvOSSDK();
      ImportWatchOSSDK();

      //ImportDriverKitSDK();
    end;

    method ImportXcode11_2;
    begin
      Darwin.DeveloperFolder := $"{ApplicationsFolder}/Xcode-11.2.1-GM.app/Contents/Developer";
      Darwin.macOSVersion := "10.15";
      Darwin.iOSVersion := "13.2";
      Darwin.tvOSVersion := "13.2";
      Darwin.watchOSVersion := "6.1";
      Darwin.DriverKitVersion := "19.0";
      Darwin.BetaSuffix := $"Xcode 11.2.1";

      ImportMacOSSDK();
      ImportIOSSDK();
      ImportMacCatalyst();
      ImportTvOSSDK();
      ImportWatchOSSDK();

      //ImportDriverKitSDK();
    end;

    method ImportXcode11_1;
    begin
      Darwin.DeveloperFolder := $"{ApplicationsFolder}/Xcode-11.1-GM.app/Contents/Developer";
      Darwin.macOSVersion := "10.15";
      Darwin.iOSVersion := "13.1";
      Darwin.tvOSVersion := "13.0";
      Darwin.watchOSVersion := "6.0";
      Darwin.DriverKitVersion := "19.0";
      Darwin.BetaSuffix := $"Xcode 11.1";

      ImportMacOSSDK();
      ImportIOSSDK();
      ImportMacCatalyst();
      ImportTvOSSDK();
      ImportWatchOSSDK();

      //ImportDriverKitSDK();
    end;

    method ImportXcode11;
    begin
      Darwin.DeveloperFolder := $"{ApplicationsFolder}/Xcode-11.1-GM.app/Contents/Developer";
      Darwin.macOSVersion := "10.15";
      Darwin.iOSVersion := "13.0";
      Darwin.tvOSVersion := "13.0";
      Darwin.watchOSVersion := "6.0";
      Darwin.DriverKitVersion := "19.0";
      Darwin.BetaSuffix := $"Xcode 11.1";

      ImportMacOSSDK();
      ImportIOSSDK();
      ImportMacCatalyst();
      ImportTvOSSDK();
      ImportWatchOSSDK();

      //ImportDriverKitSDK();
    end;

    method ImportXcode10_3;
    begin
      Darwin.DeveloperFolder := "{ApplicationsFolder}/Xcode-10.3.app/Contents/Developer";
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
      Darwin.DeveloperFolder := "{ApplicationsFolder}/Xcode-10.2.app/Contents/Developer";
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
      Darwin.DeveloperFolder := "{ApplicationsFolder}/Xcode-10.1.app/Contents/Developer";
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
      Darwin.DeveloperFolder := "{ApplicationsFolder}/Xcode-10.app/Contents/Developer";
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
      Darwin.DeveloperFolder := "{ApplicationsFolder}/Xcode-9.4.app/Contents/Developer";
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