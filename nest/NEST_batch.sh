#!/bin/bash
#PBS -t 1-6
#PBS -l walltime=24:00:00
#PBS -e logs/nest.err
#PBS -o logs/nest.out
cd $PBS_O_WORKDIR

./CHA-adaptive-bursts-iterator.py '../networks/network_N50_CC01_?.yaml' '../data/times_N50_CC01_?.txt' '../data/indices_N50_CC01_?.txt' ${PBS_ARRAYID}
