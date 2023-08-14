function tempCell = cellTemperatureSandia(G, tempAmb, WS, type, mounting)
% Calculate the cell temperature using the Sandia model
%
% Input: global irradiance as double;
%        ambient temperature as double;
%        wind speed as double;
%        type: "glass-cell-glass", "glass-cell-polymer", "polymer-thinfilm-steel";
%        mounting: "open rack", "close roof mount", "insulated back";
%
% Output: tempCell in degrees

if ~isa(type, "string") || ~isa(mounting, "string")
    disp("Wrong input type for type or mounting: string")
end % if

G0 = 1000; %W/m^2

switch type
    case "glass-cell-glass"
        if mounting == "open rack"
            a = -3.47;
            b = -0.0594;
            deltaTemp = 3;
        elseif mounting == "close roof mount"
            a = -2.98;
            b = -0.0471;
            deltaTemp = 1;
        end % if
    case "glass-cell-polymer"
        if mounting == "open rack"
            a = -3.56;
            b = -0.075;
            deltaTemp = 3;
        elseif mounting == "insulated back"
            a = -2.81;
            b = -0.0455;
            deltaTemp = 0;
        end % if
    case "polymer-thinfilm-steel"
        if mounting == "open rack"
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