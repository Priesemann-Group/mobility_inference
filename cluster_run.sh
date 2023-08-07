# Let the shell know what interpreter to run
#!/bin/bash

# Let the cluster/SGE know some stuff
#$ -S /bin/bash
#$ -N outdoor
#$ -q rostam.q
#$ -cwd

# Log stuff
#$ -o ./results/log/ # write log file here
#$ -e ./results/log/ # write error file here

# avoid multithreading in numpy
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1
export OMP_NUM_THREADS=1

source /data.nst/eiftekhar/mambaforge/bin/activate 
conda activate mobility

# It might be necessary to download the OWID data with the download_OWID.ipynb first because the cluster has no internet
python main.py