connectomicsPCV
===============

Set of tools for the connectomics post challenge verification.

Right now it includes most of the [NEST](http://www.nest-initiative.org/) scripts used to generate the spiking data and the Matlab files used to generate the fluorescence traces.

Available datasets
==================
The following datasets have been produced with the above scripts. Testing the challenge algorithms against them is a required part of the post challenge verification procedure.

Inhibition
----------
The datasets generated for the challenge contained a fraction of inhibitory neurons, however, their output connections were blocked. We have generated new datasets with those connections active. Each tgz file includes two fluorescence files, one with inhibition on and one with inhibition off (with the rest of the parameters fixed) as well as the position and network structure (for the normal-[1:4] networks). Keep in mind that the dynamical parameters are slightly different, so the 'inhibition off' part of the datasets is not equivalent to the one available at the challenge.

You can download the datasets here:
[Inhibitory datasets](https://drive.google.com/folderview?id=0B9paVWGXEHk_MW01OW5yUm9HUm8&usp=drive_web)

Original variations
-------------------
These are variations of the original test and valid networks but exploring different values of camera noise, framerate and light scattering. These are all variables that can be tuned in the real experiments, and it is interesting to explore the performance of the algorithms in these conditions.
Inside each folder (test and valid) you will find a set of compressed (gzip) fluorescence traces named:

    fluorescence_network_noise?_ls?_rate?.txt.gz

Where 'network' will either be valid or test, and each ? goes from 1 to 3 for each of the explored parameters. The parameters correspond to the following values:

1. noise = [0, 0.03, 0.06] This is the white noise added directly to the fluorescence signal. Challenge value was the middle one.
2. ls = [0, 0.03, 0.1] Characteristic length of the light scattering effect. Challenge value was the middle one.
3. rate = [25, 50, 100] Frames per second (FPS) of the fluorescence signal. Challenge value was the middle one.

Each of the fluorescence files for a given network (the 3x3x3 combinations) have been generated from the same spiking data, so you should be able to test the performance of the algorithms with exactly the same underlying dynamics.

You can download the datasets here:
[Variations datasets](https://drive.google.com/folderview?id=0B9paVWGXEHk_a1NvY3JtX1VXcHc&usp=drive_web)


Hidden neurons
--------------
The goal of this task is to check the performance of the reconstruction
algorithms when some of the neurons are not accessible. For that we hide
30% of the simulated neurons and only perform the reconstruction with
the remaining 70%.

We provide 10 sets of indices to 'kill' from the original normal-3 and
normal-4 datasets (the ones from Kaggle used for training). Each
file contains 300 indices (from 1 to 100) that you should 'kill' in your
reconstruction, i.e, remove them from the original Fluorescence files.

You can download the files here:
[hidden-neurons datasets](https://drive.google.com/folderview?id=0B9paVWGXEHk_VzdKR1ZtYm50TUE&usp=sharing)


Small datasets
--------------
This is the main dataset of the post-verification phase. It consists of N=100 networks with a 20% of inhibitory neurons (blocked) and a fixed average clustering coefficient, ranging from 0.1 to 0.6. We provide networks with 6 different levels of clustering with 500 replicas each (3000 networks in total). The network dynamics are divided in three groups: 

1. Low bursting (0.05 Hz). Network numbers from 1 to 150 and 451 to 500. Clustering levels from 0.1 to 0.6 (in 0.1 increments). Each tar file includes 50 networks.

  You can download the files here: [low-bursting datasets](https://www.dropbox.com/sh/78py9ldfatxu7lv/AABm0Fa6scBRqhxEwU0pX2w2a?dl=0)
2. Normal bursting (0.1 Hz). Network numbers from 151 to 300 and 451 to 500. Clustering levels from 0.1 to 0.6 (in 0.1 increments). Each tar file includes 50 networks.
  
  You can download the files here: [normal-bursting datasets](https://mega.co.nz/#F!pMogDQhR!XO7zattDsoyNJ7JQ9dzGQg)
3. High bursting (0.2 Hz). Network numbers from 301 to 450 and 451 to 500. Clustering levels from 0.1 to 0.6 (in 0.1 increments). Each tar file includes 50 networks.
  
  You can download the files here: [high-bursting datasets](https://drive.google.com/folderview?id=0B9paVWGXEHk_Zi11WWUzVjc5b1k&usp=sharing)

Final overview
--------------
If you have sucessfully downloaded all the datasets you should have something like the following structure:

1. Inhibition
  * normal-1_inhibition.tgz
  * normal-2_inhibition.tgz
  * normal-3_inhibition.tgz
  * normal-4_inhibition.tgz
  * test_inhibition.tgz
  * valid_inhibition.tgz
1. Original-variations
  1. test
    * fluorescence_test_noise?_ls?_rate?.txt.gz (27 files like this one)
  1. valid
    * fluorescence_valid_noise?_ls?_rate?.txt.gz (27 files like this one)
1. Hidden-neurons
  * normal-3_kill.tar.gz
  * normal-4_kill.tar.gz
1. Small
  1. low-bursting
    * N100_CC0?_?_?.tar (24 files like this one)
  1. normal-bursting
    * N100_CC0?_?_?.tar (24 files like this one)
  1. high-bursting
    * N100_CC0?_?_?.tar (24 files like this one)

Additional notes
================

Training
--------
You should not need to retrain your algorithms for these datasets. 

However if you want to also retrain, you should let us know in which networks you retrained. With the following constraints:
1. For the 'inhibition' and 'hidden neurons' datasets do not train on networks normal-3 and normal-4, we will use those to validate the results. Although there are no index to kill in the 'hidden neurons' dataset for normal-1 and normal-2, you can kill them yourself if you want to train in those networks.
2. The 'original variations' dataset has no files available for training.
3. For the small datasets only use for training networks 495 to 500.

Questions
---------
If you have specific questions about the datasets, please ask them directly to me at orlandi(at)ecm.ub.edu

Data mirrors
------------
We are sorting some mirrors for the datasets, since current hosting might be unreliable. If you think you can host the datasets, please let us know! Full dataset should be around 130GB.



