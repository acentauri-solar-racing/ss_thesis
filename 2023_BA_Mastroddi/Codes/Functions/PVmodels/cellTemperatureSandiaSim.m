function tempCell = cellTemperatureSandiaSim(G, tempAmb, WS, type, mounting)
% Calculate the cell temperature using the Sandia model
%
% Input: global irradiance as double;
%        ambient temperature as double;
%        wind speed as double;
%        type: 1"glass-cell-glass", 2"glass-cell-polymer", 3"polymer-thinfilm-steel";
%        mounting: 1"open rack", 2"close roof mount", 3"insulated back";
%
% Output: tempCell in degrees

G0 = 1000; %W/m^2

switch type
    case 1
        if mounting == 1
            a = -3.47;
            b = -0.0594;
            deltaTemp = 3;
        elseif mounting == 2
            a = -2.98;
            b = -0.0471;
            deltaTemp = 1;
        end % if
    case 2
        if mounting == 1
            a = -3.56;
            b = -0.075;
            deltaTemp = 3;
        elseif mounting == 3
            a = -2.81;
            b = -0.0455;
            deltaTemp = 0;
        end % if
    case 3
        if mounting == 1
            a = -3.58;
            b = -0.113;
            deltaTemp = 3;
        end % if
    otherwise
        a = -3.56;
        b = -0.075;
        deltaTemp = 3;
end % switch

tempModule = G.*exp(a + b.*WS) + tempAmb;
tempCell = tempModule + G/G0 * deltaTemp;

end % fct