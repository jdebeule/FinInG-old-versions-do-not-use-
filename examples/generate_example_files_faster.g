#create output and include files from .g files in the examples/gap directory.
#Executing this file is NOT necessary for the installation of the package "fining", and the
#use of all documentation.
#
#Performing these steps, files will be written in the doc directory of the
#fining package tree. Under UNIX-like operating systems, you need sufficient
#permissions to do. Executing this is NOT necessary for the installation of the
#package "fining".
#
#Messy things happen when you do it, so don't try this at home kids!
#file adapted on april 10th, 2011.

#create workspace with packages
LoadPackage("fining");
SaveWorkspace("fining.ws");
quit;

#restart gap now.

#initialize filenames

affinefiles := ["affine_parallel", "affine_shadow1", "affine_shadow2", "affine_basic", 
               "affine_elements", "affine_iterator", "affine_enumerator", "affine_join", "affine_meet"];;

examplesfiles := ["examples_pg24", "examples_hermitian", "examples_embedW", "examples_spreads", 
                  "examples_qclan", "examples_KantorKnuth","examples_PSL211"];;

incgeomfiles := ["incgeom_categories1", "incgeom_rank", "incgeom_typesofels", "incgeom_categories2", 
                 "incgeom_elementsj", "incgeom_short",
                 "incgeom_solids", "incgeom_isincident", "incgeom_shadowofelement",
		 "incgeom_shadowofflag", "incgeom_iterator" ]; 

morphismsfiles := ["morphisms_intertwiners","morphisms_embedding1","morphisms_embedding2","morphisms_typesubspace",
          "morphisms_fieldreduc1", "morphisms_fieldreduc2","morphisms_subfield1","morphisms_subfield2",
          "morphisms_isopolar","morphisms_projection","morphisms_completion","morphisms_klein","morphisms_duality"];;


projpolfiles1 := ["projpol_projectivespace", "projpol_projdimension",
                 "projpol_underlyingvs", "projpol_element1", "projpol_emptysubspace",
		 "projpol_projdimension_element", "projpol_standardframe", "projpol_coordinates",
		  "projpol_eqhyperplane", "projpol_basefieldps", "projpol_ambientspaceelps", 
		  "projpol_basefieldelps", "projpol_randomeltsps", "projpol_randomelps",
		  "projpol_span", "projpol_meet", "projpol_shadowofelement", "projpol_flag",
		  "projpol_shadowofflag"];
		 
		 
		 "projpol_hermitian", "projpol_elliptic",
		 "projpol_parabolic", "projpol_hyperbolic", "projpol_element1", "projpol_in"];

projpolfiles1 := ["projpol_projectivespace", "projpol_polarspaceform",
                 "projpol_symplectic", "projpol_hermitian", "projpol_elliptic",
		 "projpol_parabolic", "projpol_hyperbolic", "projpol_element1", "projpol_in"];

projgroupsfiles := ["projgroups_basefield",
	  "projgroups_collineation", "projgroups_collineationgroup",
	  "projgroups_correlation", "projgroups_fieldautomorphism",
	  "projgroups_projectivity", "projgroups_psisomorphism",
	  "projgroups_stduality", "projgroups_underlyingmatrix", "projgroups_onprojsubspaces",
	  "projgroups_onprojsubspacesreversing", "projgroups_simgroup", 
	  "projgroups_isomgroup", "projgroups_specialisomgroup", 
	  "projgroups_mult", "projgroups_embedding", "projgroups_representative",
	  "projgroups_order"];;

polaritiespsfiles := ["polarities_construct1", "polarities_construct2",
          "polarities_fromform", "polarities_toform", "polarities_basefield", 
	  "polarities_automorphism", "polarities_grammatrix", "polarities_ishermitian", 
	  "polarities_issymplectic", "polarities_ispseudo", "polarities_isorthogonal", 
	  "polarities_geometryofabsolutepoints", "polarities_absolutepoints", 
	  "polarities_polarspace", "polarities_frompolarspace", 
	  "polarities_commuting"];

gpolygonfiles := ["gpolygons_projplanes1", "gpolygons_projplanes2", "gpolygons_EGQByKantorFamily", 
                  "gpolygons_EGQByqClan", "gpolygons_EGQByBLTSet", "gpolygons_collineations", "gpolygons_SplitCayleyHexagon"];

diagramfiles := ["diagram_cosetgeom"];

websitefiles := ["web_hyperoval24", "web_inumbersherm", "web_embedding", "web_spreads", "web_ovoidq63"];

files := [ "projgroups_order" ];

#initialize directorynames
#exampledir = dir where .g files are located : ".../pkg/fining/examples/gap"
#preambledir = directory where 'preamble_sws.g is found' :  ".../pkg/fining/examples"
#outputdir = directory to write '.out' files: ".../pkg/fining/examples/output"
#name of script to start gap version. The user has to fill this in!

homedir := DirectoryCurrent();
exampledir := DirectoriesPackageLibrary("fining","examples/gap")[1]; 
preambledir := DirectoriesPackageLibrary("fining","examples/")[1]; 
outputdir := DirectoriesPackageLibrary("fining","examples/output")[1];
gap := Filename(Directory("/usr/bin/"),"gap4r4");  
paths := JoinStringsWithSeparator(GAP_ROOT_PATHS,";");
args := JoinStringsWithSeparator(["-l ",paths," -L fining.ws"]," ");

#create .out files using the saved workspace
#IMPORTANT: here we suppose that the script to start up our favorite version of
#GAP is called 'gap4r4', and is located in '/usr/bin'. Change the code if this is not true!
#you certainly now the name of the script, since you started gap. To find the
#dir, just issue in the gap session that is running:

Exec("which gap4r4"); #for UNIX only

for filename in files do
  Print("Now converting file: ", filename, "\n");
  gap := Filename(Directory("/usr/bin/"),"gap4r4");
  stream := InputOutputLocalProcess( homedir, gap, [args]);
  cmd := Concatenation("file := \"",filename,".out\";");
  WriteLine(stream,cmd);
  cmd := "dir \:\= DirectoriesPackageLibrary\(\"fining\"\,\"examples\/output\"\)\[1\]\;";
  WriteLine(stream,cmd);
  preamble := Filename(preambledir,"preamble.g");
  preamble_stream := InputTextFile(preamble);
  cmds := ReadAll(preamble_stream);
  WriteLine(stream,cmds);
  repeat
    str := ReadLine(stream);
  until str = "true\n";
  inputfile := Filename(exampledir,Concatenation(filename,".g"));
  input_stream := InputTextFile(inputfile);
  cmd := ReadLine(input_stream);
  while cmd <> fail do
    WriteAll(stream,cmd);
    cmd := ReadLine(input_stream);
    ReadAll(stream);
  od;
od;

#create .include files
#for the include files, some characters will be translated to suitable xml
#codes, taking more then one character. Therefore we widen the screen a little bit.
#includir: directory containing the include files: ".../pkg/fining/examples/include"
SizeScreen([256,24]);
includedir := DirectoriesPackageLibrary("fining","examples/include")[1];
for filename in files do
  i := Filename(outputdir,Concatenation(filename,".out"));
  o := Filename(includedir,Concatenation(filename,".include"));
  PrintTo(o,"");
  input_stream := InputTextFile(i);
  ReadLine(input_stream);
  ReadLine(input_stream);
  line := ReadLine(input_stream);
  while line <> "gap> quit;\n" do
    if line <> "\n" then
      line := ReplacedString(line,"\\\n","\n");
      AppendTo(o,ReplacedString(ReplacedString(line,"<","&lt;"),">","&gt;"));
    fi;
    line := ReadLine(input_stream);
  od;
od;
SizeScreen([80,24]);

#create .include files suitable for include in html, e.g. on your homepage directory (for godsake,
#comment your code!).
SizeScreen([256,24]);
includedir := DirectoriesPackageLibrary("fining","examples/html")[1];
for filename in files do
  i := Filename(outputdir,Concatenation(filename,".out"));
  o := Filename(includedir,Concatenation(filename,".html"));
  PrintTo(o,"");
  input_stream := InputTextFile(i);
  ReadLine(input_stream);
  ReadLine(input_stream);
  line := ReadLine(input_stream);
  while line <> "gap> quit;\n" do
  # while line <> fail do
    if line <> "\n" then
      line := ReplacedString(line,"\\\n","\n");
      line := ReplacedString(ReplacedString(line,"<","&lt;"),">","&gt;"); 
      #ReplacedString(line,"<","&lt;");
      AppendTo(o,ReplacedString(line,"\n","<br>\n"));
    fi;
    line := ReadLine(input_stream);
  od;
od;
#back to default.
SizeScreen([80,24]);