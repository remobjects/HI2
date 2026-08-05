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
