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


Small datasets
--------------
TBC