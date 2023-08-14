function State_of_charge_ref = SoCcontroller_linear(Position, lastStop)

State_of_charge_ref = 1 - 0.9 / (lastStop) * Position;

end % fct