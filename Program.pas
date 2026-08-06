namespace RemObjects.Elements.HI2;

uses
  RemObjects.Elements.Basics,
  System.Linq;

type
  Program = class
  public


    class method Main(args: array of String): Int32;
    begin
      try
        // add your own code here
        writeLn("RemObjects Elements .fx Importer Frontend (HI2).");
        writeLn("Copyright RemObjects Software 2016-2023. All Rights Reserved.");
        writeLn();

        var lImporter := new Importer();
        lImporter.CodeFolder := Path.Combine(Environment.UserHomeFolder, "Code/");
        lImporter.HI := Path.Combine(ElementsPaths.Instance.ElementsBinFolder, "HeaderImporter.exe");
        lImporter.FrameworksFolder := Path.GetFullPath(Path.Combine(ElementsPaths.Instance.ElementsBinFolder, "..", "Frameworks"));
        lImporter.ApplicationsFolder := Path.Combine(Environment.UserHomeFolder, "Applications");
        if not lImporter.ApplicationsFolder.FolderExists then
          lImporter.ApplicationsFolder := "/Applications";

        if (length(args) > 0) then begin

          case args[0]:ToLowerInvariant of

            "cocoa", "apple": begin
                lImporter.ImportSDKs();
                exit 0;
              end;

            "fuchsia": begin
                if length(args) < 3 then begin
                  writeLn("Usage: HI2 fuchsia <idk-folder> <platform-output-folder> [--intermediate=<folder>] [--api=<level>] [--fidlc=<path>] [--docker=<path>] [--fidlc-docker-image=<image>] [--stable-only] [--reuse-ir] [--ir-only] [--assemble-sdk --runtime-fx=<folder> --islandrtl=<folder> (--clang=<folder> | --clang-runtime=<folder>)] [--no-zip] [library ...]");
                  exit 1;
                end;

                lImporter.FuchsiaIDKFolder := args[1];
                lImporter.FuchsiaOutputFolder := args[2];
                var lLibraries := new List<String>;
                for each lArgument in args.Skip(3) do begin
                  if lArgument.StartsWith("--api=", true) then
                    lImporter.FuchsiaAPILevel := lArgument.Substring(length("--api="))
                  else if lArgument.StartsWith("--fidlc=", true) then
                    lImporter.Fidlc := lArgument.Substring(length("--fidlc="))
                  else if lArgument.StartsWith("--docker=", true) then
                    lImporter.Docker := lArgument.Substring(length("--docker="))
                  else if lArgument.StartsWith("--fidlc-docker-image=", true) then
                    lImporter.FidlcDockerImage := lArgument.Substring(length("--fidlc-docker-image="))
                  else if lArgument.StartsWith("--intermediate=", true) then
                    lImporter.FuchsiaIntermediateFolder := lArgument.Substring(length("--intermediate="))
                  else if lArgument:ToLowerInvariant = "--include-unstable" then
                    lImporter.IncludeUnstableFIDL := true
                  else if lArgument:ToLowerInvariant = "--stable-only" then
                    lImporter.IncludeUnstableFIDL := false
                  else if lArgument:ToLowerInvariant = "--ir-only" then
                    lImporter.SkipFidlBindingImport := true
                  else if lArgument:ToLowerInvariant = "--reuse-ir" then
                    lImporter.ReuseFidlIR := true
                  else if lArgument:ToLowerInvariant = "--assemble-sdk" then
                    lImporter.AssembleFuchsiaRuntime := true
                  else if lArgument.StartsWith("--runtime-fx=", true) then begin
                    lImporter.FuchsiaRuntimeFxFolder := lArgument.Substring(length("--runtime-fx="));
                  end
                  else if lArgument.StartsWith("--islandrtl=", true) then begin
                    lImporter.FuchsiaIslandRTLFolder := lArgument.Substring(length("--islandrtl="));
                  end
                  else if lArgument.StartsWith("--clang=", true) then begin
                    lImporter.FuchsiaClangFolder := lArgument.Substring(length("--clang="));
                  end
                  else if lArgument.StartsWith("--clang-runtime=", true) then begin
                    lImporter.FuchsiaClangRuntimeFolder := lArgument.Substring(length("--clang-runtime="));
                  end
                  else if lArgument:ToLowerInvariant = "--no-zip" then
                    lImporter.CreateZips := false
                  else if lArgument.StartsWith("--") then
                    raise new HIException($"Invalid Fuchsia option: {lArgument}")
                  else
                    lLibraries.Add(lArgument);
                end;

                lImporter.ImportFuchsiaIDK(lLibraries);
                exit 0;
              end;

            "windows": begin
                if length(args) < 3 then begin
                  writeLn("Usage: HI2 windows <windows-sdk-folder> <platform-output-folder> --msvc=<folder> [--netfx-sdk=<folder>] [--sdk-version=<version>] [--architectures=i386,x86_64,arm64] [--rtl-config-folder=<folder>] [--support-files=<folder>] [--intermediate=<folder>] [--header-importer=<absolute-path>] [--skip-winrt] [--no-zip]");
                  exit 1;
                end;

                lImporter.WindowsSDKFolder := args[1];
                lImporter.WindowsOutputFolder := args[2];
                for each lArgument in args.Skip(3) do begin
                  if lArgument.StartsWith("--msvc=", true) then
                    lImporter.WindowsMSVCFolder := lArgument.Substring(length("--msvc="))
                  else if lArgument.StartsWith("--netfx-sdk=", true) then
                    lImporter.WindowsNetFxSDKFolder := lArgument.Substring(length("--netfx-sdk="))
                  else if lArgument.StartsWith("--sdk-version=", true) then
                    lImporter.WindowsSDKVersion := lArgument.Substring(length("--sdk-version="))
                  else if lArgument.StartsWith("--architectures=", true) then
                    lImporter.WindowsArchitectures.Add(lArgument.Substring(length("--architectures=")).Replace(",", ";").Split(";", true))
                  else if lArgument.StartsWith("--rtl-config-folder=", true) then
                    lImporter.WindowsRTLConfigFolder := lArgument.Substring(length("--rtl-config-folder="))
                  else if lArgument.StartsWith("--support-files=", true) then
                    lImporter.WindowsSupportFilesFolder := lArgument.Substring(length("--support-files="))
                  else if lArgument.StartsWith("--intermediate=", true) then
                    lImporter.WindowsIntermediateFolder := lArgument.Substring(length("--intermediate="))
                  else if lArgument.StartsWith("--header-importer=", true) then
                    lImporter.HI := lArgument.Substring(length("--header-importer="))
                  else if lArgument:ToLowerInvariant = "--skip-winrt" then
                    lImporter.ImportWindowsRuntime := false
                  else if lArgument:ToLowerInvariant = "--no-zip" then
                    lImporter.CreateZips := false
                  else
                    raise new HIException($"Invalid Windows option: {lArgument}");
                end;

                lImporter.ImportWindowsSDK;
                exit 0;
              end;

            "linux": begin
                if length(args) < 2 then begin
                  writeLn("Usage: HI2 linux <platform-output-folder> [--ubuntu-version=26.04] [--docker-image=ubuntu:26.04] [--docker=<path>] [--architectures=x86_64,arm64] [--rtl-config-folder=<folder>] [--intermediate=<folder>] [--header-importer=<absolute-path>] [--reuse-sysroots] [--no-zip]");
                  exit 1;
                end;

                lImporter.LinuxOutputFolder := args[1];
                for each lArgument in args.Skip(2) do begin
                  if lArgument.StartsWith("--ubuntu-version=", true) then
                    lImporter.LinuxUbuntuVersion := lArgument.Substring(length("--ubuntu-version="))
                  else if lArgument.StartsWith("--docker-image=", true) then
                    lImporter.LinuxDockerImage := lArgument.Substring(length("--docker-image="))
                  else if lArgument.StartsWith("--docker=", true) then
                    lImporter.Docker := lArgument.Substring(length("--docker="))
                  else if lArgument.StartsWith("--architectures=", true) then
                    lImporter.LinuxArchitectures.Add(lArgument.Substring(length("--architectures=")).Replace(",", ";").Split(";", true))
                  else if lArgument.StartsWith("--rtl-config-folder=", true) then
                    lImporter.LinuxRTLConfigFolder := lArgument.Substring(length("--rtl-config-folder="))
                  else if lArgument.StartsWith("--intermediate=", true) then
                    lImporter.LinuxIntermediateFolder := lArgument.Substring(length("--intermediate="))
                  else if lArgument.StartsWith("--header-importer=", true) then
                    lImporter.HI := lArgument.Substring(length("--header-importer="))
                  else if lArgument:ToLowerInvariant = "--reuse-sysroots" then
                    lImporter.LinuxReuseSysroots := true
                  else if lArgument:ToLowerInvariant = "--no-zip" then
                    lImporter.CreateZips := false
                  else
                    raise new HIException($"Invalid Linux option: {lArgument}");
                end;

                lImporter.ImportLinuxSDK;
                exit 0;
              end;

            "android": begin
                if length(args) < 2 then begin
                  writeLn("Usage: HI2 android <platform-output-folder> (--ndk=<folder> | --ndk-archive=<zip>) --sqlite-archive=<zip> [--ndk-release=r29] [--api=35] [--sqlite-version=3.53.4] [--architectures=arm64-v8a,armeabi-v7a,x86,x86_64] [--rtl-config-folder=<folder>] [--intermediate=<folder>] [--header-importer=<absolute-path>] [--mono=<absolute-path>] [--docker=<absolute-path>] [--docker-image=ubuntu:24.04] [--reuse-ndk] [--reuse-sqlite] [--debug] [--no-zip]");
                  exit 1;
                end;

                lImporter.AndroidOutputFolder := args[1];
                for each lArgument in args.Skip(2) do begin
                  if lArgument.StartsWith("--ndk=", true) then
                    lImporter.AndroidNDKFolder := lArgument.Substring(length("--ndk="))
                  else if lArgument.StartsWith("--ndk-archive=", true) then
                    lImporter.AndroidNDKArchive := lArgument.Substring(length("--ndk-archive="))
                  else if lArgument.StartsWith("--sqlite-archive=", true) then
                    lImporter.AndroidSQLiteArchive := lArgument.Substring(length("--sqlite-archive="))
                  else if lArgument.StartsWith("--ndk-release=", true) then
                    lImporter.AndroidNDKRelease := lArgument.Substring(length("--ndk-release="))
                  else if lArgument.StartsWith("--api=", true) then
                    lImporter.AndroidAPILevel := lArgument.Substring(length("--api="))
                  else if lArgument.StartsWith("--sqlite-version=", true) then
                    lImporter.AndroidSQLiteVersion := lArgument.Substring(length("--sqlite-version="))
                  else if lArgument.StartsWith("--architectures=", true) then
                    lImporter.AndroidArchitectures.Add(lArgument.Substring(length("--architectures=")).Replace(",", ";").Split(";", true))
                  else if lArgument.StartsWith("--rtl-config-folder=", true) then
                    lImporter.AndroidRTLConfigFolder := lArgument.Substring(length("--rtl-config-folder="))
                  else if lArgument.StartsWith("--intermediate=", true) then
                    lImporter.AndroidIntermediateFolder := lArgument.Substring(length("--intermediate="))
                  else if lArgument.StartsWith("--header-importer=", true) then
                    lImporter.HI := lArgument.Substring(length("--header-importer="))
                  else if lArgument.StartsWith("--mono=", true) then
                    lImporter.Mono := lArgument.Substring(length("--mono="))
                  else if lArgument.StartsWith("--docker=", true) then
                    lImporter.Docker := lArgument.Substring(length("--docker="))
                  else if lArgument.StartsWith("--docker-image=", true) then
                    lImporter.AndroidDockerImage := lArgument.Substring(length("--docker-image="))
                  else if lArgument:ToLowerInvariant = "--reuse-ndk" then
                    lImporter.AndroidReuseNDK := true
                  else if lArgument:ToLowerInvariant = "--reuse-sqlite" then
                    lImporter.AndroidReuseSQLite := true
                  else if lArgument:ToLowerInvariant = "--debug" then
                    lImporter.Debug := true
                  else if lArgument:ToLowerInvariant = "--no-zip" then
                    lImporter.CreateZips := false
                  else
                    raise new HIException($"Invalid Android option: {lArgument}");
                end;

                lImporter.ImportAndroidSDK;
                exit 0;
              end;

            "gc": begin

                Darwin.LoadVersionsFromXcode();
                lImporter.GCSourceFolder := "/Users/mh/Code/RemObjects/gc";
                lImporter.GCBinariesFolder := "/Users/mh/Code/Elements/Bin/References/Island";
                //lImporter.GCBinariesFolder := lImporter.GCSourceFolder;
                //lImporter.BaseFolder := Path.Combine(lImporter.FrameworksFolder, "Island");
                lImporter.BaseFolder := Path.Combine("/Users/mh/Code/Elements/Bin/Island SDKs/");
                lImporter.ImportGC();
                exit 0;
              end;

          end;

        end
        else begin

          //..

        end;

      except
        on E: HIException do begin
            writeLn(E.Message);
            exit 1;
          end;
      end;
    end;

  end;

end.
