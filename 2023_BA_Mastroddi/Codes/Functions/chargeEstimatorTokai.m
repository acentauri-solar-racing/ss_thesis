function [increaseSoCTokai] = chargeEstimatorTokai(initialTime, finalTime)
% Return the increase in state-of-charge using "Simple Sandia
% open-rack model" for the solar panels. Battery and PV parameters as well
% as irradiance data are uploaded. The irradiance is an approximation taken
% from Tokai
% 
% Input: initialTime as datetime
%        finalTime as datetime
%       For both, valid dates range from 19.10.19 at 07:08:20 to 18:24:12
% 
% Output: increaseSoC as double

persistent param;
persistent weather;

if isempty(param)
    [param, weather, ~, ~] = loadData();
end % if

%% Find limits of integration
horizon = weather.irradiance1DTokai.time >= initialTime & weather.irradiance1DTokai.time <= finalTime;
horizonTime = weather.irradiance1DTokai.time(horizon);
horizonG = weather.irradiance1DTokai.Gtotal(horizon);

%% PV power conversion to energy
tempAmb = 30; %°
WS = 0; %m/s

PVpower = param.pv.area .* horizonG .* param.pv.eff .* param.pv.loss.total;
PVpower_simple_Sandia_openRack = PVpower .* (1 + param.pv.powerCoeff .* (cellTemperatureSandia(horizonG, tempAmb, WS, "glass-cell-polymer", "open rack") - param.pv.tempSTC));

totEnergyCharge = trapz(seconds(horizonTime - horizonTime(1)), PVpower_simple_Sandia_openRack);

increaseSoCTokai = totEnergyCharge ./ param.battery.totNum ./ param.battery.Emax;
end % fct