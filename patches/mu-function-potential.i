[Mesh]
  [./file]
    type = FileMeshGenerator
    file = Rahim_Mesh_p_plane_well_4.2.msh
    #file =Rahim_Mesh_p_plane_4.2-large.msh
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
#uniform_refine = 1
#parallel_type = DISTRIBUTED
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
      additional_generate_output = 'max_principal_stress min_principal_stress'
      block = 'well box  SDRightBack SDRightFront SDLeftBack SDLeftFront SDBottomBack SDBottomFront SDMidBack SDMidFront fault_left fault_right fault_mid fault_bottom '
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
#  [./p0]
#    family = LAGRANGE
#    order = FIRST
#  [../]
#  [./dP]
#    family = LAGRANGE
#    order = FIRST
#  [../]
  [./T0]
    family = LAGRANGE
    order = FIRST
  [../]
#  [./dT]
#    family = LAGRANGE
#    order = FIRST
#  [../]
   [./stress_excess]
     family = MONOMIAL
     order = CONSTANT
     #initial_condition = '-1e10'
     block = 'fault_left fault_right fault_mid fault_bottom '
    [../]
#     [./invCritNucArea]
#       family = MONOMIAL
#       order = CONSTANT
#       #initial_condition = '-1e10'
#       block = 'fault_left fault_right fault_mid fault_bottom '
#     [../]
#     [./normal_stress]
#       family = MONOMIAL
#       order = CONSTANT
#       #initial_condition = '-1e10'
#       block = 'fault_left fault_right fault_mid fault_bottom '
#     [../]
#     [./shear_stress]
#       family = MONOMIAL
#       order = CONSTANT
#       #initial_condition = '-1e10'
#       block = 'fault_left fault_right fault_mid fault_bottom '
#     [../]
    #  [./MCInvariant]
    #    family = MONOMIAL
    #    order = CONSTANT
    #    #initial_condition = '-1e10'
    #    block = 'fault_left fault_right fault_mid fault_bottom '
    #  [../]
    # [./Potential]
    #   family = MONOMIAL
    #   order = CONSTANT
    #   #initial_condition = '-1e10'
    #   block = 'fault_left fault_right fault_mid fault_bottom '
    # [../]
    # [./mu_sDeclare]
    #   family = MONOMIAL
    #   order = CONSTANT
    #   #initial_condition = '-1e10'
    #   block = 'fault_left fault_right fault_mid fault_bottom '
    #  [../]
    # [./stress_xx]
    #   family = MONOMIAL
    #   order = CONSTANT
    #   #initial_condition = '0'
    # [../]
    # [./stress_xy]
    #   family = MONOMIAL
    #   order = CONSTANT
    #   #initial_condition = '0'
    # [../]
    # [./stress_xz]
    #   family = MONOMIAL
    #   order = CONSTANT
    #   #initial_condition = '0'
    # [../]
    # [./stress_yx]
    #   family = MONOMIAL
    #   order = CONSTANT
    #   #initial_condition = '0'
    # [../]
    # [./stress_yy]
    #   family = MONOMIAL
    #   order = CONSTANT
    #   #initial_condition = '0'
    # [../]
    # [./stress_yz]
    #   family = MONOMIAL
    #   order = CONSTANT
    #   #initial_condition = '0'
    # [../]
    # [./stress_zx]
    #   family = MONOMIAL
    #   order = CONSTANT
    #   #initial_condition = '0'
    # [../]
    # [./stress_zy]
    #   family = MONOMIAL
    #   order = CONSTANT
    #   #initial_condition = '0'
    # [../]
    # [./stress_zz]
    #   family = MONOMIAL
    #   order = CONSTANT
    #   #initial_condition = '0'
    # [../]
[]
[AuxKernels]
#  [./p0_ker]
#    type = FunctionAux
#    variable = 'p0'
#    function = '(1000*9.81*(-z))'
#    execute_on = 'initial'
#  [../]
 [./stress_excess_ker]
   type = MaterialRealAux
   property = Coulomb_Stress
   variable = 'stress_excess'
   execute_on = 'TIMESTEP_END'
   block = 'fault_left fault_right fault_mid fault_bottom '
 [../]
#  [./dP_ker]
#    type = ParsedAux
#    variable = 'dP'
#    coupled_variables = 'pressure p0'
#    expression = 'pressure-p0'
#    execute_on = 'TIMESTEP_END'
#  [../]
  [./T0_ker]
    type = FunctionAux
   variable = 'T0'
    function = '((0.03*(-z))+283.15)'
    execute_on = 'initial'
  [../]

#  [./dT_ker]
#    type = ParsedAux
#    variable = 'dT'
#    coupled_variables = 'temperature T0'
#    expression = 'temperature-T0'
#    execute_on = 'TIMESTEP_END'
#  [../]
#   [./InvCriticalNucleationArea_ker]
#   type = TigerInvCriticalNucleationAreaAux
#   variable = 'invCritNucArea'
#   normal_stress = normal_stress
#   mu_s = mu_sfunction
#   mu_d = 0.2
#   CG = 9.2390208367e+09
#   d_c = d_cfunction
#   execute_on = ' TIMESTEP_END'
#   block = 'fault_left fault_right fault_mid fault_bottom '
#    [../]
  #
#   [./normalstress_ker]
#     type = TigerNormalStressAux
#     variable = 'normal_stress'
#     total_stress = stress
#     execute_on = 'TIMESTEP_END'
#     block = 'fault_left fault_right fault_mid fault_bottom '
#   [../]
#   [./shearstress_ker]
#     type = TigerShearStressAux
#     variable = 'shear_stress'
#     total_stress = stress
#     execute_on = 'TIMESTEP_END'
#     block = 'fault_left fault_right fault_mid fault_bottom '
#   [../]
  #  [./MC-invariant_ker]
  #    type = ParsedAux
  #    variable = 'MCInvariant'
  #    coupled_variables = 'stress_xx stress_yy stress_zz stress_xy stress_yz stress_xz mu_sDeclare'
  #    expression = '(2*mu_sDeclare * max_principal_stress) /((1-mu_sDeclare * cot(45)) * sin(90))'
  #    execute_on = 'TIMESTEP_END'
  #    block = 'fault_left fault_right fault_mid fault_bottom '
  #  [../]
  # [./Potential_ker]
  #   type = ParsedAux
  #   variable = 'Potential'
  #   coupled_variables = 'max_principal_stress min_principal_stress mu_sDeclare '
  #   #expression = '-1 * (((stress_yy - stress_xx) * 0.5 * cos(atan(mu_sDeclare))) - 0.5 * mu_sDeclare * ((stress_yy + stress_xx) + (stress_yy - stress_xx) * sin(atan(mu_sDeclare))))'
  #   expression = '-0.5 * (min_principal_stress - max_principal_stress) * cos(atan(mu_sDeclare)) + 0.5 * mu_sDeclare * (min_principal_stress + max_principal_stress + (min_principal_stress - max_principal_stress) * sin(atan(mu_sDeclare)))'
  #
  #   execute_on = 'TIMESTEP_END'
  #   block = 'fault_left fault_right fault_mid fault_bottom fault_top '
  # [../]
  # [./mu_s_ker]
  #   type = MaterialRealAux
  #   property = mu_s
  #   variable = 'mu_sDeclare'
  #   execute_on = 'TIMESTEP_END'
  #   block = 'fault_left fault_right fault_mid fault_bottom fault_top '
  # [../]
  # [stress_xx]
  #   type = RankTwoAux
  #   rank_two_tensor = stress
  #   variable = stress_xx
  #   index_i = 0
  #   index_j = 0
  #   execute_on = timestep_end
  # []
  # [stress_xy]
  #   type = RankTwoAux
  #   rank_two_tensor = stress
  #   variable = stress_xy
  #   index_i = 0
  #   index_j = 1
  #   execute_on = timestep_end
  # []
  # [stress_xz]
  #   type = RankTwoAux
  #   rank_two_tensor = stress
  #   variable = stress_xz
  #   index_i = 0
  #   index_j = 2
  #   execute_on = timestep_end
  # []
  # [stress_yx]
  #   type = RankTwoAux
  #   rank_two_tensor = stress
  #   variable = stress_yx
  #   index_i = 1
  #   index_j = 0
  #   execute_on = timestep_end
  # []
  # [stress_yy]
  #   type = RankTwoAux
  #   rank_two_tensor = stress
  #   variable = stress_yy
  #   index_i = 1
  #   index_j = 1
  #   execute_on = timestep_end
  # []
  # [stress_yz]
  #   type = RankTwoAux
  #   rank_two_tensor = stress
  #   variable = stress_yz
  #   index_i = 1
  #   index_j = 2
  #   execute_on = timestep_end
  # []
  # [stress_zx]
  #   type = RankTwoAux
  #   rank_two_tensor = stress
  #   variable = stress_zx
  #   index_i = 2
  #   index_j = 0
  #   execute_on = timestep_end
  # []
  # [stress_zy]
  #   type = RankTwoAux
  #   rank_two_tensor = stress
  #   variable = stress_zy
  #   index_i = 2
  #   index_j = 1
  #   execute_on = timestep_end
  # []
  # [stress_zz]
  #   type = RankTwoAux
  #   rank_two_tensor = stress
  #   variable = stress_zz
  #   index_i = 2
  #   index_j = 2
  #   execute_on = timestep_end
  # []
[]
# Materials Assigning
[Materials]
  [normalstress]
    type = TigerNormalShearStressM
    total_stress = stress
    #DoUWantShear = true
    block = 'fault_left fault_right fault_mid fault_bottom '
    #outputs = exodus
    []
  [failure]
      type = TigerFailure
      block = 'fault_left fault_right fault_mid fault_bottom '
      #property_name = 'matpp'
      mu_s = mu_sfunction
      #outputs = exodus
      []
      # [frictionM]
      #   type =TigerFrictionM
      #   extra_friction_vector = 'mu_sfunction mu_sfunction mu_sfunction'
      #   outputs = exodus
      #   []
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
     block = ' fault_left fault_right fault_mid fault_bottom '
  [../]
  [./wellscaling]
    type = TigerGeometryMaterial
     gravity = '0 0 -9.8'
     scale_factor = 0.1 # Fault Apperture
     block = ' well '
  [../]
  [./rock_p0]
    type = TigerPorosityMaterial
    porosity = 0.05
    specific_density = 2500
    porosity_evolution = true
    block = ' box SDRightBack SDRightFront SDLeftBack SDLeftFront SDBottomBack SDBottomFront SDMidBack SDMidFront'
  [../]
  [./rock_p1]
    type = TigerPorosityMaterial
    porosity = 0.15
    specific_density = 2500
    porosity_evolution = true
    block = 'fault_left fault_right fault_mid fault_bottom '
  [../]
   [./well]
   type = TigerPorosityMaterial
   porosity = 0.15
   specific_density = 2500
   block = well
   [../]
   [./wellperm]
   type = TigerHydraulicMaterialH
    pressure = pressure
    compressibility = 5.0e-10
    kf_uo = rock_uo2
    initial_permeability = 1e-8
    block = well
   [../]
  [./rock_f]
    type= TigerFluidMaterial
    fp_uo = water_uo
    block = 'well box SDRightBack SDRightFront SDLeftBack SDLeftFront SDBottomBack SDBottomFront SDMidBack SDMidFront fault_left fault_right fault_mid fault_bottom '
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
    block = 'fault_left fault_right fault_mid fault_bottom '
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
    block = 'well fault_left fault_right fault_mid fault_bottom '
  [../]
  [undrained_density_0]
    type = GenericConstantMaterial
    block = 'well box SDRightBack SDRightFront SDLeftBack SDLeftFront SDBottomBack SDBottomFront SDMidBack SDMidFront fault_left fault_right fault_mid fault_bottom '
    prop_names = density
    prop_values = 2500
   []
   [./mu_sDistribution]
  type = GenericFunctionMaterial
  prop_names = mu_s
  prop_values = mu_sfunction
  block = 'fault_left fault_right fault_mid fault_bottom '
  #outputs = exodus
[../]
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
   # [./overburden]
   # type = Pressure
   # boundary = top
   # variable = disp_z
   # function = 100000
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
    expression = '(1000*9.81*(-z))+100000'
  [../]
  [./Thermal]
    type = ParsedFunction
    expression = '((0.03*(-z))+313.15)'
  [../]
  [./press]
   type = ParsedFunction
   expression = 'if(t <= 1000000, (-t/1000000+100)-100, -100) '
   [../]
   [./d_cfunction]
     type = ParsedFunction
     value = '1.5'
     #params = ''
   [../]
# [./mu_sfunction]
#   type = ParsedFunction
#   #expression = 'if(sqrt(((x-cx1)^2) + ((y-cy1)^2) + ((z-cz1)^2)) <= 5, 0.45+(0.7-0.18)*((1-cos(pi*sqrt(((x-cx1)^2) + ((y-cy1)^2) + ((z-cz1)^2))/5))/2) ,
#    expression = 'if(sqrt(((x-cx2)^2) + ((y-cy2)^2) + ((z-cz2)^2)) <= 50, 0.22 ,
#     if(sqrt(((x-cx3)^2) + ((y-cy3)^2) + ((z-cz3)^2)) <= 45, 0.30 ,
#      if(sqrt(((x-cx4)^2) + ((y-cy4)^2) + ((z-cz4)^2)) <= 60, 0.35 ,
#       if(sqrt(((x-cx5)^2) + ((y-cy5)^2) + ((z-cz5)^2)) <= 40, 0.28 ,
#        if(sqrt(((x-cx6)^2) + ((y-cy6)^2) + ((z-cz6)^2)) <= 55, 0.3 ,
#         if(sqrt(((x-cx7)^2) + ((y-cy7)^2) + ((z-cz7)^2)) <= 50, 0.26 ,
#          if(sqrt(((x-cx8)^2) + ((y-cy8)^2) + ((z-cz8)^2)) <= 70, 0.29 ,
#           if(sqrt(((x-cx9)^2) + ((y-cy9)^2) + ((z-cz9)^2)) <= 45, 0.20 ,
#            if(sqrt(((x-cx10)^2) + ((y-cy10)^2) + ((z-cz10)^2)) <= 50, 0.3 ,
#             if(sqrt(((x-cx11)^2) + ((y-cy11)^2) + ((z-cz11)^2)) <= 60, 0.31 ,
#             if(sqrt(((x-cx12)^2) + ((y-cy12)^2) + ((z-cz12)^2)) <= 40, 0.27 ,
#              if(sqrt(((x-cx13)^2) + ((y-cy13)^2) + ((z-cz13)^2)) <= 55, 0.20 ,0.6))))))))))))'
#   # expression = 'if (sqrt(((x-x1)^2) + ((y-y1)^2) + ((z-z1)^2)) <= r1, 0.5,
#   #               if(sqrt(((x-x2)^2) + ((y-y2)^2) + ((z-z2)^2)) <= r2, 0.5, 0.6))'
#   symbol_names = 'cx2 cy2 cz2 r2
#                   cx3 cy3 cz3 r3
#                   cx4 cy4 cz4 r4
#                   cx5 cy5 cz5 r5
#                   cx6 cy6 cz6 r6
#                   cx7 cy7 cz7 r7
#                   cx8 cy8 cz8 r8
#                   cx9 cy9 cz9 r9
#                   cx10 cy10 cz10 r10
#                   cx11 cy11 cz11 r11
#                   cx12 cy12 cz12 r12
#                   cx13 cy13 cz13 r13'
#   symbol_values = '-576.292 -576.292 -1330.07 50
#                     438.406 438.406 -1390.09 45
#                     -49.4979 -49.4979 -1234.43 60
#                     134.35 134.35 -611.545 40
#                     438.406 438.406 -1390.09 55
#                     -410.132 -410.132 -698.07 50
#                     -636.398 -636.398 -1516.03 70
#                     46.991 46.9912 -896.012 45
#                     -49.4982 -49.4979 -1234.43 50
#                     -282.844 -282.843 -1493.86 60
#                     240.416 240.416 -1320.91 40
#                     -176.777 -176.777 -1407.39 55'
# [../]
[./mu_sfunction]
type = ParsedFunction
 expression = 'if(sqrt(((x-cx2)^2) + ((y-cy2)^2) + ((z-cz2)^2)) <= 12.5, 0.7 ,
        if(sqrt(((x-cx9)^2) + ((y-cy9)^2) + ((z-cz9)^2)) <= 12.5, 0.20 ,
           if(sqrt(((x-cx13)^2) + ((y-cy13)^2) + ((z-cz13)^2)) <= 7.25, 0.20 ,0.6)))'
symbol_names = 'cx2 cy2 cz2 r2
                cx9 cy9 cz9 r9
                cx13 cy13 cz13 r13'
symbol_values = '-46.991 -46.9912 -896.012 12.5
                  46.991 46.9912 -896.012 12.5
                  -176.777 -176.777 -1407.39 7.5'
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

# [InterfaceKernels]
#   [./interfaceZ]
#     type = InterfaceDiffusion
#     variable = disp_z
#     neighbor_var = disp_z
#     boundary = primary1_interface
#     D = 4
#    D_neighbor = 4
#   [../]
#   [./interfaceX]
#     type = InterfaceDiffusion
#     variable = disp_x
#     neighbor_var = disp_x
#     boundary = primary1_interface
#     D = 4
#    D_neighbor = 4
#   [../]
#   [./interfaceY]
#     type = InterfaceDiffusion
#     variable = disp_y
#     neighbor_var = disp_y
#     boundary = primary1_interface
#     D = 4
#    D_neighbor = 4
#   [../]
#   [./interfacebBB]
#     type = InterfaceDiffusion
#     variable = disp_z
#     neighbor_var = disp_z
#     boundary = primary7_interface
#     D = 4
#    D_neighbor = 4
#   [../]
# []
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
    # petsc_options_iname = '-pc_type -pc_hypre_type -ksp_type -ksp_gmres_restart'
    # petsc_options_value = 'hypre boomeramg gmres 30'
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
  #end_time = 315360000
  end_time = 946080000
   automatic_scaling = true
   #auto_preconditioning = true
   solve_type = 'NEWTON'
 []
[Postprocessors]
  [./dt]
    type = TimestepSize
  [../]
  [./max_stress_excess]
    type = ElementExtremeMaterialProperty
    mat_prop = Coulomb_Stress
    value_type = max
    execute_on = ' timestep_end'
    block = ' fault_mid'
  [../]
#  [stress_excess]
#  type = ElementExtremeValue
#  variable = invCritNucArea
#  block = 'fault_mid'
# []
  # [./max_area]
  #   type = VectorPostprocessorReductionValue
  #   value_type = sum
  #   vectorpostprocessor = feature_volumes
  #   vector_name = feature_volumes
  #   execute_on = ' timestep_end'
  # [../]
  []

  [UserObjects]
  [./terminator]
    type = Terminator
    expression = 'max_stress_excess > 2000000'
    fail_mode = SOFT
    execute_on = ' timestep_end'
    enable = True
  []
  # [./terminator2]
  #  type = Terminator
  #  expression = 'dt < 50'
  #  fail_mode = HARD
  #  execute_on = 'timestep_end'
  # #enable = True
  # []
  # [./flood_count]
  #  type = FeatureFloodCount
  #  variable = stress_excess
  #  # Must be turned on to build data structures necessary for FeatureVolumeVPP
  #  compute_var_to_feature_map = true
  #  threshold = 1
  #  execute_on = 'timestep_end'
  # [../]
  []


  # [VectorPostprocessors]
  # [./feature_volumes]
  #   type = FeatureVolumeVectorPostprocessor
  #   flood_counter = flood_count
  #   execute_on = ' timestep_end'
  #   output_centroids = True
  #   single_feature_per_element =true
  # [../]
  # []


# Outputs
[Outputs]
  file_base      = two-weak-strong
  exodus = true
  print_linear_residuals = false
  print_nonlinear_converged_reason = true
  print_linear_converged_reason = false
[]
