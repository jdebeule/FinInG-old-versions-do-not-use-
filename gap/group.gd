#############################################################################
##
##  group.gd              FinInG package
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
##  Declaration stuff for some new group representations
##
##  Declaration stuff for groups. changed by the new gang of four september
##  25, 2008, st. andrews.
#############################################################################

DeclareGlobalFunction("MakeAllProjectivePoints");
DeclareGlobalFunction("IsScalarMatrix");

## For later versions of GenSS, Max has changed the number of variables
## for the operation FindBasePointCandidates.

if PackageInfo("GenSS")[1]!.Version > "0.95" then
   DeclareOperation( "FindBasePointCandidates", [ IsGroup, IsRecord, IsInt ] );
 else 
   DeclareOperation( "FindBasePointCandidates", [ IsGroup, IsRecord, IsInt, IsObject ] );
fi;

###################################################################
# Construction operations for projective elements, that is matrices modulo scalars
# including representations
###################################################################

DeclareCategory( "IsProjGrpEl", IsComponentObjectRep and IsMultiplicativeElementWithInverse );
DeclareCategoryCollections( "IsProjGrpEl" );
InstallTrueMethod( IsGeneratorsOfMagmaWithInverses, IsProjGrpElCollection );

DeclareRepresentation( "IsProjGrpElRep", IsProjGrpEl, ["mat","fld"] );

BindGlobal( "ProjElsFamily", 
            NewFamily( "ProjElsFamily", IsObject, IsProjGrpEl ) );
BindGlobal( "ProjElsCollFamily", CollectionsFamily(ProjElsFamily) );

BindGlobal( "ProjElsType", NewType( ProjElsFamily, 
                                    IsProjGrpEl and IsProjGrpElRep) );

DeclareOperation( "ProjEl", [IsMatrix and IsFFECollColl] );
DeclareOperation( "ProjEls", [IsList] );

DeclareSynonym( "IsProjectiveGroup", IsGroup and IsProjGrpElCollection);

InstallTrueMethod(IsHandledByNiceMonomorphism, IsProjectiveGroup);

DeclareOperation( "Projectivity", [ IsList, IsField] );

###################################################################
# Construction operations for projective semilinear elements, that is matrices modulo scalars
# and a Frobenius automorphism, including representations
###################################################################

DeclareCategory( "IsProjGrpElWithFrob", IsComponentObjectRep and IsMultiplicativeElementWithInverse );
DeclareCategoryCollections( "IsProjGrpElWithFrob" );
InstallTrueMethod( IsGeneratorsOfMagmaWithInverses, IsProjGrpElWithFrobCollection );

DeclareRepresentation( "IsProjGrpElWithFrobRep", IsProjGrpElWithFrob, ["mat","fld","frob"] );

BindGlobal( "ProjElsWithFrobFamily", 
            NewFamily( "ProjElsWithFrobFamily",IsObject,IsProjGrpElWithFrob) );
BindGlobal( "ProjElsWithFrobCollFamily",
            CollectionsFamily(ProjElsWithFrobFamily) );
BindGlobal( "ProjElsWithFrobType",
     NewType( ProjElsWithFrobFamily, 
              IsProjGrpElWithFrob and IsProjGrpElWithFrobRep) );

DeclareOperation( "ProjElWithFrob", [IsMatrix and IsFFECollColl, IsMapping] );
DeclareOperation( "ProjElWithFrob", [IsMatrix and IsFFECollColl, IsMapping, IsField] );
DeclareOperation( "ProjElsWithFrob", [IsList] );
DeclareOperation( "ProjElsWithFrob", [IsList, IsField] );

DeclareOperation( "ProjectiveSemilinearMap", [ IsList, IsField] );
DeclareOperation( "ProjectiveSemilinearMap", [ IsList, IsMapping, IsField] );
DeclareSynonym( "CollineationOfProjectiveSpace", ProjectiveSemilinearMap);
DeclareOperation( "ProjectivityByImageOfStandardFrameNC", [IsProjectiveSpace, IsList] );

###################################################################
# Some operations for elements
###################################################################

DeclareOperation( "UnderlyingMatrix", [ IsProjGrpElWithFrob and IsProjGrpElWithFrobRep ] );
DeclareOperation( "UnderlyingMatrix", [ IsProjGrpEl and IsProjGrpElRep] );
DeclareOperation( "FieldAutomorphism", [ IsProjGrpElWithFrob and IsProjGrpElWithFrobRep ] );

#################################################
# Frobenius automorphisms and groups using them:
#################################################

DeclareGlobalFunction( "OnProjPoints" );
DeclareGlobalFunction( "OnProjSubspacesNoFrob" );

DeclareOperation( "ActionOnAllProjPoints", [IsProjectiveGroup] );
DeclareOperation( "SetAsNiceMono", [IsProjectiveGroup, IsGroupHomomorphism] );

DeclareAttribute( "Dimension", IsProjectiveGroup );
DeclareProperty( "CanComputeActionOnPoints", IsProjectiveGroup );

DeclareSynonym( "IsProjectiveGroupWithFrob", IsGroup and IsProjGrpElWithFrobCollection);

#################################################
# action functions:
#################################################

InstallTrueMethod( IsHandledByNiceMonomorphism, IsProjectiveGroupWithFrob );

DeclareGlobalFunction( "OnProjPointsWithFrob" );
DeclareGlobalFunction( "OnProjSubspacesWithFrob" );

DeclareOperation( "ActionOnAllProjPoints", [IsProjectiveGroupWithFrob] );
DeclareOperation( "SetAsNiceMono", [IsProjectiveGroupWithFrob, IsGroupHomomorphism] );

DeclareAttribute( "Dimension", IsProjectiveGroupWithFrob );
DeclareProperty( "CanComputeActionOnPoints", IsProjectiveGroupWithFrob );

DeclareGlobalFunction( "NiceMonomorphismByOrbit" );
DeclareGlobalFunction( "NiceMonomorphismByDomain" );

###########################
# Some group constructions:
###########################

## helper operations for canonical matrices, for classical groups.

DeclareOperation( "CanonicalGramMatrix", [IsString, IsPosInt, IsField]); 
DeclareOperation( "CanonicalQuadraticForm", [IsString, IsPosInt, IsField]); 

## The following are conjugates of the groups in the classical groups
## library which are compatible with the canonical forms in FinInG 

DeclareOperation( "SOdesargues", [IsInt, IsPosInt, IsField and IsFinite]);
DeclareOperation( "GOdesargues", [IsInt, IsPosInt, IsField and IsFinite]);
DeclareOperation( "SUdesargues", [IsPosInt, IsField and IsFinite]);
DeclareOperation( "GUdesargues", [IsPosInt, IsField and IsFinite]);
DeclareOperation( "Spdesargues", [IsPosInt, IsField and IsFinite]);

## The following are methods which return the full group of invertible 
## matrices which preserve a form up to scalars

DeclareOperation( "GeneralSymplecticGroup", [IsPosInt, IsField and IsFinite]);
DeclareOperation( "GSpdesargues", [IsPosInt, IsField and IsFinite]);
DeclareOperation( "DeltaOminus", [IsPosInt, IsField and IsFinite]);
DeclareOperation( "DeltaOplus", [IsPosInt, IsField and IsFinite]);

## The following are methods which return the full group of invertible 
## matrices which preserve a form up to scalars and a field aut.

DeclareOperation( "GammaOminus", [IsPosInt, IsField and IsFinite]);
DeclareOperation( "GammaO", [IsPosInt, IsField and IsFinite]);
DeclareOperation( "GammaOplus", [IsPosInt, IsField and IsFinite]);
DeclareOperation( "GammaU", [IsPosInt, IsField and IsFinite]);
DeclareOperation( "GammaSp", [IsPosInt, IsField and IsFinite]);