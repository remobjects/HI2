namespace RemObjects.Elements.HI2;

uses
  RemObjects.Elements.Basics,
  RemObjects.Elements.FidlImporter,
  RemObjects.Elements.Fx,
  RemObjects.Elements.RTL;

type
  FuchsiaFidlLibrary = private class
  public

    constructor(aName: not nullable String; aRoot: not nullable String; aStable: Boolean);
    begin
      Name := aName;
      Root := aRoot;
      Stable := aStable;
    end;

    property Name: not nullable String; readonly;
    property Root: not nullable String; readonly;
    property Sources := new List<String>; readonly;
    property Dependencies := new List<String>; readonly;
    property Stable: Boolean;
  end;

  Importer = public partial class
  private

    field fFidlcRunsInDocker: Boolean;

    method LoadFuchsiaFidlLibraries(out aSDKID: not nullable String): not nullable Dictionary<String, FuchsiaFidlLibrary>;
    begin
      var lManifestPath := Path.Combine(FuchsiaIDKFolder, "meta", "manifest.json");
      if not lManifestPath.FileExists then
        raise new Exception($"The Fuchsia IDK manifest was not found at '{lManifestPath}'.");

      var lManifest := JsonDocument.FromString(File.ReadText(lManifestPath));
      if not (lManifest is JsonObject) then
        raise new Exception($"The Fuchsia IDK manifest at '{lManifestPath}' is not a JSON object.");

      var lManifestObject := JsonObject(lManifest);
      var lSDKID := lManifestObject["id"]:StringValue;
      if length(lSDKID) = 0 then
        raise new Exception($"The Fuchsia IDK manifest at '{lManifestPath}' has no SDK id.");
      aSDKID := lSDKID as not nullable;

      var lParts := lManifestObject["parts"];
      if not (lParts is JsonArray) then
        raise new Exception($"The Fuchsia IDK manifest at '{lManifestPath}' has no parts array.");

      result := new Dictionary<String, FuchsiaFidlLibrary>;
      for each lPartNode in JsonArray(lParts) do begin
        if not (lPartNode is JsonObject) then
          continue;

        var lPart := JsonObject(lPartNode);
        if lPart["type"]:StringValue ≠ "fidl_library" then
          continue;

        var lMetaPath := lPart["meta"]:StringValue;
        if length(lMetaPath) = 0 then
          raise new Exception("A Fuchsia FIDL manifest part has no metadata path.");
        lMetaPath := Path.Combine(FuchsiaIDKFolder, lMetaPath);
        if not lMetaPath.FileExists then begin
          var lBazelBuildPath := Path.Combine(Path.GetParentDirectory(lMetaPath), "BUILD.bazel");
          if lBazelBuildPath.FileExists then
            raise new Exception($"Fuchsia FIDL metadata was not found at '{lMetaPath}'. This appears to be a Bazel-transformed SDK view because '{lBazelBuildPath}' exists. HI2 requires a raw Fuchsia IDK containing each FIDL library's meta.json; install the fuchsia/sdk/core/linux-amd64 CIPD package and pass its root folder instead.");
          raise new Exception($"Fuchsia FIDL metadata was not found at '{lMetaPath}'.");
        end;

        var lMetadataNode := JsonDocument.FromString(File.ReadText(lMetaPath));
        if not (lMetadataNode is JsonObject) then
          raise new Exception($"Fuchsia FIDL metadata at '{lMetaPath}' is not a JSON object.");
        var lMetadata := JsonObject(lMetadataNode);

        var lName := lMetadata["name"]:StringValue;
        var lRoot := lMetadata["root"]:StringValue;
        if (length(lName) = 0) or (length(lRoot) = 0) then
          raise new Exception($"Fuchsia FIDL metadata at '{lMetaPath}' has no name or root.");
        var lRequiredName := lName as not nullable;
        var lRequiredRoot := lRoot as not nullable;
        if result.ContainsKey(lRequiredName) then
          raise new Exception($"The Fuchsia IDK contains duplicate FIDL metadata for '{lName}'.");

        var lLibrary := new FuchsiaFidlLibrary(lRequiredName,
                                               lRequiredRoot,
                                               lMetadata["stable"]:BooleanValue);
        var lSources := lMetadata["sources"];
        if not (lSources is JsonArray) or (JsonArray(lSources).Count = 0) then
          raise new Exception($"Fuchsia FIDL library '{lName}' has no source files.");
        lLibrary.Sources.Add(JsonArray(lSources).ToStrings);

        var lDependencies := lMetadata["deps"];
        if lDependencies is JsonArray then
          lLibrary.Dependencies.Add(JsonArray(lDependencies).ToStrings);

        result.Add(lRequiredName, lLibrary);
      end;
    end;

    method AppendFuchsiaFidlLibrary(aName: not nullable String;
                                    aLibraries: not nullable Dictionary<String, FuchsiaFidlLibrary>;
                                    aVisiting: not nullable System.Collections.Generic.HashSet<String>;
                                    aVisited: not nullable System.Collections.Generic.HashSet<String>;
                                    aResult: not nullable List<FuchsiaFidlLibrary>);
    begin
      if aVisited.Contains(aName) then
        exit;
      if not aVisiting.Add(aName) then
        raise new Exception($"The Fuchsia FIDL dependency graph contains a cycle at '{aName}'.");

      if not aLibraries.ContainsKey(aName) then
        raise new Exception($"Fuchsia FIDL dependency '{aName}' is absent from the IDK manifest.");
      var lLibrary := aLibraries[aName] as not nullable;

      for each lDependency in lLibrary.Dependencies.OrderBy(aDependency -> aDependency) do
        AppendFuchsiaFidlLibrary(lDependency, aLibraries, aVisiting, aVisited, aResult);

      aVisiting.Remove(aName);
      aVisited.Add(aName);
      aResult.Add(lLibrary);
    end;

    method FuchsiaFidlClosure(aName: not nullable String; aLibraries: not nullable Dictionary<String, FuchsiaFidlLibrary>): not nullable List<FuchsiaFidlLibrary>;
    begin
      result := new List<FuchsiaFidlLibrary>;
      AppendFuchsiaFidlLibrary(aName,
                               aLibraries,
                               new System.Collections.Generic.HashSet<String>,
                               new System.Collections.Generic.HashSet<String>,
                               result);
    end;

    method ResolveFidlc: not nullable String;
    begin
      fFidlcRunsInDocker := false;
      var lResult: nullable String;
      if length(Fidlc) > 0 then begin
        lResult := Path.GetFullPath(Fidlc as not nullable);
      end
      else begin
        case Environment.OS of
          OperatingSystem.Linux: begin
              var lHostArchitecture := case Environment.OSArchitecture of
                "arm64", "aarch64": "arm64";
                else "x64";
              end;
              lResult := Path.Combine(FuchsiaIDKFolder, "tools", lHostArchitecture, "fidlc");
            end;

          OperatingSystem.macOS: begin
              lResult := Path.Combine(FuchsiaIDKFolder, "tools", "x64", "fidlc");
              fFidlcRunsInDocker := true;
            end;

          else
            raise new Exception("Fuchsia fidlc host tools can be run natively on Linux or through Docker on macOS. Set Importer.Fidlc to override the compiler path.");
        end;
      end;

      if not lResult:FileExists then
        raise new Exception($"fidlc was not found at '{lResult}'.");
      result := lResult as not nullable;
    end;

    method ResolveDocker: not nullable String;
    begin
      var lCandidates := new List<String>;
      if length(Docker) > 0 then
        lCandidates.Add(Docker);
      lCandidates.Add("/usr/local/bin/docker");
      lCandidates.Add("/opt/homebrew/bin/docker");
      lCandidates.Add("/Applications/Docker.app/Contents/Resources/bin/docker");
      lCandidates.Add(Path.Combine(Environment.UserHomeFolder, "Applications", "Docker.app", "Contents", "Resources", "bin", "docker"));

      for each lCandidate in lCandidates do begin
        var lFullPath := Path.GetFullPath(lCandidate);
        if lFullPath.FileExists then
          exit lFullPath as not nullable;
      end;

      raise new Exception("The Docker executable was not found. Install Docker Desktop or pass its absolute path using --docker=<path>.");
    end;

    method RunFidlc(aExecutable: not nullable String;
                    aArguments: not nullable ImmutableList<String>;
                    aWorkingDirectory: not nullable String);
    begin
      if fFidlcRunsInDocker then begin
        if length(FidlcDockerImage) = 0 then
          raise new Exception("FidlcDockerImage must be set when running Linux fidlc on macOS.");

        var lDockerArguments := new List<String>;
        lDockerArguments.Add("run");
        lDockerArguments.Add("--rm");
        lDockerArguments.Add("--platform");
        lDockerArguments.Add("linux/amd64");
        lDockerArguments.Add("--mount");
        lDockerArguments.Add($"type=bind,source={FuchsiaIDKFolder},target={FuchsiaIDKFolder},readonly");
        lDockerArguments.Add("--mount");
        lDockerArguments.Add($"type=bind,source={FuchsiaIntermediateFolder},target={FuchsiaIntermediateFolder}");
        lDockerArguments.Add("--workdir");
        lDockerArguments.Add(aWorkingDirectory);
        lDockerArguments.Add(FidlcDockerImage);
        lDockerArguments.Add(aExecutable);
        lDockerArguments.Add(aArguments);
        aExecutable := ResolveDocker;
        aArguments := lDockerArguments;
      end;

      Log(Process.StringForCommand(aExecutable) Parameters(aArguments));
      var lOutput := new StringBuilder;
      var lExitCode := Process.Run(aExecutable, aArguments.ToArray, nil, aWorkingDirectory, aLine -> begin
        lOutput.AppendLine(aLine);
        if Debug or assigned(LoggingCallback) then
          Log("  "+aLine);
      end, aLine -> begin
        lOutput.AppendLine(aLine);
        Log("  "+aLine);
      end);

      if lExitCode ≠ 0 then begin
        if not (Debug or assigned(LoggingCallback)) then
          Log(lOutput.ToString);
        raise new HIException($"fidlc failed with exit code {lExitCode}.");
      end;
    end;

  public

    property FuchsiaIDKFolder: nullable String;
    property FuchsiaOutputFolder: nullable String;
    property FuchsiaIntermediateFolder: nullable String;
    property FuchsiaAPILevel: nullable String;
    property Fidlc: nullable String;
    property Docker: nullable String;
    property FidlcDockerImage := "ubuntu:24.04";
    property IncludeUnstableFIDL := true;
    property SkipFidlBindingImport := false;
    property ReuseFidlIR := false;

    method ImportFuchsiaIDK(aRequestedLibraries: nullable ImmutableList<String> := nil);
    begin
      if length(FuchsiaIDKFolder) = 0 then
        raise new Exception("FuchsiaIDKFolder must be set.");
      if length(FuchsiaOutputFolder) = 0 then
        raise new Exception("FuchsiaOutputFolder must be set.");

      FuchsiaIDKFolder := Path.GetFullPath(FuchsiaIDKFolder);
      FuchsiaOutputFolder := Path.GetFullPath(FuchsiaOutputFolder);

      var lSDKID: String;
      var lLibraries := LoadFuchsiaFidlLibraries(out lSDKID);
      var lAPILevel := FuchsiaAPILevel;
      if length(lAPILevel) = 0 then
        lAPILevel := lSDKID.SubstringToFirstOccurrenceOf(".");
      if length(lAPILevel) = 0 then
        raise new Exception($"Could not derive a Fuchsia API level from SDK id '{lSDKID}'.");
      if length(FuchsiaIntermediateFolder) = 0 then
        FuchsiaIntermediateFolder := Path.Combine(FuchsiaOutputFolder, "FIDL IR", lSDKID)
      else
        FuchsiaIntermediateFolder := Path.GetFullPath(FuchsiaIntermediateFolder);
      Folder.Create(FuchsiaIntermediateFolder);

      var lRequestedRoots := new List<String>;
      if assigned(aRequestedLibraries) and (aRequestedLibraries.Count > 0) then begin
        lRequestedRoots.Add(aRequestedLibraries);
      end
      else begin
        lRequestedRoots.Add(lLibraries.Values
                                       .Where(aLibrary -> IncludeUnstableFIDL or aLibrary.Stable)
                                       .Select(aLibrary -> aLibrary.Name)
                                       .OrderBy(aName -> aName));
      end;

      var lRequestedLibraries := new List<FuchsiaFidlLibrary>;
      var lVisiting := new System.Collections.Generic.HashSet<String>;
      var lVisited := new System.Collections.Generic.HashSet<String>;
      for each lName in lRequestedRoots.Distinct.OrderBy(aName -> aName) do
        AppendFuchsiaFidlLibrary(lName, lLibraries, lVisiting, lVisited, lRequestedLibraries);

      var lFidlc := ResolveFidlc;
      Folder.Create(FuchsiaOutputFolder);
      var lSDKFolder := Path.Combine(FuchsiaOutputFolder, "Fuchsia "+lSDKID);
      var lX64Folder := Path.Combine(lSDKFolder, "x64");
      var lArm64Folder := Path.Combine(lSDKFolder, "arm64");
      Folder.Create(lX64Folder);
      Folder.Create(lArm64Folder);

      var lOutputManifest := JsonDocument.CreateObject;
      lOutputManifest["format"] := "elements-fuchsia-fidl-sdk";
      lOutputManifest["formatVersion"] := 1;
      lOutputManifest["sdkID"] := lSDKID;
      lOutputManifest["apiLevel"] := lAPILevel;
      var lOutputLibraries := new JsonArray;
      lOutputManifest["libraries"] := lOutputLibraries;

      Log($"Importing {lRequestedLibraries.Count} FIDL libraries from Fuchsia IDK {lSDKID} at API level {lAPILevel}.");
      for each lLibrary in lRequestedLibraries do begin
        var lName := lLibrary.Name;
        var lClosure := FuchsiaFidlClosure(lName, lLibraries);
        var lLibraryOutputFolder := Path.Combine(FuchsiaIntermediateFolder, lName);
        Folder.Create(lLibraryOutputFolder);
        var lIrPath := Path.Combine(lLibraryOutputFolder, lName+".fidl.json");

        var lArguments := new List<String>;
        lArguments.Add("--json");
        lArguments.Add(lIrPath);
        lArguments.Add("--available");
        lArguments.Add("fuchsia:"+lAPILevel);
        lArguments.Add("--name");
        lArguments.Add(lName);
        for each lClosureLibrary in lClosure do begin
          lArguments.Add("--files");
          for each lSource in lClosureLibrary.Sources do begin
            var lSourcePath := Path.Combine(FuchsiaIDKFolder, lSource);
            if not lSourcePath.FileExists then
              raise new Exception($"Fuchsia FIDL source was not found at '{lSourcePath}'.");
            lArguments.Add(lSource);
          end;
        end;
        if not (ReuseFidlIR and lIrPath.FileExists) then
          RunFidlc(lFidlc, lArguments, FuchsiaIDKFolder);

        if not SkipFidlBindingImport then begin
          var lIr := JsonObject.FromString(File.ReadText(lIrPath));
          var lX64FxPath := Path.Combine(lX64Folder, lName+".fx");
          var lX64Fx := FidlFxImporter.Import(lIr, "x64", lSDKID, lAPILevel);
          using lX64Stream := new System.IO.FileStream(lX64FxPath, System.IO.FileMode.Create, System.IO.FileAccess.Write) do
            lX64Fx.Write(lX64Stream);

          var lArm64FxPath := Path.Combine(lArm64Folder, lName+".fx");
          var lArm64Fx := FidlFxImporter.Import(lIr, "arm64", lSDKID, lAPILevel);
          using lArm64Stream := new System.IO.FileStream(lArm64FxPath, System.IO.FileMode.Create, System.IO.FileAccess.Write) do
            lArm64Fx.Write(lArm64Stream);
        end;

        var lOutputLibrary := new JsonObject;
        lOutputLibrary["name"] := lName;
        lOutputLibrary["stable"] := lLibrary.Stable;
        lOutputLibrary["dependencies"] := new JsonArray(lLibrary.Dependencies.OrderBy(aDependency -> aDependency));
        lOutputLibrary["ir"] := Path.Combine(lName, lName+".fidl.json");
        if not SkipFidlBindingImport then begin
          lOutputLibrary["x64Fx"] := Path.Combine("Fuchsia "+lSDKID, "x64", lName+".fx");
          lOutputLibrary["arm64Fx"] := Path.Combine("Fuchsia "+lSDKID, "arm64", lName+".fx");
        end;
        lOutputLibraries.Add(lOutputLibrary);
      end;

      if not SkipFidlBindingImport then begin
        Log($"Wrote {lRequestedLibraries.Count} FIDL .fx libraries for x64 and arm64 to {lSDKFolder}.");
        if not AssembleFuchsiaRuntime then
          Log("Fuchsia runtime SDK assembly was not requested; pass --assemble-sdk with the runtime input options to create the complete SDK and ZIP.");
      end;

      var lOutputManifestPath := Path.Combine(FuchsiaIntermediateFolder, "manifest.elements.json");
      if AssembleFuchsiaRuntime then begin
        var lZipPath := AssembleFuchsiaSDK(lSDKID, lAPILevel as not nullable, lSDKFolder);
        lOutputManifest["runtimeAssembled"] := true;
        lOutputManifest["sdkFolder"] := "Fuchsia "+lSDKID;
        if assigned(lZipPath) then
          lOutputManifest["zip"] := Path.Combine("__Public", Path.GetFileName(lZipPath));
      end;
      if CreateFuchsiaGCPackage then begin
        var lGCZipPath := AssembleFuchsiaGC(lSDKID);
        lOutputManifest["gcAssembled"] := true;
        if assigned(lGCZipPath) then
          lOutputManifest["gcZip"] := lGCZipPath;
      end;
      File.WriteText(lOutputManifestPath, lOutputManifest.ToJsonString(JsonFormat.HumanReadable));
      Log($"Wrote Fuchsia FIDL SDK manifest to {lOutputManifestPath}.");
    end;

  end;

end.
