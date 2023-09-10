clc;
clear;
close all;

[param, weather, route, driver] = loadData();

cd("C:\Users\giaco\Git_Repositories\Bachelor_Arbeit\Codes\Optimization\Mean Values");

out = load("SimOutput_2022_12_16_12_21base.mat").out;

%% integration over time of power values with varying time step
Emotor = trapz(out.tout, (out.MotorPower.Data - elPower2mechPower_Willans(out.MotorPower.Data, param))); %motor losses
Ebat = trapz(out.tout, param.battery.R * out.batCurrent.Data.^2); %battery losses
Ebear = param.suspension.bearingFriction.total * out.Pos.Data(end); %bearing losses at the wheels

Eroll = trapz(out.tout, out.Froll.Data .* out.Vel.Data);
Eaero = trapz(out.tout, out.Faero.Data .* out.Vel.Data);

effLoss = (Eroll + Eaero) / (Emotor + Ebat + Ebear + Eroll + Eaero)

%% save variables
save("inefficiency","effLoss")