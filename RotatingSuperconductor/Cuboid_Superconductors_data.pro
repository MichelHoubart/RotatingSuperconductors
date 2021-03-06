// Include cross data
Include "Sample_Characteristics.pro";

// ---- Domain Dimensions ----
R_air = 0.08; // Inner shell radius [m]
R_inf = 0.1; // Outer shell radius [m]

// ---- Mesh parameters ----
DefineConstant [meshMult = 3]; // Multiplier [-] of a default mesh size distribution
DefineConstant [NbElemCube = 12]; // Mesh size in superconductors [m]
DefineConstant [LcAir = meshMult*0.001]; // Mesh size away from superconductors [m]

// ---- Formulation definitions (dummy values) ----
h_formulation = 2;
a_formulation = 6;
coupled_formulation = 5;

// ---- Parameters of the configuration ----
DefineConstant[
  Modelled_Samples = {1, Choices{
        1="1 : Qualitative bulk",
        2="2 : Real Bulks",
        3="3 : Stacked Tapes"}
		, Name "Parameters of the array/1Type of sample to consider"}
];
DefineConstant[
  Num_Super = {1, Choices{
        1="1 : Single superconductor in field",
        2="2 : Pair of superconductors in field"
      }
		, Name "Parameters of the configuration/2Number of superconductors"}
];

If(Modelled_Samples == 1)
		// Qualitative bulks
		Config_Base_1 = 666;
		Config_Base_2 = 666;
ElseIf(Modelled_Samples == 2)
		// Real Bulks
		Config_Base_1 = 1219;
		Config_Base_2 = 1218;
ElseIf(Modelled_Samples == 3)
		// Model Stacked tapes
		Config_Base_1 = 123456789;
		Config_Base_2 = 123456789;
EndIf
	For i In {1:Num_Super}
		DefineConstant[ Sample~{i} = {Config_Base~{i}, Choices{
        1216,
        1218,
        1219,
		1220,
		1222,
		1215,
		1217,
		1221,
		1223,
		123456789,
		666},
	Name Sprintf("Parameters of the configuration/5Sample%g Number", i), Visible 1}];
	EndFor

// ---- Rotation of the bulk ----
// Position of the centre of each BULK
If(Num_Super==1)
  CentreXSuperconductor_1 = 0.00;
  CentreYSuperconductor_1 = 0.00;
  CentreZSuperconductor_1 = 0.00;
  // x Bottom
  x_Bottom_Super_1 = CentreXSuperconductor_1-ax~{Sample_1}/2;
  // y Bottom
  y_Bottom_Super_1 = CentreYSuperconductor_1-ay~{Sample_1}/2;
  // z x_Bottom
  z_Bottom_Super_1 = CentreZSuperconductor_1-az~{Sample_1}/2;
ElseIf(Num_Super==2)
  CentreXSuperconductor_1 = 0;
  CentreYSuperconductor_1 = 0;
  CentreZSuperconductor_1 = 0;

  CentreXSuperconductor_2 = 0;
  CentreYSuperconductor_2 = 0;
  CentreZSuperconductor_2 = 0;

  For i In {1:Num_Super}
  // x Bottom
  x_Bottom_Super~{i} = CentreXSuperconductor~{i}-ax~{Sample~{i}}/2;
  // y Bottom
  y_Bottom_Super~{i} = CentreYSuperconductor~{i}-ay~{Sample~{i}}/2;
  // z x_Bottom
  z_Bottom_Super~{i} = CentrezSuperconductor~{i}-az~{Sample~{i}}/2;
  EndFor
EndIf

//Inputs
DefineConstant[
  Active_approach = {0, Choices{
        0="0 : No Rotation: Initial condition",
        1="1 : Rotation then stop",
        2="2 : Rotation + Flux creep"}
		, Name "zBulks Motion/Input/0Model Rotation?", Visible 1}
];

Flag_Mvt_hformulation = 0;
Approach_cycle_nb = 1;

DefineConstant[ ThetaMax = {2*Pi, Name "zBulks Rotation/Input/1Maximum Value of the rotation angle", Visible 1}];
DefineConstant[ Time_step_per_cycle = {40, Name "zBulks Motion/Input/2Time step per cycle", Visible Active_approach }];
DefineConstant[ Rotation_Speed = { Pi/100 , Name "zBulks Motion/Input/3Rotation speed [Rad/s]", Visible Active_approach }];
DefineConstant[ Time_step_amplitude = {(Rotation_Speed == 0) ? 180 : (ThetaMax)/(Time_step_per_cycle*Rotation_Speed), Name "zBulks Motion/Input/4Time step duration during motion[s]", Visible Active_approach }];
DefineConstant[ Flag_Test_projection = {0, Name "zBulks Motion/Input/5Test Projection"}];
DefineConstant [Flag_JcB = {0, Name "Input/3Material Properties/6Jc(B) dependence?"}];
DefineConstant [FlagFCNoCurrent = {1, Name "Input/3Material Properties/7Model FC without current?"}];


// Informations for the user
DefineConstant[ Time_step = {1, Min 1, Max ((Active_approach == 0) ? 1 : Time_step_per_cycle), Step 1, Loop  2, Name "zBulks Motion/Real time information/1Time step number", Visible Active_approach}];
DefineConstant[ Cycle = {1, Min 1, Max ((Active_approach == 0) ? 1 : Approach_cycle_nb), Step 1, Loop  1, Name "zBulks Motion/Real time information/2Current cycle ", Visible Active_approach}];
DefineConstant[ dTheta = {(Active_approach == 0) ? 0 : Rotation_Speed*Time_step_amplitude, Name "zBulks Motion/Real time information/4Increment angle", Visible 1}];
MyTheta = dTheta*Time_step;


// Sensor experimental position
If(Modelled_Samples == 1 || Modelled_Samples == 2)
	DFromSurf = 0.001;
Else
	DFromSurf = 0.0015;
EndIf

// ---- Saving Files for Matlab post-processing? ----
DefineConstant[ Save_later = {1, Name "Input/5Save for Matlab?", Visible 1 }];

// Air volume
Air_Lx = 0;
Air_Ly = 0;
Air_Lz = 0;
For i In {1:Num_Super}
	If(Air_Lx < ax~{Sample~{i}})
		Air_Lx = ax~{Sample~{i}};
	EndIf
	If(Air_Ly < ay~{Sample~{i}})
		Air_Ly = ay~{Sample~{i}};
	EndIf
	Air_Lz = Air_Lz + az~{Sample~{i}};
EndFor

Air_Lx = Air_Lx + 0.05;
Air_Ly = Air_Ly + 0.05;
Air_Lz = Air_Lz + 0.05;

// ---- Constant definition for regions ----
AIR = 2000;
SUPERCONDUCTING_REGION = 3000;
BND_MATERIAL = 4000;
SURF_OUT = 5000;
For i In {1:Num_Super}
	BULK~{i} = 10000*i;
	Boundary_BULK~{i} = 11111*i;
EndFor
ARBITRARY_POINT = 11000;
AP = 123456789;
