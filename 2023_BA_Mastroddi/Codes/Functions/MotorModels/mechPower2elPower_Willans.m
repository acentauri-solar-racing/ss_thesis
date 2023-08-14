function El_power = mechPower2elPower_Willans(Mech_power, param)

if (Mech_power + param.motor.p0) / param.motor.efficiency >= 0
    El_power = (Mech_power + param.motor.p0) / param.motor.efficiency;
else
    El_power = (Mech_power + param.motor.p0) * param.motor.efficiency;
end % if
end % fct