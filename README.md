# routineCameraCalibration

Why calibrate your camera? If you want to compare the intensities of images recorded on different instruments or with different acquisition settings (e.g. different em gain), you need to convert the pixel values from analog-to-digital (ADU) units to photons:

<p align="center">
intensity (photons) = [intensity (ADU counts) - offset]/gain
</p>

Any analysis that takes photon statistics into account (e.g. many localisation algorithms for SMLM) will ask you for the camera gain and offset to do this conversion. The offset and gain can be measured by doing a camera calibration which involves recording uniform intensity images at different brightnesses. You can also look these values up in the *birth certificate* of your camera, but the gain of EMCCD cameras can drift over time so it's recommended to regularly calibrate your camera. Unlike EMCCD cameras, CMOS cameras have a pixel-dependent offset, variance and gain. Some localisation algorithms ([Huang *et al.*](https://doi.org/10.1038/Nmeth.2488), [Lin *et al.*](https://doi.org/10.1364/OE.25.011701)) use those pixel-dependent offset, variance and gain maps and you can measure them by calibrating your camera.

## Instructions for quick routine camera calibration: ##
Calibrating your camera is very easy when your microscope has a brightfield lamp with an intensity that you can vary. Follow the following steps:
* After recording your data, take off your sample and replace it with a piece of paper or a lens tissue. Don't change the settings of your camera, you want to use the same gain, roi etc that you used for recording your sample. The purpose of placing a piece of paper or lens tissue as a sample is to get an approximately uniform intensity in the image. 
* Acquire 100 dark frames (all lights and lasers off) and call the stack 'dark.tif'
* Turn the brightfield lamp on and acquire 100 frames at a low intensity. Call the stack 'int1.tif'.
* Repeat the previous step but at a higher intensity of the brightfield lamp. Call the stacks 'int2.tif', 'int3.tif' and 'int4.tif', where you increase the intensity each time.


## Instructions for analysing the data: ##

* Double-check that you used the correct filenaming convention as explained in the instructions above. All the data for the camera calibration should be in one folder.
* Open the script *calibrateCamera.m* in MATLAB and fill in the parameters: the path to the folder containing the stacks and part of the name of the dark and bright images.
* Run the script. It will create a new folder inside the folder that contains the calibration data and save
   * a file 'results.mat' which you can load in matlab and contains a structure with 6 elements: the average offset, variance and gain, and the pixel-dependent offset, variance and gain maps
   * 3 matlab figures showing the pixel-dependent maps and corresponding histograms of their pixel values
   * a matlab figure showing the data and linear fit used to estimate the gain

The estimation of the offset, variance and gain was implemented as described in the supplementary material of [Huang *et al.*](https://doi.org/10.1038/Nmeth.2488)


## Troubleshooting and tips: ##

**Tip 1:** The more frames you measure, the better. If you just want an average offset, variance and gain, 100 frames are definitely enough. If you have an sCMOS camera and want to get pixel-dependet gain, offset and variance maps, you should take more than 100 frames for each stack. Aim for something on the order of 10k-60k frames per intensity level (these numbers come from the methods section of [Huang *et al.*](https://doi.org/10.1038/Nmeth.2488) and [Diekmann *et al.*](https://doi.org/10.1038/s41598-017-14762-6)). I know that's a lot of data. When recording these long stacks (especially when you are calibrating the full chip) MicroManager or whatever software you are using for image acquisition might start chopping up the stacks into 'dark_0.tif', 'dark_1.tif', 'dark_2.tif' etc. The code will automatically group these stacks. The code also never reads a whole stack into memory, only a single frame at a time.

**Tip 2:** The more different intensities you measure, the better your estimate of the gain will be. In principle 2 are enough, but to have more confidence in the results, use at least 4 levels. Ideally, 1) the lowest intensity level has pixel values close to the dark image, 2) the highest intensity level has pixel values close to the maximum pixel values you see in your data and 3) the other intensity levels are more or less equally spaced between the lowest and highest intensity levels.

**Tip 3:** If you don't have a brightfield lamp on your microscope with adjustable brightness, you can use another lamp and layer lens tissues to decrease the intensity in steps. You can also use your laser as a light source if you have a fluorescent slide (e.g. from [Chroma](https://www.chroma.com/products/accessories/92001-autofluorescent-plastic-slides)) instead of a piece of paper. The latter works best when your illumination profile is flat over your roi.
