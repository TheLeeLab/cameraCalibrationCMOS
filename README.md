# routineCameraCalibration
This repository contains MATLAB code and instructions for performing a routine camera calibration.

**Why calibrate your camera?** If you want to convert the pixel values of your data from 'counts' to 'photons' or e.g. use a localisation algorithm that requires you to know the camera offset and gain, you need to calibrate your camera. You can also look these values up in the *birth certificate* of your camera, but the gain of EMCCD cameras can drift over time so it's recommended to regularly calibrate your camera. Unlike EMCCD cameras, CMOS cameras have a pixel-dependent offset, variance and gain. Some localisation algorithms ([Huang et al.](https://doi.org/10.1038/Nmeth.2488), [Lin et al.](https://doi.org/10.1364/OE.25.011701)). use those pixel-dependent offset, variance and gain maps and you can measure them by calibrating your camera.

## Instructions for quick routine camera calibration: ##
Calibrating your camera is very easy when your microscope has a brightfield lamp with an intensity that you can varry. Follow the following steps:
* After recording your data, take off your sample and replace it with a piece of paper or a lens tissue. Don't change the settings of your camera, you want to use the same gain, roi etc that you used for recording your sample. The purpose of placing a piece of paper or lens tissue as a sample is to get an approximately uniform intensity in the image. 
* Acquire 100 dark frames (all lights and lasers off) and call the stack 'dark.tif'
* Turn the brightfield lamp on and acquire 100 frames at a low intensity. Call the stack 'int1.tif'.
* Repeat the previous step but at a higher intensity of the brightfield lamp. Call the stacks 'int2.tif', 'int3.tif' and 'int4.tif', where you increase the intensity each time.


## Instructions for analysing the data: ##

* Double-check that you used the correct filenaming convention as explained in the instructions above. All the data for the camera caibration should be in one folder.
* Open the script *calibrateCamera.m* in MATLAB and run it. A window will pop up asking you to navigate to the folder.
* The script will create a new folder inside the folder that contains the calibration data. It contains the following files:
   * a text file with the estimated average gain and offset (also called bias)
   * gain.tif, variance.tif and offset.tif maps
   * regression.png a figure of the regression to determine the gain. It should be a nice linear fit.


## Troubleshooting and tips: ##

**Tip 1:** The more different intensities you measure, the better. In principle 2 are enough, but to have more confidence in the results, use at least 4 levels. Ideally, 1) the lowest intensity level has pixel values close to the dark image, 2) the highest intensity level has pixel values close to the maximum pixel values you see in your data and 3) the other intensity levels are more or less equally spaced between the lowest and highest intensity levels.

**Tip 2:** If you don't have brightfield lamp on your microscope with adjustable intensity, you can use another lamp and layer lens tissues to decrease the intensity in steps. You can also use your laser as a light source if you have a fluorescent slide (e.g. those from Chroma) instead of a piece of paper. The latter works best when your illumination profile is flat over your roi.

**Tip 3:** If you have an sCMOS camera and want to get pixel-dependet gain, offset and variance maps, you should take more than 100 frames for each stack. Aim for something on the order of 10k-60k frames per intensity level (these numbers come from these papers: [Huang et al.](https://doi.org/10.1038/Nmeth.2488) and [Diekmann et al.](https://doi.org/10.1038/s41598-017-14762-6)). I know that's a lot of data and MicroManager or whatever software you are using for image acquisition might start chopping up the stacks into 'dark_0.tif', 'dark_1.tif', 'dark_2.tif' etc. The code will automatically group these stacks. The code also never reads a whole stack into memory, only a single frame at a time.
