namespace HI2;

type
  Architecture = public record
  public
    Triple: String;
    CpuType: String;
    Defines: String;
    SDKName: String;
    Simulator: Boolean;
    MinimumTargetSDK: String;
    MinimumDeploymentTarget: String;
  end;

  Darwin = public static class
  private
    const _definesShared = "__LITTLE_ENDIAN__;__APPLE__;__APPLE_CC__;__MACH__;__GNUC__=4;__GNUC_MINOR__=2;__OBJC__;__OBJC2__;__STDC__=1;__NOUGAT__;__TOFFEE__;JSC_OBJC_API_ENABLED";
    const _macOSdefines64 =        _definesShared+";__x86_64__;__LP64__=1;__SSE__;__SSE2__;IOKIT";
    const _iOSDefines32 =          _definesShared+";__arm__";
    const _iOSDefines64 =          _definesShared+";__arm__;__arm64__;__LP64__=1";
    const _iOSDefinesSimulator32 = _definesShared+";__i386__;__SSE__;__SSE2__";
    const _iOSDefinesSimulator64 = _macOSdefines64;

    const cpuType_Penryn = "penryn";

  public
    const macOSDefines64 =            _macOSdefines64+"OSX;MACOS;MAC;DEVICE";
    const iOSDefines32 =              _iOSDefines32+";IOS;DEVICE";
    const iOSDefines64 =              _iOSDefines64+";IOS;DEVICE";
    const watchOSDefines32 =          _iOSDefines32+";WATCHOS;DEVICE";
    const tvOSDefines64 =             _iOSDefines64+";TVOS;DEVICE";
    const iOSDefinesSimulator32 =     _iOSDefinesSimulator32+";IOS;IOSSIMULATOR;SIMULATOR";
    const iOSDefinesSimulator64 =     _iOSDefinesSimulator64+";IOS;IOSSIMULATOR;SIMULATOR";
    const watchOSDefinesSimulator32 = _iOSDefinesSimulator32+";WATCHOS;WATCHOSSIMULATOR;SIMULATOR";
    const tvOSDefinesSimulator64 =    _iOSDefinesSimulator64+";TVOS;TVOSSIMULATOR;SIMULATOR";

    property Architecture_macOS_x86_64          : Architecture read new Architecture(Triple := "x86_64-apple-macosx",  Defines := macOSDefines64,            SDKName := "macOS",                      CpuType := cpuType_Penryn);
    property Architecture_iOS_armv7             : Architecture read new Architecture(Triple := "armv7-apple-ios",      Defines := iOSDefines32,              SDKName := "iOS");
    property Architecture_iOS_armv7s            : Architecture read new Architecture(Triple := "armv7s-apple-ios",     Defines := iOSDefines32,              SDKName := "iOS",                                                   MinimumTargetSDK := "6.0");
    property Architecture_iOS_arm64             : Architecture read new Architecture(Triple := "arm64-apple-ios",      Defines := iOSDefines64,              SDKName := "iOS",                                                   MinimumTargetSDK := "6.0", MinimumDeploymentTarget := "6.0");
    property Architecture_iOSSimulator_i386     : Architecture read new Architecture(Triple := "i386-apple-ios",       Defines := iOSDefinesSimulator32,     SDKName := "iOS",     Simulator := true, CpuType := cpuType_Penryn);
    property Architecture_iOSSimulator_x86_64   : Architecture read new Architecture(Triple := "x86_64-apple-ios",     Defines := iOSDefinesSimulator64,     SDKName := "iOS",     Simulator := true, CpuType := cpuType_Penryn, MinimumTargetSDK := "6.0", MinimumDeploymentTarget := "6.0");
    property Architecture_watchOS_armv7k        : Architecture read new Architecture(Triple := "armv7k-apple-watchos", Defines := watchOSDefines32,          SDKName := "watchOS",                                               MinimumTargetSDK := "2.0");
    property Architecture_watchOSSimulator_i386 : Architecture read new Architecture(Triple := "i386-apple-watchos",   Defines := watchOSDefinesSimulator32, SDKName := "watchOS", Simulator := true, CpuType := cpuType_Penryn, MinimumTargetSDK := "2.0");
    property Architecture_tvOS_arm64            : Architecture read new Architecture(Triple := "arm64-apple-tvos",     Defines := tvOSDefines64,             SDKName := "tvOS",                                                  MinimumTargetSDK := "9.0");
    property Architecture_tvOSSimulator_x86_64  : Architecture read new Architecture(Triple := "x86_64-apple-tvos",    Defines := tvOSDefinesSimulator64,    SDKName := "tvOS",    Simulator := true, CpuType := cpuType_Penryn, MinimumTargetSDK := "9.0");

    //method AllArchitectures: tuple of (Architecture, String); iterator;
    //begin
      //yield (Architecture_macOS_x86_64, macOSCurrentVersion);
      //yield (Architecture_iOS_armv7, iOSCurrentVersion);
      //yield (Architecture_iOS_armv7s, iOSCurrentVersion);
      //yield (Architecture_iOS_arm64, iOSCurrentVersion);
      //yield (Architecture_iOSSimulator_i386, iOSCurrentVersion);
      //yield (Architecture_iOSSimulator_x86_64, iOSCurrentVersion);
      //yield (Architecture_tvOS_arm64, tvOSCurrentVersion);
      //yield (Architecture_tvOSSimulator_x86_64, tvOSCurrentVersion);
      //yield (Architecture_watchOS_armv7k, watchOSCurrentVersion);
      //yield (Architecture_watchOSSimulator_i386, watchOSCurrentVersion);
    //end;

    const macOSEnvironmentVersionDefine   = '__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__';
    const iOSEnvironmentVersionDefine     = '__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__';
    const tvOSEnvironmentVersionDefine    = '__ENVIRONMENT_TV_OS_VERSION_MIN_REQUIRED__';
    const watchOSEnvironmentVersionDefine = '__ENVIRONMENT_WATCH_OS_VERSION_MIN_REQUIRED__';

    const macOSDeploymentTargets =    "10.14;10.13;10.12;10.11;10.10;10.9;10.8;10.7;10.6";
    const iOSDeploymentTargets =     "12.0;11.4;11.0;10.0;9.0;8.0";
    const tvOSDeploymentTargets =    "12.0;11.4;11.0;10.0;9.0";
    const watchOSDeploymentTargets = "5.0;4.3;4.0;3.0;2.0";

    const MIN_IOS_VERSION_FOR_ARMV7S    = "6.0";
    const MIN_IOS_VERSION_FOR_ARM64     = "7.0";
    const MAX_IOS_VERSION_FOR_ARM_32BIT = "10.0";

    const macOSCurrentVersion = "10.14";
    const iOSCurrentVersion = "12.0";
    const tvOSCurrentVersion = "12.0";
    const watchOSCurrentVersion = "5.0";

    const xcodeCurrentVersion = "10.0"; // 2018
  end;

end.