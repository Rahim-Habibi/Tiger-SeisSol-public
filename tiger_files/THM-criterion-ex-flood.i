
[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
  pressure = pressure
  #has_supg = true
  temperature = temperature
  stress_free_temperature = 'T0'
  thermal_expansion_coeff = 1e-5 # 8e-6  engineering toolbox # linear
[]
# properties of fluid is defined here, and in the following will be called by material block
[Physics/SolidMechanics/QuasiStatic]
      [./all]
      add_variables = true
      strain = SMALL
      incremental = true
      #temperature = temperature
      #use_displaced_mesh = true
      eigenstrain_names = 'reduced_eigenstrain'
      volumetric_locking_correction = true
      additional_generate_output = 'stress_xx stress_xy stress_xz stress_yy stress_yz stress_zz'
      additional_material_output_order =  'FIRST'
      [../]
[]
[FluidProperties]
[./water_uo]
  type = TigerIdealWater
  cp = 3800
  thermal_conductivity = 0.6
  bulk_modulus = 2.16356e+09
[../]
[]


# Permeability Assigning
[UserObjects]
  [./rock_uo0]
    type = TigerPermeabilityConst
    permeability_type = isotropic
     k0 = '3.0e-17'
  [../]
  [./rock_uo1]
    type = TigerPermeabilityConst
    permeability_type = isotropic
    k0 = '1.5e-14'
  [../]
  [./rock_uo2]
    type = TigerPermeabilityConst
    permeability_type = isotropic
    k0 = '5.0e-5'
  [../]
  [./rock_uo3]
    type = TigerPermeabilityConst
    permeability_type = isotropic
    k0 = '4.0e-10'
  [../]
  [./supg_w]
    type = TigerSUPG
    effective_length = min
    supg_coeficient = transient_tezduyar
  [../]
  [./supg_f]
    type = TigerSUPG
    effective_length = average
    supg_coeficient = transient_tezduyar
  [../]
  [./supg_m]
    type = TigerSUPG
    effective_length = directional_average
    supg_coeficient = transient_tezduyar
  [../]
[]
[AuxVariables]
  [./p0]
    family = LAGRANGE
    order = FIRST
  [../]
  [./dP]
    family = LAGRANGE
    order = FIRST
  [../]
  [./T0]
    family = LAGRANGE
    order = FIRST
  [../]
  [./dT]
    family = LAGRANGE
    order = FIRST
  [../]
  [./stress_excess]
    family = MONOMIAL
    order = CONSTANT
    block = 'Fault1 Fault2'
  [../]
  [./invCritNucArea]
    family = MONOMIAL
    order = CONSTANT
    block = 'Fault1 Fault2'
  [../]
  [./normal_stress]
    family = MONOMIAL
    order = CONSTANT
    block = 'Fault1 Fault2'
  [../]
  [./shear_stress]
    family = MONOMIAL
    order = CONSTANT
    block = 'Fault1 Fault2'
  [../]
[]


[AuxKernels]
  [./p0_ker]
    type = FunctionAux
    variable = 'p0'
    function = '(1000*9.81*(500-(z+200)))'
    execute_on = 'initial'
  [../]
  [./stress_excess_ker]
    type = ParsedAux
    variable = 'stress_excess'
    coupled_variables = 'shear_stress normal_stress'
    expression = 'shear_stress - 0.6 * max(0.0, -normal_stress)' # the sign of normal stress is negative in compression
    execute_on = 'initial TIMESTEP_END'
    block = 'Fault1 Fault2'
  [../]
  [./dP_ker]
    type = ParsedAux
    variable = 'dP'
    coupled_variables = 'pressure p0'
    expression = 'pressure-p0'
    execute_on = 'initial TIMESTEP_END'
  [../]
  [./T0_ker]
    type = FunctionAux
    variable = 'T0'
    function = '((0.03*(500-z))+283.15)'
    execute_on = 'initial'
  [../]

  [./dT_ker]
    type = ParsedAux
    variable = 'dT'
    coupled_variables = 'temperature T0'
    expression = 'temperature-T0'
    execute_on = 'initial TIMESTEP_END'
  [../]

  [./InvCriticalNucleationArea_ker]
    type = TigerInvCriticalNucleationAreaAux
    variable = 'invCritNucArea'
    normal_stress = normal_stress
    mu_s = 0.6
    mu_d = 0.2
    CG = 9.2390208367e+09
    d_c = 0.1
    execute_on = 'initial TIMESTEP_END'
    block = 'Fault1 Fault2'
  [../]
  [./normalstress_ker]
    type = TigerNormalStressAux
    variable = 'normal_stress'
    total_stress = stress
    execute_on = 'initial TIMESTEP_END'
    block = 'Fault1 Fault2'
  [../]
  [./shearstress_ker]
    type = TigerShearStressAux
    variable = 'shear_stress'
    total_stress = stress
    execute_on = 'initial TIMESTEP_END'
    block = 'Fault1 Fault2'
  [../]
[]
# Materials Assigning
[Materials]
  [./Elasticity_tensor]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 15e9
    poissons_ratio = 0.2
    block = 'Well1 Well2 Well3 Fault1 Fault2 Sediment-Left Sediment-Mid Sediment-Right Reservoir-Right Reservoir-Mid Reservoir-Left Base-Left Base-Mid Base-Right BackEx FrontEx BottomEx'
  [../]
  [./stress]
    type = ComputeFiniteStrainElasticStress
    block = 'Well1 Well2 Well3 Fault1 Fault2 Sediment-Left Sediment-Mid Sediment-Right Reservoir-Right Reservoir-Mid Reservoir-Left Base-Left Base-Mid Base-Right BackEx FrontEx BottomEx'
  [../]
  [./thermal_expansion]
    type = ComputeThermalExpansionEigenstrain
    # thermal_expansion_coeff = 1e-5
    # temperature = temperature
    # stress_free_temperature = 'T0'
    eigenstrain_name = 'thermal_eigenstrain'
    block = 'Well1 Well2 Well3 Fault1 Fault2 Sediment-Left Sediment-Mid Sediment-Right Reservoir-Right Reservoir-Mid Reservoir-Left Base-Left Base-Mid Base-Right BackEx FrontEx BottomEx'
  [../]
  [./reduced_order_eigenstrain]
    type = ComputeReducedOrderEigenstrain
    input_eigenstrain_names = 'thermal_eigenstrain'
    eigenstrain_name = 'reduced_eigenstrain'
    block = 'Well1 Well2 Well3 Fault1 Fault2 Sediment-Left Sediment-Mid Sediment-Right Reservoir-Right Reservoir-Mid Reservoir-Left Base-Left Base-Mid Base-Right BackEx FrontEx BottomEx'
  [../]
  [./rock_g0]
    type = TigerGeometryMaterial
     gravity = '0 0 -9.8'
     scale_factor = 1 # 100
     block = 'Sediment-Left Sediment-Mid Sediment-Right Reservoir-Right Reservoir-Mid Reservoir-Left Base-Left Base-Mid Base-Right BackEx FrontEx BottomEx'
  [../]
  [./rock_fault]
    type = TigerGeometryMaterial
     gravity = '0 0 -9.8'
     scale_factor = 0.01 # Fault Apperture
     block = 'Fault1 Fault2'
  [../]
  [./rock_wells]
    type = TigerGeometryMaterial
     gravity = '0 0 -9.8'
     scale_factor = 0.1 # Well Diameter
     block = 'Well1 Well2 Well3'
  [../]
  [./rock_p0]
    type = TigerPorosityMaterial
    porosity = 0.01
    specific_density = 2500
    block = 'Sediment-Left Sediment-Mid Sediment-Right Base-Left Base-Mid Base-Right BackEx FrontEx BottomEx'
  [../]
  [./rock_p1]
    type = TigerPorosityMaterial
    porosity = 0.15
    specific_density = 2500
    block = 'Well1 Well2 Well3 Fault1 Fault2 Reservoir-Right Reservoir-Mid Reservoir-Left'
  [../]
  [./rock_f]
    type= TigerFluidMaterial
    fp_uo = water_uo
    block = 'Well1 Well2 Well3 Fault1 Fault2 Sediment-Left Sediment-Mid Sediment-Right Reservoir-Right Reservoir-Mid Reservoir-Left Base-Left Base-Mid Base-Right BackEx FrontEx BottomEx'
  [../]
  [./rock_h0]
    type = TigerHydraulicMaterialH
    pressure = pressure
    compressibility = 5.0e-10
    initial_permeability = 3e-18
    kf_uo = rock_uo0
    block = 'Sediment-Left Sediment-Mid Sediment-Right Base-Left Base-Mid Base-Right BackEx FrontEx BottomEx'
  [../]
  [./rock_h1]
    type = TigerHydraulicMaterialH
    pressure = pressure
    compressibility = 5.0e-10
    initial_permeability = 3e-17
    kf_uo = rock_uo1
    block = 'Well3 Reservoir-Right Reservoir-Mid Reservoir-Left'
  [../]
  [./rock_h2]
    type = TigerHydraulicMaterialH
    pressure = pressure
    compressibility = 5.0e-10
    initial_permeability = 1e-11
    kf_uo = rock_uo2
    block = 'Well1 Well2'
  [../]
  [./FaultActivation]
    type = TigerHydraulicMaterialH
    pressure = pressure
    compressibility = 5.0e-10
    initial_permeability = 1e-11
    kf_uo = rock_uo3
    block = 'Fault1 Fault2'
  [../]
  [./Thermalsediment]
    type = TigerThermalMaterialT
    conductivity_type = isotropic
    mean_calculation_type = geometric
    lambda = 3
    specific_heat = 800
    has_supg = true
    supg_uo = supg_f
    advection_type = darcy_velocity
    block = 'Sediment-Left Sediment-Mid Sediment-Right Base-Left Base-Mid Base-Right BackEx FrontEx BottomEx'
  [../]
  [./ThermalReservoir]
    type = TigerThermalMaterialT
    conductivity_type = isotropic
    mean_calculation_type = geometric
    lambda = 3
    specific_heat = 800
    has_supg = true
    advection_type = darcy_velocity
    supg_uo = supg_f
    block = 'Well3 Reservoir-Right Reservoir-Mid Reservoir-Left'
  [../]
  [./ThermalWells]
    type = TigerThermalMaterialT
    conductivity_type = isotropic
    mean_calculation_type = geometric
    lambda = 3
    specific_heat = 800
    has_supg = true
    advection_type = darcy_velocity
    supg_uo = supg_f
    block = 'Well1 Well2'
  [../]
  [./ThermalFaults]
    type = TigerThermalMaterialT
    conductivity_type = isotropic
    mean_calculation_type = geometric
    lambda = 3
    specific_heat = 800
    has_supg = true
    advection_type = darcy_velocity
    supg_uo = supg_f
    block = 'Fault1 Fault2'
  [../]
[]
# Boundary Conditions
[BCs]
  [./no_x]
    type = DirichletBC
    variable = disp_x
    boundary = 'Right Left'
    value = 0.0
  [../]
  [./no_y]
    type = DirichletBC
    variable = disp_y
    boundary = 'Back Front'
    value = 0.0
  [../]
  [./no_z]
    type = DirichletBC
    variable = disp_z
    boundary = 'Bottom'
    value = 0.0
  [../]
  [./overburden]
    type = Pressure
    boundary = 'Top'
    variable = disp_z
    function = ini_zz_force
  [../]
  [./Top]
    type = FunctionDirichletBC
    variable = pressure
    boundary = 'Top Bottom'
    function = hydrostatic
  [../]
  [./TempBottom]
    type = FunctionDirichletBC
    variable = temperature
    boundary = 'Top Bottom'
    function = Thermal
  [../]
  [./t_inject]
    type = DirichletBC
    variable = temperature
    boundary = 'inj'
    value = 313.15 # 40 C
  [../]
  [./t_inject2]
    type = DirichletBC
    variable = temperature
    boundary = 'inj'
    value = 283.15 # 60 C
  [../]
[]
[Functions]
  [./ini_zz_force]
    type = ParsedFunction
    expression = '((-z + 500) * 9.81 * 2500)'
  [../]
  [./ini_xx]
    type = ParsedFunction
    expression = '-((-z + 500) * 9.81 * 2500) *  0.6'
  [../]
  [./ini_yy]
    type = ParsedFunction
    expression = '-((-z + 500) * 9.81 * 2500) * 1.5'
  [../]
  [./ini_zz]
    type = ParsedFunction
    expression = '-((-z + 500) * 9.81 * 2500)'
  [../]
  [./ini_xy]
    type = ParsedFunction
    expression = '0'
  [../]
  [./ini_xz]
    type = ParsedFunction
    expression = '0'
  [../]
  [./ini_yz]
    type = ParsedFunction
    expression = '0'
  [../]
  [./hydrostatic]
    type = ParsedFunction
    expression = '(1000*9.81*(500-(z+200)))'
  [../]
  [./Thermal]
    type = ParsedFunction
    expression = '((0.03*(500-z))+283.15)'
  [../]
[]

# Variable Definitions
[Variables]
  [./pressure]
  [../]
  [./temperature]
  [../]
  [./disp_x]
  [../]
  [./disp_y]
  [../]
  [./disp_z]
  [../]
[]
# DirecKernels
[DiracKernels]
  [./pump_in]
    type = TigerHydraulicPointSourceH
    point = '3639.94 5000 -1953.78'
    mass_flux = 100.0 # Mass Flow (kg/s)
    variable = pressure
  [../]
  [./pump_out]
    type = TigerHydraulicPointSourceH
    point = '5289.5 5000 -2052.38'
    mass_flux = -100.0 # Mass Flow (kg/s)
    variable = pressure
  [../]
[]
# tried that but it did not work
# [Controls]
#    [./Terminators_switch]
#     type = TimePeriod
#       enable_objects = 'UserObjects::terminator UserObjects::terminator2'
#       start_time0 = ${fparse ${Executioner/TimeStepper/dt} + ${Executioner/start_time}}
#       start_time = '${start_time0} ${start_time0}'
#   [../]
#[]


#   # [./cold_well_injection_year1]
#   #   type = TimePeriod
#   #   enable_objects = 'BCs::T_cold'
#   #   start_time = '15768001' # 1/2 year
#   #   end_time = 31536000 # 1 year
#   # [../]
#   # [./hot_well_injection_year2]
#   #   type = TimePeriod
#   #   enable_objects = 'BCs::T_hot2'
#   #   start_time = '31536001'
#   #   end_time = 47304000
#   # [../]
#   []
# Kernels
[Kernels]
  [./gravity_z]
    type = TigerMechanicsGravityM
    variable = 'disp_z'
    component = 2
    use_displaced_mesh = false
  [../]
  [./hdiff]
    type = TigerHydraulicKernelH
    variable = pressure
  [../]
  [./htime]
    type = TigerHydraulicTimeKernelH
    variable = pressure
  [../]
  [./T_diff]
    type = TigerThermalDiffusionKernelT
    variable = temperature
  [../]
  [./T_advect]
    type = TigerThermalAdvectionKernelT
    variable = temperature
    pressure = pressure
  [../]
  [./T_time]
    type = TigerThermalTimeKernelT
    variable = temperature
  [../]
  # [./hm]
  #   type = TigerHydroMechanicsKernelHM
  #   variable = pressure
  #   displacements = 'disp_x disp_y disp_z'
  # [../]
  [./poro_x]
    type = PoroMechanicsCoupling
    variable = disp_x
    porepressure = pressure
    component = 0
    use_displaced_mesh = false
  [../]
  [./poro_y]
    type = PoroMechanicsCoupling
    variable = disp_y
    porepressure = pressure
    component = 1
    use_displaced_mesh = false
  [../]
  [./poro_z]
    type = PoroMechanicsCoupling
    variable = disp_z
    porepressure = pressure
    component = 2
    use_displaced_mesh = false
  [../]
[]
[Preconditioning]
  active = 'p1'
  [./p1]
    type = SMP
    full = true
    #petsc_options = '-snes_ksp_ew'
    petsc_options_iname = '-pc_type -pc_hypre_type -snes_type -snes_linesearch_type -sub_pc_factor_shift_type'
    petsc_options_value = 'hypre boomeramg newtonls basic NONZERO'
  [../]
  [./p2]
    type = SMP
    full = true
    #petsc_options = '-snes_ksp_ew'
    petsc_options_iname = '-pc_type -sub_pc_type -snes_type -snes_linesearch_type -sub_pc_factor_shift_type -ksp_gmres_restart'
    petsc_options_value = 'asm lu newtonls basic NONZERO 51'
  [../]
  [./p3]
    type = SMP
    full = true
    #petsc_options = '-snes_ksp_ew'
    petsc_options_iname = '-pc_type -ksp_type -sub_pc_type -snes_type -snes_linesearch_type -pc_asm_overlap -sub_pc_factor_shift_type -ksp_gmres_restart'
    petsc_options_value = 'asm gmres lu newtonls basic 2 NONZERO 51'
  [../]
  [./p4]
    type = FSP
    full = true
    topsplit = pT
    [./pT]
      splitting = 'p T'
      splitting_type = multiplicative
      petsc_options_iname = '-ksp_type -pc_type -snes_type -snes_linesearch_type'
      petsc_options_value = 'fgmres lu newtonls basic'
    [../]
    [./p]
      vars = 'pressure'
      petsc_options_iname = '-ksp_type -pc_type -sub_pc_type'
      petsc_options_value = 'fgmres asm ilu'
    [../]
    [./T]
      vars = 'temperature'
      petsc_options_iname = '-ksp_type -pc_type -pc_hypre_type'
      petsc_options_value = 'preonly hypre boomeramg'
    [../]
  [../]
[]
# Executioners
[Executioner]
  type = Transient
 l_tol = 1e-11
 nl_rel_tol = 1e-6
 nl_abs_tol = 1e-10
 l_max_its = 20
 nl_max_its = 20
 [./TimeStepper]
   #type = TigerTimeStepper
   type = IterationAdaptiveDT
   dt = 360
   #postprocessor = ratio
   growth_factor = 10

 [../]
 dtmax = 10512000
 start_time = 0
 end_time = 315360000
 #end_time = 946080000
  automatic_scaling = true
  #auto_preconditioning = true
  solve_type = 'NEWTON'
[]

[Postprocessors]
  [./dt]
    type = TimestepSize
    execute_on = 'initial timestep_end'
  [../]
  [./t]
    type = TimePostprocessor
    execute_on = 'initial timestep_end'
 [../]
  [./max_dP]
    type = ElementExtremeValue
    variable = dP
    execute_on = 'timestep_end'
    block = 'Fault1 Fault2'
  [../]
  [./max_stress_excess]
    type = ElementExtremeValue
    variable = stress_excess
    execute_on = 'initial timestep_end'
    block = 'Fault1 Fault2'
  [../]
  [./flood_count]
     type = FeatureFloodCount
     variable = stress_excess
     # Must be turned on to build data structures necessary for FeatureVolumeVPP
     compute_var_to_feature_map = true
     threshold = 0.0
     #threshold = 3e6
     execute_on = 'timestep_end'
     block = 'Fault1 Fault2'
  [../]
  [./max_overstress_area_ratio]
    type = VectorPostprocessorReductionValue
    value_type = max
    vectorpostprocessor = feature_volumes
    vector_name = feature_variable_element_integral
    execute_on = 'initial timestep_end'
  [../]
  [./max_area]
    type = VectorPostprocessorReductionValue
    value_type = max
    vectorpostprocessor = feature_volumes
    vector_name = feature_volumes
    execute_on = 'initial timestep_end'
  [../]
[]

[UserObjects]
  [./terminator]
    type = Terminator
    #threshold = '${env threshold}'
    threshold = 1.0
    start_time0 = ${fparse ${Executioner/TimeStepper/dt} + ${Executioner/start_time}}
    expression = 'if(t<=${start_time0}, 0, if(max_overstress_area_ratio > ${threshold}, 1, 0))'
    #expression = 'max_overstress_area_ratio > ${threshold}'
    fail_mode = SOFT
    execute_on = 'initial timestep_end'
  []
  [./terminator2]
    type = Terminator
    start_time0 = ${fparse ${Executioner/TimeStepper/dt} + ${Executioner/start_time}}
    expression = 'if(t<=${start_time0}, 0, if(dt<3600, 1, 0))'
    fail_mode = HARD
    execute_on = 'timestep_end'
  []
[]


[VectorPostprocessors]
  [./feature_volumes]
    type = FeatureVolumeVectorPostprocessor
    flood_counter = flood_count
    execute_on = 'initial timestep_end'
    output_centroids = True
    variable= 'invCritNucArea'
    #single_feature_per_element = True
  [../]
[]


# [Postprocessors]
#   [./production_temp]
#     type = PointValue
#     variable = temperature
#     point = '4856.916 5000 -1988.58'
#   [../]
#   [./Injection_temp]
#     type = PointValue
#     variable = temperature
#     point = '4019.506 5000 -1961.17'
#   [../]
#   [./production_pressure]
#     type = PointValue
#     variable = pressure
#     point = '4856.916 5000 -1988.58'
#   [../]
#   [./Injection_pressure]
#     type = PointValue
#     variable = pressure
#     point = '4019.506 5000 -1961.17'
#   [../]
# []
# Outputs
[Outputs]
  exodus = true
  #csv = true
  print_linear_residuals = false
  print_nonlinear_converged_reason = true
  print_linear_converged_reason = false
  [CSV]
    type = CSV
    execute_on = 'FINAL'
  []
  [out]
    type = Checkpoint
    num_files = 1
 []

[]
