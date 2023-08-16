clearvars;
close all;

savingDir = uigetdir(); %choose the Wind&Temperature folder
cd(savingDir);

route = load('RouteData.mat').route;

temperature = struct();
wind = struct();

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

additionalData = struct(); %useful for calculation
additionalData.windDir = [];

%% read weather data from institut
numData = 1;
directory = dir;

for k = 1:length(dir)
    dirNameSplitted = strsplit(directory(k).name, '_');

    if string(dirNameSplitted(1)) == "ERA5"
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
        additionalData.windDir(:,numData) = tmpData(:,6);
        temperature.tempMean(:,numData) = tmpData(:,9);

        numData = numData + 1; %found data, saved, ready for next column
    end % if
end % for

wind.lati = temperature.lati;
wind.long = temperature.long;
wind.time = temperature.time;
wind.timeDur = temperature.timeDur;

%% lati/long conversion to vector
additionalData.arclen = [];
additionalData.az = [];

for k = 1:length(temperature.lati(:,1))-1
    [additionalData.arclen(k,1), additionalData.az(k,1)] = distance('gc', temperature.lati(k,1), temperature.long(k,1), temperature.lati(k+1,1), temperature.long(k+1,1));
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
close;

%% save data
save("WeatherData", "temperature", "wind", "additionalData")
