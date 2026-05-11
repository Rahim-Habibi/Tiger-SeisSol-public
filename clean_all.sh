#!/bin/bash
echo "this will remove all *.vtk *.e *.csv tiger_files/THM-criterion-ex-flood_out_cp* and many more files" 
echo "if you are sure you want to do this, press y" 
read ready 
if ! [ $ready = y ]
then
   echo $ready
   echo "Typo error OR you probably do not want to start the simulation"
   exit 1
else
rm -v *.vtk
rm -v *.e
rm -v *.csv
rm -v *.log
rm -v tiger_files/THM-criterion-ex-flood_out_cp* -rf
rm -v tiger_files/THM-criterion-ex-flood*.csv -rf
rm -v tiger_files/*.e -rf
rm -v SeisSolSetup/*.log
rm -v SeisSolSetup/output/* -rf
rm -v SeisSolSetup/seissol_* -rf
find . -type f -empty -delete
fi 


