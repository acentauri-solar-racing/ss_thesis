function [increaseSoC] = chargeEstimator(initialTime, finalTime)
% Return the increase in state-of-charge using "Simple Sandia
% open-rack model" for the solar panels. Battery and PV parameters as wellirradiance
% as irradiance1D data are uploaded
% 
% Input: initialTime as datetime
%        finalTime as datetime
%       For both, valid dates range from 01.10.20 to 31.10.20
%       Additionally, only the minutes are important: seconds must be zero
% 
% Output: increaseSoC as double

persistent param;
persistent weather;

if isempty(param)
    [param, weather, ~, ~] = loadData();
end % if

%% Find limits of integration
horizon = weather.irradiance1D.time >= initialTime & weather.irradiance1D.time <= finalTime;
horizonTime = weather.irradiance1D.time(horizon);
horizonG = weather.irradiance1D.Gtotal(horizon);

%% PV power conversion to energy
tempAmb = 30; %°
WS = 0; %m/s

PVpower = param.pv.area .* horizonG .* param.pv.eff .* param.pv.loss.total;
PVpower_simple_Sandia_openRack = PVpower .* (1 + param.pv.powerCoeff .* (cellTemperatureSandia(horizonG, tempAmb, WS, "glass-cell-polymer", "open rack") - param.pv.tempSTC));

totEnergyCharge = trapz(seconds(horizonTime - horizonTime(1)), PVpower_simple_Sandia_openRack);

increaseSoC = totEnergyCharge ./ param.battery.totNum ./ param.battery.Emax;
end % fct