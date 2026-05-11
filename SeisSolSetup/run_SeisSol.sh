export OMP_STACKSIZE=16M
export MP_SINGLE_THREAD=no
unset KMP_AFFINITY
export OMP_NUM_THREADS=64
export OMP_PLACES="cores(64)"
#Prevents errors such as experience in Issue #691
export I_MPI_SHM_HEAP_VSIZE=8192

export XDMFWRITER_ALIGNMENT=4096
export XDMFWRITER_BLOCK_SIZE=4096

export ASYNC_MODE=SYNC
export ASYNC_BUFFER_ALIGNMENT=4096
source /etc/profile.d/modules.sh

ulimit -Ss 2097152
module use /import/exception-dump/ulrich/spack/modules/linux-debian11-zen2
module load seissol-env/develop-gcc-12.2.0-f4bnvcu
/export/dump/ulrich/myLibs/seissol/build-cpu/SeisSol_Release_shsw_4_elastic parameters.par
