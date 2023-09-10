function State_of_charge_ref = SoCcontroller_quadratic02(Position, lastStop)


c = 1;
xEnd = lastStop;
yEnd = 0.1;
yEndConsumed = 0.15;
b = (2*yEnd - 2*c) / xEnd;
a = (yEnd - c - b*xEnd) / xEnd^2;

SoC = a*Position.^2 + b*Position + c;
horizon = SoC >= yEndConsumed;

State_of_charge_ref = SoC .* ~horizon + yEndConsumed .* horizon;

end % fct