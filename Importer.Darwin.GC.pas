namespace HI2;

type
  Importer = public partial class
  public

    property GCSourceFolder: String;   // for GC import, folder that has the GIT chdeckout from ssh://git@bugs.remobjects.com/source/gc.git
    property GCBinariesFolder: String; // for GC import, optional folder that has the GC binaries

    method ImportGC;
    begin
      ImportGC(Darwin.Architecture_macOS_x86_64, Darwin.macOSCurrentVersion);
      ImportGC(Darwin.Architecture_iOS_armv7, Darwin.iOSCurrentVersion);
      ImportGC(Darwin.Architecture_iOS_armv7s, Darwin.iOSCurrentVersion);
      ImportGC(Darwin.Architecture_iOS_arm64, Darwin.iOSCurrentVersion);
      ImportGC(Darwin.Architecture_iOSSimulator_i386, Darwin.iOSCurrentVersion);
      ImportGC(Darwin.Architecture_iOSSimulator_x86_64, Darwin.iOSCurrentVersion);
      ImportGC(Darwin.Architecture_tvOS_arm64, Darwin.tvOSCurrentVersion);
      ImportGC(Darwin.Architecture_tvOSSimulator_x86_64, Darwin.tvOSCurrentVersion);
      ImportGC(Darwin.Architecture_watchOS_armv7k, Darwin.watchOSCurrentVersion);
      ImportGC(Darwin.Architecture_watchOSSimulator_i386, Darwin.watchOSCurrentVersion);

      //MergeGCArchitectures("macOS");
      //MergeGCArchitectures("iOS");
      //MergeGCArchitectures("iOS Simulator");
      //MergeGCArchitectures("tvOS");
      //MergeGCArchitectures("tvOS Simulator");
      //MergeGCArchitectures("watchOS");
      //MergeGCArchitectures("watchOS Simulator");
    end;

    method MergeGCArchitectures(aSDKName: String);
    begin
      MergeArchitectures(Path.Combine(BaseFolder, "Darwin", "GC", aSDKName), "gc.fx");
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

      var lBaseJsonFile := Path.Combine(BaseFolder, aArchitecture.Triple+".gc-json");
      File.WriteText(lBaseJsonFile, lBaseJson.ToString);

      var lArch := aArchitecture.Triple.SubstringToFirstOccurrenceOf("-");
      var lSDK := aArchitecture.SDKName+" "+aVersion;
      var lSDKName := aArchitecture.SDKName;
      if aArchitecture.Simulator then begin
        lSDK := lSDK+" Simulator";
        lSDKName := lSDKName+" Simulator";
      end;

      var lOutPath := Path.Combine(BaseFolder, "Darwin", "GC", lSDKName, lArch);

      var lArgs := new List<String>;
      lArgs.Add("import");
      lArgs.Add("--json="+lBaseJsonFile);
      lArgs.Add("--fxpaths="+Path.Combine(BaseFolder, "Darwin", lSDK));
      lArgs.Add("--include="+Path.Combine(GCSourceFolder, "include"));
      lArgs.Add("--outpath="+lOutPath);

      writeLn(Task.StringForCommand("HeaderImporter") Parameters(lArgs.ToArray));
      Task.Run(HI, lArgs.ToArray, nil, nil, s -> writeLn(s), s -> writeLn(s));

      if GCBinariesFolder:FolderExists then begin
        var lBinary := Path.Combine(GCBinariesFolder, "gc-"+aArchitecture.Triple+".a");
        writeLn($'lBinary {lBinary}');
        if lBinary.FileExists then
          File.CopyTo(lBinary, Path.Combine(lOutPath, "libgc.a"));
      end;

    end;

  end;
end.