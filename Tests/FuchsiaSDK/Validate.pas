namespace FuchsiaSdkCheck;

uses
  System,
  System.IO,
  System.Reflection;

type
  Program = class
  public

    // Exercise the real SDK validator and ZIP entry point without importing or altering a real SDK.
    class method Main(aArguments: array of String);
    begin
      var lAssembly := System.Reflection.Assembly.LoadFrom(Path.GetFullPath(aArguments[0]));
      var lType := lAssembly.GetType("RemObjects.Elements.HI2.Importer", true);
      var lImporter := Activator.CreateInstance(lType);
      var lFlags := BindingFlags.Instance or BindingFlags.NonPublic;
      var lValidate := lType.GetMethod("ValidateFuchsiaSDK", lFlags);
      var lZip := lType.GetMethod("CreateFuchsiaSDKZip", lFlags);
      var lRoot := Path.Combine(Path.GetTempPath, "fuchsia-sdk-check-"+Guid.NewGuid.ToString);
      Directory.CreateDirectory(lRoot);
      try
        for each lArch in ["arm64", "x86_64"] do
          for each lFile in ["Scrt1.o", "libfdio.so", "libzircon.so", "ld.so.1",
                            "dist/libfdio.so", "libunwind.a", "rtl.fx", "fuchsia.test.fx",
                            "libc.so", "libclang_rt.builtins.a"] do begin
            var lPath := Path.Combine(lRoot, lArch, lFile);
            Directory.CreateDirectory(Path.GetDirectoryName(lPath));
            File.WriteAllText(lPath, "fixture");
          end;
        lValidate.Invoke(lImporter, [lRoot]);
        for each lArch in ["arm64", "x86_64"] do
          for each lFile in ["Island.a", "Island.fx", "gc.fx", "libgc.a"] do begin
            var lPath := Path.Combine(lRoot, lArch, lFile);
            File.WriteAllText(lPath, "stale compiler runtime");
            for each lMethod in [lValidate, lZip] do begin
              var lRejected := false;
              try
                lMethod.Invoke(lImporter, [lRoot]);
              except
                on e: TargetInvocationException do
                  lRejected := e.InnerException.Message.Contains("must not contain '"+lFile+"'");
              end;
              if not lRejected then
                raise new Exception("Failed to reject "+lArch+"/"+lFile+" in "+lMethod.Name);
            end;
            File.Delete(lPath);
          end;
        lValidate.Invoke(lImporter, [lRoot]);
        Console.WriteLine("PASS: clean SDK accepted; all 8 stale runtime entries rejected by validation and ZIP creation.");
      finally
        Directory.Delete(lRoot, true);
      end;
    end;

  end;

end.
