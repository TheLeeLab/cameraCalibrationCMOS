%% simulateCameraCalibrationData.m
% 
% This script simulates camera calibration data to validate the calibration
% script on.

clear all; close all; clc

%% ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% Parameters

% path to the folder containing the calibration stacks
outputdir = 'testdata';

% camera parameters
fov = 500; % size square field-of-view in pixels 
cameraParam.cameraType     = 'sCMOS';
cameraParam.QE             = 0.75; % quantum efficiency of the sensor at average wavelength of the signal (photoelectrons/photon)
cameraParam.sigmaReadNoise = 2.1; % read noise in photoelectrons (e.g. root mean square read noise from manufacturer)
cameraParam.e_adu          = 0.5; % analog-to-digital conversion factor (photoelectrons/analog-to-digital unit)
cameraParam.offset         = 100; % camera offset, bias or baseline (ADU, analog-to-digital unit)
cameraParam.bit            = 12; % resolution of the analog-to-digital converter (saturation = 2^bit - 1)

photons = linspace(50,1000,5);
framesPerCondition = 500;

% name of the dark stack without extension or suffix (e.g. 'dark' if the
% is called dark.tif, or if the are multiple substacks dark_0.tif, dark_1.tif, dark_2.tif ...)
dark_id   = 'dark';

% list of the names of the bright stacks without extension or suffix (like
% above), ordered from dimmest to brightest
power_ids = {'int1','int2','int3','int4','int5'};

%% ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

photons = [0 photons]; % add zero for the dark stack
for i=1:numel(photons)
    
    if i==1 % dark frames first
        fprintf('Simulating dark frames... ')
        t = Tiff(fullfile(outputdir,strcat(dark_id,'.tif')),'w'); % set up tif for writing
        tagstruct.ImageLength = fov; % image height
        tagstruct.ImageWidth  = fov; % image width
        tagstruct.Photometric = Tiff.Photometric.MinIsBlack; % https://de.mathworks.com/help/matlab/ref/tiff.html
        tagstruct.BitsPerSample = 16;
        tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
        tagstruct.Software = 'MATLAB';
        frame = zeros(fov,fov);
        for j=1:framesPerCondition
            frameWithNoise = noiseModelsCMOS(frame,cameraParam);
            setTag(t,tagstruct)
            write(t,squeeze(uint16(frameWithNoise)));
            if j < framesPerCondition; writeDirectory(t); end
        end
        close(t)
        fprintf('done!\n')
    else
        fprintf('Simulating %s frames... ',power_ids{i-1})
        t = Tiff(fullfile(outputdir,strcat(power_ids{i-1},'.tif')),'w'); % set up tif for writing
        tagstruct.ImageLength = fov; % image height
        tagstruct.ImageWidth  = fov; % image width
        tagstruct.Photometric = Tiff.Photometric.MinIsBlack; % https://de.mathworks.com/help/matlab/ref/tiff.html
        tagstruct.BitsPerSample = 16;
        tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
        tagstruct.Software = 'MATLAB';
        frame = photons(i-1)*ones(fov,fov);
        for j=1:framesPerCondition
            frameWithNoise = noiseModelsCMOS(frame,cameraParam);
            setTag(t,tagstruct)
            write(t,squeeze(uint16(frameWithNoise)));
            if j < framesPerCondition; writeDirectory(t); end
        end
        close(t)
        fprintf('done!\n')

    end
    
end

fprintf('Results were saved in: %s\n',outputdir)



%% ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



function [] = writeTifImage(image,path)
t = Tiff(path,'w');
tagstruct.ImageLength = size(image,1);
tagstruct.ImageWidth = size(image,2);
tagstruct.Compression = Tiff.Compression.None;
tagstruct.SampleFormat = Tiff.SampleFormat.IEEEFP;
tagstruct.Photometric = Tiff.Photometric.LinearRaw;
tagstruct.BitsPerSample = 32;
tagstruct.SamplesPerPixel = 1;
tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
t.setTag(tagstruct);
t.write(single(image));
t.close();
end

function img = cameraNoiseModel(img,cameraParam,photons,normalisation)
% CAMERANOISEMODEL
switch cameraParam.cameraType
    case 'sCMOS'
        img = photons*img/normalisation;
        img = noiseModelsCMOS(img,cameraParam);
    case 'EMCCD'
        img = photons*img/normalisation;
        img = noiseModelEMCCD(img,cameraParam);
    otherwise
        fprintf('Unexpted value for property "cameraType" in class "Acquisition".\n')
end
end

function img = noiseModelsCMOS(img,cameraParam)
% NOISEMODELSCMOS Model detection process by a sCMOS camera
%   img: image in units of photons
%   cameraParam.QE: quantum efficiency of the sensor at average wavelength of the signal (electrons/photon)
%   cameraParam.offset: camera offset, bias or baseline (ADU, analog-to-digital unit)
%   cameraParam.e_adu: analog-to-digital conversion factor (electrons per analog-to-digital unit)
%   cameraParam.sigmaReadNoise: read noise in electrons (root mean square read noise)
%   cameraParam.bit: resolution of the analog-to-digital converter (saturation = 2^bit - 1)
%
%   Example parameters of the Prime 95B from Photometrics
%   QE = 0.95, offset = 100, e_adu = 1, sigmaReadNoise = 1.3
%
% returns: img: original image with detection noise added

QE             = cameraParam.QE;
sigmaReadNoise = cameraParam.sigmaReadNoise;
e_adu          = cameraParam.e_adu;
offset         = cameraParam.offset;
bit            = cameraParam.bit;

photoElectrons = poissrnd(QE*img) + normrnd(0,sigmaReadNoise,size(img));
img = floor(photoElectrons/e_adu) + offset;
saturation = 2^bit - 1;
img(img > saturation) = saturation;
end

function img = noiseModelEMCCD(img,cameraParam)
% NOISEMODELEMCCD Model detection process by an EMCCD camera
%   img: image in units of photons
%   cameraParam.QE: quantum efficiency of the sensor at average wavelength of the signal (electrons/photon)
%   cameraParam.offset: camera offset, bias or baseline (ADU, analog-to-digital unit)
%   cameraParam.e_adu: analog-to-digital conversion factor (electrons per analog-to-digital unit)
%   cameraParam.sigmaReadNoise: read noise in electrons (root mean square read noise)
%   cameraParam.emgain: electron-multiplying gain
%   cameraParam.c: spurious charge (clock-induced charge only, dark counts negligible)
%   cameraParam.bit: resolution of the analog-to-digital converter (saturation = 2^bit - 1)
%
%   Example parameters of the Evolve Delta 512 from Photometrics
%   QE = 0.9, offset = 100, e_adu = 45, sigmaReadNoise = 74.4,emgain = 300, c = 0.002
%
% returns: img: original image with detection noise added

QE             = cameraParam.QE;
sigmaReadNoise = cameraParam.sigmaReadNoise;
e_adu          = cameraParam.e_adu;
offset         = cameraParam.offset;
emgain         = cameraParam.emgain;
c              = cameraParam.c;
bit            = cameraParam.bit;

photoElectrons = poissrnd(QE*img + c);
photoElectrons = gamrnd(photoElectrons,emgain,size(img,1),size(img,2)) + normrnd(0,sigmaReadNoise,size(img));
img = floor(photoElectrons/e_adu) + offset;
saturation = 2^bit - 1;
img(img > saturation) = saturation;
end