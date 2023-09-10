clearvars;
close all;

cd("C:\Users\giaco\Git_Repositories\Bachelor_Arbeit\Codes\Data\Weather\Irradiance 1D");

irradiance1D = struct();
irradiance1DTokai = struct();

%% read irradiance from Australia
data = readmatrix("AliceSprings2020October.xlsx");
irradiance1D.time = datetime(data(:,3), data(:,4), data(:,5), data(:,6), data(:,7),0); %timeseries
irradiance1D.Gtotal = data(:,9); %W/m^2

%% sunrise and sunset precalculation - October
for day = 1:1:31
    [~, irradiance1D.sunrise.datetime(day,1), irradiance1D.sunset.datetime(day,1), ~] = sunRiseSetEstimator(day);
    irradiance1D.sunrise.vec(day,1) = 2020;
    irradiance1D.sunset.vec(day,1) = 2020;
    irradiance1D.sunrise.vec(day,2) = 10;
    irradiance1D.sunset.vec(day,2) = 10;
    irradiance1D.sunrise.vec(day,3) = day;
    irradiance1D.sunset.vec(day,3) = day;
    irradiance1D.sunrise.vec(day,4) = hour(irradiance1D.sunrise.datetime(day,1));
    irradiance1D.sunset.vec(day,4) = hour(irradiance1D.sunset.datetime(day,1));
    irradiance1D.sunrise.vec(day,5) = minute(irradiance1D.sunrise.datetime(day,1));
    irradiance1D.sunset.vec(day,5) = minute(irradiance1D.sunset.datetime(day,1));
    irradiance1D.sunrise.vec(day,6) = 0;
    irradiance1D.sunset.vec(day,6) = 0;
end % for

%15 minutes before sunrise
irradiance1D.bef15minSunrise.datetime = irradiance1D.sunrise.datetime - minutes(15);
irradiance1D.bef15minSunrise.vec = irradiance1D.sunrise.vec;
irradiance1D.bef15minSunrise.vec(:,4) = hour(irradiance1D.bef15minSunrise.datetime);
irradiance1D.bef15minSunrise.vec(:,5) = minute(irradiance1D.bef15minSunrise.datetime);

%15 min after sunset
irradiance1D.aft15minSunset.datetime = irradiance1D.sunset.datetime + minutes(15);
irradiance1D.aft15minSunset.vec = irradiance1D.sunset.vec;
irradiance1D.aft15minSunset.vec(:,4) = hour(irradiance1D.aft15minSunset.datetime);
irradiance1D.aft15minSunset.vec(:,5) = minute(irradiance1D.aft15minSunset.datetime);

%% read irradiance from Tokai
irrTokai = readmatrix("IrradianceTokai_cleaned.xlsx");
tmpTime = irrTokai(:,1); %h as double
irradiance1DTokai.Gtotal = irrTokai(:,2); %W/m^2

%conversion to time
floorHoursWTT = floor(tmpTime); %extract hours
minDiff = tmpTime - floorHoursWTT;
minDiff_time = minDiff * 60;
floorMinutesWTT = floor(minDiff_time); % extract minutes
secDiff = minDiff_time - floorMinutesWTT;
secDiff_time = secDiff * 60;
floorSecondsWTT = floor(secDiff_time); %extract seconds and forget smaller values

irradiance1DTokai.time = datetime(2019,10,19,floorHoursWTT,floorMinutesWTT,floorSecondsWTT);

%% save data
save("WeatherIrradiance1D", "irradiance1D", "irradiance1DTokai")
