namespace RemObjects.Elements.HI2;

uses
  RemObjects.Elements.RTL;

type
  HIException = public class(Exception)
  end;

  Importer = public partial class
  public

    property CodeFolder: String;
    property ApplicationsFolder: String;

    property BaseFolder: String;
    property HI: String;
    property Mono: String;
    property Debug := false;
    property CreateZips := true;

    property HIRunsEmbedded := false;

//    property FXBaseFolder: String; // MUST BE SET!

    property LoggingCallback: block(aLine: String);

    method Log(aLine: String);
    begin
      if assigned(LoggingCallback) then
        LoggingCallback(aLine)
      else
        writeLn(aLine);
    end;

    method RunHI(aArgs: ImmutableList<String>) SDKFolder(aSDKFolder: nullable String := nil);
    begin
      Log(Process.StringForCommand("HeaderImporter") Parameters(aArgs));
      var lOutput := new StringBuilder();

      var lExe := HI;
      if defined("TOFFEE") and assigned(Mono) then begin
        var lArguments := aArgs.MutableVersion;
        lArguments.Insert(0, HI);
        aArgs := lArguments;
        lExe := Mono;
      end;

      var lExitCode: Integer;

      if defined("ECHOES") and HIRunsEmbedded then begin
        lExitCode := HeaderImporter.HeaderImporterConsoleApp.Main(aArgs.ToArray);
      end
      else begin
        lExitCode := Process.Run(lExe, aArgs.ToArray, nil, nil, s -> begin
          lOutput.AppendLine(s);
          if Debug or assigned(LoggingCallback) then
            Log("  "+s);
        end, s -> begin
          lOutput.AppendLine(s);
          Log("  "+s);
        end);
      end;

      if lExitCode ≠ 0 then begin
        if not (Debug or assigned(LoggingCallback)) then
          Log(lOutput.ToString);
        if assigned(aSDKFolder) then begin
          writeLn($"Header Importer failed");
          writeLn($"SDK Folder: {aSDKFolder}");
          writeLn($"Command Line: {Process.StringForCommand("HeaderImporter.exe") Parameters(aArgs)}");
        end;
        raise new HIException("HeaderImporter failed");
      end;
    end;

    method MergeArchitectures(aFolder: String; aFileName: String; aDelete: Boolean := true);
    begin

      var lFiles := new List<String>;
      for each f in Folder.GetSubfolders(aFolder) do begin
        f := Path.Combine(f, aFileName);
        if f.FileExists then
          lFiles.Add(f);
      end;

      var lOutputFile := Path.Combine(aFolder, aFileName);

      if lFiles.Count > 1 then begin
        var lArgs := new List<String>;
        lArgs.Add("combine");
        lArgs.Add(lOutputFile);
        lArgs.Add(lFiles);
        RunHI(lArgs);
      end
      else if lFiles.Count = 1 then begin
        File.CopyTo(lFiles.First, lOutputFile);
      end;

      if aDelete then
        for each f in Folder.GetSubfolders(aFolder) do
          Folder.Delete(f);

    end;

  end;
end.