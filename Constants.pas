namespace HI2;

uses
  RemObjects.Elements.Basics;

type
  Architecture = public record
  public
    Triple: String;
    property Arch: String read Triple.SubstringToFirstOccurrenceOf("-");
    CpuType: String;
    Defines: String;
    SDKName: String;
    Simulator: Boolean;
    MinimumTargetSDK: String;
    MinimumDeploymentTarget: String;
  end;

  Darwin = public static partial class
  private

    const _definesShared = "_USE_EXTENDED_LOCALES_;__LITTLE_ENDIAN__;__APPLE__;__APPLE_CC__;__MACH__;__GNUC__=4;__GNUC_MINOR__=2;__OBJC__;__OBJC2__;__STDC__=1;JSC_OBJC_API_ENABLED;";
    const _macOSdefines64 =        _definesShared+";__x86_64__;__LP64__=1;__SSE__;__SSE2__;IOKIT;CPU64";
    const _iOSDefines32 =          _definesShared+";__arm__;ARM;CPU32;";
    const _iOSDefines64 =          _definesShared+";__arm__;__arm64__;__LP64__=1;ARM;ARM64;CPU64";
    const _iOSDefinesSimulator32 = _definesShared+";__i386__;__SSE__;__SSE2__;CPU32";
    const _iOSDefinesSimulator64 = _macOSdefines64;

    const cpuType_Penryn = "penryn";

  public
    const macOSDefines64 =            _macOSdefines64+";OSX;MACOS;MAC;DEVICE";
    const iOSDefines32 =              _iOSDefines32+";IOS;DEVICE;";
    const iOSDefines64 =              _iOSDefines64+";IOS;DEVICE;";
    const watchOSDefines32 =          _iOSDefines32+";WATCHOS;DEVICE";
    const watchOSDefines64 =          _iOSDefines64+";WATCHOS;DEVICE";
    const tvOSDefines64 =             _iOSDefines64+";TVOS;DEVICE";
    const iOSDefinesSimulator32 =     _iOSDefinesSimulator32+";IOS;IOSSIMULATOR;SIMULATOR";
    const iOSDefinesSimulator64 =     _iOSDefinesSimulator64+";IOS;IOSSIMULATOR;SIMULATOR";
    const watchOSDefinesSimulator32 = _iOSDefinesSimulator32+";WATCHOS;WATCHOSSIMULATOR;SIMULATOR";
    const watchOSDefinesSimulator64 = _iOSDefinesSimulator64+";WATCHOS;WATCHOSSIMULATOR;SIMULATOR";
    const tvOSDefinesSimulator64 =    _iOSDefinesSimulator64+";TVOS;TVOSSIMULATOR;SIMULATOR";

    const ExtraDefinesToffee = ";DARWIN;__ELEMENTS;__TOFFEE__";
    const ExtraDefinesIsland = ";DARWIN;__ELEMENTS;__ISLAND__";

    property Architecture_macOS_x86_64            : Architecture read new Architecture(Triple := "x86_64-apple-macosx",  Defines := macOSDefines64,            SDKName := "macOS",                      CpuType := cpuType_Penryn);
    property Architecture_iOS_armv7               : Architecture read new Architecture(Triple := "armv7-apple-ios",      Defines := iOSDefines32,              SDKName := "iOS");
    property Architecture_iOS_armv7s              : Architecture read new Architecture(Triple := "armv7s-apple-ios",     Defines := iOSDefines32,              SDKName := "iOS",                                                   MinimumTargetSDK := "6.0");
    property Architecture_iOS_arm64               : Architecture read new Architecture(Triple := "arm64-apple-ios",      Defines := iOSDefines64,              SDKName := "iOS",                                                   MinimumTargetSDK := "6.0", MinimumDeploymentTarget := "6.0");
    property Architecture_iOSSimulator_i386       : Architecture read new Architecture(Triple := "i386-apple-ios",       Defines := iOSDefinesSimulator32,     SDKName := "iOS",     Simulator := true, CpuType := cpuType_Penryn);
    property Architecture_iOSSimulator_x86_64     : Architecture read new Architecture(Triple := "x86_64-apple-ios",     Defines := iOSDefinesSimulator64,     SDKName := "iOS",     Simulator := true, CpuType := cpuType_Penryn, MinimumTargetSDK := "6.0", MinimumDeploymentTarget := "6.0");
    property Architecture_watchOS_armv7k          : Architecture read new Architecture(Triple := "armv7k-apple-watchos", Defines := watchOSDefines32,          SDKName := "watchOS",                                               MinimumTargetSDK := "2.0");
    property Architecture_watchOS_arm64           : Architecture read new Architecture(Triple := "arm64-apple-watchos",  Defines := watchOSDefines64,          SDKName := "watchOS",                                               MinimumTargetSDK := "5.0");
    property Architecture_watchOSSimulator_i386   : Architecture read new Architecture(Triple := "i386-apple-watchos",   Defines := watchOSDefinesSimulator32, SDKName := "watchOS", Simulator := true, CpuType := cpuType_Penryn, MinimumTargetSDK := "2.0");
    property Architecture_watchOSSimulator_x86_64 : Architecture read new Architecture(Triple := "x86_64-apple-watchos", Defines := watchOSDefinesSimulator64, SDKName := "watchOS", Simulator := true, CpuType := cpuType_Penryn, MinimumTargetSDK := "5.0");
    property Architecture_tvOS_arm64              : Architecture read new Architecture(Triple := "arm64-apple-tvos",     Defines := tvOSDefines64,             SDKName := "tvOS",                                                  MinimumTargetSDK := "9.0");
    property Architecture_tvOSSimulator_x86_64    : Architecture read new Architecture(Triple := "x86_64-apple-tvos",    Defines := tvOSDefinesSimulator64,    SDKName := "tvOS",    Simulator := true, CpuType := cpuType_Penryn, MinimumTargetSDK := "9.0");

    const macOSEnvironmentVersionDefine   = '__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__';
    const iOSEnvironmentVersionDefine     = '__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__';
    const tvOSEnvironmentVersionDefine    = '__ENVIRONMENT_TV_OS_VERSION_MIN_REQUIRED__';
    const watchOSEnvironmentVersionDefine = '__ENVIRONMENT_WATCH_OS_VERSION_MIN_REQUIRED__';

    const macOSDeploymentTargets =   "10.14;10.13;10.12;10.11;10.10;10.9;10.8;10.7;10.6";
    const iOSDeploymentTargets =     "12.0;11.0;10.0;9.0;8.0";
    const tvOSDeploymentTargets =    "12.0;11.0;10.0;9.0";
    const watchOSDeploymentTargets = "5.0;4.0;3.0;2.0";

    const MIN_IOS_VERSION_FOR_ARMV7S    = "6.0";
    const MIN_IOS_VERSION_FOR_ARM64     = "7.0";
    const MAX_IOS_VERSION_FOR_ARM_32BIT = "10.0";

    const MIN_WATCHOS_VERSION_FOR_ARM64 = "5.0";

    const macOSCurrentVersion = "10.14";
    const iOSCurrentVersion = "12.0";
    const tvOSCurrentVersion = "12.0";
    const watchOSCurrentVersion = "5.0";

    const xcodeCurrentVersion = "10.0"; // 2018

    // Ovverride these values to control what Xcode ansd SDK Versions to use
    property macOSVersion: String := macOSCurrentVersion;
    property iOSVersion: String := iOSCurrentVersion;
    property tvOSVersion: String := tvOSCurrentVersion;
    property watchOSVersion: String := watchOSCurrentVersion;
    property BetaSuffix: String := "";
    property DeveloperFolder: String := ToffeePaths.Instance.LocalXcodeDeveloperFolder;
    property Island := true;
    property Toffee := false;

    property Mode: String read if Toffee then "Toffee" else if Island then "Island" else "Unknown";

    //property CrossBox := RemObjects.Elements.CrossBox.CrossBoxManager.Instance.LocalCrossBoxServer as RemObjects.Elements.CrossBox.ICrossBoxServerForToffee; readonly;


    method CalculateIntegerVersion(aName: String; aVersion: String): String;
    begin
      if aName in ["OS X", "macOS"] then begin
        if aVersion.CompareVersionTripleTo("10.10") ≥ 0 then
          result := ShortVersion(aVersion).Replace(".", "")+"00" // 10.10 -> 101000;
        else
          result := ShortVersion(aVersion).Replace(".", "")+"0"; // 10.8 -> 1080;
      end
      else begin
        result := ShortVersion(aVersion).Replace(".", "0")+"00"; // 6.1 -> 60100
      end;
    end;

    method ShortVersion(aVersion: String): String;
    begin
      var v := aVersion.split(".");
      if length(v) < 2 then
        raise new Exception($"Invalid SDK version beginaVersionend;");
      result := v[0]+"."+v[1];
    end;

    method NameForMacOS(aVersion: String): String;
    begin
      //if aVersion.MinorVersionNumber ≥ 12 then
        result := "macOS"
      //else
        //result := "OS X";
    end;

    method SdkNameInXcode(aName: String; aVersion: String; aSimulator: Boolean): String;
    begin
      result := case aName of
        "macOS": "MacOSX";
        "iOS": if aSimulator then "iPhoneSimulator" else "iPhoneOS";
        "tvOS": if aSimulator then "AppleTVSimulator" else "AppleTVOS";
        "watchOS": if aSimulator then "WatchSimulator" else "WatchOS";
      end;
    end;

    method SdkFolderInXcode(aName: String; aVersion: String; aSimulator: Boolean): String;
    begin
      var lShortVersion := ShortVersion(aVersion);
      var lNameInXcode := SdkNameInXcode(aName, aVersion, aSimulator);
      result := Path.Combine(Darwin.DeveloperFolder, "Platforms", $"{lNameInXcode}.platform", "Developer", "SDKs", $"{lNameInXcode}{lShortVersion}.sdk");
    end;

    //
    // Architectures
    //

    method AllArchitectures: sequence of tuple of (Architecture, String); iterator;
    begin
      yield (Architecture_macOS_x86_64, macOSVersion);
      yield (Architecture_iOS_armv7, iOSVersion);
      yield (Architecture_iOS_armv7s, iOSVersion);
      yield (Architecture_iOS_arm64, iOSVersion);
      yield (Architecture_iOSSimulator_i386, iOSVersion);
      yield (Architecture_iOSSimulator_x86_64, iOSVersion);
      yield (Architecture_tvOS_arm64, tvOSVersion);
      yield (Architecture_tvOSSimulator_x86_64, tvOSVersion);
      yield (Architecture_watchOS_armv7k, watchOSVersion);
      yield (Architecture_watchOS_arm64, watchOSVersion);
      yield (Architecture_watchOSSimulator_i386, watchOSVersion);
      yield (Architecture_watchOSSimulator_x86_64, watchOSVersion);
    end;

    method macOSArchitectures: sequence of tuple of (Architecture, String); iterator;
    begin
      yield (Architecture_macOS_x86_64, macOSVersion);
    end;

    method iOSArchitectures: sequence of tuple of (Architecture, String); iterator;
    begin
      //if iOSVersion.CompareVersionTripleTo(MAX_IOS_VERSION_FOR_ARM_32BIT) ≤ 0 then begin
      yield (Architecture_iOS_armv7, iOSVersion);
      if iOSVersion.CompareVersionTripleTo(MIN_IOS_VERSION_FOR_ARMV7S) ≥ 0/* && compareVersions(version, MAX_IOS_VERSION_FOR_ARM_32BIT) <= 0)*/ then
        yield (Architecture_iOS_armv7s, iOSVersion);
      //end;
      if iOSVersion.CompareVersionTripleTo(MIN_IOS_VERSION_FOR_ARM64) ≥ 0 then
        yield (Architecture_iOS_arm64, iOSVersion);
    end;

    method iOSSimulatorArchitectures: sequence of tuple of (Architecture, String); iterator;
    begin
      //if iOSVersion.CompareVersionTripleTo(MAX_IOS_VERSION_FOR_ARM_32BIT) ≤ 0 then
      yield (Architecture_iOSSimulator_i386, iOSVersion);
      if iOSVersion.CompareVersionTripleTo(MIN_IOS_VERSION_FOR_ARM64) ≥ 0 then
        yield (Architecture_iOSSimulator_x86_64, iOSVersion);
    end;

    method tvOSArchitectures: sequence of tuple of (Architecture, String); iterator;
    begin
      yield (Architecture_tvOS_arm64, tvOSVersion);
    end;

    method tvOSSimulatorArchitectures: sequence of tuple of (Architecture, String); iterator;
    begin
      yield (Architecture_tvOSSimulator_x86_64, tvOSVersion);
    end;

    method watchOSArchitectures: sequence of tuple of (Architecture, String); iterator;
    begin
      yield (Architecture_watchOS_armv7k, watchOSVersion);
      if watchOSVersion.CompareVersionTripleTo(MIN_WATCHOS_VERSION_FOR_ARM64) ≥ 0 then
        yield (Architecture_watchOS_arm64, watchOSVersion);
    end;

    method watchOSSimulatorArchitectures: sequence of tuple of (Architecture, String); iterator;
    begin
      yield (Architecture_watchOSSimulator_i386, watchOSVersion);
      if watchOSVersion.CompareVersionTripleTo(MIN_WATCHOS_VERSION_FOR_ARM64) ≥ 0 then
        yield (Architecture_watchOSSimulator_x86_64, watchOSVersion);
    end;

    //
    // RTL Files
    //

    method IsInBlacklist(aBlacklist: ImmutableList<String>; aName: String; aVersion: String; aArchitecture: Architecture): Boolean;
    begin
      if aBlacklist.Contains(aName) then begin
        writeLn("Skipping " + aName + ", blacklisted");
        exit true;
      end;

      if aBlacklist.Contains(aVersion + ":" + aName) then begin
        writeLn("Skipping " + aName + ", blacklisted for " + aVersion);
        exit true;
      end;

      if aBlacklist.Contains(aArchitecture.Triple + ":" + aName) then begin
        writeLn("Skipping " + aName + ", blacklisted for " + aArchitecture.Triple);
        exit true;
      end;

      if aBlacklist.Contains(aVersion + ":" + aArchitecture.Triple + ":" + aName) then begin
        writeLn("Skipping " + aName + ", blacklisted for " + aVersion + ":" + aArchitecture.Triple);
        exit true;
      end;

      exit false;
    end;

    method FilterIncludeFileList(aList: array of String; aVersion: String; aArchitecture: Architecture): List<String>; inline;
    begin
      result := FilterIncludeFileList(aList.ToList(), aVersion, aArchitecture);
    end;

    method FilterIncludeFileList(aList: ImmutableList<String>; aVersion: String; aArchitecture: Architecture): List<String>;
    begin
      result := new List<String>;
      for each f in aList do
        if not IsInBlacklist(IncludeHeaderBlackList, f, aVersion, aArchitecture) then
          result.Add(f);
    end;

    method GetRTLFiles(aVersion: String; aArchitecture: Architecture): ImmutableList<String>;
    begin
      var lFiles := FilterIncludeFileList(rtlFiles, aVersion, aArchitecture);;
      case aArchitecture.SDKName of
        "macOS": lFiles.Add(FilterIncludeFileList(rtlFiles_macOS, aVersion, aArchitecture));
        "iOS": if aArchitecture.Simulator then
            lFiles.Add(FilterIncludeFileList(rtlFiles_iOSSimulator, aVersion, aArchitecture))
          else
            lFiles.Add(FilterIncludeFileList(rtlFiles_iOS, aVersion, aArchitecture));
        "watchOS": if aArchitecture.Simulator then
            lFiles.Add(FilterIncludeFileList(rtlFiles_watchOSSimulator, aVersion, aArchitecture))
          else
            lFiles.Add(FilterIncludeFileList(rtlFiles_watchOS, aVersion, aArchitecture));
        "tvOS": if aArchitecture.Simulator then
            lFiles.Add(FilterIncludeFileList(rtlFiles_tvOSSimulator, aVersion, aArchitecture))
          else
            lFiles.Add(FilterIncludeFileList(rtlFiles_tvOS, aVersion, aArchitecture));
      end;
      result := lFiles;
    end;

    method GetIndirectRTLFiles(aVersion: String; aArchitecture: Architecture): ImmutableList<String>;
    begin
      var lFiles := FilterIncludeFileList(indirectRtlFiles, aVersion, aArchitecture);;
      case aArchitecture.SDKName of
        "macOS": lFiles.Add(FilterIncludeFileList(indirectRtlFiles_macOS, aVersion, aArchitecture));
        "iOS": if aArchitecture.Simulator then
            lFiles.Add(FilterIncludeFileList(indirectRtlFiles_iOSSimulator, aVersion, aArchitecture))
          else
            lFiles.Add(FilterIncludeFileList(indirectRtlFiles_iOS, aVersion, aArchitecture));
        "watchOS": if aArchitecture.Simulator then
            lFiles.Add(FilterIncludeFileList(indirectRtlFiles_watchOSSimulator, aVersion, aArchitecture))
          else
            lFiles.Add(FilterIncludeFileList(indirectRtlFiles_watchOS, aVersion, aArchitecture));
        "tvOS": if aArchitecture.Simulator then
            lFiles.Add(FilterIncludeFileList(indirectRtlFiles_tvOSSimulator, aVersion, aArchitecture))
          else
            lFiles.Add(FilterIncludeFileList(indirectRtlFiles_tvOS, aVersion, aArchitecture));
      end;
      result := lFiles;
    end;

    method GetForceIncludeFiles(aVersion: String; aArchitecture: Architecture): JsonArray;
    begin
      var lPerPlatformString := case aArchitecture.SDKName of
        "macOS": forceIncludes_macOS;
        "iOS": forceIncludes_iOS;
        "watchOS": forceIncludes_watchOS;
        "tvOS": forceIncludes_tvOS;
      end;
      var lShared := JsonDocument.TryFromString(forceIncludes_Shared);
      var lPerPlatform := JsonDocument.TryFromString(lPerPlatformString);
      result := lShared.Root as JsonArray;
      result.Add((lPerPlatform.Root as JsonArray).Items);
    end;

    method FilterBlacklist(aBlackList: ImmutableList<String>; aVersion: String; aArchitecture: Architecture): ImmutableList<String>;
    begin
      var lResult := new List<String>;
      for each b in aBlackList do begin
        var i := b.indexOf(':');

        if i > -1 then begin
          var prefix := b.substring(0, i);
          b := b.substring(i+1);
          if (prefix ≠ aVersion) and (prefix ≠ aArchitecture.Triple) and (prefix ≠ aArchitecture.SDKName) then
            continue;
          i := b.indexOf(':');
          if i > -1 then begin
            prefix := b.Substring(0, i);
            b := b.Substring(i + 1);
            if prefix ≠ aVersion then begin
              continue;
            end;
            lResult.Add(b);
          end
          else begin
            lResult.Add(b);
          end;
        end
        else begin
          lResult.Add(b);
        end;

      end;
      result := lResult;
    end;

  end;

end.