% -------------------------------------------------------------------------
%  Name: Continuous_Raman_Acquisition.m
%  Version: 1.0
%  Environment: Matlab 2017b
%  Date: 24/05/2019
%  Author: Conor Horgan
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
%  1. Initialise Spectrometer (QEPro, OceanOptics)
% -------------------------------------------------------------------------

% Suppress warnings
warning('off', 'MATLAB:MKDIR:DirectoryExists');
warning('off', 'MATLAB:hg:AutoSoftwareOpenGL');
warning('off', 'MATLAB:Java:DuplicateClass');

% Connect to Ocean Optics spectrometer and initialise acquisition settings
try
    javaaddpath('C:\Program Files\Ocean Optics\OmniDriver\OOI_HOME\OmniDriver.jar');
    import('com.oceanoptics.omnidriver.api.wrapper.Wrapper');
    wrapper = Wrapper();
    NoOfDevices = wrapper.openAllSpectrometers();

    Raman_Acquisition_Time = 1;
    wrapper.setIntegrationTime(0,1000000*Raman_Acquisition_Time);
    wrapper.setScansToAverage(0,1);
catch
    errordlg('Problem connecting to Ocean Optics spectrometer. Check spectrometer is correctly connected and restart MATLAB', 'Spectrometer Connection Error');
end

% -------------------------------------------------------------------------
%  2. Data Acquisition (Requires PLS_Toolbox, Eigenvector Research)
% -------------------------------------------------------------------------

% Get current directory and store for saving data
Current_Path = mfilename('fullpath');
[File_Path,name,ext] = fileparts(Current_Path);

% Get current date as a string for saving data
FormatOut = 'yyyy-mm-dd';
Datestring = datestr(now,FormatOut);

% Initialise variable for saving spectral data
Raw_Spectra = [];

%Define the desired number of acquisitions in seconds
Num_Acquisitions = 5;

% Acquire Spectra
for i = 1:Num_Acquisitions
    
    % Get current spectrometer axis (Wavelengths) and data (Spectrum)
    Collected_Wavelengths = wrapper.getWavelengths(0);
    Collected_Spectrum = wrapper.getSpectrum(0);
    
    % Add current spectral data to matrix of time series spectral data
    Raw_Spectra = [Raw_Spectra; Collected_Spectrum'];
    Axis = Collected_Wavelengths;
    
end

% Create save directory if it does not exist
Save_Directory = strcat(File_Path, '\', Datestring);
if ~exist(Save_Directory, 'dir')
    mkdir(Save_Directory)
end

% Save raw spectra
Raw_Spectra_Save_Name = strcat(Save_Directory, '\' , 'Raw_Spectra');
save(Raw_Spectra_Save_Name,'Raw_Spectra');

% Save x-axis
Axis_Save_Name = strcat(Save_Directory, '\' , 'Axis');
save(Axis_Save_Name,'Axis');

% -------------------------------------------------------------------------
%  2. Data Processing
% -------------------------------------------------------------------------

% Initialise filtering parameters
Lambda = 100000;
Filter_Options = struct('filter','whittaker');

% Crop spectra at each end to remove spectrometer artefacts
Processed_Spectra_Crop = Raw_Spectra(:,10:end-10);

% Subtract background from spectra
Processed_Spectra_SubBG = wlsbaseline(double(Processed_Spectra_Crop),Lambda,Filter_Options);

% Filter spectra
Processed_Spectra_Filt = savgol(Processed_Spectra_SubBG,3,0,1);

% Normalise spectra
Processed_Spectra_Norm = normaliz(Processed_Spectra_Filt,0,1);
Processed_Spectra = Processed_Spectra_Norm;

% Save processed spectra
Processed_Spectra_Save_Name = strcat(Save_Directory, '\' , 'Processed_Spectra');
save(Processed_Spectra_Save_Name,'Processed_Spectra');

% Save cropped x-axis
Axis_Crop = Axis(10:end-10);
Axis_Save_Name = strcat(Save_Directory, '\' , 'Axis_Crop');
save(Axis_Save_Name,'Axis_Crop');
