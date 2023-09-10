function [weatherSim] = weatherSimFullRace(interestDay, enhanceFactor, raceDays, plotIsRequested)
% Prepare the weather data of irradiance, wind and temperature for the
% full simulation of 4 consecutive days, namely by converting all the times
% in seconds and chop the days, so that the nights are taken out.
%
% Input: day of interest as datetime;
%        enhance factor as double: when charging in the morning and in the
%        afternoon, the solar panels are inclined, resulting in more energy
%        convertible. Good values between 1 and 3;
%        number of racing days as double: 5 to have a complete simulation
%
% Output: weatherSim as a struct with irradiance, irradiance enhanced, wind
%         temperature data.

%% First day
%Start at 10:00 but ends at 15 min after sunset
[weatherSim] = weather2weatherSim(interestDay, enhanceFactor, "10", "15minSunset", plotIsRequested);
weatherSim.irradiance.dayNumSec = repelem(1,length(weatherSim.irradiance.timeSec),1);


%% Rest of race days
%Start 15 min before sunrise and ends 15 min after sunset
for i = 2:raceDays
    interestDayLoop = datetime(year(interestDay), month(interestDay), day(interestDay)+i-1);

    [tmpLoop] = weather2weatherSim(interestDayLoop, enhanceFactor, "15minSunrise", "15minSunset", false);
    %construct extended irradiance vector
    weatherSim.irradiance.timeSec = [weatherSim.irradiance.timeSec; tmpLoop.irradiance.timeSec + weatherSim.irradiance.timeSec(end)];
    weatherSim.irradiance.GtotalSec = [weatherSim.irradiance.GtotalSec; tmpLoop.irradiance.GtotalSec];
    weatherSim.irradiance.driving_8_17_Sec = [weatherSim.irradiance.driving_8_17_Sec; tmpLoop.irradiance.driving_8_17_Sec];
    weatherSim.irradiance.dayNumSec = [weatherSim.irradiance.dayNumSec; repelem(i,length(tmpLoop.irradiance.timeSec),1)];

    %construct extended temperature matrix
    weatherSim.temperature.timeSec = [weatherSim.temperature.timeSec; tmpLoop.temperature.timeSec + weatherSim.temperature.timeSec(end)];
    weatherSim.temperature.tempMean = [weatherSim.temperature.tempMean, tmpLoop.temperature.tempMean];
    
    %construct extended wind matrix
    weatherSim.wind.timeSec = [weatherSim.wind.timeSec; tmpLoop.wind.timeSec + weatherSim.wind.timeSec(end)];
    weatherSim.wind.windMean = [weatherSim.wind.windMean, tmpLoop.wind.windMean];
    weatherSim.wind.frontWind = [weatherSim.wind.frontWind, tmpLoop.wind.frontWind];
    weatherSim.wind.sideWind = [weatherSim.wind.sideWind, tmpLoop.wind.sideWind];
end % for

weatherSim.irradiance.stopTimeSec = find(diff(weatherSim.irradiance.driving_8_17_Sec)==-1);

end % fct