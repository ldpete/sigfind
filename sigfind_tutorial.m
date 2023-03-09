%% Liam Peterson | 5/18/2020 | ldpete@umd.edu
% sigfind.m tutorial

%% Make Sure to Clear your Workspace Before Running Your Code 

clear all; close all;

%% Run the Function
[signal, background, data, LB, UB]=sigfind('olivine1.csv', 300);
% Inputs:
%   - file_name.csv = the name of the data file, in this case
%   "olivine1.csv"
%   - t_um = thickness of the sample in microns
% Outputs:
%   - signal = n-by-2 matrix that contains the x-y coordinates of the
%   region containing the major peaks/peaks of interest
%   - background = n-by-2 matrix that contains the x-y coordinates of the
%   region not containing the major peaks/peaks of interest and any points
%   where the signal meets the baseline
%   - data = n-by-2 matrix containing x-y coordinates of the input data,
%   the y-coordinate (absorbance) is corrected to a thickness of 1 cm using
%   the input "t_um"
%   - LB = Lower Bound of the signal region
%   - UB = Upper Bound of the signal region

%% Find the Baseline and Baseline Subtracted Absorbance using pchip
bline=pchip(background(:,1),background(:,2),data(:,1)); % baseline interpolated from the background; for information on the pchip function, please examine the MATLAB Documentation: https://www.mathworks.com/help/matlab/ref/pchip.html?s_tid=mwa_osa_a
sub_abs=data(:,2)-bline; % baseline subtracted absorbance

%% Calculate the Area (Integrated Absorbance)
dx=abs(max(data(LB:UB,1)-min(data(LB:UB,1)))); % Finds the change in wavenumber across the portion of the spectra defined by LB and UB
dy=mean(sub_abs(LB:UB,1)); % Finds the change in absorbance over the portion of the spectra defined by LB and UB
area=dx*dy; % calculates the integrated absorbance over the region of the spectra defined by LB and UB
area=(0.005*10)/2.7;
%% Calculate the Concentration of Water Using the Bell and Withers Corrections
% NOTE: these create 1x2 matrices for the Withers and Bell corrections
% where the first column is the area and the second column is the error
withers_ol(1,1)=area*0.119; % calculates the water concentration using the correction of Withers et al. 2012 for olivine
withers_ol(1,2)=((0.006*area)^2+(0*0.119)^2)^0.5; % error propagation of absorption coefficient to concentration calculation; analytical error is not considered as it is much smaller than the error introduced by the absorption coefficient
bell_ol(1,1)=area*0.188; % calculates the water concentration using the correction of Bell et al. 2003 for olivine
bell_ol(1,2)=((0.012*area)^2)^0.5; % error propagation from the absorption coefficient

%% Plotting

% Plots the Data, Baseline, and Bounds
figure(1); hold on;
plot(data(:,1),data(:,2)); % plots the data
plot(data(:,1),bline); % plots the baseline
scatter(data(LB,1),data(LB,2)); % plots the lower bound
scatter(data(UB,1),data(UB,2)); % plots the upper bound
xlim([3000 4000]);
legend('Data','Pchip');
set(gca,'xdir','reverse');
hold off;

% Plots the Data and Baseline Subtracted Data
figure(2); hold on;
plot(data(:,1),data(:,2)); % plots the data
plot(data(:,1),sub_abs); % plots the baseline subtracted data
xlim([3000 4000]);
legend('Data','sub__abs');
set(gca,'xdir','reverse');
hold off;

