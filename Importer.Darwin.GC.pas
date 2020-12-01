namespace RemObjects.Elements.HI2;

uses
  RemObjects.Elements.RTL;

type
  Importer = public partial class
  public

    property GCSourceFolder: String;   // for GC import, folder that has the GIT chdeckout from ssh://git@bugs.remobjects.com/source/gc.git
    property GCBinariesFolder: String; // for GC import, optional folder that has the GC binaries

    method ImportGC;
    begin
      for each (a, v) in Darwin.AllIslandDarwinArchitectures do
        ImportGC(a, v);

      if defined("ECHOES") and CreateZips then begin
        var lTargetZipName := Path.Combine(BaseFolder, "GC", "Darwin.zip");
        writeLn($"Creating {lTargetZipName}");
        CreateZip(Path.Combine(BaseFolder, "GC", "Darwin"), lTargetZipName);
      end;
    end;

    method MergeGCArchitectures(aSDKName: String);
    begin
      MergeArchitectures(Path.Combine(BaseFolder, "GC", "Darwin", aSDKName), "gc.fx");
    end;

    method ImportGC(aArchitecture: Architecture; aVersion:String);
    begin
      var lJsonString := "{
        'TargetString': '...',
        'Version': '...',
        'SDKVersionString': '...',
        'SDKName': '...',
        'Island': true,
        'Imports': [
          {
            'Name': 'gc',
            'Framework': false,
            'Prefix': '',
            'ForceNamespace': 'gc',
            'Explicit': false,
            'Files': [ 'gc.h' ],
            'DepLibs': [ 'libgc.a' ],
            'ImportDefs': []
          }
        ],
        'Defines': ['GC_THREADS', 'GC_NO_THREAD_DECLS'],
        'Platform': 'Darwin'
      }".Replace("'", '"');

      var lBaseJson := JsonDocument.FromString(lJsonString);
      var lTargetString := aArchitecture.Triple;
      if length(aArchitecture.CpuType) > 0 then
        lTargetString := lTargetString+";"+aArchitecture.CpuType;
      lBaseJson.Root["TargetString"] := lTargetString;
      lBaseJson.Root["Version"] := aVersion;
      lBaseJson.Root["SDKVersionString"] := aVersion;
      lBaseJson.Root["SDKName"] := aArchitecture.SDKName;

      Folder.Create(BaseFolder);
      var lBaseJsonFile := Path.Combine(BaseFolder, aArchitecture.Triple+".gc-json");
      File.WriteText(lBaseJsonFile, lBaseJson.ToString);

      var lArch := aArchitecture.Triple.SubstringToFirstOccurrenceOf("-");
      var lSDK := aArchitecture.DisplaySDKName+" "+aVersion;
      var lSDKName := aArchitecture.DisplaySDKName;
      if aArchitecture.Simulator then begin
        lSDK := lSDK+" Simulator";
        lSDKName := lSDKName+" Simulator";
      end
      else if aArchitecture.MacCatalyst then begin
        //lSDK := "UIKit for Mac "+aVersion;
        lSDKName := "UIKit for Mac";
      end;

      var lOutPath := Path.Combine(BaseFolder, "GC", "Darwin", lSDKName, lArch);

      var lArgs := new List<String>;
      lArgs.Add("import");
      lArgs.Add("--json="+lBaseJsonFile);
      lArgs.Add("--fxpaths="+Path.Combine(SDKsBaseFolder, lSDK));
      lArgs.Add("--include="+Path.Combine(GCSourceFolder, "include"));
      lArgs.Add("--outpath="+lOutPath);

      RunHI(lArgs);

      if GCBinariesFolder:FolderExists then begin
        //var lBinary := Path.Combine(GCBinariesFolder, "gc-"+aArchitecture.OS.ToLower+"-"+(if aArchitecture.Simulator then "-simulator" else "")+aArchitecture.Triple+".a");
        //writeLn($"checking {lBinary}");
        //if lBinary.FileExists then begin
          //writeLn($'lBinary {lBinary}');
          //File.CopyTo(lBinary, Path.Combine(lOutPath, "libgc.a"));
        //end
        /*else*/ begin
          var lBinary := Path.Combine(GCBinariesFolder, lSDKName, aArchitecture.Arch, "libgc.a");
          if lBinary.FileExists then begin
            File.CopyTo(lBinary, Path.Combine(lOutPath, "libgc.a"));
          end
          else begin
            lBinary := Path.Combine(GCBinariesFolder, lSDKName, aArchitecture.Arch, "libgc.a");
            if lBinary.FileExists then begin
              File.CopyTo(lBinary, Path.Combine(lOutPath, "libgc.a"));
            end
            else begin
              writeLn("No binary at "+lBinary);
            end;
          end;
        end;
      end;

    end;

  end;
end.