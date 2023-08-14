function State_of_charge_ref = SoCcontroller_quadratic(Position, lastStop)


c = 1;
xEnd = lastStop;
yEnd = 0.1;
b = (2*yEnd - 2*c) / xEnd;
a = (yEnd - c - b*xEnd) / xEnd^2;

State_of_charge_ref = a*Position.^2 + b*Position + c;

end % fct