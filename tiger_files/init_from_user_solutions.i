[Mesh]
  file = THM-criterion-ex-flood_out_cp/LATEST
[]
[Problem]
  restart_file_base = THM-criterion-ex-flood_out_cp/LATEST
[]

[UserObjects]
  [./solution_seissol] 
    type = SolutionUserObject
    mesh = seissoloutput.e
    timestep = LATEST
    system_variables = 'sigma_xx sigma_xy sigma_xz sigma_yy sigma_yz sigma_zz'
  [../]
[]
[Functions]
  # variables of SeisSol
  [seissol_xx]
    type = SolutionFunction
    from_variable = 'sigma_xx'
    solution = 'solution_seissol'
    execute_on = 'INITIAL'
  []
  [seissol_xy]
    type = SolutionFunction
    from_variable = 'sigma_xy'
    solution = 'solution_seissol'
    execute_on = 'INITIAL'
  []
  [seissol_xz]
    type = SolutionFunction
    from_variable = 'sigma_xz'
    solution = 'solution_seissol'
    execute_on = 'INITIAL'
  []
  [seissol_yy]
    type = SolutionFunction
    from_variable = 'sigma_yy'
    solution = 'solution_seissol'
    execute_on = 'INITIAL'
  []
  [seissol_yz]
    type = SolutionFunction
    from_variable = 'sigma_yz'
    solution = 'solution_seissol'
    execute_on = 'INITIAL'
  []
  [seissol_zz]
    type = SolutionFunction
    from_variable = 'sigma_zz'
    solution = 'solution_seissol'
    execute_on = 'INITIAL'
  []
  # adding SeisSol results from last time step
  [./ini2_xx]
    type = ParsedFunction
    expression = 'ini_xx + seissol_xx'
    symbol_names = 'ini_xx seissol_xx'
    symbol_values = 'ini_xx seissol_xx'
  [../]
  [./ini2_yy]
    type = ParsedFunction
    expression = 'ini_yy + seissol_yy'
    symbol_names = 'ini_yy seissol_yy'
    symbol_values = 'ini_yy seissol_yy'
  [../]
  [./ini2_zz]
    type = ParsedFunction
    expression = 'ini_zz + seissol_zz'
    symbol_names = 'ini_zz seissol_zz'
    symbol_values = 'ini_zz seissol_zz'
  [../]
  [./ini2_xy]
    type = ParsedFunction
    expression = 'ini_xy + seissol_xy'
    symbol_names = 'ini_xy seissol_xy'
    symbol_values = 'ini_xy seissol_xy'
  [../]
  [./ini2_xz]
    type = ParsedFunction
    expression = 'ini_xz + seissol_xz'
    symbol_names = 'ini_xz seissol_xz'
    symbol_values = 'ini_xz seissol_xz'
  [../]
  [./ini2_yz]
    type = ParsedFunction
    expression = 'ini_yz + seissol_yz'
    symbol_names = 'ini_yz seissol_yz'
    symbol_values = 'ini_yz seissol_yz'
  [../]


[../]
[Materials]
[./rock_m]
    type = TigerMechanicsMaterialM
    disps = 'disp_x disp_y disp_z'
    incremental = true
    biot_coefficient = 1
    solid_bulk_modulus = 8e9
    extra_stress_vector = 'ini2_xx ini2_xy ini2_xz ini2_xy ini2_yy ini2_yz ini2_xz ini2_yz ini2_zz'
    block = 'Well1 Well2 Well3 Fault1 Fault2 Sediment-Left Sediment-Mid Sediment-Right Reservoir-Right Reservoir-Mid Reservoir-Left Base-Left Base-Mid Base-Right BackEx FrontEx BottomEx'
  [../]
[]
