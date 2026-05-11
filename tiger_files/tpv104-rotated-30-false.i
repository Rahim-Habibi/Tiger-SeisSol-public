[Mesh]
  [./file]
    type = FileMeshGenerator
    file = Rahim_Mesh_20m_rotated_no_circle.msh
  [../]
  [./sidesetmid1]
    type = SideSetsBetweenSubdomainsGenerator
    input = 'file'
    primary_block = 'SDMidBack SDLeftBack SDRightBack '
    paired_block = 'SDMidFront SDLeftFront SDRightFront '
    new_boundary = 'primary1_interface primary3_interface primary4_interface '
  [../]
  [./sidesetmid2]
    type = SideSetsBetweenSubdomainsGenerator
    input = 'sidesetmid1'
    primary_block = 'SDMidFront SDLeftFront SDRightFront '
    paired_block = 'SDMidBack SDLeftBack SDRightBack '
    new_boundary = 'primary2_interface primary5_interface primary6_interface ' #'primary2_interface primary5_interface primary6_interface primary7_interface'
  [../]
  [./sidesetmid3]
    type = SideSetsBetweenSubdomainsGenerator
    input = 'sidesetmid2'
    primary_block = ' SDBottomFront'
    paired_block = ' SDBottomBack'
    new_boundary = ' primary7_interface' #'primary2_interface primary5_interface primary6_interface primary7_interface'
  [../]
  [./inj]
   type  = ExtraNodesetGenerator
   coord = '0 0 -300'
   new_boundary = 'injection_point2'
   input = sidesetmid3
   [../]
[]
[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
  pressure = pressure
  temperature = temperature
  stress_free_temperature = 'T0'
  thermal_expansion_coeff = 1e-6 # 8e-6  engineering toolbox # linear
[]
# properties of fluid is defined here, and later will be call by material block
[Modules]
  [./TensorMechanics]
    [./Master]
      [./all]
      add_variables = true
      strain = SMALL
      incremental = true
      #temperature = temperature
      #use_displaced_mesh = true
      eigenstrain_names = 'reduced_eigenstrain'
      volumetric_locking_correction = true
      #additional_generate_output = 'stress_xx stress_xy stress_xz stress_yx stress_yy stress_yz stress_zx stress_zy stress_zz'
      block = 'box  SDRightBack SDRightFront SDLeftBack SDLeftFront SDBottomBack SDBottomFront SDMidBack SDMidFront fault_left fault_right fault_mid fault_bottom fault_top '
      [../]
    [../]
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
    k0 = '8e-14'
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
     order = SECOND
     #initial_condition = '-1e10'
     block = 'fault_left fault_right fault_mid fault_bottom fault_top '
    [../]
    # [./invCritNucArea]
    #   family = MONOMIAL
    #   order = SECOND
    #   #initial_condition = '-1e10'
    #   block = 'fault_left fault_right fault_mid fault_bottom fault_top '
    # [../]
    # [./normal_stress]
    #   family = MONOMIAL
    #   order = SECOND
    #   #initial_condition = '-1e10'
    #   block = 'fault_left fault_right fault_mid fault_bottom fault_top '
    # [../]
    # [./shear_stress]
    #   family = MONOMIAL
    #   order = SECOND
    #   #initial_condition = '-1e10'
    #   block = 'fault_left fault_right fault_mid fault_bottom fault_top '
    # [../]
    [./stress_xx]
      family = MONOMIAL
      order = CONSTANT
      #initial_condition = '0'
    [../]
    [./stress_xy]
      family = MONOMIAL
      order = CONSTANT
      #initial_condition = '0'
    [../]
    [./stress_xz]
      family = MONOMIAL
      order = CONSTANT
      #initial_condition = '0'
    [../]
    [./stress_yx]
      family = MONOMIAL
      order = CONSTANT
      #initial_condition = '0'
    [../]
    [./stress_yy]
      family = MONOMIAL
      order = CONSTANT
      #initial_condition = '0'
    [../]
    [./stress_yz]
      family = MONOMIAL
      order = CONSTANT
      #initial_condition = '0'
    [../]
    [./stress_zx]
      family = MONOMIAL
      order = CONSTANT
      #initial_condition = '0'
    [../]
    [./stress_zy]
      family = MONOMIAL
      order = CONSTANT
      #initial_condition = '0'
    [../]
    [./stress_zz]
      family = MONOMIAL
      order = CONSTANT
      #initial_condition = '0'
    [../]
[]
[AuxKernels]
  [./p0_ker]
    type = FunctionAux
    variable = 'p0'
    function = '(1000*9.81*(-z))'
    execute_on = 'initial'
  [../]
  [./stress_excess_ker]
    type = MaterialRealAux
    property = Coulomb_Stress
    variable = 'stress_excess'
    execute_on = 'TIMESTEP_END'
    block = 'fault_left fault_right fault_mid fault_bottom fault_top'
  [../]
  [./dP_ker]
    type = ParsedAux
    variable = 'dP'
    coupled_variables = 'pressure p0'
    expression = 'pressure-p0'
    execute_on = 'TIMESTEP_END'
  [../]
  [./T0_ker]
    type = FunctionAux
    variable = 'T0'
    function = '((0.03*(-z))+283.15)'
    execute_on = 'initial'
  [../]

  [./dT_ker]
    type = ParsedAux
    variable = 'dT'
    coupled_variables = 'temperature T0'
    expression = 'temperature-T0'
    execute_on = 'TIMESTEP_END'
  [../]
  # [./InvCriticalNucleationArea_ker]
  # type = TigerInvCriticalNucleationAreaAux
  # variable = 'invCritNucArea'
  # normal_stress = normal_stress
  # mu_s = 0.6
  # mu_d = 0.2
  # CG = 9.2390208367e+09
  # d_c = 0.1
  # execute_on = ' TIMESTEP_END'
  # block = 'fault_left fault_right fault_mid fault_bottom fault_top '
  #  [../]
  #
  # [./normalstress_ker]
  #   type = TigerNormalStressAux
  #   variable = 'normal_stress'
  #   total_stress = stress
  #   execute_on = 'TIMESTEP_END'
  #   block = 'fault_left fault_right fault_mid fault_bottom fault_top '
  # [../]
  # [./shearstress_ker]
  #   type = TigerShearStressAux
  #   variable = 'shear_stress'
  #   total_stress = stress
  #   execute_on = 'TIMESTEP_END'
  #   block = 'fault_left fault_right fault_mid fault_bottom fault_top '
  # [../]
  [stress_xx]
    type = RankTwoAux
    rank_two_tensor = stress
    variable = stress_xx
    index_i = 0
    index_j = 0
    execute_on = timestep_end
  []
  [stress_xy]
    type = RankTwoAux
    rank_two_tensor = stress
    variable = stress_xy
    index_i = 0
    index_j = 1
    execute_on = timestep_end
  []
  [stress_xz]
    type = RankTwoAux
    rank_two_tensor = stress
    variable = stress_xz
    index_i = 0
    index_j = 2
    execute_on = timestep_end
  []
  [stress_yx]
    type = RankTwoAux
    rank_two_tensor = stress
    variable = stress_yx
    index_i = 1
    index_j = 0
    execute_on = timestep_end
  []
  [stress_yy]
    type = RankTwoAux
    rank_two_tensor = stress
    variable = stress_yy
    index_i = 1
    index_j = 1
    execute_on = timestep_end
  []
  [stress_yz]
    type = RankTwoAux
    rank_two_tensor = stress
    variable = stress_yz
    index_i = 1
    index_j = 2
    execute_on = timestep_end
  []
  [stress_zx]
    type = RankTwoAux
    rank_two_tensor = stress
    variable = stress_zx
    index_i = 2
    index_j = 0
    execute_on = timestep_end
  []
  [stress_zy]
    type = RankTwoAux
    rank_two_tensor = stress
    variable = stress_zy
    index_i = 2
    index_j = 1
    execute_on = timestep_end
  []
  [stress_zz]
    type = RankTwoAux
    rank_two_tensor = stress
    variable = stress_zz
    index_i = 2
    index_j = 2
    execute_on = timestep_end
  []
[]
# Materials Assigning
[Materials]
  [normalstress]
    type = TigerNormalShearStressM
    total_stress = stress
    DoUWantShear = true
    block = 'fault_left fault_right fault_mid fault_bottom fault_top '
    outputs = exodus
    []
  [failure]
      type = TigerFailure
      block = 'fault_left fault_right fault_mid fault_bottom fault_top '
      #property_name = 'matpp'
      mu_s = 0.6
      outputs = exodus
      []
  [./Elasticity_tensor_box]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 15e9
    poissons_ratio = 0.2
    #     block = ' box SDRightBack SDRightFront SDLeftBack SDLeftFront SDBottomBack SDBottomFront SDMidBack SDMidFront'
  [../]
    #  [./Elasticity_tensor_fault]
    #    type = ComputeIsotropicElasticityTensor
    #    youngs_modulus = 15e7
    #    poissons_ratio = 0.2
    #    block = 'fault_left fault_right fault_mid fault_bottom'
    #  [../]
  [./stress]
    type = ComputeFiniteStrainElasticStress
  [../]
  [./thermal_expansion]
    type = ComputeThermalExpansionEigenstrain
    eigenstrain_name = 'thermal_eigenstrain'
  [../]
  [./reduced_order_eigenstrain]
    type = ComputeReducedOrderEigenstrain
    input_eigenstrain_names = 'thermal_eigenstrain'
    eigenstrain_name = 'reduced_eigenstrain'
  [../]
  [./rock_m]
    type = TigerMechanicsMaterialM
    disps = 'disp_x disp_y disp_z'
    incremental = true
    biot_coefficient = 1
    solid_bulk_modulus = 8e9
    extra_stress_vector = 'ini_yy ini_xx 0'
    # output_properties = 'extra_stress'
    # outputs = 'exodus'
  [../]
  [./rock_g0]
    type = TigerGeometryMaterial
     gravity = '0 0 -9.8'
     scale_factor = 1 # 100
     block = ' box SDRightBack SDRightFront SDLeftBack SDLeftFront SDBottomBack SDBottomFront SDMidBack SDMidFront '
  [../]
  [./rock_fault]
    type = TigerGeometryMaterial
     gravity = '0 0 -9.8'
     scale_factor = 0.001 # Fault Apperture
     block = ' fault_left fault_right fault_mid fault_bottom fault_top '
  [../]
  [./rock_p0]
    type = TigerPorosityMaterial
    porosity = 0.05
    specific_density = 2500
    block = ' box SDRightBack SDRightFront SDLeftBack SDLeftFront SDBottomBack SDBottomFront SDMidBack SDMidFront'
  [../]
  [./rock_p1]
    type = TigerPorosityMaterial
    porosity = 0.15
    specific_density = 2500
    block = 'fault_left fault_right fault_mid fault_bottom fault_top '
  [../]
  [./rock_f]
    type= TigerFluidMaterial
    fp_uo = water_uo
    block = ' box SDRightBack SDRightFront SDLeftBack SDLeftFront SDBottomBack SDBottomFront SDMidBack SDMidFront fault_left fault_right fault_mid fault_bottom fault_top '
  [../]
  [./rock_h0]
    type = TigerHydraulicMaterialH
    pressure = pressure
    compressibility = 5.0e-10
    kf_uo = rock_uo0
    initial_permeability = 3e-18
    block = ' box'
  [../]
  [./rock_reservoir]
    type = TigerHydraulicMaterialH
    pressure = pressure
    compressibility = 5.0e-10
    kf_uo = rock_uo1
    initial_permeability = 3e-17
    block = '  SDRightBack SDRightFront SDLeftBack SDLeftFront SDBottomBack SDBottomFront SDMidBack SDMidFront'
  [../]
  [./FaultActivation]
    type = TigerHydraulicMaterialH
    pressure = pressure
    compressibility = 5.0e-10
    kf_uo = rock_uo3
    initial_permeability = 20e-11
    block = 'fault_left fault_right fault_mid fault_bottom fault_top '
  [../]
  [./Thermalsediment]
    type = TigerThermalMaterialT
    conductivity_type = isotropic
    mean_calculation_type = geometric
    lambda = 2
    specific_heat = 1400
    has_supg = true
    supg_uo = supg_f
    advection_type = darcy_velocity
    block = ' box SDRightBack SDRightFront SDLeftBack SDLeftFront SDBottomBack SDBottomFront SDMidBack SDMidFront'
  [../]
  [./ThermalFaults]
    type = TigerThermalMaterialT
    conductivity_type = isotropic
    mean_calculation_type = geometric
    lambda = 3
    specific_heat = 1000
    has_supg = true
    advection_type = darcy_velocity
    supg_uo = supg_f
    block = 'fault_left fault_right fault_mid fault_bottom fault_top '
  [../]
  [undrained_density_0]
    type = GenericConstantMaterial
    block = ' box SDRightBack SDRightFront SDLeftBack SDLeftFront SDBottomBack SDBottomFront SDMidBack SDMidFront fault_left fault_right fault_mid fault_bottom fault_top '
    prop_names = density
    prop_values = 2500
   []
[]
# Boundary Conditions
[BCs]
  [./no_x]
    type = DirichletBC
    variable = disp_x
    boundary = 'back front'
    value = 0.0
  [../]
  [./no_y]
    type = DirichletBC
    variable = disp_y
    boundary = 'right left'
    value = 0.0
  [../]
  [./no_zz]
    type = DirichletBC
    variable = disp_z
    boundary = 'bottom'
    value = 0.0
  [../]
  [./no_xz]
    type = DirichletBC
    variable = disp_x
    boundary = 'bottom'
    value = 0.0
  [../]
  [./no_yz]
    type = DirichletBC
    variable = disp_y
    boundary = 'bottom'
    value = 0.0
  [../]
  [./Top]
    type = FunctionDirichletBC
    variable = pressure
    boundary = 'top bottom'
    function = hydrostatic
  [../]
  [./TempBottom]
    type = FunctionDirichletBC
    variable = temperature
    boundary = 'top bottom'
    function = Thermal
  [../]
   [./t_inject]
     type = DirichletBC
     variable = temperature
     boundary = 'injection_point'
     value = 303.15 # 40 C
   [../]
   # [./p_inject]
   # type = FunctionDirichletBC
   # variable = pressure
   # boundary ='injection_point'
   # function = press
   # [../]
[]

[Functions]
  [./ini_xx]
    type = ParsedFunction
    #expression = '-((-z) * 9.81 * 2500)'
    expression = 'if (z >= 0,0,
                  if(z<0, ((-((-z) * 10894)+37537)*1.2),0))'
  [../]
  [./ini_yy]
    type = ParsedFunction
    expression = '(-((-z) * 10894)+37537)*0.7'
  [../]
  [./ini_zz]
    type = ParsedFunction
    expression = '((-z) * 9.81 * 2500)' # total stress is negative, pore pressure is positive. so the effective can be read in this way
    # expression = 'if(z >= 0, 0,
    #           if(z < 0, (-((-z) * 9.81 * 2500) + (1000*9.81*(-z))),0))'
  [../]
  [./hydrostatic]
    type = ParsedFunction
    expression = '(1000*9.81*(-z))'
  [../]
  [./Thermal]
    type = ParsedFunction
    expression = '((0.03*(-z))+283.15)'
  [../]
  [./press]
   type = ParsedFunction
   expression = 'if(t <= 1000000, (-t/1000000+100)-100, -100) '
   [../]
[]
[ICs]
  [./hydrostatic_ic]
    type = FunctionIC
    variable = pressure
    function = hydrostatic
  [../]
  [./temperature_ic]
    type = FunctionIC
    variable = temperature
    function = Thermal
  [../]
[]
# [Debug]
#    show_material_props = true
#   show_var_residual_norms = true
#   show_execution_order = initial
# []
# Variable Definitions
[Variables]
  [./pressure]
  [../]
  [./temperature]
  [../]
  [./disp_x]
    initial_condition = 0
    block = 'box  SDRightBack SDRightFront SDLeftBack SDLeftFront SDBottomBack SDBottomFront SDMidBack SDMidFront '
  [../]
  [./disp_y]
    initial_condition = 0
    block = 'box  SDRightBack SDRightFront SDLeftBack SDLeftFront SDBottomBack SDBottomFront SDMidBack SDMidFront '
  [../]
  [./disp_z]
    initial_condition = 0
    scaling = 1e-8
    block = 'box  SDRightBack SDRightFront SDLeftBack SDLeftFront SDBottomBack SDBottomFront SDMidBack SDMidFront '
  [../]
[]

###Control
[Controls]
  [./No_injection_2days]
    type = TimePeriod
      enable_objects = 'BCs::t_inject'
      start_time = '1'
      #end_time = 77583600 # 492 days
  [../]
  [./cold_well_injection_year1]
    type = TimePeriod
    enable_objects = 'DiracKernels::pump_in'
    start_time = '1' # 1/2 year
    #end_time = 31536000 # 1 year
  [../]
#    [./hot_well_injection_year2]
#      type = TimePeriod
#      enable_objects = 'UserObjects::terminator2'
#      start_time = '1'
#   #   end_time = 47304000
#    [../]
  []

[DiracKernels]
 [./pump_in]
   type = TigerHydraulicPointSourceH
   point = '0 0 -1000'
  # point = '-0.0061802826821804 0.00478761177510023 -1015.40734863281'
  #  mass_flux_function = 'press'
    mass_flux = -20
   variable = pressure
 [../]
[]

[InterfaceKernels]
  [./interfaceZ]
    type = InterfaceDiffusion
    variable = disp_z
    neighbor_var = disp_z
    boundary = primary1_interface
    D = 4
   D_neighbor = 4
  [../]
  [./interfaceX]
    type = InterfaceDiffusion
    variable = disp_x
    neighbor_var = disp_x
    boundary = primary1_interface
    D = 4
   D_neighbor = 4
  [../]
  [./interfaceY]
    type = InterfaceDiffusion
    variable = disp_y
    neighbor_var = disp_y
    boundary = primary1_interface
    D = 4
   D_neighbor = 4
  [../]
  [./interfacebBB]
    type = InterfaceDiffusion
    variable = disp_z
    neighbor_var = disp_z
    boundary = primary7_interface
    D = 4
   D_neighbor = 4
  [../]
[]
# Kernels
[Kernels]
      [./gravity]
    type = Gravity
    use_displaced_mesh = false
    variable = disp_z
    value = -9.81
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
  active = 'p2'
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
   type = IterationAdaptiveDT
   dt = 86400
   #postprocessor = ratio
   growth_factor = 10
 [../]
  dtmax = 10512000
  start_time = -172800
  end_time = 315360000
  #end_time = 946080000
   automatic_scaling = true
   #auto_preconditioning = true
   solve_type = 'NEWTON'
 []
[Postprocessors]
  [./dt]
    type = TimestepSize
  [../]
  [./max_dP]
    type = ElementExtremeValue
    variable = dP
    execute_on = 'initial timestep_end'
    block = ' fault_mid'
  [../]
  [./max_stress_excess]
    type = ElementExtremeMaterialProperty
    mat_prop = Coulomb_Stress
    value_type = max
    execute_on = ' timestep_end'
    block = ' fault_mid'
  [../]

  #[./max_overstress_area_ratio]
  #  type = VectorPostprocessorReductionValue
  #  value_type = sum
  #  vectorpostprocessor = feature_volumes
  #  vector_name = feature_variable_element_integral
  #  execute_on = ' timestep_end'
 # [../]
  # [./max_area]
  #   type = VectorPostprocessorReductionValue
  #   value_type = max
  #   vectorpostprocessor = feature_volumes
  #   vector_name = feature_volumes
  #   execute_on = 'initial timestep_end'
  # [../]
[]

[UserObjects]
  [./terminator]
    type = Terminator
    expression = 'max_stress_excess > 1000000'
    fail_mode = SOFT
    execute_on = ' timestep_end'
    enable = True
  []
 [./terminator2]
   type = Terminator
   expression = 'dt < 50'
   fail_mode = HARD
   execute_on = 'timestep_end'
  #enable = True
 []
  [./flood_count]
     type = FeatureFloodCount
     variable = stress_excess
     # Must be turned on to build data structures necessary for FeatureVolumeVPP
     compute_var_to_feature_map = true
     threshold = 1
     execute_on = 'timestep_end'
  [../]
[]


[VectorPostprocessors]
  [./feature_volumes]
    type = FeatureVolumeVectorPostprocessor
    flood_counter = flood_count
    execute_on = ' timestep_end'
    output_centroids = True
    #variable= 'stress_excess'
    #single_feature_per_element = True
  [../]
[]

# Outputs
[Outputs]
  file_base      = test
  exodus = true
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
