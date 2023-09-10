clearvars;
close all;

% https://scientificgems.wordpress.com/2019/10/30/world-solar-challenge-revisited-some-additional-charts/

cd("C:\Users\giaco\OneDrive - ETH Zurich\BA\Codes\Data\Route");

route = struct();

%load first parameters
[route.long, route.lati, route.alti, route.dist] = loadWaypoints('Route.geojson');

%smooth data
route.altiSmooth = smoothdata(route.alti, 'gaussian', 1000, 'SamplePoints', route.dist);

%insert inclination
for idx = 1:length(route.alti)-1
    route.incl(idx,1) = atan((route.alti(idx+1) - route.alti(idx)) / (route.dist(idx+1) - route.dist(idx))); %rad
    route.inclSmooth(idx,1) = atan((route.altiSmooth(idx+1) - route.altiSmooth(idx)) / (route.dist(idx+1) - route.dist(idx))); %rad
end % for

route.incl(isnan(route.incl)) = 0; %remove NaN

%insert max speed
roadInfo = readmatrix("Route.csv");
route.maxSpeed = roadInfo(:,6) / 3.6; %m/s
route.roadType = roadInfo(:,7);

save("RouteData","route");