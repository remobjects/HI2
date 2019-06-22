namespace RemObjects.Elements.HI2;

type
  Program = class
  public


    class method Main(args: array of String): Int32;
    begin
      // add your own code here
      writeLn("RemObjects Elements .fx Importer Frontend (HI2).");
      writeLn("Copyright RemObjects Software 2016-2018. All Rights Reserved.");
      writeLn();

      var lImporter := new Importer();
      lImporter.HI := "/Users/mh/Code/Elements/Source/HeaderImporter/Bin/Debug/HeaderImporter.exe";
      var lFrameworkBaseFolder := "/Users/mh/Code/Elements/Frameworks/";

      lImporter.SkipDeploymentTargets := false;
      //lImporter.Debug := true;

      method PrepareIsland();
      begin
        Darwin.Toffee := false;
        Darwin.Island := true;
        //lImporter.SkipDeploymentTargets := true;
        lImporter.BaseFolder := Path.Combine(lFrameworkBaseFolder, "Island");
      end;

      method PrepareToffee();
      begin
        Darwin.Toffee := true;
        Darwin.Island := false;
        //lImporter.SkipDeploymentTargets := true;
        lImporter.BaseFolder := Path.Combine(lFrameworkBaseFolder, "Toffee");
      end;

      method ImportGC();
      begin
        lImporter.GCSourceFolder := "/Users/mh/Code/RemObjects/gc";
        lImporter.GCBinariesFolder := "/Users/mh/Code/Elements/Bin/References/Island";
        //lImporter.GCBinariesFolder := "/Users/mh/Downloads/gc";
        lImporter.BaseFolder := Path.Combine(lFrameworkBaseFolder, "Island");
        lImporter.ImportGC();
      end;

      //ImportGC();
      //exit;

      PrepareToffee();
      lImporter.ImportCurrentXcode();

      PrepareIsland();
      lImporter.ImportCurrentXcode();

      //lImporter.ImportXcode10_0();
      //lImporter.ImportXcode94();
    end;

  end;

end.