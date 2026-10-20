// Positive regression guards: a refreshed Windows SDK has four distinct CPU slices,
// WinRT depends on rtl, and EC imports Windows functions with the AMD64 CONTEXT layout.
// Negative guard: ordinary ARM64 context fields must not leak into the EC declarations.
namespace WindowsSdkCheck;

uses System, System.IO, System.Linq, RemObjects.Elements.Fx;

type
  Program = class
  private
    class method Check(aCondition: Boolean; aMessage: String);
    begin
      if not aCondition then
        raise new Exception(aMessage);
    end;

    class method Load(aPath: String): FxFile;
    begin
      result := new FxFile;
      using lStream := File.OpenRead(aPath) do
        result.Read(lStream);
    end;

  public
    class method Main(aArgs: array of String);
    begin
      Check(length(aArgs) = 1, 'Pass the Windows SDK root');
      for each lArchitecture in ['i386', 'x86_64', 'arm64', 'arm64ec'] do begin
        var lCPU := FxCpuTarget(Enum.Parse(typeOf(FxCpuTarget), lArchitecture));
        for each lName in ['rtl', 'winrt'] do begin
          var lFx := Load(Path.Combine(aArgs[0], lArchitecture, lName+'.fx'));
          Check(lFx.Name = lName, 'FX name: '+lArchitecture+'/'+lName);
          Check(lFx.Platform = 'Windows', 'FX platform');
          Check((lFx.TargetDescriptors.Count = 1) and (lFx.TargetDescriptors[0] = lCPU), 'FX architecture: '+lArchitecture);
          Check(lFx.Targets.Count = 1, 'Expected single CPU slice');
          var lTarget := lFx.Targets[0];
          var lTripleCPU := if lArchitecture = 'i386' then 'i686' else lArchitecture;
          Check(lTarget.TargetString = lTripleCPU+'-pc-windows-msvc', 'FX target triple');
          if lName = 'winrt' then
            Check(lTarget.DependentFx.Contains('rtl'), 'WinRT must reference rtl');
          if (lName = 'rtl') and (lArchitecture in ['arm64', 'arm64ec']) then begin
            var lContext := lTarget.NamedTypes.First(n -> n.Name = 'rtl.CONTEXT');
            var lDefinition := lTarget.Types[lContext.Type] as FxDefinitionType;
            Check(lDefinition <> nil, 'CONTEXT definition');
            var lFields := lDefinition.Members.Select(m -> m.Name).ToArray;
            if lArchitecture = 'arm64ec' then begin
              Check(lFields.Contains('Rsp') and lFields.Contains('Rip') and lFields.Contains('Rbp'), 'EC requires AMD64 CONTEXT fields');
              Check(not lFields.Contains('Sp'), 'Native ARM64 CONTEXT leaked into EC');
              Check(lTarget.Types.OfType<FxDefinitionType>.Any(t -> t.Members.Any(m -> (m.Name = 'GetTickCount') and m.Attributes.Any(a -> a.SpecialID = FxSpecialAttributeID.DllImport))), 'GetTickCount DLL import missing');
            end
            else begin
              Check(lFields.Contains('Sp') and lFields.Contains('Pc'), 'ARM64 CONTEXT fields');
              Check(not lFields.Contains('Rsp'), 'EC layout leaked into ARM64');
            end;
          end;
        end;
        Console.WriteLine('PASS: '+lArchitecture+' rtl and winrt metadata');
      end;
    end;
  end;
end.
