Include "constitutiveLaws.pro";

// ----------------------------------------------------------------------------
// -------------------------- GROUPS ------------------------------------------
// ----------------------------------------------------------------------------
// Groups associated with function spaces
Group{
    // Domains for the different formulations
    If(formulation == h_formulation)
        Omega_h = Region[{Omega}];
        Omega_h_OmegaC = Region[{OmegaC}];
        Omega_h_OmegaC_AndBnd = Region[{OmegaC, BndOmegaC}];
        Omega_h_OmegaCC = Region[{OmegaCC}];
        If(Flag_MB==1)
            Omega_h_OmegaCC_AndBnd = Region[{OmegaCC, BndOmegaC, Rotor_Bnd_MBaux}];
        Else
            Omega_h_OmegaCC_AndBnd = Region[{OmegaCC, BndOmegaC}];
        EndIf
        Omega_a  = Region[{}];
        Omega_a_AndBnd = Region[{}];
        Omega_a_OmegaCC = Region[{}];
        BndOmega_ha = Region[{}];
    ElseIf(formulation == a_formulation)
        Omega_h = Region[{}];
        Omega_h_OmegaC = Region[{}];
        Omega_h_OmegaC_AndBnd = Region[{}];
        Omega_h_OmegaCC = Region[{}];
        Omega_h_OmegaCC_AndBnd = Region[{}];
        Omega_a  = Region[{Omega}];
        If(Flag_MB==1)
            Omega_a_AndBnd  = Region[{Omega, GammaAll, BndOmegaC, Rotor_Bnd_MBaux}];
        Else
            Omega_a_AndBnd  = Region[{Omega, GammaAll, BndOmegaC}];
        EndIf
        Omega_a_OmegaCC = Region[{OmegaCC}];
        Omega_a_OmegaCC_AndBnd = Region[{OmegaCC, BndOmegaC}];
        BndOmega_ha = Region[{}];
    ElseIf(formulation == coupled_formulation)
        Omega_h = Region[{OmegaC}];
        Omega_h_OmegaC = Region[{OmegaC}];
        Omega_h_OmegaC_AndBnd = Region[{OmegaC, BndOmegaC}];
        Omega_h_OmegaCC = Region[{}];
        Omega_h_OmegaCC_AndBnd = Region[{BndOmegaC}];
        Omega_a  = Region[{OmegaCC}];
        If(Flag_MB==1)
            Omega_a_AndBnd  = Region[{Omega, GammaAll, BndOmegaC, Rotor_Bnd_MBaux}];
        Else
            Omega_a_AndBnd  = Region[{OmegaCC, GammaAll, BndOmegaC}];
        EndIf
        Omega_a_OmegaCC = Region[{OmegaCC}];
        BndOmega_ha = Region[{BndOmegaC}];
		Omega_h_AndBnd = Region[{OmegaC, BndOmegaC}];
    EndIf
    TransitionLayerAndBndOmegaC = ElementsOf[BndOmegaC_side, OnOneSideOf Cuts];
}
Function{
    T_max[] = ( SquDyadicProduct[$1] - SquNorm[$1] * TensorDiag[0.5, 0.5, 0.5] ) / mu0 ;
}

// ----------------------------------------------------------------------------
// -------------------------- JACOBIAN ----------------------------------------
// ----------------------------------------------------------------------------
// Jacobian-type for the transformation into isoparameteric elements
Jacobian {
    // For volume integration (Dim N)
    { Name Vol ;
        Case {
            If(Axisymmetry == 0)
                // Classical transformation Jacobian
                {Region All ; Jacobian Vol ;}
            Else
                // Axisymmetric problems
                //  Simple Jacobian, well suited to Edge basis function
                {Region Omega_h ; Jacobian VolAxi ;}
                //  Second-type, better suited to PerpendicularEdge basis functions
                {Region Omega_a ; Jacobian VolAxiSqu ;}
            EndIf
        }
    }
    // For surface integration (Dim N-1)
    { Name Sur ;
        Case {
            If(Axisymmetry == 0)
                { Region All ; Jacobian Sur ; }
            Else
                { Region All ; Jacobian SurAxi ; }
            EndIf
        }
    }
}

// ----------------------------------------------------------------------------
// --------------------------- INTEGRATION ------------------------------------
// ----------------------------------------------------------------------------
// Type of integration and number of quadrature points for each element type
Integration {
    { Name Int ;
        Case {
            { Type Gauss ;
	           Case {
                  { GeoElement Point ; NumberOfPoints 1 ; }
                  { GeoElement Line ; NumberOfPoints 3 ; }
                  { GeoElement Line2 ; NumberOfPoints 4 ; } // Second-order element
	              { GeoElement Triangle ; NumberOfPoints 3 ; }
                  { GeoElement Triangle2 ; NumberOfPoints 12 ; }
                  { GeoElement Quadrangle ; NumberOfPoints 4 ; }
                  { GeoElement Quadrangle2 ; NumberOfPoints 4 ; } // Second-order element
                  { GeoElement Tetrahedron ; NumberOfPoints  5 ; }
                  { GeoElement Tetrahedron2 ; NumberOfPoints  5 ; } // Second-order element
                  { GeoElement Pyramid ; NumberOfPoints  8 ; }
                  { GeoElement Hexahedron ; NumberOfPoints  6 ; }
	            }
            }
        }
    }
}

// ----------------------------------------------------------------------------
// --------------------------- FUNCTION SPACE ---------------------------------
// ----------------------------------------------------------------------------
// Gauge condition for the vector potential
Group {
    Surf_a_noGauge = Region [ {Gamma_e, BndOmegaC} ] ;
}
Constraint {
    { Name GaugeCondition ; Type Assign ;
        Case {
            // Zero on edges of a tree in Omega_CC, containing a complete tree on Surf_a_noGauge
            {Region Omega_a_OmegaCC ; SubRegion Surf_a_noGauge; Value 0.; }
        }
    }
	{ Name psiSta ;
        Case {
            { Region ArbitraryPoint ; Type Assign ; Value 0.0 ; }
        }
    }
	{ Name GaugeCondition_hs ; Type Assign ;
        Case {
            { Region Omega_h_OmegaC ; SubRegion BndOmegaC ; Value 0. ; }
        }
    }
}
// Function spaces for the spatial discretization
FunctionSpace {
	{ Name phi_space; Type Form0;
        BasisFunction{
            { Name phin; NameOfCoef psin; Function BF_Node;
                Support Omega_h; Entity NodesOf[All]; }
        }
        Constraint{
            { NameOfCoef psin; EntityType NodesOf; NameOfConstraint psiSta; }
        }
    }

	{ Name hs_space; Type Form1;
        BasisFunction {
            { Name psie; NameOfCoef he; Function BF_Edge;
                Support Omega_h_OmegaC; Entity EdgesOf[All, Not BndOmegaC]; }
            { Name ci; NameOfCoef Ii; Function BF_GradGroupOfNodes;
                Support ElementsOf[Omega_h_OmegaCC, OnPositiveSideOf Cuts];
                Entity GroupsOfNodesOf[Cuts]; }
            { Name ci; NameOfCoef Ii2; Function BF_GroupOfEdges;
                Support Omega_h_OmegaC;
                Entity GroupsOfEdgesOf[Cuts, InSupport TransitionLayerAndBndOmegaC] ; } // To treat properly the Cut-Omega_C junction
        }
        SubSpace {
          { Name BF_Cut ; NameOfBasisFunction { ci } ; }
        }
        Constraint {
             { NameOfCoef he; EntityType EdgesOfTreeIn; EntitySubType StartingOn;
                  NameOfConstraint GaugeCondition_hs; }
             { NameOfCoef Ii ;
                 EntityType GroupsOfNodesOf ; NameOfConstraint Current ; }
             { NameOfCoef Ii2 ;
                 EntityType GroupsOfNodesOf ; NameOfConstraint Current ; }
        }
    }

    // Function space for magnetic field h in h-conform formulation
    //  h = sum phi_n * grad(psi_n)     (nodes in Omega_CC with boundary)
    //      + sum h_e * psi_e           (edges in Omega_C)
    //      + sum I_i * c_i             (cuts, global basis functions for net current intensity)
    { Name h_space; Type Form1;
        BasisFunction {
            { Name gradpsin; NameOfCoef phin; Function BF_GradNode;
                Support Omega_h_OmegaCC_AndBnd; Entity NodesOf[OmegaCC]; } // Extend support to boundary for surface integration
            { Name gradpsin; NameOfCoef phin2; Function BF_GroupOfEdges;
                Support Omega_h_OmegaC; Entity GroupsOfEdgesOnNodesOf[BndOmegaC]; } // To treat properly the Omega_CC-Omega_C boundary
            { Name psie; NameOfCoef he; Function BF_Edge;
                Support Omega_h_OmegaC_AndBnd; Entity EdgesOf[All, Not BndOmegaC]; }
            { Name ci; NameOfCoef Ii; Function BF_GradGroupOfNodes;
                Support ElementsOf[Omega_h_OmegaCC, OnPositiveSideOf Cuts];
                Entity GroupsOfNodesOf[Cuts]; }
            { Name ci; NameOfCoef Ii2; Function BF_GroupOfEdges;
                Support Omega_h_OmegaC_AndBnd;
                Entity GroupsOfEdgesOf[Cuts, InSupport TransitionLayerAndBndOmegaC] ; } // To treat properly the Cut-Omega_C junction
			// { Name gradpsin2; NameOfCoef phi2nd; Function BF_GradNode_2E;
                    // Support Omega_h_AndBnd; Entity EdgesOf[BndOmega_ha]; }
        }
        GlobalQuantity {
            { Name I ; Type AliasOf        ; NameOfCoef Ii ; }
            { Name V ; Type AssociatedWith ; NameOfCoef Ii ; }
        }
        Constraint {
            { NameOfCoef phin; EntityType NodesOf; NameOfConstraint phi; }
            { NameOfCoef phin2; EntityType NodesOf; NameOfConstraint phi; }
            { NameOfCoef he; EntityType EdgesOf; NameOfConstraint h; }
            { NameOfCoef Ii ;
                EntityType GroupsOfNodesOf ; NameOfConstraint Current ; }
            { NameOfCoef Ii2 ;
                EntityType GroupsOfNodesOf ; NameOfConstraint Current ; }
            { NameOfCoef V ;
                EntityType GroupsOfNodesOf ; NameOfConstraint Voltage ; }
        }
    }

    // Function space for the magnetic vector potential a in b-conform formulation
    //  1: In 2D with in-plane b
    //      a = sum a_n * psi_n       (nodes in Omega_a)
    { Name a_space_2D; Type Form1P;
        BasisFunction {
            { Name psin; NameOfCoef an; Function BF_PerpendicularEdge;
                Support Omega_a_AndBnd; Entity NodesOf[All]; }
            { Name psin2; NameOfCoef an2; Function BF_PerpendicularEdge_2E;
                Support Omega_a_AndBnd; Entity EdgesOf[BndOmega_ha]; } // Second order for stability of the coupling
        }
        Constraint {
            { NameOfCoef an; EntityType NodesOf; NameOfConstraint a; }
            { NameOfCoef an2; EntityType EdgesOf; NameOfConstraint a2; }
        }
    }
    //  2: In 3D or 2D with perpendicular b
    //      a = sum a_e * psi_e     (edges of co-tree in Omega_a)
    { Name a_space_3D; Type Form1;
        BasisFunction {
            { Name psie ; NameOfCoef ae ; Function BF_Edge ;
                Support Omega_a_AndBnd ; Entity EdgesOf[ All, Not BndOmegaC ] ; }
            { Name psie2 ; NameOfCoef ae2 ; Function BF_Edge ;
                Support Omega_a_AndBnd ; Entity EdgesOf[ BndOmegaC ] ; } // To keep all dofs of BndOmegaC where a is unique (because e is known)
        }
        Constraint {
            { NameOfCoef ae; EntityType EdgesOf; NameOfConstraint a; }
            { NameOfCoef ae2; EntityType EdgesOf; NameOfConstraint a; }
            // Gauge condition
            { NameOfCoef ae; EntityType EdgesOfTreeIn; EntitySubType StartingOn;
                NameOfConstraint GaugeCondition; }
        }
    }
    // Function space for the electric scalar potential in b-conform formulation
    //  1: In 2D with in-plane b
    //      v = sum U_i * z_i        (connected conducting regions)
    { Name grad_v_space_2D; Type Form1P;
        BasisFunction {
            { Name zi; NameOfCoef Ui; Function BF_RegionZ;
                Support Region[OmegaC]; Entity Region[OmegaC]; }
        }
        GlobalQuantity {
            { Name U; Type AliasOf; NameOfCoef Ui; }
            { Name I; Type AssociatedWith; NameOfCoef Ui; }
        }
        Constraint {
            { NameOfCoef U;
                EntityType Region; NameOfConstraint Voltage; }
            { NameOfCoef I;
                EntityType Region; NameOfConstraint Current; }
        }
    }
    //  2: In 3D or 2D with perpendicular b
    //      v = sum V_i * v_i   (connected conducting regions)
    { Name grad_v_space_3D; Type Form1;
        BasisFunction {
            { Name vi; NameOfCoef Vi; Function BF_GradGroupOfNodes;
                Support ElementsOf[OmegaC, OnPositiveSideOf Electrodes];
                Entity GroupsOfNodesOf[Electrodes]; }
        }
        GlobalQuantity {
            { Name V; Type AliasOf; NameOfCoef Vi; }
            { Name I; Type AssociatedWith; NameOfCoef Vi; }
        }
        Constraint {
            { NameOfCoef V;
                EntityType GroupsOfNodesOf; NameOfConstraint Voltage; }
            { NameOfCoef I;
                EntityType GroupsOfNodesOf; NameOfConstraint Current; }
        }
    }
}

// ----------------------------------------------------------------------------
// --------------------------- FORMULATION ------------------------------------
// ----------------------------------------------------------------------------
Formulation {
	// Initial projection of h
	{ Name Projection_h ; Type FemEquation ;
        Quantity {
            { Name h ; Type Local ; NameOfSpace h_space ; }
            { Name I ; Type Global ; NameOfSpace h_space[I]; }
            // If(alt_formulation == 1)
                // { Name e; Type Local; NameOfSpace e_space; }
            // EndIf
        }
        Equation {
            // Linear magnetic domain
            Galerkin { [ Dof{h}, {h} ] ;
                In Omega; Jacobian Vol ; Integration Int ; }
            Galerkin { [ - h_fromFile[], {h} ] ;
                In Omega ; Jacobian Vol ; Integration Int ; }
        }
    }

	// Initial projection of j
	{ Name Projection_j ; Type FemEquation ;
        Quantity {
            { Name h ; Type Local  ; NameOfSpace h_space ; }
            { Name hs ; Type Local  ; NameOfSpace hs_space ; }
            { Name phi ; Type Local ; NameOfSpace phi_space; }
            { Name I; Type Global; NameOfSpace h_space[I]; }
            { Name V; Type Global; NameOfSpace h_space[V]; }
        }
        Equation {
			Galerkin { [mu0 * Dof{hs}, {d phi} ] ;
                In Omega ; Jacobian Vol ; Integration Int ; }
            Galerkin { [- mu0 * Dof{d phi}, {d phi} ] ;
                In Omega ; Jacobian Vol ; Integration Int ; }

			Galerkin { [  Dof{h}, {h} ] ;
                In Omega ; Jacobian Vol ; Integration Int ; }
            Galerkin { [  -Dof{hs}, {h} ] ;
                In Omega ; Jacobian Vol ; Integration Int ; }
            Galerkin { [  Dof{d phi}, {h} ] ;
                In Omega ; Jacobian Vol ; Integration Int ; }

            Galerkin { [  Dof{d hs}, {d hs} ] ;
                In Omega ; Jacobian Vol ; Integration Int ; }
            // Galerkin { [ - j_fromFile[], {d hs} ] ;
                // In Omega ; Jacobian Vol ; Integration Int ; }

            GlobalTerm { [ 0 , {I} ] ; In Cuts ; }
        }
    }

	// Initial projection of field a
	{ Name Projection_a ; Type FemEquation ;
    Quantity {
	    If(Dim == 1 || Dim == 2)
			{ Name a  ; Type Local  ; NameOfSpace a_space_2D ; }
		ElseIf(Dim == 3)
			{ Name a  ; Type Local  ; NameOfSpace a_space_3D ; }
		EndIf
    }
    Equation {
      Galerkin { [  Dof{a}, {a} ] ;
        In Region[{Super}]; Integration Int; Jacobian Vol;  }
      Galerkin { [ -a_fromFile[], {a} ] ;
        In Region[{Super}] ; Integration Int; Jacobian Vol;  }
    }
	}

    // h-formulation
    { Name MagDyn_htot; Type FemEquation;
        Quantity {
            { Name h; Type Local; NameOfSpace h_space; }
            { Name hp; Type Local; NameOfSpace h_space; } // To avoid auto-symmetrization by GetDP
            { Name I; Type Global; NameOfSpace h_space[I]; }
            { Name V; Type Global; NameOfSpace h_space[V]; }
        }
        Equation {
            // DO NOT REMOVE!!!
            // Keeping track of Dofs in auxiliar line of MB if Symmetry==1
            If(Flag_MB==1)
                Galerkin {  [  0*Dof{h} , {h} ]  ;
                    In Rotor_Bnd_MBaux; Jacobian Sur; Integration Int; }
            EndIf
            // Time derivative of b (NonMagnDomain)
            Galerkin { [ mu[] * Dof{h} / $DTime , {h} ];
                In MagnLinDomain; Integration Int; Jacobian Vol;  }
            Galerkin { [ - mu[] * {h}[1] / $DTime , {h} ];
                In MagnLinDomain; Integration Int; Jacobian Vol;  }
            // Time derivative of b (MagnAnhyDomain)
            If(Flag_NR_Ferro)
                Galerkin { [ mu[{h}] * {h} / $DTime , {h} ];
                    In MagnAnhyDomain; Integration Int; Jacobian Vol;  }
                Galerkin { [ dbdh[{h}] * Dof{h} / $DTime , {h}];
                    In MagnAnhyDomain; Integration Int; Jacobian Vol;  }
                Galerkin { [ - dbdh[{h}] * {h}  / $DTime , {h}];
                    In MagnAnhyDomain; Integration Int; Jacobian Vol;  }
            Else
                Galerkin { [ mu[{h}] * Dof{h} / $DTime , {h} ];
                    In MagnAnhyDomain; Integration Int; Jacobian Vol;  }
            EndIf
            Galerkin { [ - mu[{h}[1]] * {h}[1] / $DTime , {h} ];
                In MagnAnhyDomain; Integration Int; Jacobian Vol;  }
            // Induced current (NonLinOmegaC)
            If(Flag_NR_Super)
                Galerkin { [ rho[{d h}, mu[]*Norm[{h}] ]*SQRTAN[]*SQRTAN[] * {d h} , {d h} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  }
				Galerkin { [ AddRho[] * {d h} , {d h} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  } // Anisotropic Term
                Galerkin { [ dedj[{d h},mu[]*Norm[{h}] ] * Dof{d h} , {d h} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  } // Dof appears linearly
                Galerkin { [ - dedj[{d h},mu[]*Norm[{h}]] * {d h} , {d h} ];
                    In NonLinOmegaC ; Integration Int; Jacobian Vol;  }

				Galerkin { [ AddRho[] * Dof{d h} , {d h} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  } // Anisotropic Term
                Galerkin { [ - AddRho[] * {d h} , {d h} ];
                    In NonLinOmegaC ; Integration Int; Jacobian Vol;  } // Anisotropic Term

            Else
				Galerkin { [ TensorDiag[rho[{d h}, mu[]*Norm[{h}]] ,rho[{d h}, mu[]*Norm[{h}]] ,rho[{d h}, mu[]*Norm[{h}]] ] * Dof{d h} , {d h} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  }
            EndIf
            // Induced current (LinOmegaC)
            Galerkin { [ rho[] * Dof{d h} , {d h} ];
                In LinOmegaC; Integration Int; Jacobian Vol;  }
            // Induced currents (Global variables)
            GlobalTerm { [ Dof{V} , {I} ] ; In Cuts ; }
            // Surface term for natural condition (be careful with this)
            //If(SourceType == 3)
            //    Galerkin { [ - (bs_bnd[] - bs_bnd_prev[])/$DTime * Normal[] , {dInv h} ];
            //        In Gamma_e; Integration Int; Jacobian Sur;  }
            //EndIf
        }
    }

	// h-formulation with movement
    { Name MagDyn_htot_WithMVT; Type FemEquation;
        Quantity {
            { Name h; Type Local; NameOfSpace h_space; }
            { Name hp; Type Local; NameOfSpace h_space; } // To avoid auto-symmetrization by GetDP
            { Name I; Type Global; NameOfSpace h_space[I]; }
            { Name V; Type Global; NameOfSpace h_space[V]; }
        }
        Equation {
            // DO NOT REMOVE!!!
            // Keeping track of Dofs in auxiliar line of MB if Symmetry==1
            If(Flag_MB==1)
                Galerkin {  [  0*Dof{h} , {h} ]  ;
                    In Rotor_Bnd_MBaux; Jacobian Sur; Integration Int; }
            EndIf
            // Time derivative of b (NonMagnDomain)
            Galerkin { [ mu[] * Dof{h} / $DTime , {h} ];
                In MagnLinDomain; Integration Int; Jacobian Vol;  }
			Galerkin { [ - mu[] * h_fromFile[] / $DTime , {h} ];
                In MagnLinDomain; Integration Int; Jacobian Vol;  }


            If(Flag_NR_Ferro)
                Galerkin { [ mu[{h}] * {h} / $DTime , {h} ];
                    In MagnAnhyDomain; Integration Int; Jacobian Vol;  }
                Galerkin { [ dbdh[{h}] * Dof{h} / $DTime , {h}];
                    In MagnAnhyDomain; Integration Int; Jacobian Vol;  }
                Galerkin { [ - dbdh[{h}] * {h}  / $DTime , {h}];
                    In MagnAnhyDomain; Integration Int; Jacobian Vol;  }
            Else
                Galerkin { [ mu[{h}] * Dof{h} / $DTime , {h} ];
                    In MagnAnhyDomain; Integration Int; Jacobian Vol;  }
            EndIf
			Galerkin { [ - mu[h_fromFile[]] * h_fromFile[] / $DTime , {h} ];
                In MagnAnhyDomain; Integration Int; Jacobian Vol;  }
            If(Flag_NR_Super)
                Galerkin { [ rho[{d h}, mu[]*Norm[{h}] ]*SQRTAN[]*SQRTAN[] * {d h} , {d h} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  }
				Galerkin { [ AddRho[] * {d h} , {d h} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  }
                Galerkin { [ dedj[{d h},mu[]*Norm[{h}] ] * Dof{d h} , {d h} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  } // Dof appears linearly
                Galerkin { [ - dedj[{d h},mu[]*Norm[{h}]] * {d h} , {d h} ];
                    In NonLinOmegaC ; Integration Int; Jacobian Vol;  }
            Else
				Galerkin { [ TensorDiag[rho[{d h}, mu[]*Norm[{h}]] ,rho[{d h}, mu[]*Norm[{h}]] ,rho[{d h}, mu[]*Norm[{h}]] ] * Dof{d h} , {d h} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  }
            EndIf
			Galerkin { [ - mu0 * Velocity[] /\ {h} , {d h} ];
                    In OmegaC; Integration Int; Jacobian Vol;  }

            // Induced current (LinOmegaC)
            Galerkin { [ rho[] * Dof{d h} , {d h} ];
                In LinOmegaC; Integration Int; Jacobian Vol;  }
            // Induced currents (Global variables)
            GlobalTerm { [ Dof{V} , {I} ] ; In Cuts ; }
            // Surface term for natural condition (be careful with this)
            //If(SourceType == 3)
            //    Galerkin { [ - (bs_bnd[] - bs_bnd_prev[])/$DTime * Normal[] , {dInv h} ];
            //        In Gamma_e; Integration Int; Jacobian Sur;  }
            //EndIf
        }
    }

    // a-v-formulation, total potential
    { Name MagDyn_avtot; Type FemEquation;
        Quantity {
            If(Dim == 1 || Dim == 2)
                { Name a; Type Local; NameOfSpace a_space_2D; }
                { Name ap; Type Local; NameOfSpace a_space_2D; } // To avoid auto-symmetrization by GetDP
                { Name ur; Type Local; NameOfSpace grad_v_space_2D; }
                { Name I; Type Global; NameOfSpace grad_v_space_2D [I]; }
                { Name U; Type Global; NameOfSpace grad_v_space_2D [U]; }
            ElseIf(Dim == 3)
                { Name a; Type Local; NameOfSpace a_space_3D; }
                { Name ap; Type Local; NameOfSpace a_space_3D; } // To avoid auto-symmetrization by GetDP
                { Name ur; Type Local; NameOfSpace grad_v_space_3D; }
                { Name I; Type Global; NameOfSpace grad_v_space_3D [I]; }
                { Name U; Type Global; NameOfSpace grad_v_space_3D [V]; }
            EndIf
        }
        Equation {
            // DO NOT REMOVE!!!
            // Keeping track of Dofs in auxiliar line of MB if Symmetry==1
            If(Flag_MB==1)
              Galerkin {  [  0*Dof{d a} , {d a} ]  ;
                In Rotor_Bnd_MBaux; Jacobian Sur; Integration Int; }
            EndIf
            // Curl h term - NonMagnDomain
            Galerkin { [ nu[] * Dof{d a} , {d a} ];
                In MagnLinDomain; Integration Int; Jacobian Vol; }
            // Curl h term - MagnAnhyDomain
            If(Flag_NR_Ferro)
                Galerkin { [ nu[{d a}] * {d a} , {d a} ];
                    In MagnAnhyDomain; Integration Int; Jacobian Vol; }
                Galerkin { [ dhdb[{d a}] * Dof{d a} , {d a} ];
                    In MagnAnhyDomain; Integration Int; Jacobian Vol; }
                Galerkin { [ - dhdb[{d a}] * {d a} , {d a} ];
                    In MagnAnhyDomain; Integration Int; Jacobian Vol; }
            Else
                Galerkin { [ nu[{d a}] * Dof{d a}, {d a} ];
                    In MagnAnhyDomain; Integration Int; Jacobian Vol; }
            EndIf
            // Induced currents
            // Non-linear OmegaC
            If(Flag_NR_Super) // Very difficult to converge. Use Picard iteration instead.

				// Classic formulation
                Galerkin { [ - ((Active_approach == 0 && (Flag_Test_projection == 0 || $TimeStep > 1)))*(sigmae[ (- {a} + {a}[1]) / $DTime - {ur}]), {a} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  }
                Galerkin { [ - ((Active_approach == 0 && (Flag_Test_projection == 0 || $TimeStep > 1)))*(sigmae[ (- {a} + {a}[1]) / $DTime - {ur}]), {ur} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  }

                Galerkin { [ ((Active_approach == 0 && (Flag_Test_projection == 0 || $TimeStep > 1)))*(djde[ (- {a} + {a}[1]) / $DTime - {ur} ] * Dof{a}/$DTime) , {a} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  } // Dof appears linearly
                Galerkin { [ - ((Active_approach == 0 && (Flag_Test_projection == 0 || $TimeStep > 1)))*(djde[ (- {a} + {a}[1]) / $DTime - {ur} ] * {a}/$DTime) , {a} ];
                    In NonLinOmegaC ; Integration Int; Jacobian Vol;  }
                Galerkin { [ ((Active_approach == 0 && (Flag_Test_projection == 0 || $TimeStep > 1)))*(djde[ (- {a} + {a}[1]) / $DTime - {ur} ] * Dof{ur}) , {a} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  } // Dof appears linearly
                Galerkin { [ - ((Active_approach == 0 && (Flag_Test_projection == 0 || $TimeStep > 1)))*(djde[ (- {a} + {a}[1]) / $DTime - {ur} ] * {ur}) , {a} ];
                    In NonLinOmegaC ; Integration Int; Jacobian Vol;  }

                Galerkin { [ ((Active_approach == 0 && (Flag_Test_projection == 0 || $TimeStep > 1)))*(djde[ (- {a} + {a}[1]) / $DTime - {ur} ] * Dof{a}/$DTime) , {ur} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  } // Dof appears linearly
                Galerkin { [ - ((Active_approach == 0 && (Flag_Test_projection == 0 || $TimeStep > 1)))*(djde[ (- {a} + {a}[1]) / $DTime - {ur} ] * {a}/$DTime) , {ur} ];
                    In NonLinOmegaC ; Integration Int; Jacobian Vol;  }
                Galerkin { [ ((Active_approach == 0 && (Flag_Test_projection == 0 || $TimeStep > 1)))*(djde[ (- {a} + {a}[1]) / $DTime - {ur} ] * Dof{ur}) , {ur} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  } // Dof appears linearly
                Galerkin { [ - ((Active_approach == 0 && (Flag_Test_projection == 0 || $TimeStep > 1)))*(djde[ (- {a} + {a}[1]) / $DTime - {ur} ] * {ur}) , {ur} ];
                    In NonLinOmegaC ; Integration Int; Jacobian Vol;  }

				// a_fromFile[] instead of a[1]
                Galerkin { [ - (($TimeStep == 1 && (Flag_Test_projection == 1)) || ((Active_approach == 1)||(Active_approach == 2)))*(sigmae[ (- {a} + a_fromFile[]) / $DTime - {ur}]), {a} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  }
                Galerkin { [ - (($TimeStep == 1 && (Flag_Test_projection == 1)) || ((Active_approach == 1)||(Active_approach == 2)))*(sigmae[ (- {a} + a_fromFile[]) / $DTime - {ur}]), {ur} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  }

				Galerkin { [ (($TimeStep == 1 && (Flag_Test_projection == 1)) || ((Active_approach == 1)||(Active_approach == 2)))*(djde[ (- {a} + a_fromFile[]) / $DTime - {ur} ] * Dof{a}/$DTime) , {a} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  } // Dof appears linearly
                Galerkin { [ - (($TimeStep == 1 && (Flag_Test_projection == 1)) || ((Active_approach == 1)||(Active_approach == 2)))*(djde[ (- {a} + a_fromFile[]) / $DTime - {ur} ] * {a}/$DTime) , {a} ];
                    In NonLinOmegaC ; Integration Int; Jacobian Vol;  }
                Galerkin { [ (($TimeStep == 1 && (Flag_Test_projection == 1)) || ((Active_approach == 1)||(Active_approach == 2)))*(djde[ (- {a} + a_fromFile[]) / $DTime - {ur} ] * Dof{ur}) , {a} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  } // Dof appears linearly
                Galerkin { [ - (($TimeStep == 1 && (Flag_Test_projection == 1)) || ((Active_approach == 1)||(Active_approach == 2)))*(djde[ (- {a} + a_fromFile[]) / $DTime - {ur} ] * {ur}) , {a} ];
                    In NonLinOmegaC ; Integration Int; Jacobian Vol;  }

                Galerkin { [ (($TimeStep == 1 && (Flag_Test_projection == 1)) || ((Active_approach == 1)||(Active_approach == 2)))*(djde[ (- {a} + a_fromFile[]) / $DTime - {ur} ] * Dof{a}/$DTime) , {ur} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  } // Dof appears linearly
                Galerkin { [ - (($TimeStep == 1 && (Flag_Test_projection == 1)) || ((Active_approach == 1)||(Active_approach == 2)))*(djde[ (- {a} + a_fromFile[]) / $DTime - {ur} ] * {a}/$DTime) , {ur} ];
                    In NonLinOmegaC ; Integration Int; Jacobian Vol;  }
                Galerkin { [ (($TimeStep == 1 && (Flag_Test_projection == 1)) || ((Active_approach == 1)||(Active_approach == 2)))*(djde[ (- {a} + a_fromFile[]) / $DTime - {ur} ] * Dof{ur}) , {ur} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  } // Dof appears linearly
                Galerkin { [ - (($TimeStep == 1 && (Flag_Test_projection == 1)) || ((Active_approach == 1)||(Active_approach == 2)))*(djde[ (- {a} + a_fromFile[]) / $DTime - {ur} ] * {ur}) , {ur} ];
                    In NonLinOmegaC ; Integration Int; Jacobian Vol;  }
			Else
				// Classic Formulation
				Galerkin { [ ((Active_approach == 0 && (Flag_Test_projection == 0 || $TimeStep > 1)))*(sigma[ (- {a} + {a}[1]) / $DTime - {ur}]*Anys_Matrix[] * Dof{a} / $DTime) , {a} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  }
                Galerkin { [ - ((Active_approach == 0 && (Flag_Test_projection == 0 || $TimeStep > 1)))*(sigma[ (- {a} + {a}[1]) / $DTime - {ur}]*Anys_Matrix[] * {a}[1] / $DTime) ,  {a} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  }

                Galerkin { [ ((Active_approach == 0 && (Flag_Test_projection == 0 || $TimeStep > 1)))*(sigma[ (- {a} + {a}[1]) / $DTime - {ur}]*Anys_Matrix[] * Dof{ur}) , {a} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  }

                Galerkin { [ ((Active_approach == 0 && (Flag_Test_projection == 0 || $TimeStep > 1)))*(sigma[ (- {a} + {a}[1]) / $DTime - {ur}]*Anys_Matrix[] * Dof{a} / $DTime) , {ur} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  }
                Galerkin { [ - ((Active_approach == 0 && (Flag_Test_projection == 0 || $TimeStep > 1)))*(sigma[ (- {a} + {a}[1]) / $DTime - {ur}]*Anys_Matrix[] * {a}[1] / $DTime) ,  {ur} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  }

                Galerkin { [ ((Active_approach == 0 && (Flag_Test_projection == 0 || $TimeStep > 1)))*(sigma[ (- {a} + {a}[1]) / $DTime - {ur}]*Anys_Matrix[] * Dof{ur}) , {ur} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  }

				// a_fromFile[] instead of a[1]
				Galerkin { [ (($TimeStep == 1 && (Flag_Test_projection == 1)) || ((Active_approach == 1)||(Active_approach == 2)))*(sigma[ (- {a} + a_fromFile[]) / $DTime - {ur}]*Anys_Matrix[] * Dof{a} / $DTime) , {a} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  }
                Galerkin { [ - (($TimeStep == 1 && (Flag_Test_projection == 1)) || ((Active_approach == 1)||(Active_approach == 2)))*(sigma[ (- {a} + a_fromFile[]) / $DTime - {ur}]*Anys_Matrix[] * {a}[1] / $DTime) ,  {a} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  }

                Galerkin { [ (($TimeStep == 1 && (Flag_Test_projection == 1)) || ((Active_approach == 1)||(Active_approach == 2)))*(sigma[ (- {a} + a_fromFile[]) / $DTime - {ur}]*Anys_Matrix[] * Dof{ur}) , {a} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  }

                Galerkin { [ (($TimeStep == 1 && (Flag_Test_projection == 1)) || ((Active_approach == 1)||(Active_approach == 2)))*(sigma[ (- {a} + a_fromFile[]) / $DTime - {ur}]*Anys_Matrix[] * Dof{a} / $DTime) , {ur} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  }
                Galerkin { [ - (($TimeStep == 1 && (Flag_Test_projection == 1)) || ((Active_approach == 1)||(Active_approach == 2)))*(sigma[ (- {a} + a_fromFile[]) / $DTime - {ur}]*Anys_Matrix[] * {a}[1] / $DTime) ,  {ur} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  }

                Galerkin { [ (($TimeStep == 1 && (Flag_Test_projection == 1)) || ((Active_approach == 1)||(Active_approach == 2)))*(sigma[ (- {a} + a_fromFile[]) / $DTime - {ur}]*Anys_Matrix[] * Dof{ur}) , {ur} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  }
            EndIf
            // Linear OmegaC
            Galerkin { [ sigma[] * Dof{a} / $DTime , {a} ];
                In LinOmegaC; Integration Int; Jacobian Vol;  }
            Galerkin { [ - sigma[] * {a}[1] / $DTime ,  {a} ];
                In LinOmegaC; Integration Int; Jacobian Vol;  }
            Galerkin { [ sigma[] * Dof{ur} , {a} ];
                In LinOmegaC; Integration Int; Jacobian Vol;  }
            Galerkin { [ sigma[] * Dof{a} / $DTime , {ur} ];
                In LinOmegaC; Integration Int; Jacobian Vol;  }
            Galerkin { [ - sigma[] * {a}[1] / $DTime ,  {ur} ];
                In LinOmegaC; Integration Int; Jacobian Vol;  }
            Galerkin { [ sigma[] * Dof{ur} , {ur} ];
                In LinOmegaC; Integration Int; Jacobian Vol;  }
            // Stranded conductor region (belongs to OmegaCC)
            Galerkin { [ -js[] , {a} ];
                In OmegaC_stranded; Integration Int; Jacobian Vol;  }
            // Global term
            If(Dim == 1 || Dim == 2)
                GlobalTerm { [ Dof{I}  , {U} ]; In OmegaC; }
            ElseIf(Dim == 3)
                Galerkin { [ - hsVal[] * (directionApplied[] /\ Normal[]), {a} ];
                    In Gamma_h ; Integration Int ; Jacobian Sur; }
                GlobalTerm { [ Dof{I}  , {U} ]; In Electrodes; }
            EndIf
            // For special "one-dimension-like cases"
            // Galerkin { [ - hsVal[] * (directionApplied[] /\ Normal[]), {a} ];
            //    In SurfOut ; Integration Int ; Jacobian Sur; }
        }
    }

    // Coupled formulation
    { Name MagDyn_coupled; Type FemEquation;
        Quantity {
            { Name h; Type Local; NameOfSpace h_space; }
            { Name I; Type Global; NameOfSpace h_space[I]; }
            { Name V; Type Global; NameOfSpace h_space[V]; }
            If(Dim == 3)
                { Name a; Type Local; NameOfSpace a_space_3D; }
                { Name ap; Type Local; NameOfSpace a_space_3D; } // To avoid auto-symmetrization by GetDP
            Else
                { Name a; Type Local; NameOfSpace a_space_2D; }
                { Name ap; Type Local; NameOfSpace a_space_2D; } // To avoid auto-symmetrization by GetDP
            EndIf
        }
        Equation {
            // DO NOT REMOVE!!!
            // Keeping track of Dofs in auxiliar line of MB if Symmetry==1
            If(Flag_MB==1)
              Galerkin {  [  0*Dof{d a} , {d a} ]  ;
                In Rotor_Bnd_MBaux; Jacobian Sur; Integration Int; }
            EndIf
            // ---- SUPER ----
            // Time derivative - current solution
            Galerkin { [ mu[] * Dof{h} / $DTime , {h} ];
                In MagnLinDomain; Integration Int; Jacobian Vol;  }
            // Time derivative - previous solution
             Galerkin { [ - (($TimeStep == 1 && (FlagFCNoCurrent==1 || Flag_Test_projection == 1)) || ((Active_approach == 1)||(Active_approach == 2))) * mu[] * h_fromFile[]##2 / $DTime , {h} ];
                In MagnLinDomain; Integration Int; Jacobian Vol;  }
            Galerkin { [ - ((Active_approach == 0 && (Flag_Test_projection == 0 && FlagFCNoCurrent == 0) || $TimeStep > 1)) * mu[] * {h}[1] / $DTime , {h} ];
                In MagnLinDomain; Integration Int; Jacobian Vol;  }
            // Induced currents
            // Non-linear OmegaC
            Galerkin { [ rho[{d h}, mu[]*Norm[{h}] ] * {d h} , {d h} ];
                In NonLinOmegaC; Integration Int; Jacobian Vol;  }
			Galerkin { [ AddRho[] * {d h} , {d h} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  }// Anisotropic term

            Galerkin { [ dedj[{d h}, mu[]*Norm[{h}] ] * Dof{d h} , {d h} ];
                In NonLinOmegaC; Integration Int; Jacobian Vol;  }
            Galerkin { [ - dedj[{d h}, mu[]*Norm[{h}] ] * {d h} , {d h} ];
                In NonLinOmegaC ; Integration Int; Jacobian Vol;  }
			Galerkin { [ AddRho[] * Dof{d h} , {d h} ];
                    In NonLinOmegaC; Integration Int; Jacobian Vol;  } // Anisotropic term
            Galerkin { [ - AddRho[] * {d h} , {d h} ];
                    In NonLinOmegaC ; Integration Int; Jacobian Vol;  } // Anisotropic term
            // Linear OmegaC
            Galerkin { [ rho[] * Dof{d h} , {d h} ];
                In LinOmegaC; Integration Int; Jacobian Vol;  }
            // Stranded conductor region (belongs to OmegaCC)
            Galerkin { [ -js[] , {a} ];
                In OmegaC_stranded; Integration Int; Jacobian Vol;  }
            // ---- FERRO ----
            // Curl h term - NonMagnDomain
            Galerkin { [ nu[] * Dof{d a} , {d a} ];
                In MagnLinDomain; Integration Int; Jacobian Vol; }
            // Curl h term - MagnAnhyDomain
            Galerkin { [ nu[{d a}] * {d a} , {d a} ];
                In MagnAnhyDomain; Integration Int; Jacobian Vol; }
            Galerkin { [ dhdb[{d a}] * Dof{d a} , {d a} ];
                In MagnAnhyDomain; Integration Int; Jacobian Vol; }
            Galerkin { [ - dhdb[{d a}] * {d a} , {d a} ];
                In MagnAnhyDomain; Integration Int; Jacobian Vol; }
            // ---- SURFACE TERMS ----
            Galerkin { [ + Dof{a} /\ Normal[] /$DTime , {h}];
                In BndOmega_ha; Integration Int; Jacobian Sur; }
            Galerkin { [ - (($TimeStep == 1 && (FlagFCNoCurrent==1 || Flag_Test_projection == 1)) || ((Active_approach == 1)||(Active_approach == 2))) *a_fromFile[]##1 /\ Normal[] /$DTime , {h}];
                In BndOmega_ha; Integration Int; Jacobian Sur; }
            Galerkin { [ - ((Active_approach == 0 && (Flag_Test_projection == 0 && FlagFCNoCurrent == 0) || $TimeStep > 1)) *{a}[1] /\ Normal[] /$DTime , {h}];
                In BndOmega_ha; Integration Int; Jacobian Sur; }
            Galerkin { [ Dof{h} /\ Normal[] , {a}];
                In BndOmega_ha; Integration Int; Jacobian Sur; } // Sign for normal (should be -1 but normal is opposite)
            If(Dim == 3)
                Integral { [ - hsVal[] * (directionApplied[] /\ Normal[]), {a} ];
                    In SurfOut ; Integration Int ; Jacobian Sur; }
                // Do not integrate on the part of bnd that is in Omega_h (and not in Omega_a)
                // Or, define the completely rigorous function space (that would be more general)
            EndIf
            // ---- TERM FOR GLOBAL CONSTRAINT ----
            GlobalTerm { [ Dof{V} , {I} ] ; In Cuts ; }
        }
    }
}

// ----------------------------------------------------------------------------
// --------------------------- POST-PROCESSING --------------------------------
// ----------------------------------------------------------------------------
PostProcessing {
	{ Name Visualise_Projection; NameOfFormulation Projection_a;
        Quantity {
            { Name a_fromFile; Value{ Local{ [ {a} ] ;
                In OmegaCC; Jacobian Vol; } } }
        }
    }


    // h-formulation, total field
    { Name MagDyn_htot; NameOfFormulation MagDyn_htot;
        Quantity {
            { Name phi; Value{ Local{ [ {dInv h} ] ;
                In OmegaCC; Jacobian Vol; } } }
            { Name h; Value{ Local{ [ {h} ] ;
                In Omega; Jacobian Vol; } } }
            { Name b; Value {
                Term { [ mu[] * {h} ] ; In MagnLinDomain; Jacobian Vol; }
                Term { [ mu[{h}] * {h} ] ; In MagnAnhyDomain; Jacobian Vol; }
                }
            }
            { Name mur; Value{ Local{ [ mu[{h}]/mu0 ] ;
                In MagnAnhyDomain; Jacobian Vol; } } }
            { Name j; Value{ Local{ [ {d h} ] ;
                In OmegaC; Jacobian Vol; } } }
            { Name e; Value{ Local{ [ rho[{d h}, mu0*Norm[{h}]] * {d h} ] ;
                In OmegaC; Jacobian Vol; } } }
            { Name jz; Value{ Local{ [ CompZ[{d h}] ] ;
                In OmegaC; Jacobian Vol; } } }
            { Name jx; Value{ Local{ [ CompX[{d h}] ] ;
                In OmegaC; Jacobian Vol; } } }
            { Name jy; Value{ Local{ [ CompY[{d h}] ] ;
                In OmegaC; Jacobian Vol; } } }
            { Name norm_j; Value{ Local{ [ Norm[{d h}] ] ;
                In OmegaC; Jacobian Vol; } } }
            If(Axisymmetry == 1)
                { Name m_avg; Value{ Integral{ [ 2*Pi * 0.5 * XYZ[] /\ {d h} / (Pi*SurfaceArea[]*W_cylinder1/2) ] ;
                    In OmegaC; Integration Int; Jacobian Vol; } } } // Jacobian is in "Vol"
                { Name m_avg_y_tesla; Value{ Integral{ [ mu0*2*Pi * 0.5 * Vector[0,1,0] * (XYZ[] /\ {d h}) / (Pi*SurfaceArea[]*W_cylinder1/2) ] ;
                    In OmegaC; Integration Int; Jacobian Vol; } } }
            ElseIf(Dim == 1)
                // TBC...
            ElseIf(Dim == 2)
                // Not axisym, so surface integral to give (total) magnetization per unit length.
                // Here, the average is computed. ATTENTION: Factor 2 is not introduced
                { Name m_avg; Value{ Integral{ [ 0.5 * XYZ[] /\ {d h} / (SurfaceArea[]) ] ;
                    In OmegaC; Integration Int; Jacobian Vol; } } }
                { Name m_avg_y_tesla; Value{ Integral{ [ mu0 * 0.5 * Vector[0,1,0] * (XYZ[] /\ {d h}) / (SurfaceArea[]) ] ;
                    In OmegaC; Integration Int; Jacobian Vol; } } }
                { Name m_avg_x_tesla; Value{ Integral{ [ mu0 * 0.5 * Vector[1,0,0] * (XYZ[] /\ {d h}) / (SurfaceArea[]) ] ;
                    In OmegaC; Integration Int; Jacobian Vol; } } }
            ElseIf(Dim == 3)
                { Name m_avg; Value{ Integral{ [ 0.5 * XYZ[] /\ {d h} / GetVolume[] ] ;
                    In OmegaC; Integration Int; Jacobian Vol; } } }
            EndIf
            { Name hsVal; Value{ Term { [ hsVal[] ]; In Omega; } } }
            { Name bsVal; Value{ Term { [ mu0*hsVal[] ]; In Omega; } } }
            { Name time; Value{ Term { [ $Time ]; In Omega; } } }
            { Name time_ms; Value{ Term { [ 1000*$Time ]; In Omega; } } }
            If(Flag_MB == 1)
                { Name rotor_angle; Value{ Term { [ 180/Pi*omega*$Time ]; In Omega; } } }
            EndIf
            { Name power;
                Value{
                    Integral{ [ (mu[{h}]*{h} - mu[{h}[1]]*{h}[1]) / $DTime * {h} ] ;
                        In MagnAnhyDomain ; Integration Int ; Jacobian Vol; }
                    Integral{ [ mu[] * ({h} - {h}[1]) / $DTime * {h} ] ;
                        In MagnLinDomain ; Integration Int ; Jacobian Vol; }
                    Integral{ [rho[{d h}, mu0*Norm[{h}] ]*{d h}*{d h}] ;
                        In OmegaC ; Integration Int ; Jacobian Vol; }
                }
            }
            { Name V; Value { Term{ [ {V} ] ; In Cuts; } } }
            { Name I; Value { Term{ [ {I} ] ; In Cuts; } } }
            { Name dissPowerGlobal;
                Value { Term{ [ {V}*{I} ] ; In Cuts; } } }
            { Name dissPower;
                Value{
                    Integral{ [rho[{d h}, mu0*Norm[{h}] ]*{d h}*{d h}] ;
                        In OmegaC ; Integration Int ; Jacobian Vol; }
                }
            }
        }
    }
    // a-v-formulation, total potential
    { Name MagDyn_avtot; NameOfFormulation MagDyn_avtot;
        Quantity {
            { Name a; Value{ Local{ [ {a} ] ;
                In Omega; Jacobian Vol; } } }
            { Name az; Value{ Local{ [ CompZ[{a}] ] ;
                In Omega; Jacobian Vol; } } }
            { Name b; Value{ Local{ [ {d a} ] ;
                In Omega; Jacobian Vol; } } }
            { Name mur; Value{ Local{ [ 1.0/(nu[{d a}] * mu0) ] ;
                In MagnAnhyDomain; Jacobian Vol; } } }
            { Name h; Value {
                Term { [ nu[] * {d a} ] ; In MagnLinDomain; Jacobian Vol; }
                Term { [ nu[{d a}] * {d a} ] ; In MagnAnhyDomain; Jacobian Vol; }
                }
            }
            { Name e; Value{ Local{ [ - Dt[{a}] - {ur} ] ;
                In OmegaC; Jacobian Vol; } } }
            { Name ur; Value{ Local{ [ {ur} ] ;
                In OmegaC; Jacobian Vol; } } }
            { Name j; Value{ Local{ [ sigmae[ - Dt[{a}] - {ur} ] ] ;
                In OmegaC; Jacobian Vol; } } }
            { Name js; Value{ Local{ [ js[] ] ;
                In OmegaC_stranded; Jacobian Vol; } } }
            { Name jnorm; Value{ Local{ [ Norm[sigmae[ - Dt[{a}] - {ur} ]] ] ;
                In OmegaC; Jacobian Vol; } } }
            { Name jz; Value{ Local{ [ CompZ[sigmae[ - Dt[{a}] - {ur} ]] ] ;
                In OmegaC; Jacobian Vol; } } }
			{ Name jx; Value{ Local{ [ CompX[sigmae[ - Dt[{a}] - {ur} ]] ] ;
                In OmegaC; Jacobian Vol; } } }
			{ Name jy; Value{ Local{ [ CompY[sigmae[ - Dt[{a}] - {ur} ]] ] ;
                In OmegaC; Jacobian Vol; } } }
            { Name I; Value{ Term{ [ {I} ] ;
                In OmegaC; } } }
            { Name U; Value{ Term{ [ {U} ] ;
                In OmegaC; } } }
            If(Axisymmetry == 1)
                { Name m_avg; Value{ Integral{ [ 2*Pi * 0.5 * XYZ[]
                    /\ sigmae[ (- {a} + {a}[1]) / $DTime - {ur} ] / (Pi * SurfaceArea[] * W_cylinder1/2) ] ;
                    In OmegaC; Integration Int; Jacobian Vol; } } }
                { Name m_avg_y_tesla; Value{ Integral{ [ mu0*2*Pi * 0.5 * Vector[0,1,0] * (XYZ[]
                    /\ sigmae[ (- {a} + {a}[1]) / $DTime - {ur} ]) / (Pi * SurfaceArea[] * W_cylinder1/2) ] ;
                    In OmegaC; Integration Int; Jacobian Vol; } } }
            Else
                // Not axisym, so surface integral to give (total) magnetization per unit length.
                // Here, the average is computed. ATTENTION: Factor 2 (for end junctions) is not introduced
                // { Name m_avg; Value{ Integral{ [ 0.5 * XYZ[]
                    // /\ sigmae[ (- {a} + {a}[1]) / $DTime - {ur} ] / (SurfaceArea[]) ] ;
                    // In OmegaC; Integration Int; Jacobian Vol; } } }
                // { Name m_avg_y_tesla; Value{ Integral{ [ mu0*0.5 * Vector[0,1,0] * (XYZ[]
                    // /\ sigmae[ (- {a} + {a}[1]) / $DTime - {ur} ]) / (SurfaceArea[]) ] ;
                    // In OmegaC; Integration Int; Jacobian Vol; } } }
                // { Name m_avg_x_tesla; Value{ Integral{ [ mu0*0.5 * Vector[1,0,0] * (XYZ[]
                    // /\ sigmae[ (- {a} + {a}[1]) / $DTime - {ur} ]) / (SurfaceArea[]) ] ;
                    // In OmegaC; Integration Int; Jacobian Vol; } } }
            EndIf
            { Name hsVal; Value{ Term { [ hsVal[] ]; In Omega; } } }
            { Name bsVal; Value{ Term { [ mu0*hsVal[] ]; In Omega; } } }
            { Name time; Value{ Term { [ $Time ]; In Omega; } } }
            { Name time_ms; Value{ Term { [ 1000*$Time ]; In Omega; } } }
            If(Flag_MB == 1)
                { Name rotor_angle; Value{ Term { [ 180/Pi*omega*$Time ]; In Omega; } } }
            EndIf
            { Name power;
                Value{
                    Integral{ [ ({d a} - {d a}[1]) / $DTime * nu[{d a}] * {d a} ] ;
                        In MagnAnhyDomain ; Integration Int ; Jacobian Vol; }
                    Integral{ [ ({d a} - {d a}[1]) / $DTime * nu[] * {d a} ] ;
                        In MagnLinDomain ; Integration Int ; Jacobian Vol; }
                    Integral{ [sigma[ (- {a} + {a}[1]) / $DTime - {ur}]
                        * ((- {a} + {a}[1]) / $DTime - {ur} ) * ((- {a} + {a}[1]) / $DTime - {ur} )] ;
                        In OmegaC ; Integration Int ; Jacobian Vol; }
                }
            }
            { Name dissPowerGlobal;
                Value{
                    Term{ [ {U}*{I} ] ; In OmegaC;}
                }
            }
            { Name dissPower;
                Value{
                    Integral{ [sigma[ (- {a} + {a}[1]) / $DTime - {ur}]
                        * ((- {a} + {a}[1]) / $DTime - {ur} ) * ((- {a} + {a}[1]) / $DTime - {ur} )] ;
                        In OmegaC ; Integration Int ; Jacobian Vol; }
                }
            }
            If(Flag_MB==1)
                { Name torqueMaxwell ;
                  // Torque computation via Maxwell stress tensor
                  Value {
                    Integral {
                      // \int_S (\vec{r} \times (T_max \vec{n}) ) / ep
                      // with ep = |S| / (2\pi r_avg) (directly accounts for the total torque for the total circumference)
                      [ CompZ [ XYZ[] /\ (T_max[{d a}] * XYZ[]) ] * 2*Pi*thickness/SurfaceArea[] ] ;
                      In Omega ; Jacobian Vol  ; Integration Int; }
                  }
                }
            EndIf
        }
    }
    // Coupled formulation
    { Name MagDyn_coupled; NameOfFormulation MagDyn_coupled;
        Quantity {
            { Name phi; Value{ Local{ [ {dInv h} ] ;
                In Omega_h_OmegaCC_AndBnd; Jacobian Vol; } } }
            { Name h; Value {
                Term { [ {h} ]; In OmegaC; Jacobian Vol; }
                Term { [ nu[{d a}] * {d a} ] ; In MagnAnhyDomain; Jacobian Vol; }
                Term { [ nu[] * {d a} ] ; In MagnLinDomain; Jacobian Vol; }
                }
            }
            { Name b; Value{
                Term { [ mu[{h}]*{h} ]; In OmegaC; Jacobian Vol; }
                Term { [ {d a} ] ; In OmegaCC; Jacobian Vol;} } }
            { Name a; Value{ Local{ [ {a} ] ;
                In OmegaCC; Jacobian Vol; } } }
            { Name mur; Value{ Local{ [ 1.0/(nu[{d a}] * mu0) ] ;
                In OmegaCC; Jacobian Vol; } } }
            { Name j; Value{ Local{ [ {d h} ] ;
                In OmegaC; Jacobian Vol; } } }
            { Name jx; Value{ Local{ [ CompX[{d h}] ] ;
                In OmegaC; Jacobian Vol; } } }
            { Name jy; Value{ Local{ [ CompY[{d h}] ] ;
                In OmegaC; Jacobian Vol; } } }
			{ Name jz; Value{ Local{ [ CompZ[{d h}] ] ;
                In OmegaC; Jacobian Vol; } } }
            { Name js; Value{ Local{ [ js[] ] ;
                In OmegaC_stranded; Jacobian Vol; } } }
            { Name e; Value{ Local{ [ rho[{d h}, mu[{h}]*Norm[{h}] ]*{d h} ] ;
                In OmegaC; Jacobian Vol; } } }
            { Name norm_j; Value{ Local{ [ Norm[{d h}] ] ;
                In OmegaC; Jacobian Vol; } } }
            If(Axisymmetry == 1)
                { Name m_avg; Value{ Integral{ [ 2*Pi * 0.5 * XYZ[] /\ {d h} / (Pi*SurfaceArea[]*W_cylinder1/2) ] ;
                    In OmegaC; Integration Int; Jacobian Vol; } } } // Jacobian is in "Vol"
                { Name m_avg_y_tesla; Value{ Integral{ [ mu0*2*Pi * 0.5 * Vector[0,1,0] * (XYZ[] /\ {d h}) / (Pi*SurfaceArea[]*W_cylinder1/2) ] ;
                    In OmegaC; Integration Int; Jacobian Vol; } } }
            Else
                // { Name m_avg; Value{ Integral{ [ 0.5 * XYZ[] /\ {d h} / (SurfaceArea[]) ] ;
                    // In OmegaC; Integration Int; Jacobian Vol; } } }
                // { Name m_avg_y_tesla; Value{ Integral{ [ mu0 * 0.5 * Vector[0,1,0] * (XYZ[] /\ {d h}) / (SurfaceArea[]) ] ;
                    // In OmegaC; Integration Int; Jacobian Vol; } } }
                // { Name m_avg_x_tesla; Value{ Integral{ [ mu0 * 0.5 * Vector[1,0,0] * (XYZ[] /\ {d h}) / (SurfaceArea[]) ] ;
                    // In OmegaC; Integration Int; Jacobian Vol; } } }
            EndIf
            // { Name b_avg; Value{ Integral{ [ 2*Pi*mu[{h}] * {h} / (SurfaceArea[]) ] ;
                // In OmegaC; Integration Int; Jacobian Vol; } } }
            { Name hsVal; Value{ Term { [ hsVal[] ]; In Omega; } } }
            { Name bsVal; Value{ Term { [ mu0*hsVal[] ]; In Omega; } } }
            { Name time; Value{ Term { [ $Time ]; In Omega; } } }
            { Name time_ms; Value{ Term { [ 1000*$Time ]; In Omega; } } }
            If(Flag_MB == 1)
                { Name js_value; Value{ Term { [ pulse[] ]; In Omega; } } }
                { Name rotor_angle; Value{ Term { [ 180/Pi*omega*$Time ]; In Omega; } } }
            EndIf
            { Name power;
                Value{
                    Integral{ [ ({d a} - {d a}[1]) / $DTime * nu[{d a}] * {d a} ] ;
                        In MagnAnhyDomain ; Integration Int ; Jacobian Vol; }
                    Integral{ [ ({d a} - {d a}[1]) / $DTime * nu[] * {d a} ] ;
                        In MagnLinDomain ; Integration Int ; Jacobian Vol; }
                    Integral{ [ (mu[{h}]*{h} - mu[{h}]*{h}[1]) / $DTime * {h} ] ;
                        In OmegaC ; Integration Int ; Jacobian Vol; }
                    Integral{ [rho[{d h}, mu[{h}]*Norm[{h}] ]*{d h}*{d h}] ;
                        In OmegaC ; Integration Int ; Jacobian Vol; }
                }
            }
            { Name dissPower;
                Value{
                    Integral{ [rho[{d h}, mu[{h}]*Norm[{h}] ]*{d h}*{d h}] ;
                        In OmegaC ; Integration Int ; Jacobian Vol; }
                }
            }
            { Name V;
                Value{
                    Term{ [ {V} ] ; In Cuts;}
                }
            }
            { Name I;
                Value{
                    Term{ [ {I} ] ; In Cuts;}
                }
            }
            { Name dissPowerGlobal;
                Value{
                    Term{ [ {V}*{I} ] ; In Cuts;}
                }
            }
            If(Flag_MB==1)
                { Name torqueMaxwell ;
                  // Torque computation via Maxwell stress tensor (should be in a domain)
                  Value {
                    Integral {
                      // \int_S (\vec{r} \times (T_max \vec{n}) ) / ep
                      // with ep = |S| / (2\pi r_avg) (directly accounts for the total torque for the total circumference)
                      [ CompZ [ XYZ[] /\ (T_max[{d a}] * XYZ[]) ] * 2*Pi*thickness/SurfaceArea[] ] ;
                      In Omega ; Jacobian Vol  ; Integration Int; }
                  }
                }
            EndIf
        }
    }
}
