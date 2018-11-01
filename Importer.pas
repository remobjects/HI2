namespace HI2;

type
  Importer = public partial class
  public

    property BaseFolder: String;
    property HI: String;
    property Debug := false;

//    property FXBaseFolder: String; // MUST BE SET!

    method RunHI(aArgs: ImmutableList<String>);
    begin
      writeLn(Process.StringForCommand("HeaderImporter") Parameters(aArgs));
      var lOutput := new StringBuilder();
      var lExitCode := Process.Run(HI, aArgs.ToArray, nil, nil, s -> begin
        lOutput.AppendLine(s);
        if Debug then
          writeLn("  "+s);
      end, s -> begin
        lOutput.AppendLine(s);
        writeLn("  "+s);
      end);

      if lExitCode ≠ 0 then begin
        writeLn(lOutput.ToString);
        raise new Exception("HeaderImporter failed with {0}", lExitCode);
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