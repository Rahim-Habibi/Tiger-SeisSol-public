[Mesh]
  [./file]
    type = FileMeshGenerator
    file = ExtendedBottom_1703_small.msh
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
  [./stress_xx_ic]
    type = FunctionIC
    variable = stress_xx
    function = ini_xx
  [../]
  [./stress_yy_ic]
    type = FunctionIC
    variable = stress_yy
    function = ini_yy
  [../]
  [./stress_zz_ic]
    type = FunctionIC
    variable = stress_zz
    function = ini_zz
  [../]
  [./stress_xy_ic]
    type = FunctionIC
    variable = stress_xy
    function = ini_xy
  [../]
  [./stress_xz_ic]
    type = FunctionIC
    variable = stress_xz
    function = ini_xz
  [../]
  [./stress_yz_ic]
    type = FunctionIC
    variable = stress_yz
    function = ini_yz
  [../]
[]


[Materials]
[./rock_m]
    type = TigerMechanicsMaterialM
    disps = 'disp_x disp_y disp_z'
    incremental = true
    biot_coefficient = 1
    solid_bulk_modulus = 8e9
    extra_stress_vector = 'ini_xx ini_xy ini_xz ini_xy ini_yy ini_yz ini_xz ini_yz ini_zz'
    block = 'Well1 Well2 Well3 Fault1 Fault2 Sediment-Left Sediment-Mid Sediment-Right Reservoir-Right Reservoir-Mid Reservoir-Left Base-Left Base-Mid Base-Right BackEx FrontEx BottomEx'
  [../]
[]
