#############################################################################
##
##  group2.gd              FinInG package
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
##  Copyright 2008 University of Western Australia, Perth
##                 Lehrstuhl D fuer Mathematik, RWTH Aachen
##                 Ghent University
##                 Colorado State University
##                 Vrije Universiteit Brussel
##
##  Declaration stuff for correlation groups and polarities of a projective
##  space.
##
#############################################################################

########################################
#
# Things To Do:
#
# - reorganise
#
########################################

DeclareCategory( "IsProjectiveSpaceIsomorphism", IsSPGeneralMapping );
DeclareCategory( "IsStandardDualityOfProjectiveSpace", IsProjectiveSpaceIsomorphism );
DeclareCategory( "IsIdentityMappingOfElementsOfProjectiveSpace", IsProjectiveSpaceIsomorphism );

DeclareCategory( "IsProjGrpElWithFrobWithPSIsom", IsComponentObjectRep and IsMultiplicativeElementWithInverse );
DeclareCategoryCollections( "IsProjGrpElWithFrobWithPSIsom" );
InstallTrueMethod( IsGeneratorsOfMagmaWithInverses, IsProjGrpElWithFrobWithPSIsomCollection );

DeclareRepresentation( "IsProjGrpElWithFrobWithPSIsomRep", IsProjGrpElWithFrobWithPSIsom, ["mat","fld","frob","psisom"] );

BindGlobal( "ProjElsWithFrobWithPSIsomFamily", 
            NewFamily( "ProjElsWithFrobWithPSIsomFamily",IsObject,
	                 IsProjGrpElWithFrobWithPSIsom ) );  
BindGlobal( "ProjElsWithFrobWithPSIsomCollFamily",
            CollectionsFamily(ProjElsWithFrobWithPSIsomFamily) );

BindGlobal( "ProjElsWithFrobWithPSIsomType",
     NewType( ProjElsWithFrobWithPSIsomFamily, 
              IsProjGrpElWithFrobWithPSIsom and 
	      IsProjGrpElWithFrobWithPSIsomRep ) );

InstallTrueMethod( IsHandledByNiceMonomorphism, IsProjectiveGroupWithFrob );

DeclareSynonym( "IsProjGroupWithFrobWithPSIsom", IsGroup and IsProjGrpElWithFrobWithPSIsomCollection);

InstallTrueMethod( IsHandledByNiceMonomorphism, IsProjGroupWithFrobWithPSIsom );

DeclareGlobalFunction( "OnProjPointsWithFrobWithPSIsom" );
DeclareGlobalFunction( "OnProjSubspacesWithFrobWithPSIsom" );
DeclareGlobalFunction( "OnProjSubspacesReversing" );

DeclareOperation( "StandardDualityOfProjectiveSpace", [IsProjectiveSpace] );
DeclareOperation( "IdentityMappingOfElementsOfProjectiveSpace", [IsProjectiveSpace] );
DeclareOperation( "ActionOnAllPointsHyperplanes", [IsProjGroupWithFrobWithPSIsom] );    
DeclareOperation( "ProjElWithFrobWithPSIsom",
   [IsMatrix and IsFFECollColl, IsMapping, IsField] ); 
DeclareOperation( "ProjElWithFrobWithPSIsom",
   [IsMatrix and IsFFECollColl, IsMapping, IsField,
   IsStandardDualityOfProjectiveSpace] ); 
DeclareOperation( "ProjElWithFrobWithPSIsom",
   [IsMatrix and IsFFECollColl, IsMapping, IsField,
   IsGeneralMapping and IsSPGeneralMapping and IsOne] ); 
DeclareOperation( "ProjElsWithFrobWithPSIsom", [IsList, IsField] );
DeclareOperation( "SetAsNiceMono", 
                  [IsProjGroupWithFrobWithPSIsom, IsGroupHomomorphism] );
DeclareAttribute( "Dimension", IsProjGroupWithFrobWithPSIsom );
DeclareProperty( "CanComputeActionOnPoints", IsProjGroupWithFrobWithPSIsom );
DeclareOperation( "CorrelationOfProjectiveSpace", [ IsList, IsField] );
DeclareOperation( "CorrelationOfProjectiveSpace", [ IsList, IsMapping, IsField] );
DeclareOperation( "CorrelationOfProjectiveSpace", [ IsList, IsField, IsStandardDualityOfProjectiveSpace] );
DeclareOperation( "CorrelationOfProjectiveSpace", [ IsList, IsMapping, IsField, IsStandardDualityOfProjectiveSpace] );
DeclareOperation( "UnderlyingMatrix", [ IsProjGrpElWithFrobWithPSIsom and IsProjGrpElWithFrobWithPSIsomRep ] );
DeclareOperation( "FieldAutomorphism", [ IsProjGrpElWithFrobWithPSIsom and IsProjGrpElWithFrobWithPSIsomRep ] );
DeclareOperation( "ProjectiveSpaceIsomorphism", [ IsProjGrpElWithFrobWithPSIsom and IsProjGrpElWithFrobWithPSIsomRep ] );


#############################################################################
#
# operations to create incidence preserving and reversing maps (to be placed in geometry.gd afterwards).
#
#############################################################################

#DeclareOperation( "Collineation", [IsIncidenceStructure, IsMultiplicativeElementWithInverse] );
#DeclareOperation( "Correlation", [IsIncidenceStructure, IsMultiplicativeElementWithInverse] );
#DeclareOperation( "Triality", [IsIncidenceStructure, IsMultiplicativeElementWithInverse] );

#DeclareOperation( "Polarity", [IsIncidenceStructure, IsMultiplicativeElementWithInverse] );
#DeclareOperation( "PolarityOfProjectiveSpace", [IsProjectiveSpace, IsMultiplicativeElementWithInverse] );

DeclareCategory( "IsPolarityOfProjectiveSpace", IsProjGrpElWithFrobWithPSIsomRep );
DeclareRepresentation( "IsPolarityOfProjectiveSpaceRep", IsProjGrpElWithFrobWithPSIsomRep, ["mat","fld","frob","psisom", "form"] );

#############################################################################
# polarities are equivalent with sesquilinear forms. 
# This explains the basic constructor
#############################################################################

DeclareOperation( "PolarityOfProjectiveSpaceOp", [IsForm] );
DeclareOperation( "PolarityOfProjectiveSpace", [IsForm] );
DeclareOperation( "PolarityOfProjectiveSpace", [IsMatrix,IsField and IsFinite] );
DeclareOperation( "PolarityOfProjectiveSpace", [IsMatrix,IsFrobeniusAutomorphism,IsField and IsFinite] );
DeclareOperation( "HermitianPolarityOfProjectiveSpace", [IsMatrix, IsField and IsFinite ] );

DeclareOperation( "PolarityOfProjectiveSpace", [IsClassicalPolarSpace] );

#DeclareAttribute( "IsDegeneratePolarity", IsPolarityOfProjectiveSpace ); #obsolete.
DeclareOperation( "BaseField", [ IsPolarityOfProjectiveSpace ]);
DeclareAttribute( "GramMatrix", IsPolarityOfProjectiveSpace );
DeclareAttribute( "CompanionAutomorphism", IsPolarityOfProjectiveSpace );
DeclareAttribute( "SesquilinearForm", IsPolarityOfProjectiveSpace );


#############################################################################
# operations and attributes for polarities of projective space. 
#############################################################################

DeclareProperty( "IsHermitianPolarityOfProjectiveSpace", IsPolarityOfProjectiveSpace );
DeclareProperty( "IsSymplecticPolarityOfProjectiveSpace", IsPolarityOfProjectiveSpace );
DeclareProperty( "IsOrthogonalPolarityOfProjectiveSpace", IsPolarityOfProjectiveSpace );
DeclareProperty( "IsPseudoPolarityOfProjectiveSpace", IsPolarityOfProjectiveSpace );

DeclareOperation( "IsAbsoluteElement", [ IsElementOfIncidenceStructure, IsPolarityOfProjectiveSpace ] );

DeclareOperation( "GeometryOfAbsolutePoints", [ IsPolarityOfProjectiveSpace ] );
DeclareOperation( "AbsolutePoints", [ IsPolarityOfProjectiveSpace ] );
DeclareOperation( "PolarSpace", [ IsPolarityOfProjectiveSpace ] );