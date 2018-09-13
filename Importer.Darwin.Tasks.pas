namespace HI2;

uses
  RemObjects.Elements.Basics;

type
  Importer = public partial class
  public

    method ImportXcode10();
    begin
      Darwin.DeveloperFolder := '/Users/mh/Applications/Xcode-10.app/Contents/Developer';
      Darwin.macOSVersion := '10.14';
      Darwin.iOSVersion := '12.0';
      Darwin.tvOSVersion := '12.0';
      Darwin.watchOSVersion := '5.0';

      ImportMacOSSDK();
      ImportIOSSDK();
      ImportTvOSSDK();
      ImportWatchOSSDK();
    end;

    method ImportXcode94();
    begin
      Darwin.DeveloperFolder := '/Users/mh/Applications/Xcode-94.app/Contents/Developer';
      Darwin.macOSVersion := '10.13.5';
      Darwin.iOSVersion := '11.4';
      Darwin.tvOSVersion := '11.4';
      Darwin.watchOSVersion := '4.3';

      ImportMacOSSDK();
      ImportIOSSDK();
      ImportTvOSSDK();
      ImportWatchOSSDK();
    end;

  end;

end.