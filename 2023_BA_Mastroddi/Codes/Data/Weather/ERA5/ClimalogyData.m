clearvars;
close all;

cd("C:\Users\giaco\Git_Repositories\Bachelor_Arbeit\Codes\Data\Weather\ERA5\");
route = load('RouteData.mat').route;

temperature = struct();
wind = struct();
irradiance = struct();

temperature.tempMean = [];
temperature.lati = [];
temperature.long = [];
temperature.dist = [];
temperature.time = [];
% temperature.datetime = NaT;

wind.windMean = [];
wind.sideWind = [];
wind.frontWind = [];
wind.lati = [];
wind.long = [];
wind.dist = [];
wind.time = [];

irradiance.irradianceMean = [];
irradiance.lati = [];
irradiance.long = [];
irradiance.dist = [];
irradiance.time = [];

additionalData = struct(); %useful for calculation
additionalData.windDir = [];

%% read weather data from institut
numData = 1;
directory = dir;

for k = 1:length(dir)
    dirNameSplitted = strsplit(directory(k).name, '_');

    if contains(directory(k).name, "ERA5")
        tmpData = readmatrix(directory(k).name);
        tmpData(1,:) = []; %remove first row

        %save time read from data
        time = strsplit(char(dirNameSplitted(4)), '.');
        time = strsplit(char(time(1)), '-');
        temperature.time(numData,1) = str2double(cell2mat(time(1)));
        temperature.time(numData,2) = str2double(cell2mat(time(2)));
        temperature.timeDur(numData,1) = hours(temperature.time(numData,1)) + minutes(temperature.time(numData,2));

        %save interesting data
        temperature.lati(:,1) = tmpData(:,2); %one column is enough
        temperature.long(:,1) = tmpData(:,3); %one column is enough
        wind.windMean(:,numData) = tmpData(:,4);
        wind.windMax(:,numData) = tmpData(:,6);
        additionalData.windDir(:,numData) = tmpData(:,7);
        temperature.tempMean(:,numData) = tmpData(:,9);
        temperature.temp90(:,numData) = tmpData(:,10);
        temperature.temp10(:,numData) = tmpData(:,11);
        irradiance.irradianceMean(:,numData) = tmpData(:,12) / 3600; %radiation in J/m^2 converted to W/m^2 with hourly approximation
        irradiance.irradiance90(:,numData) = tmpData(:,13) / 3600; %radiation in J/m^2 converted to W/m^2 with hourly approximation
        irradiance.irradiance10(:,numData) = tmpData(:,14) / 3600; %radiation in J/m^2 converted to W/m^2 with hourly approximation
        numData = numData + 1; %found data, saved, ready for next column
    end % if
end % for

wind.lati = temperature.lati;
wind.long = temperature.long;
wind.time = temperature.time;
wind.timeDur = temperature.timeDur;

irradiance.lati = temperature.lati;
irradiance.long = temperature.long;
irradiance.time = temperature.time;
irradiance.timeDur = temperature.timeDur;

%% lati/long conversion to vector
additionalData.arclen = [];
additionalData.az = [];

for k = 1:length(temperature.lati(:,1))-1
    [additionalData.arclen(k,1), additionalData.az(k,1)] = distance(temperature.lati(k,1), temperature.long(k,1), temperature.lati(k+1,1), temperature.long(k+1,1));
end % for

%conversion to meter from degree
additionalData.arclen = deg2rad(additionalData.arclen) * earthRadius; %m
additionalData.dirVert = cos(deg2rad(additionalData.az));
additionalData.dirHori = sin(deg2rad(additionalData.az));

%% wind speed conversion to vector
additionalData.windVert = cos(deg2rad(additionalData.windDir));
additionalData.windHori = sin(deg2rad(additionalData.windDir));

%% side and front wind calculation
additionalData.theta = NaN(size(additionalData.az));
additionalData.windAttackOnRightSide = false(size(additionalData.az)); %boolean

for i = 1:numData-1
    additionalData.theta(:,i) = acos(additionalData.dirVert .* additionalData.windVert(1:end-1,i) + additionalData.dirHori .* additionalData.windHori(1:end-1,i)); %minimum angle from drivingDir to windDir
%     tmp.theta(:,i) = abs(tmp.az - tmp.windDir(1:end-1,i)); %angle difference
    additionalData.windAttackOnRightSide(:,i) = additionalData.az < additionalData.windDir(1:end-1,i);
end % for

additionalData.windAttackOnLeftSide = ~additionalData.windAttackOnRightSide;
additionalData.beta = additionalData.theta .* additionalData.windAttackOnLeftSide - additionalData.theta .* additionalData.windAttackOnRightSide;

wind.sideWind = sin(additionalData.theta) .* wind.windMean(1:end-1,:); %always positive
wind.frontWind = cos(additionalData.theta) .* wind.windMean(1:end-1,:); %positive against driving, negative towards driving

%% Perform "Map Matching"
localCoordinateSystem = findLocalProjectionUtm(route.lati / 180*pi, route.long / 180*pi);

[~, ~, indsFirstToSecond, indsSecondToFirst] = matchGeographicTrajectories(route.lati / 180*pi, route.long / 180*pi, ...
    wind.lati / 180*pi, wind.long / 180*pi, ...
    localCoordinateSystem, true);

% Calculate interpolation grid
distanceBetweenBrouterPoints = haversine(route.lati / 180*pi, route.long / 180*pi);
distanceVector = [0; cumsum(distanceBetweenBrouterPoints)];

wind.dist = distanceVector(indsFirstToSecond);

temperature.dist = wind.dist;

irradiance.dist = wind.dist;

close;

%% save data
save("WeatherData1990_2021", "temperature", "wind", "additionalData", "irradiance")

%% save data for Michi
timeVecHour = hours(5.5) : hours(1) : hours(19.5);
timeVecHourStr = string(timeVecHour,"hh:mm");

writematrix(timeVecHourStr, "frontWind.csv")
writematrix(wind.frontWind, "frontWind.csv",'WriteMode','append')

writematrix(timeVecHourStr, "sideWind.csv")
writematrix(wind.sideWind, "sideWind.csv",'WriteMode','append')

writematrix(timeVecHourStr, "windMean.csv")
writematrix(wind.windMean, "windMean.csv",'WriteMode','append')

writematrix(timeVecHourStr, "tempMean.csv")
writematrix(temperature.tempMean, "tempMean.csv",'WriteMode','append')

distVecStr = ["latitude","longitude","corrected distance"];
writematrix(distVecStr, "positionCorrected.csv")
writematrix([wind.lati, wind.long, wind.dist], "positionCorrected.csv",'WriteMode','append')
