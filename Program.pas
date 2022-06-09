namespace RemObjects.Elements.HI2;

uses
  RemObjects.Elements.Basics;

type
  Program = class
  public


    class method Main(args: array of String): Int32;
    begin
      try
        // add your own code here
        writeLn("RemObjects Elements .fx Importer Frontend (HI2).");
        writeLn("Copyright RemObjects Software 2016-2021. All Rights Reserved.");
        writeLn();

        var lImporter := new Importer();
        lImporter.CodeFolder := Path.Combine(Environment.UserHomeFolder, "Code/");
        lImporter.HI := Path.Combine(ElementsPaths.Instance.ElementsBinFolder, "HeaderImporter.exe");
        lImporter.FrameworksFolder := Path.Combine(ElementsPaths.Instance.ElementsBinFolder, "..", "Frameworks");
        lImporter.ApplicationsFolder := Path.Combine(Environment.UserHomeFolder, "Applications");
        if not lImporter.ApplicationsFolder.FolderExists then
          lImporter.ApplicationsFolder := "/Applications";

        //lImporter.Debug := true;

        method ImportGC();
        begin
          lImporter.GCSourceFolder := "/Users/mh/Code/RemObjects/gc";
          lImporter.GCBinariesFolder := "/Users/mh/Code/Elements/Bin/References/Island";
          //lImporter.GCBinariesFolder := lImporter.GCSourceFolder;
          //lImporter.BaseFolder := Path.Combine(lImporter.FrameworksFolder, "Island");
          lImporter.BaseFolder := Path.Combine("/Users/mh/Code/Elements/Bin/Island SDKs/");
          lImporter.ImportGC();
        end;

        //ImportGC();
        //exit;

        lImporter.ImportSDKs()

        //PrepareToffee();
        //lImporter.ImportCurrentXcode();

        //PrepareIsland();
        //lImporter.ImportCurrentXcode();

        //lImporter.ImportXcode10_0();
        //lImporter.ImportXcode94();

      except
        on E: HIException do;
      end;
    end;

  end;

end.