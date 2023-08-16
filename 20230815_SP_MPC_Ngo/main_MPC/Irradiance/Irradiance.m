clearvars;
close all;

savingDir = uigetdir(); %choose the Irradiance folder
cd(savingDir);

irradiance = struct();

%% read irradiance from Australia
data = readmatrix("AliceSprings2020October.xlsx");
irradiance.time = datetime(data(:,3), data(:,4), data(:,5), data(:,6), data(:,7),0); %timeseries
irradiance.Gtotal = data(:,9); %W/m^2

%% sunrise and sunset precalculation - October
for day = 1:1:31
    [~, irradiance.sunrise.datetime(day,1), irradiance.sunset.datetime(day,1), ~] = sunRiseSetEstimator(day);
    irradiance.sunrise.vec(day,1) = 2020;
    irradiance.sunset.vec(day,1) = 2020;
    irradiance.sunrise.vec(day,2) = 10;
    irradiance.sunset.vec(day,2) = 10;
    irradiance.sunrise.vec(day,3) = day;
    irradiance.sunset.vec(day,3) = day;
    irradiance.sunrise.vec(day,4) = hour(irradiance.sunrise.datetime(day,1));
    irradiance.sunset.vec(day,4) = hour(irradiance.sunset.datetime(day,1));
    irradiance.sunrise.vec(day,5) = minute(irradiance.sunrise.datetime(day,1));
    irradiance.sunset.vec(day,5) = minute(irradiance.sunset.datetime(day,1));
    irradiance.sunrise.vec(day,6) = 0;
    irradiance.sunset.vec(day,6) = 0;
end % for

%15 minutes before sunrise
irradiance.bef15minSunrise.datetime = irradiance.sunrise.datetime - minutes(15);
irradiance.bef15minSunrise.vec = irradiance.sunrise.vec;
irradiance.bef15minSunrise.vec(:,4) = hour(irradiance.bef15minSunrise.datetime);
irradiance.bef15minSunrise.vec(:,5) = minute(irradiance.bef15minSunrise.datetime);

%15 min after sunset
irradiance.aft15minSunset.datetime = irradiance.sunset.datetime + minutes(15);
irradiance.aft15minSunset.vec = irradiance.sunset.vec;
irradiance.aft15minSunset.vec(:,4) = hour(irradiance.aft15minSunset.datetime);
irradiance.aft15minSunset.vec(:,5) = minute(irradiance.aft15minSunset.datetime);

%% save data
save("WeatherIrradiance", "irradiance")
