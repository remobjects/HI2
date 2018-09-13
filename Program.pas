namespace HI2;

type
  Program = class
  public

    class method Main(args: array of String): Int32;
    begin
      // add your own code here
      writeLn('The magic happens here.');
      var lImporter := new Importer();
      lImporter.BaseFolder := "/Users/mh/Code/Elements/Frameworks/Island2";
      lImporter.GCSourceFolder := "/Users/mh/Code/git/gc";
      lImporter.GCBinariesFolder := "/Users/mh/Downloads/gc";
      lImporter.HI := "/Users/mh/Code/Elements/Bin/HeaderImporter.exe";

      //lImporter.FXBaseFolder

      //lImporter.ImportGC();
      lImporter.ImportXcode10Beta();
    end;

  end;

end.