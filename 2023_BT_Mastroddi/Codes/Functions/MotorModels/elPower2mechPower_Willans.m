function Mech_power = elPower2mechPower_Willans(El_power, param)

if El_power >= 0
    Mech_power = El_power * param.motor.efficiency - param.motor.p0;
else
    Mech_power = El_power / param.motor.efficiency - param.motor.p0;
end % if
end % fct