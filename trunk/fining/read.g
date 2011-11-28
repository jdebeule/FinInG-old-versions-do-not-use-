#############################################################################
##
##  read.g              FinInG package
##                                                              John Bamberg
##                                                              Anton Betten
##                                                              Jan De Beule
##                                                             Philippe Cara
##                                                            Michel Lavrauw
##                                                                 Maska Law
##                                                           Max Neunhoeffer
##                                                            Michael Pauley
##                                                             Sven Reichard
##
##  Copyright 2011	Colorado State University, Fort Collins
##					Università degli Studi di Padova
##					Universeit Gent
##					University of St. Andrews
##					University of Western Australia, Perth
##                  Vrije Universiteit Brussel
##                 
##
##  Reading the implementation part of the FinInG package.
##
#############################################################################

if InstalledPackageVersion("forms") < "1.2" then
   ReadPackage("fining","gap/forms_ext.gi"); 
fi;
if InstalledPackageVersion("forms") < "1.2.2" then
   Forms_RESET := RESET; 
fi;
if InstalledPackageVersion("forms") <= "1.2.2" then
   ReadPackage("fining","gap/forms_patch.gi"); 
fi;

ReadPackage("fining","gap/geometry.gi");

ReadPackage("fining","gap/liegeometry.gi"); 

ReadPackage("fining","gap/group.gi"); 

ReadPackage("fining","gap/projectivespace.gi");

ReadPackage("fining","gap/correlations.gi");

ReadPackage("fining","gap/polarspace.gi");
ReadPackage("fining","gap/morphisms.gi");

ReadPackage("fining","gap/enumerators.gi");

ReadPackage("fining","gap/diagram.gi");

ReadPackage("fining","gap/varieties.gi");

ReadPackage("fining","gap/affinespace.gi");
ReadPackage("fining","gap/affinegroup.gi");

ReadPackage("fining","gap/gpolygons.gi");

Print("\n");
#ReadPackage("fining","gap/emptysubspace.gi");
#ReadPackage("fining","gap/linearalgebra_patch.g");
##ReadPackage("fining","gap/polaritiesps.gi"); #obsolete.