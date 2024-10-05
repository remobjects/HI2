namespace RemObjects.Elements.HI2;

type
  Darwin = public static partial class
  private
  protected
  public

    property EssentialFrameworks := ["CoreFoundation",
                                     "Foundation",

                                     "Combine",
                                     "SwiftUI",

                                     "AppKit",

                                     "UIKit"];

    property IncludeHeaderBlackList := [
                "sys/_symbol_aliasing.h",
                "sys/_posix_availability.h",
                "sys/vstat.h",
                "sys/_structs.h",
                "sys/_select.h",
                "sys/kauth.h",
                "sys/acl.h",
                "arm/_types.h",
                "sys/lctx.h",
                "sys/quota.h",
                "sys/vm.h",
                "sys/acct.h",
                "sys/dtrace.h",
                "sys/dtrace_glue.h",
                "sys/dtrace_impl.h",
                "sys/fasttrap.h",
                "sys/fasttrap_isa.h",
                "sys/kern_control.h",
                "sys/lockf.h",
                "sys/mbuf.h",
                "sys/netport.h",
                "sys/pipe.h",
                "sys/ptrace.h",
                "sys/resourcevar.h",
                "sys/sbuf.h",
                "sys/socketvar.h",
                "sys/ubc.h",
                "sys/unpcb.h",
                "sys/vmmeter.h",

                "AppleShareClientCore/afpHLMount.h",
                "ApplicationServices/CoreGraphics/*.h",
                "CarbonCore/CarbonCore.h",
                "CoreServices/LaunchServices/LSOpenDeprecated.h",
                "CoreServices/LaunchServices/LSInfoDeprecated.h",
                "CoreServices/CarbonCore/*.h", //fails on iOS 6.x Simulator and lower
                "x86_64-apple-macosx:device/*.h",
                "i386-apple-ios:device/*.h",
                "IOKit/IOHIDSessionPlugIn.h",
                "IOKit/iokitmig.h",
                "IOKit/IOSharedLock.h",
                "IOKit/graphics/*.h",
                "IOKit/OSMessageNotification.h",
                "IOKit/video/*.h",
                "Kernel/*.h",
                "libkern/OSKextLib.h",
                "OpenAL/oalMacOSX_OALExtensions.h",
                //"vecLib/*",
                "WebKit/WebCore/MicroTask.h",

                "10.8:sys/_types/*.h",

                "watchOS:11.0:Accelerate/vImage/vImage_CVUtilities.h", // watchOS 4.0 doesn't have CoreVideo (yet?)
                "watchOS:11.0:Accelerate/vImage/vImage_Utilities.h", // watchOS 4.0 doesn't have CoreVideo (yet?)

                //"Accelerate/vecLib/Sparse/SolveImplementation.h",
                //"Accelerate/vecLib/Sparse/SolveImplementationTyped.h",
                //"Accelerate/vecLib/LinearAlgebra/base.h",
                //"Accelerate/vecLib/LinearAlgebra/object.h",
                //"Accelerate/vecLib/LinearAlgebra/matrix.h",
                //"Accelerate/vecLib/LinearAlgebra/vector.h",
                //"Accelerate/vecLib/LinearAlgebra/splat.h",
                //"Accelerate/vecLib/LinearAlgebra/arithmetic.h",
                //"Accelerate/vecLib/LinearAlgebra/linear_systems.h",
                //"Accelerate/vecLib/LinearAlgebra/norms.h",

                //"arm64-apple-macosx:Accelerate/vecLib/LinearAlgebra/vBasicOps.h",
                //"arm64-apple-macosx:Accelerate/vecLib/LinearAlgebra/vecLibTypes.h",

                "Foundation/FoundationLegacySwiftCompatibility.h",

                // these three we import as separate .fx; not blacklisting them here will confuse HI later.
                "sqlite3.h",
                "zlib.h",
                "zconf.h",

                //"10.6:xpc/xpc.h"
                ].ToList; readonly;

    property FrameworksBlackList := [
                  'GSS',
                  '10.7:GSS',         /* GSS/gssapi.h (934) Cannot find include file: GSS/GSS/gssapi_spi.h */
                  '10.8:GSS',          /* GSS/gssapi_oid.h (25:41 pp: 751) One of Semicolon, Comma expected; current token: Identifier  __gss_krb5_copy_ccache_x_oid_desc */
                  '5.0:GSS',           /* GSS/gssapi.h (840:3 pp: 1733) Declaration expected; current token: Identifier  ssize_t */
                  '5.1:GSS',           /* GSS/gssapi.h (840:3 pp: 1733) Declaration expected; current token: Identifier  ssize_t */
                  '6.0:GSS',           /* GSS/gssapi_oid.h (25:41 pp: 742) One of Semicolon, Comma expected; current token: Identifier  __gss_krb5_copy_ccache_x_oid_desc */

                  /* known bad and not supported */
                  '10.6:JavaVM',        /* JavaNativeFoundation/JNFJNI.h (20) Cannot find include file: JavaNativeFoundation/JavaVM/jni.h */
                  'JavaFrameEmbedding',    /* JavaFrameEmbedding/JavaFrameView.h (10) Cannot find include file: JavaFrameEmbedding/jni.h */
                  'Tk',             /* An error occurred: Tk/tkMacOSX.h (31:61 pp: 662943) Declaration expected; current token: Identifier  TkRegion */

                  'QuickTime',         /* only 4.3 and below, anyways */
                  'vecLib',           /* it's in Accelerate, now */

                  /* review later: */
                  'AudioVideoBridging',           /* AudioVideoBridging/AVBConstants.h (16:27 pp: 770) Declaration expected; current token: Identifier  AVB17221ADPEntityCapabilities */
                  '10.6:Kerberos',             /* An error occurred: Kerberos/profile.h (190) Error token! */
                  'x86_64-apple-macosx:QuickTime',
                  'x86_64-apple-macosx:DVComponentGlue',

                  'Kernel',

                  //'i386-apple-watchos:AVFoundation',
                  'i386-apple-ios:IOKit',

                  '8.4:i386-apple-ios:Metal',
                  '8.3:i386-apple-ios:Metal',
                  '8.2:i386-apple-ios:Metal',
                  '8.1:i386-apple-ios:Metal',
                  '8.0:i386-apple-ios:Metal',
                  '8.4:x86_64-apple-ios:Metal',
                  '8.3:x86_64-apple-ios:Metal',
                  '8.2:x86_64-apple-ios:Metal',
                  '8.1:x86_64-apple-ios:Metal',
                  '8.0:x86_64-apple-ios:Metal',

                  '11.0:i386-apple-ios:IOSurface',    // fails on missing xpc/xpc.h
                  '11.0:x86_64-apple-ios:IOSurface',  // fails on missing xpc/xpc.h
                  '11.0:x86_64-apple-tvos:IOSurface', // fails on missing xpc/xpc.h
                  '11.1:i386-apple-ios:IOSurface',    // fails on missing xpc/xpc.h
                  '11.1:x86_64-apple-ios:IOSurface',  // fails on missing xpc/xpc.h
                  '11.1:x86_64-apple-tvos:IOSurface', // fails on missing xpc/xpc.h
                  '11.2:i386-apple-ios:IOSurface',    // fails on missing xpc/xpc.h
                  '11.2:x86_64-apple-ios:IOSurface',  // fails on missing xpc/xpc.h
                  '11.2:x86_64-apple-tvos:IOSurface', // fails on missing xpc/xpc.h
                  '11.3:i386-apple-ios:IOSurface',    // fails on missing xpc/xpc.h
                  '11.3:x86_64-apple-ios:IOSurface',  // fails on missing xpc/xpc.h
                  '11.3:x86_64-apple-tvos:IOSurface', // fails on missing xpc/xpc.h
                  '11.4:i386-apple-ios:IOSurface',    // fails on missing xpc/xpc.h
                  '11.4:x86_64-apple-ios:IOSurface',  // fails on missing xpc/xpc.h
                  '11.4:x86_64-apple-tvos:IOSurface', // fails on missing xpc/xpc.h

                  // Review for Xcode 9.4 (and retest for 10?) Still broken in 11
                  'MetalPerformanceShaders',
                  'MetalPerformanceShadersGraph', // pulls in MetalPerformanceShaders

                  // 10.15 and later, these are C++ so we cannot support them
                  'DriverKit',
                  'HIDDriverKit',
                  'NetworkingDriverKit',
                  'USBDriverKit',
                  'USBSerialDriverKit',

                  // Deprecated and not supported on UIKit for Mac:
                  'x86_64-apple-ios-macabi:GLKit',
                  'arm64-apple-ios-macabi:GLKit',

                  //'x86_64-apple-ios:Accelerate',
                  //'arm64-apple-ios:Accelerate',
                  //'x86_64-apple-ios-simulator:Accelerate',
                  //'i386-apple-ios-simulator:Accelerate',
                  //'arm64-apple-ios-simulator:Accelerate',
                  'Accelerate',

                  'PCIDriverKit', //83882: HI: breakage with Xcode 11.4

                  'IOKit', // Error   IOKit/IORPC.h - IOKit/IORPC.h (5902) opening brace expected Identifier (IORPCMessage)

                  // macOS 11
                  'GameController',     //GameController.h - GameController/GCPhysicalInputProfile.h (89277) One of semicolon, comma, (eof) expected Identifier (GCControllerButtonInput)
                  'GameKit',            //GameKit.h - GameController/GCPhysicalInputProfile.h (89758) One of semicolon, comma, (eof) expected Identifier (GCControllerButtonInput)
                  'Hypervisor',         //Hypervisor.h - Hypervisor/hv_vm.h (5435) Declaration expected Identifier (hv_vm_config_t)

                  'x86_64-apple-macosx:ClockKit', // imports UIKit, even though its on macOS!?
                  'arm64-apple-macosx:ClockKit',
                  //'arm64-apple-macosx:Carbon',

                  '15.0:CoreThreadCommissionerService',
                  //'15.0:i386-apple-ios:CoreThreadCommissionerService',
                  //'15.0:x86_64-apple-ios:CoreThreadCommissionerService',
                  //'15.0:arm64-apple-ios:CoreThreadCommissionerService',

                  'visionOS:SensitiveContentAnalysis',
                  'macosx:AccessorySetupKit',
                  'xros:SwiftUICore',

                  ].ToList; readonly;

  end;

end.