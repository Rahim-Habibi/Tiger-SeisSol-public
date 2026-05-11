#!/bin/bash
set -euo pipefail

module use /import/exception-dump/ulrich/spack/modules/linux-debian11-zen2
#checking if seissol-env is loaded
seissol_env=$(module list -l | awk '/seissol-env/ {print $1}')
if ! [ -z "$seissol_env" ]
then 
   module unload $seissol_env
fi
#checking if seissol is loaded
seissol=$(module list -l | awk '/seissol/ {print $1}')
if ! [ -z "$seissol" ]
then 
   module unload $seissol
fi

SeisSol_exe=/import/exception-dump/ulrich/seissol_exe_1.3.1/SeisSol_Release_drome_4_elastic

#source /import/tegern-data/ulrich/MyLibs/mambaforge3/bin/activate moose
#list of the files required for run#


#TigerInput =../input file# here Tiger input file with extension .e should be specified.
#TigerMesh= ../mesh file # here mesh file created in Gmsh with extension .msh should be specified
#SeisSolInput= ../ seissol input file # here seissol input files should be spacified, seissol needs 4 files, so this variable will be modified later.
#SeisSolMesh= ../ Seissol mesh file should be spacified by this variable.

#below I am asking user to assign required file #
echo " Please check all input files needed for both Tiger and SeisSol"
if [ $# -ne 4 ]
then 
    echo "illegal number of parameters, usage:"
    echo "./tiger_seissol_script.sh Tiger_exe Tiger_input_file Tiger_processors Seissol_parameter_file"
    exit 1
else
   Tiger_exe=$1
   TigerInput=$2
   nCPUsTiger=$3
   SeisSolInput=$(realpath $4)
   echo "name of Tiger exe: $Tiger_exe"
   echo "name of Tiger input file: $TigerInput"
   echo "number of processors for running Tiger: $nCPUsTiger"
   echo "name of SeisSol exe: $SeisSol_exe"
   echo "name of SeisSol input parameter file: $SeisSolInput"
   if ! [ -f "$TigerInput" ] 
   then
      echo "TigerInput: $TigerInput does not exists"
      exit 1
   fi
   if ! [ -f "$SeisSolInput" ]
   then
      echo "SeisSolInput: $SeisSolInput does not exists"
      exit 1
   fi
   #this condition checks if the number of processors assigned by useris is larger than zero#
   re='^[1-9]+$'
   if ! [[ $nCPUsTiger=~$re ]]
   then
      echo $nCPUsTiger
      echo "error: Tiger_processors: $nCPUsTiger Not a number OR zero"
      exit 1
   fi
   SeisSolDir=$(dirname "$SeisSolInput")
   TigerDir=$(dirname "$TigerInput")
fi

#this line extracts the whole line holding "end_time" in tiger input file, like start_time = 11
EndTime=$(grep end_time $TigerInput | awk '!/#/ {print $3}')
echo "EndTime read: $EndTime"

loop=1


if [ $loop == 1 ]
then
   #this last time refers to moment when failure takes place, it is initialised here but within the while loop will be re-written when tiger terminates
   CurrentTime=0
   echo "It is assumed the first time step is:$CurrentTime"
else
   CurrentTime=$(tail -n 1 $(($loop-1)).csv | awk -F "," '{ print $1 }' | awk -F "." '{ print $1 }')
fi
echo "loop:$loop"
echo "if you are ready, please type 'go'" 
read ready 
if ! [ $ready = go ]
then
   echo $ready
   echo "Typo error OR you probably do not want to start the simulation"
   exit 1
fi 
#while [ "$EndTime" -gt "$CurrentTime" ];
while [ $EndTime > $CurrentTime ]
do

   ##################################
   #Tiger#
   ##################################

   echo " I am calling Tiger..."
   # Prior to calling moose we unset some environement variables (set when running seissol) that seem to mess with moose
   export OMP_NUM_THREADS=1
   unset OMP_PLACES OMP_PROC_BIND KMP_AFFINITY MP_SINGLE_THREAD
   if [ $loop == 1 ]
   then
      conda run -n moose --live-stream mpirun -n $nCPUsTiger $Tiger_exe -i $TigerDir/init_from_functions.i $TigerInput 2>&1 | tee Tiger_$loop.log
   else
      #in the second and the loops after, I only need to mention the name of the file used for SolutionUserObject which can be done in terminal, so this addition will be added through following line.
      #These two aruements should be passed through terminal in the loops after 1st. the $time step can be read from CSV file and .e file can managed by renaming Tiger outputs.
      #conda run -n moose --live-stream mpirun -n $nCPUsTiger $Tiger_exe -i $TigerDir/init_from_user_solutions.i $TigerInput Executioner/start_time=$CurrentTime 2>&1 | tee -a Tiger_$loop.log
      conda run -n moose --live-stream mpirun -n $nCPUsTiger $Tiger_exe -i $TigerDir/init_from_user_solutions.i $TigerInput Executioner/start_time=$CurrentTime 2>&1 | tee Tiger_$loop.log
      rm -v $CurrentTime

      # Note: this should never happen, as the terminator in disabled in time step 1. But could be useful to have later
      out_e="${TigerInput%".i"}_out.e"
      ntimeSteps=$(ncdump $out_e -h | grep currently | sed -n 's/.*(\([0-9]\+\) currently).*/\1/p')
      if [ $ntimeSteps == 1 ]
      then
         echo "after restart, the Terminator criterion was directly reached (interpolation error)"
         exit 1
      fi
   fi
   ##################################
   #Renaming Tiger outputs #
   ##################################
   # We extract last time step where failure took place using Tiger outputs, the CSV file is assigned to be 
   # created in Tiger input file to track time. this info are not mondatary, it only gives some extra info during the run
   out_csv="${TigerInput%".i"}_CSV.csv"
   out_e="${TigerInput%".i"}_out.e"
   out_cp="${TigerInput%".i"}_out_cp"

   mv -v $out_csv $loop.csv
   # keeping checkpoint to enable (manual) restart
   cp -rv $out_cp $out_cp${loop}
   #added separator '.' because the while comparison will only work on integers
   CurrentTime=$(tail -n 1 $loop.csv | awk -F "," '{ print $1 }' | awk -F "." '{ print $1 }')
   #I suggest to set CSV output in "output" block in input file which holding only last time step when failure takes place.

   #these lines are used for renaming Tiger outputs for archiving purposes
   mv -v $out_e $loop.e
   cp -v $loop.e $TigerDir/output.e
   echo "Failure took place at $CurrentTime in loop $loop, while the end time is $EndTime"
   echo " Tiger finished the run, you can find the ouput at: $(pwd)"
   #  this condition checks if the current loop is last loop, based on the CurrentTime and EndTime, if yes the SeisSol part and conversion will be skipped.
   if [[ ${CurrentTime%.*} -gt ${EndTime%.*} ]] 
   then
      echo " the CurrentTime = $CurrentTime is larger than specified Endtime = $EndTime: we stop simulating"
      break
   fi
   echo " the CurrentTime = $CurrentTime is lower than specified Endtime = $EndTime: we continue simulating"
   ##################################
   #Conversion: Exodus --> xdmf #
   ##################################
   echo "I am converting format..."

   #python scripts/computeTractionsFromExodus.py --block 4 ${loop}.e
   #python scripts/computeTractionsFromExodus.py --block 5 ${loop}.e
   #python scripts/projectGAB2NetcdfVtk.py  ${loop}_tractions_4.vtk
   #python scripts/projectGAB2NetcdfVtk.py  ${loop}_tractions_5.vtk
   #rm -v ${loop}_tractions_*.vtk

   # use merged for the tpv103 setup
   #python scripts/project_fault_exodus_tractions_onto_asagi_grid_merged.py $loop.e --dx 25
   # for the initial setup with 2 faults
   scripts/project_fault_exodus_tractions_onto_asagi_grid.py $loop.e --dx 10

   # Uncomment for initializing with stress tensor (rather than by traction
   #python scripts/computeTractionsFromExodus.py --block 3D ${loop}.e
   #python scripts/interpolate_vtu_to_grid.py ${loop}_stress_3D.vtu --Data s_xx s_xy s_xz s_yy s_yz s_zz  --box "50 1600 8100 0 10e3 -3e3 -500" --add "_background"
   #python scripts/interpolate_vtu_to_grid.py ${loop}_stress_3D.vtu --Data s_xx s_xy s_xz s_yy s_yz s_zz  --box "20 3300 5600  2800 5800 -2500 -1600" --add "_near_wells"
   #rm -v *stress_3D.vtu
   #mv -v gridded_asagi_dx* $SeisSolDir/ASAGI_files/

   ##################################
   #SeisSol #
   ##################################

   echo "now running SeisSol..."
   cd $SeisSolDir
   mkdir -p output
   export OMP_STACKSIZE=16M
   export MP_SINGLE_THREAD=no
   unset KMP_AFFINITY
   export OMP_PLACES="cores"
   export OMP_PROC_BIND=spread
   export XDMFWRITER_ALIGNMENT=4096
   export XDMFWRITER_BLOCK_SIZE=4096
   export ASYNC_BUFFER_ALIGNMENT=4096
   source /etc/profile.d/modules.sh
   export SEISSOL_ASAGI_MPI_MODE=OFF
   ulimit -Ss 2097152
   module use /import/exception-dump/ulrich/spack/modules/linux-debian12-zen2   #/import/exception-dump/ulrich/spack/modules/linux-debian12-zen2
   
   if ! [[ $SeisSol_exe == *"cuda"* ]]
   then 
      export OMP_NUM_THREADS=32
      export ASYNC_MODE=SYNC
      mpirun -n 2 --map-by ppr:1:numa:pe=32 $(which $SeisSol_exe) $SeisSolInput 2>&1 | tee -a SeisSol_$loop.log
   else
      export OMP_NUM_THREADS=10
      export ASYNC_MODE=THREAD
      mpirun -n 2 --map-by ppr:2:numa:pe=10 --report-bindings $(which seissol-launch) $(which $SeisSol_exe) ./parameters.par 2>&1 | tee -a SeisSol_$loop.log
   fi

   rm -rfv ./seissol_$loop
   mv -v output ./seissol_$loop
   mkdir output
   cd -
   ##################################
   #H5 & xdmf to vtk #
   ##################################
   echo "SeisSol finished the run, you can find the output at $SeisSolDir/seissol_$loop"
   echo "First step of data conversion is going to start ..."
   #here it should call python code for data conversion, name of ouput should be
   pvpython scripts/convert_xdmf_to_Exodus.py $SeisSolDir/seissol_$loop/GAB_dc15_ExtendedBottom_1703.xdmf $TigerDir/seissoloutput.e
   echo "data conversion done."

   echo "First Failure took place at $CurrentTime , while the end time is $EndTime"
   #From now on next loop will be performed.
   echo " loop $loop was finished and data were converted."
   loop=$(($loop+1))
   echo loop
   #the done here belong to while
done 
echo "end of the simulation. See you..."
#End of first condition which checks whether user wants to start
