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
    const _definesOSX64 =          _definesShared+";__x86_64__;__LP64__=1;__SSE__;__SSE2__;IOKIT";
    const _definesiOS32 =          _definesShared+";__arm__";
    const _definesiOS64 =          _definesShared+";__arm__;__arm64__;__LP64__=1";
    const _definesiOSSimulator32 = _definesShared+";__i386__;__SSE__;__SSE2__";
    const _definesiOSSimulator64 = _definesOSX64;

  public
    const definesOSX64 =              _definesOSX64+"OSX;MACOS";
    const definesiOS32 =              _definesiOS32+"IOS";
    const definesiOS64 =              _definesiOS64+"IOS";
    const definesWatchOS32 =          _definesiOS32+"WATCHOS";
    const definesTvOS64 =             _definesiOS64+"TVOS";
    const definesiOSSimulator32 =     _definesiOSSimulator32+"IOS";
    const definesiOSSimulator64 =     _definesiOSSimulator64+"IOS;IOSSIMULATOR;SIMULATOR";
    const definesWatchOSSimulator32 = _definesiOSSimulator32+"WATCHOS;WATCHOSSIMULATOR;SIMULATOR";
    const definesTvOSSimulator64 =    _definesiOSSimulator64+"TVOS;TVOSSIMULATOR;SIMULATOR";

    const cpuType_Penryn = "penryn";

    property architecture_OSX_x86_64            : Architecture read new Architecture(Triple := "x86_64-apple-macosx",  Defines := definesOSX64,              SDKName := "macOS",                      CpuType := cpuType_Penryn);
    property architecture_iOS_armv7             : Architecture read new Architecture(Triple := "armv7-apple-ios",      Defines := definesiOS32,              SDKName := "iOS");
    property architecture_iOS_armv7s            : Architecture read new Architecture(Triple := "armv7s-apple-ios",     Defines := definesiOS32,              SDKName := "iOS",                                                   MinimumTargetSDK := "6.0");
    property architecture_iOS_arm64             : Architecture read new Architecture(Triple := "arm64-apple-ios",      Defines := definesiOS64,              SDKName := "iOS",                                                   MinimumTargetSDK := "6.0", MinimumDeploymentTarget := "6.0");
    property architecture_iOSSimulator_i386     : Architecture read new Architecture(Triple := "i386-apple-ios",       Defines := definesiOSSimulator32,     SDKName := "iOS",     Simulator := true, CpuType := cpuType_Penryn);
    property architecture_iOSSimulator_x86_64   : Architecture read new Architecture(Triple := "x86_64-apple-ios",     Defines := definesiOSSimulator64,     SDKName := "iOS",     Simulator := true, CpuType := cpuType_Penryn, MinimumTargetSDK := "6.0", MinimumDeploymentTarget := "6.0");
    property architecture_watchOS_armv7k        : Architecture read new Architecture(Triple := "armv7k-apple-watchos", Defines := definesWatchOS32,          SDKName := "watchOS",                                               MinimumTargetSDK := "2.0");
    property architecture_watchOSSimulator_i386 : Architecture read new Architecture(Triple := "i386-apple-watchos",   Defines := definesWatchOSSimulator32, SDKName := "watchOS", Simulator := true, CpuType := cpuType_Penryn, MinimumTargetSDK := "2.0");
    property architecture_tvOS_arm64            : Architecture read new Architecture(Triple := "arm64-apple-tvos",     Defines := definesTvOS64,             SDKName := "tvOS",                                                  MinimumTargetSDK := "9.0");
    property architecture_tvOSSimulator_x86_64  : Architecture read new Architecture(Triple := "x86_64-apple-tvos",    Defines := definesTvOSSimulator64,    SDKName := "tvOS",    Simulator := true, CpuType := cpuType_Penryn, MinimumTargetSDK := "9.0");

    const OSXEnvironmentVersionDefine     = '__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__';
    const iOSEnvironmentVersionDefine     = '__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__';
    const watchOSEnvironmentVersionDefine = '__ENVIRONMENT_WATCH_OS_VERSION_MIN_REQUIRED__';
    const tvOSEnvironmentVersionDefine    = '__ENVIRONMENT_TV_OS_VERSION_MIN_REQUIRED__';

    const iOSDeploymentTargets =     "12.0;11.4;11.0;10.0;9.0;8.0";
    const OSXDeploymentTargets =     "10.14;10.13;10.12;10.11;10.10;10.9;10.8;10.7;10.6";
    const watchOSDeploymentTargets = "5.0;4.3;4.0;3.0;2.0";
    const tvOSDeploymentTargets =    "12.0;11.4;11.0;10.0;9.0";

    const MIN_IOS_VERSION_FOR_ARMV7S    = "6.0";
    const MIN_IOS_VERSION_FOR_ARM64     = "7.0";
    const MAX_IOS_VERSION_FOR_ARM_32BIT = "10.0";

  end;

end.