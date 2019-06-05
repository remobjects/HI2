namespace RemObjects.Elements.HI2;

type
  Darwin = public static partial class
  private

    const rtlFiles = [
                "assert.h",
                "copyfile.h",
                "ctype.h",
                "cups/cups.h",
                "cups/ppd.h",
                "device/*.h",
                "dirent.h",
                "errno.h",
                "i386/limits.h",
                "iconv.h",
                "inttypes.h",
                "limits.h",
                "locale.h",
                "math.h",
                "netdb.h",
                "netinet/in.h",
                "netinet/in6_var.h",
                "netinet/ip.h",
                "netinet/tcp.h",
                "netinet/tcpip.h",
                "netinet/udp.h",
                "pthread/pthread.h",
                "pwd.h",
                "regex.h",
                "setjmp.h",
                "signal.h",
                "simd/simd.h",
                "stddef.h",
                "stdint.h",
                "stdio.h",
                "stdlib.h",
                "sys/event.h",
                "sys/ioctl.h",
                "sys/mount.h",
                "sys/stat.h",
                "sys/utsname.h",
                "TargetConditionals.h",
                "time.h",
                "unwind.h",
                "wchar.h",
                "wctype.h",
                "xpc/xpc.h"

                //"bsm/*.h",         //iOS6: bsm/audit_filter.h (51:40 pp: 91) One of ClosingParenthesis, Comma expected; current token: Identifier  tok
                //"net/*.h",         //iOS6: net/pfkeyv2.h (109:3 pp: 135) Declaration expected; current token: Identifier  u_int8_t
                //"netinet6/*.h",    //iOS6:  do not include netinet6/in6.h directly, include netinet/in.h. see RFC2553
                //"NSSystemDirectories.h",
                //"os/*.h",
                //"pthread/pthread.h",
                //"rpc/*.h",         //iOS6: rpc/xdr.h (129:3 pp: 176) Declaration expected; current token: Identifier  bool_t
                //"rpcsvc/*.h",      // rpcsvc/yp_prot.h (146:2 pp: 178) (146:2 pp: 178) Declaration expected; current token: Identifier  bool_t
                //"stdbool.h",
                //"sys/_types/*.h",
                //"sys/event.h",
                //"sys/ioctl.h",
                //"sys/mount.h",
                //"sys/utsname.h",
                //"xpc/xpc.h",
                ];

    const rtlFiles_macOS = [//"cups/*.h",
                //"curl/*.h",
                //"DNSServiceDiscovery/*.h",
                //"editline/*.h",
                //"ffi/*.h",
                //"gssapi/*.h",
                //"hfs/*.h",*/    //TEST LATER
                //"net-snmp/*.h",   //net-snmp/types.h (11) "Please include <net-snmp/net-snmp-config.h> before this file"
                //"netkey/*.h",    //netkey/keysock.h (39:2 pp: 93) Declaration expected; current token: Identifier  u_quad_t
                //"nfs/*.h",       //An error occurred: nfs/krpc.h (39:2 pp: 107) Declaration expected; current token: Identifier  mbuf_t
                //"openssl/*.h",    // deprecated, not sure if worth including, might break 10.9. also An error occurred: openssl/bn.h (284:2 pp: 996) Declaration expected; current token: Identifier  BN_ULONG
                //"pcap/*.h",    //pcap/namedb.h (56:63 pp: 96) Declaration expected; current token: Identifier  FILE
                //"protocols/*.h",  //10.6: protocols/dumprestore.h (102:35 pp: 134) Declaration expected; current token: Identifier  daddr_t
                //"sasl/*.h",    // sasl/hmac-md5.h (11:5 pp: 54) Declaration expected; current token: Identifier  MD5_CTX
                //"security/*.h",  // security/mac_policy.h (83) Cannot find include file: security/security/_label.h
                //"vfs/*.h",      // fs/vfs_support.h (48) Cannot find include file: vfs/sys/systm.h
                "arpa/*.h",
                "CommonCrypto/*.h",
                "dispatch/dispatch.h",
                "libkern/*.h",
                "mach-o/*.h",
                "malloc/*.h",
                "objc/*.h",
                "sys/_types/*.h",
                "uuid/*.h",
                "xar/*.h"
                ];

    //const rtlFiles_DrivereKit = [];


    const rtlFiles_iOS = [
                          "arpa/*.h",
                          "CommonCrypto/*.h",
                          "dispatch/dispatch.h",
                          "libkern/*.h",
                          "mach-o/*.h",
                          "malloc/*.h",
                          "objc/*.h",
                          "os/log.h",
                          "sys/_types/*.h",
                          "uuid/*.h",
                          "arm/limits.h"];
    const rtlFiles_iOSSimulator: array of String = [];

    property rtlFiles_watchOS: array of String read rtlFiles_iOS;
    property rtlFiles_watchOSSimulator: array of String read rtlFiles_iOSSimulator;

    property rtlFiles_tvOS: array of String read rtlFiles_iOS;
    property rtlFiles_tvOSSimulator: array of String read rtlFiles_iOSSimulator;

    //
    //
    //

    const indirectRtlFiles = [
                "_wctype.h",
                "dispatch/*.h",
                //"mach-o/i386/*.h",
                //"mach-o/ppc/*.h" ,
                //"mach-o/x86_64/*.h",
                "netinet6/in6.h",
                "simd/*.h",
                "sys/*.h",
                "sys/*.h",
                "xlocale/*.h"
                ];
    const indirectRtlFiles_macOS = ["mach-o/i386/*.h", "mach-o/x86_64/*.h"]; // // "mach-o/arm/*.h", "mach-o/arm64/*.h"
    const indirectRtlFiles_iOS = ["mach-o/arm/*.h", "mach-o/arm64/*.h"];
    const indirectRtlFiles_watchOS: array of String = []; // ["mach-o/arm/*.h", "mach-o/arm64/*.h"];
    const indirectRtlFiles_tvOS = ["mach-o/arm64/*.h"];
    const indirectRtlFiles_DriverKit: array of String = [];

    property indirectRtlFiles_iOSSimulator: array of String read indirectRtlFiles_macOS;
    const indirectRtlFiles_tvOSSimulator = ["mach-o/x86_64/*.h"];
    const indirectRtlFiles_watchOSSimulator: array of String = [];//"mach-o/i386/*.h"];

    //
    //
    //

    var forceIncludes_Shared := "[
            { 'Key': 'ApplicationServices/HIServices/AXAttributeConstants.h', 'Value': [ 'CoreFoundation/CoreFoundation.h' ] },
            { 'Key': 'ApplicationServices/HIServices/AXNotificationConstants.h', 'Value': [ 'CoreFoundation/CoreFoundation.h' ] },
            { 'Key': 'ApplicationServices/PrintCore/PDEPluginInterface.h', 'Value': [ 'Foundation/NSObjCRuntime.h' ] },
            { 'Key': 'AudioToolbox/AudioToolbox.h', 'Value': [ 'CoreMIDI/CoreMIDI.h' ] },
            { 'Key': 'CalendarStore/CalendarStore.h', 'Value': [ 'Foundation/Foundation.h' ] },
            { 'Key': 'CFOpenDirectory/CFOpenDirectory.h', 'Value': [ 'Foundation/Foundation.h' ] },
            { 'Key': 'CoreTelephony/CTCellularData.h', 'Value': [ 'Foundation/Foundation.h' ] },
            { 'Key': 'EventKit/EventKit.h', 'Value': [ 'Foundation/Foundation.h' ] },
            { 'Key': 'ExternalAccessory/ExternalAccessory.h', 'Value': [ 'Foundation/Foundation.h' ] },
            { 'Key': 'ImageCaptureCore/ImageCaptureCore.h', 'Value': [ 'Foundation/Foundation.h' ] },
            { 'Key': 'IMServicePlugIn/IMServicePlugIn.h', 'Value': [ 'Foundation/Foundation.h' ] },
            { 'Key': 'IOKit/graphics/IOGraphicsInterface.h', 'Value': [ 'IOKit/graphics/IOGraphicsInterfaceTypes.h' ] },
            { 'Key': 'IOKit/i2c/IOI2CInterface.h', 'Value': [ 'MacTypes.h', 'IOKit/IOReturn.h' ] },
            { 'Key': 'IOKit/ndrvsupport/IOMacOSVideo.h', 'Value': [ 'IOKit/graphics/IOGraphicsTypes.h' ] },
            { 'Key': 'IOKit/network/IOEthernetStats.h', 'Value': [ 'MacTypes.h' ] },
            { 'Key': 'IOKit/network/IONetworkStats.h', 'Value': [ 'MacTypes.h' ] },
            { 'Key': 'IOKit/ps/IOPowerSources.h', 'Value': [ 'CoreFoundation/CoreFoundation.h' ] },
            { 'Key': 'IOKit/pwr_mgt/IOPMLibDefs.h', 'Value': [ 'Availability.h' ] },
            { 'Key': 'IOKit/DV/DVFamily.h', 'Value': [ 'MacTypes.h' ] },
            { 'Key': 'IOKit/graphics/IOGraphicsEngine.h', 'Value': [ 'MacTypes.h' ] },
            { 'Key': 'IOKit/sbp2/IOFireWireSBP2Lib.h', 'Value': [ 'CoreFoundation/CFPlugInCOM.h' ] },
            { 'Key': 'JavaRuntimeSupport/JavaRuntimeSupport.h', 'Value': [ 'Foundation/Foundation.h' ] },
            { 'Key': 'OpenDirectory/CFOpenDirectory/CFOpenDirectoryConstants.h', 'Value': [ 'CoreFoundation/CoreFoundation.h' ] },
            { 'Key': 'Quartz/ImageKit/ImageKitDeprecated.h', 'Value': [ 'Foundation/Foundation.h' ] },
            { 'Key': 'SafariServices/SafariServices.h','Value': ['UIKit/UIActivity.h'] },
            { 'Key': 'IOKit/hid/IOHIDBase.h', 'Value': [ 'CoreFoundation/CFBase.h'] },
            { 'Key': 'Foundation/NSItemProvider.h', 'Value': [ 'Foundation/NSError.h'] }
            ]".Replace("'",'"');
    var forceIncludes_iOS := "[
            { 'Key': 'GameKit/GameKit.h','Value': ['UIKit/UIKit.h', 'OpenGLES/gltypes.h']},
            { 'Key': 'GLKit/GLKit.h','Value': ['OpenGLES/gltypes.h']},
            { 'Key': 'NotificationCenter/NotificationCenter.h','Value': ['UIKit/UIVisualEffectView.h'] },
            { 'Key': 'SceneKit/SceneKit.h', 'Value': [ 'CoreImage/CoreImage.h' ] },
            { 'Key': 'Social/Social.h','Value': ['UIKit/UITextView.h']},
            { 'Key': 'ImageCaptureCore/ICDevice.h', 'Value': ['availability.h']}
            ]".Replace("'",'"');
    var forceIncludes_watchOS := forceIncludes_iOS;
    var forceIncludes_tvOS := forceIncludes_iOS;
    var forceIncludes_macOS := "[
            { 'Key': 'Quartz/ImageKit/IKImageEditPanel.h','Value': ['Foundation/NSError.h']},
            { 'Key': 'Quartz/ImageKit/IKImageView.h','Value': ['Foundation/NSError.h']}
            ]".Replace("'",'"');

  end;

end.