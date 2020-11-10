namespace RemObjects.Elements.HI2;

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

    Vendor: String;
    OS: String;
    Environment: String;

    property DisplaySDKName: String read if OS = "DriverKit" then OS else if Environment = "macabi" then "Mac Catalyst" else SDKName;
    property MacCatalyst: Boolean read Environment = "macabi";
  end;

  Darwin = public static partial class
  private

    const _definesShared = "_USE_EXTENDED_LOCALES_;__LITTLE_ENDIAN__;__APPLE__;__APPLE_CC__;__MACH__;__GNUC__=4;__GNUC_MINOR__=2;__OBJC__;__OBJC2__;__STDC__=1;JSC_OBJC_API_ENABLED;WK_API_ENABLED;OS_OBJECT_USE_OBJC;OS_OBJECT_HAVE_OBJC_SUPPORT";
    const _macOSdefines_x64 =      _definesShared+";__x86_64__;__LP64__=1;__SSE__;__SSE2__;IOKIT;CPU64";
    const _macOSdefines_arm64 =    _definesShared+";__arm64__;__LP64__=1;ARM;ARM64;CPU64"; {$HINT GUESSWORK}
    const _iOSDefines32 =          _definesShared+";__arm__;ARM;CPU32;";
    const _iOSDefines64 =          _definesShared+";__arm64__;__LP64__=1;ARM;ARM64;CPU64";
    const _watchOSDefines64 =      _definesShared+";__arm__;__arm64_32__;ARM;ARM64;";
    const _iOSDefinesSimulator32 = _definesShared+";__i386__;__SSE__;__SSE2__;CPU32";
    const _iOSDefinesSimulator64 = _macOSdefines_x64;

    const cpuType_Penryn = "penryn";

  public
    const AVAILABILITY_HACK = ";__AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_13=;__AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_14=;__AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_15=";

    const macOSDefines_x64 =          _macOSdefines_x64+";OSX;MACOS;MAC;DEVICE";//+AVAILABILITY_HACK;
    const macOSDefines_arm64 =        _macOSdefines_arm64+";OSX;MACOS;MAC;DEVICE";//+AVAILABILITY_HACK;
    const MacCatalystDefines_x64 =    _macOSdefines_x64+";IOS;MACOS;MAC;UIKITFORMAC;MACCATALYST;!TARGET_OS_IPHONE=1";//+AVAILABILITY_HACK;
    const MacCatalystDefines_arm64 =  _macOSdefines_arm64+";IOS;MACOS;MAC;UIKITFORMAC;MACCATALYST;!TARGET_OS_IPHONE=1";//+AVAILABILITY_HACK;
    const iOSDefines32 =              _iOSDefines32+";IOS;DEVICE;";
    const iOSDefines64 =              _iOSDefines64+";IOS;DEVICE;";
    const watchOSDefines32 =          _iOSDefines32+";WATCHOS;DEVICE";
    const watchOSDefines64 =          _watchOSDefines64+";WATCHOS;DEVICE";
    const tvOSDefines64 =             _iOSDefines64+";TVOS;DEVICE";
    const iOSDefinesSimulatorI386 =      _iOSDefinesSimulator32+";IOS;IOSSIMULATOR;SIMULATOR";
    const iOSDefinesSimulatorX64 =       _iOSDefinesSimulator64+";IOS;IOSSIMULATOR;SIMULATOR";
    const iOSDefinesSimulatorArm64 =     _iOSDefines64         +";IOS;IOSSIMULATOR;SIMULATOR";
    const watchOSDefinesSimulatori386 =  _iOSDefinesSimulator32+";WATCHOS;WATCHOSSIMULATOR;SIMULATOR";
    const watchOSDefinesSimulatorX64 =   _iOSDefinesSimulator64+";WATCHOS;WATCHOSSIMULATOR;SIMULATOR";
    const watchOSDefinesSimulatorArm64 = _iOSDefines64         +";WATCHOS;WATCHOSSIMULATOR;SIMULATOR";
    const tvOSDefinesSimulatorX64 =      _iOSDefinesSimulator64+";TVOS;TVOSSIMULATOR;SIMULATOR";
    const tvOSDefinesSimulatorArm64 =    _iOSDefines64         +";TVOS;TVOSSIMULATOR;SIMULATOR";

    const ExtraDefinesToffee = ";DARWIN;__ELEMENTS;__TOFFEE__";
    const ExtraDefinesIsland = ";DARWIN;__ELEMENTS;__ISLAND__;POSIX";

    property Architecture_MacCatalyst_x86_64      : Architecture read new Architecture(Triple := "x86_64-apple-ios-macabi", Defines := MacCatalystDefines_x64,       SDKName := "iOS",                        Environment := "macabi",     CpuType := cpuType_Penryn);
    property Architecture_MacCatalyst_arm64       : Architecture read new Architecture(Triple := "arm64-apple-ios-macabi",  Defines := MacCatalystDefines_arm64,     SDKName := "iOS",                        Environment := "macabi");
    property Architecture_DriverKit_x86_64        : Architecture read new Architecture(Triple := "x86_64-apple-macosx",     Defines := macOSDefines_x64,             SDKName := "macOS", OS := "DriverKit",                                CpuType := cpuType_Penryn);
    property Architecture_DriverKit_arm64         : Architecture read new Architecture(Triple := "arm64-apple-macosx" ,     Defines := macOSDefines_arm64,           SDKName := "macOS", OS := "DriverKit");
    property Architecture_macOS_x86_64            : Architecture read new Architecture(Triple := "x86_64-apple-macosx",     Defines := macOSDefines_x64,             SDKName := "macOS",                                                   CpuType := cpuType_Penryn);
    property Architecture_macOS_arm64             : Architecture read new Architecture(Triple := "arm64-apple-macosx",      Defines := macOSDefines_arm64,           SDKName := "macOS");
    property Architecture_iOS_armv7               : Architecture read new Architecture(Triple := "armv7-apple-ios",         Defines := iOSDefines32,                 SDKName := "iOS");
    property Architecture_iOS_armv7s              : Architecture read new Architecture(Triple := "armv7s-apple-ios",        Defines := iOSDefines32,                 SDKName := "iOS",                                                                                MinimumTargetSDK := "6.0");
    property Architecture_iOS_arm64               : Architecture read new Architecture(Triple := "arm64-apple-ios",         Defines := iOSDefines64,                 SDKName := "iOS",                                                                                MinimumTargetSDK := "6.0",  MinimumDeploymentTarget := "6.0");
    property Architecture_iOS_arm64e              : Architecture read new Architecture(Triple := "arm64e-apple-ios",        Defines := iOSDefines64,                 SDKName := "iOS",                                                                                MinimumTargetSDK := "12.0", MinimumDeploymentTarget := "12.0");
    property Architecture_iOSSimulator_i386       : Architecture read new Architecture(Triple := "i386-apple-ios",          Defines := iOSDefinesSimulatorI386,      SDKName := "iOS",     Simulator := true, Environment := "simulator",  CpuType := cpuType_Penryn);
    property Architecture_iOSSimulator_x86_64     : Architecture read new Architecture(Triple := "x86_64-apple-ios",        Defines := iOSDefinesSimulatorX64,       SDKName := "iOS",     Simulator := true, Environment := "simulator",  CpuType := cpuType_Penryn, MinimumTargetSDK := "6.0",  MinimumDeploymentTarget := "6.0");
    property Architecture_iOSSimulator_arm64      : Architecture read new Architecture(Triple := "arm64-apple-ios",         Defines := iOSDefinesSimulatorArm64,     SDKName := "iOS",     Simulator := true, Environment := "simulator",                             MinimumTargetSDK := "14.2",  MinimumDeploymentTarget := "14.2");
    property Architecture_watchOS_armv7k          : Architecture read new Architecture(Triple := "armv7k-apple-watchos",    Defines := watchOSDefines32,             SDKName := "watchOS",                                                                            MinimumTargetSDK := "2.0");
    property Architecture_watchOS_arm64_32        : Architecture read new Architecture(Triple := "arm64_32-apple-watchos",  Defines := watchOSDefines64,             SDKName := "watchOS",                                                                            MinimumTargetSDK := "5.0");
    property Architecture_watchOSSimulator_i386   : Architecture read new Architecture(Triple := "i386-apple-watchos",      Defines := watchOSDefinesSimulatori386,  SDKName := "watchOS", Simulator := true, Environment := "simulator",  CpuType := cpuType_Penryn, MinimumTargetSDK := "2.0");
    property Architecture_watchOSSimulator_x86_64 : Architecture read new Architecture(Triple := "x86_64-apple-watchos",    Defines := watchOSDefinesSimulatorX64,   SDKName := "watchOS", Simulator := true, Environment := "simulator",  CpuType := cpuType_Penryn, MinimumTargetSDK := "5.0");
    property Architecture_watchOSSimulator_arm64  : Architecture read new Architecture(Triple := "arm64-apple-watchos",     Defines := watchOSDefinesSimulatorArm64, SDKName := "watchOS", Simulator := true, Environment := "simulator",                             MinimumTargetSDK := "7.1");
    property Architecture_tvOS_arm64              : Architecture read new Architecture(Triple := "arm64-apple-tvos",        Defines := tvOSDefines64,                SDKName := "tvOS",                                                                               MinimumTargetSDK := "9.0");
    property Architecture_tvOSSimulator_x86_64    : Architecture read new Architecture(Triple := "x86_64-apple-tvos",       Defines := tvOSDefinesSimulatorX64,      SDKName := "tvOS",    Simulator := true, Environment := "simulator",  CpuType := cpuType_Penryn, MinimumTargetSDK := "9.0");
    property Architecture_tvOSSimulator_arm64     : Architecture read new Architecture(Triple := "arm64-apple-tvos",        Defines := tvOSDefinesSimulatorArm64,    SDKName := "tvOS",    Simulator := true, Environment := "simulator",                             MinimumTargetSDK := "14.2");

    const macOSEnvironmentVersionDefine   = '__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__';
    const iOSEnvironmentVersionDefine     = '__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__';
    const tvOSEnvironmentVersionDefine    = '__ENVIRONMENT_TV_OS_VERSION_MIN_REQUIRED__';
    const watchOSEnvironmentVersionDefine = '__ENVIRONMENT_WATCH_OS_VERSION_MIN_REQUIRED__';

    const macCatalystDeploymentTargets_x86_64 =   "14.0;13.0";
    const macCatalystDeploymentTargets_arm64  =   "14.0";
    const macOSDeploymentTargets_x86_64 =   "11.0;10.15;10.14;10.13;10.12;10.11;10.10;10.9;10.8;10.7;10.6";
    const macOSDeploymentTargets_arm64 =    "11.0";
    const iOSDeploymentTargets =     "14.0;13.0;12.0;11.0;10.0;9.0";
    const tvOSDeploymentTargets =    "14.0;13.0;12.0;11.0;10.0;9.0";
    const watchOSDeploymentTargets = "7.0;6.0;5.0;4.0;3.0;2.0";

    method DeploymentTargets(aSDK: String; aArchitecture: String): String;
    begin
      result := case aSDK of
        "macOS": case aArchitecture of
            "arm64": macOSDeploymentTargets_arm64;
            "x86_64": macOSDeploymentTargets_x86_64;
          end;
        "Mac Catalyst": case aArchitecture of
            "arm64": macCatalystDeploymentTargets_arm64;
            "x86_64": macCatalystDeploymentTargets_x86_64;
          end;
        "iOS": iOSDeploymentTargets;
        "tvOS": tvOSDeploymentTargets;
        "watchOS": watchOSDeploymentTargets;
      end;
    end;

    const MIN_MACOS_VERSION_FOR_ARM64   = "11.0";
    const MAX_MACOS_VERSION_FOR_X86_64  = "1000.0";

    const MIN_IOS_VERSION_FOR_ARMV7S    = "6.0";
    const MIN_IOS_VERSION_FOR_ARM64     = "7.0";
    const MIN_IOS_VERSION_FOR_ARM64E    = "12.0";
    const MIN_IOS_VERSION_FOR_ARM64E_SIMULATOR = "14.2";
    const MAX_IOS_VERSION_FOR_ARM_32BIT = "10.0";

    const MIN_WATCHOS_VERSION_FOR_ARM64 = "5.0";
    const MIN_WATCHOS_VERSION_FOR_ARM64E_SIMULATOR = "7.1";

    const MIN_TVOS_VERSION_FOR_ARM64E_SIMULATOR = MIN_IOS_VERSION_FOR_ARM64E_SIMULATOR;

    const macOSCurrentVersion = "11.0";
    const iOSCurrentVersion = "14.0";
    const tvOSCurrentVersion = "14.0";
    const watchOSCurrentVersion = "7.0";
    const driverKitCurrentVersion = "20.0";
    const xcodeCurrentVersion = "12.0";

    // Ovverride these values to control what Xcode ansd SDK Versions to use
    property macOSVersion: String := macOSCurrentVersion;
    property iOSVersion: String := iOSCurrentVersion;
    property tvOSVersion: String := tvOSCurrentVersion;
    property watchOSVersion: String := watchOSCurrentVersion;
    property DriverKitVersion: String := driverKitCurrentVersion;
    property BetaSuffix: String := "";
    property DeveloperFolder: String := ToffeePaths.Instance.LocalXcodeDeveloperFolder;
    property Island := true;
    property Toffee := false;

    property Mode: String read if Toffee then "Toffee" else if Island then "Island" else "Unknown";

    //property CrossBox := RemObjects.Elements.CrossBox.CrossBoxManager.Instance.LocalCrossBoxServer as RemObjects.Elements.CrossBox.ICrossBoxServerForToffee; readonly;

    property iOS32: Boolean read Toffee or (iOSVersion.CompareVersionTripleTo(MAX_IOS_VERSION_FOR_ARM_32BIT) ≤ 0);
    property iOS64: Boolean read iOSVersion.CompareVersionTripleTo(MIN_IOS_VERSION_FOR_ARM64) ≥ 0;
    property macOS_Intel: Boolean read macOSVersion.CompareVersionTripleTo(MAX_MACOS_VERSION_FOR_X86_64) ≤ 0;
    property macOS_ARM: Boolean read macOSVersion.CompareVersionTripleTo(MIN_MACOS_VERSION_FOR_ARM64) ≥ 0;
    property macCatalyst_Intel: Boolean read macOS_Intel;
    property macCatalyst_ARM: Boolean read macOS_ARM;
    property iOSSimulatorArm: Boolean read iOSVersion.CompareVersionTripleTo(MIN_IOS_VERSION_FOR_ARM64E_SIMULATOR) ≥ 0;
    property watchOSSimulatorArm: Boolean read iOSVersion.CompareVersionTripleTo(MIN_WATCHOS_VERSION_FOR_ARM64E_SIMULATOR) ≥ 0;
    property tvOSSimulatorArm: Boolean read iOSVersion.CompareVersionTripleTo(MIN_TVOS_VERSION_FOR_ARM64E_SIMULATOR) ≥ 0;

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

    method PlatformNameInXcode(aName: String; aVersion: String; aSimulator: Boolean): String;
    begin
      result := case aName of
        "macOS": "MacOSX";
        "Mac Catalyst": "MacOSX";
        "DriverKit": "MacOSX";
        "iOS": if aSimulator then "iPhoneSimulator" else "iPhoneOS";
        "tvOS": if aSimulator then "AppleTVSimulator" else "AppleTVOS";
        "watchOS": if aSimulator then "WatchSimulator" else "WatchOS";
      end;
    end;

    method SdkNameInXcode(aName: String; aVersion: String; aSimulator: Boolean): String;
    begin
      result := case aName of
        "macOS": "MacOSX";
        "Mac Catalyst": "MacOSX";
        "DriverKit": "DriverKit";
        "iOS": if aSimulator then "iPhoneSimulator" else "iPhoneOS";
        "tvOS": if aSimulator then "AppleTVSimulator" else "AppleTVOS";
        "watchOS": if aSimulator then "WatchSimulator" else "WatchOS";
      end;
    end;

    method SdkFolderInXcode(aName: String; aVersion: String; aSimulator: Boolean): String;
    begin
      var lShortVersion := ShortVersion(aVersion);
      var lPlatformNameInXcode := PlatformNameInXcode(aName, aVersion, aSimulator);
      var lSdkNameInXcode := SdkNameInXcode(aName, aVersion, aSimulator);
      result := Path.Combine(Darwin.DeveloperFolder, "Platforms", $"{lPlatformNameInXcode}.platform", "Developer", "SDKs", $"{lSdkNameInXcode}{lShortVersion}.sdk");
    end;

    //
    // Architectures
    //

    method AllIslandDarwinArchitectures: sequence of tuple of (Architecture, String); iterator;
    begin
      yield (Architecture_macOS_arm64, macOSVersion);
      yield (Architecture_macOS_x86_64, macOSVersion);
      yield (Architecture_MacCatalyst_x86_64, iOSVersion);
      yield (Architecture_MacCatalyst_arm64, iOSVersion);
      //yield (Architecture_iOS_armv7, iOSVersion);
      //yield (Architecture_iOS_armv7s, iOSVersion);
      yield (Architecture_iOS_arm64, iOSVersion);
      //yield (Architecture_iOSSimulator_i386, iOSVersion);
      yield (Architecture_iOSSimulator_x86_64, iOSVersion);
      yield (Architecture_iOSSimulator_arm64, iOSVersion);
      yield (Architecture_tvOS_arm64, tvOSVersion);
      yield (Architecture_tvOSSimulator_x86_64, tvOSVersion);
      yield (Architecture_tvOSSimulator_arm64, iOSVersion);
      yield (Architecture_watchOS_armv7k, watchOSVersion);
      yield (Architecture_watchOS_arm64_32, watchOSVersion);
      yield (Architecture_watchOSSimulator_i386, watchOSVersion);
      yield (Architecture_watchOSSimulator_x86_64, watchOSVersion);
      yield (Architecture_watchOSSimulator_arm64, iOSVersion);
    end;

    method MacCatalystArchitectures: sequence of tuple of (Architecture, String); iterator;
    begin
      if macCatalyst_ARM then
        yield (Architecture_MacCatalyst_arm64, macOSVersion);
      if macCatalyst_Intel then
        yield (Architecture_MacCatalyst_x86_64, macOSVersion);
    end;

    method DriverKitArchitectures: sequence of tuple of (Architecture, String); iterator;
    begin
      yield (Architecture_DriverKit_x86_64, macOSVersion);
    end;

    method macOSArchitectures: sequence of tuple of (Architecture, String); iterator;
    begin
      if macOS_ARM then
        yield (Architecture_macOS_arm64, macOSVersion);
      if macOS_Intel then
        yield (Architecture_macOS_x86_64, macOSVersion);
    end;

    method iOSArchitectures: sequence of tuple of (Architecture, String); iterator;
    begin
      if iOS32 then
        yield (Architecture_iOS_armv7, iOSVersion);
      if (iOSVersion.CompareVersionTripleTo(MIN_IOS_VERSION_FOR_ARMV7S) ≥ 0) and iOS32 then
        yield (Architecture_iOS_armv7s, iOSVersion);
      //if (iOSVersion.CompareVersionTripleTo(MIN_IOS_VERSION_FOR_ARM64E) ≥ 0) and Island then
      //  yield (Architecture_iOS_arm64e, iOSVersion);
      if iOS64 then
        yield (Architecture_iOS_arm64, iOSVersion);
    end;

    method iOSSimulatorArchitectures: sequence of tuple of (Architecture, String); iterator;
    begin
      if iOS32 then
        yield (Architecture_iOSSimulator_i386, iOSVersion);
      if iOS64 then
        yield (Architecture_iOSSimulator_x86_64, iOSVersion);
      if iOSSimulatorArm then
        yield (Architecture_iOSSimulator_arm64, iOSVersion);
    end;

    method tvOSArchitectures: sequence of tuple of (Architecture, String); iterator;
    begin
      yield (Architecture_tvOS_arm64, tvOSVersion);
    end;

    method tvOSSimulatorArchitectures: sequence of tuple of (Architecture, String); iterator;
    begin
      yield (Architecture_tvOSSimulator_x86_64, tvOSVersion);
      if tvOSSimulatorArm then
        yield (Architecture_tvOSSimulator_arm64, iOSVersion);
    end;

    method watchOSArchitectures: sequence of tuple of (Architecture, String); iterator;
    begin
      yield (Architecture_watchOS_armv7k, watchOSVersion);
      if watchOSVersion.CompareVersionTripleTo(MIN_WATCHOS_VERSION_FOR_ARM64) ≥ 0 then
        yield (Architecture_watchOS_arm64_32, watchOSVersion);
    end;

    method watchOSSimulatorArchitectures: sequence of tuple of (Architecture, String); iterator;
    begin
      yield (Architecture_watchOSSimulator_i386, watchOSVersion);
      if watchOSVersion.CompareVersionTripleTo(MIN_WATCHOS_VERSION_FOR_ARM64) ≥ 0 then
        yield (Architecture_watchOSSimulator_x86_64, watchOSVersion);
      if watchOSSimulatorArm then
        yield (Architecture_watchOSSimulator_arm64, iOSVersion);
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
        "macOS":
          case aArchitecture.OS of
            "DriverKit": //lFiles.Add(FilterIncludeFileList(rtlFiles_DriverKit, aVersion, aArchitecture));
            else lFiles.Add(FilterIncludeFileList(rtlFiles_macOS, aVersion, aArchitecture));
          end;
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
        "macOS":
          case aArchitecture.OS of
            "DriverKit": lFiles := FilterIncludeFileList(indirectRtlFiles_DriverKit, aVersion, aArchitecture); // and ONLY driverkit
            else lFiles.Add(FilterIncludeFileList(indirectRtlFiles_macOS, aVersion, aArchitecture));
          end;

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
        "Mac Catalyst": forceIncludes_macOS;
        "iOS": forceIncludes_iOS;
        "watchOS": forceIncludes_watchOS;
        "tvOS": forceIncludes_tvOS;
      end;

      if aArchitecture.Environment = "macabi" then
        lPerPlatformString := forceIncludes_macOS;

      var lShared := JsonDocument.TryFromString(forceIncludes_Shared);
      var lPerPlatform := JsonDocument.TryFromString(lPerPlatformString);
      result := lShared.Root as JsonArray;
      result.Add((lPerPlatform.Root as JsonArray).Items);
    end;

    method FilterBlacklist(aBlackList: ImmutableList<String>; aVersion: String; aArchitecture: Architecture): ImmutableList<String>;
    begin
      var lResult := new List<String>;
      for each b in aBlackList do begin
        var i := b.IndexOf(':');

        if i > -1 then begin
          var prefix := b.Substring(0, i);
          b := b.Substring(i+1);
          if (prefix ≠ aVersion) and (prefix ≠ aArchitecture.Triple) and (prefix ≠ aArchitecture.SDKName) then
            continue;
          i := b.IndexOf(':');
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