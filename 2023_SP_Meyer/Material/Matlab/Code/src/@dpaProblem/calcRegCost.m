%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   Calculate input regularisation cost
%
%   [J_reg] = calcRegCost(obj, nextStateGrids, optInputs_next, endUpStateGrids, k)
%
%   Inputs:     OptPrb              Optimization problem as a dpaProblem
%               dpInput             Input struct
%               nextStateGrids      State grid (cell array)
%               optInputs_next      Grid values (cell array)
%               endUpStateGrids     Sample points (cell array)
%               k                   time step
%
%   Outputs:    J_reg       Input regularisation cost
%
%
%   Authors:
%   Hansi Ritzmann      (JR)    jritzman@ethz.ch
%   Stijn van Dooren    (SV)    stijnva@ethz.ch
%   Andreas Ritter      (AR)    anritter@idsc.mavt.ethz.ch
%   Dario Nastasi       (DN)    nastasid@ethz.ch
%   Hokwang Choi        (HC)    hochoi@ethz.ch
%   Kerim Barhoumi      (KB)    bkerim@ethz.ch
%   Ashwin Sandeep      (AS)    asandeep@student.ethz.ch
%
%   Revision:
%   12.05.2022  KB  created
%   13.05.2022  KB  Add boundary line correction

function J_reg = calcRegCost(obj, dpInput, nextStateGrids, optInputs_next, endUpStateGrids, k)
J_reg = 0;

for i = 1:length(obj.inputVars)
    if any(obj.inputVars(i).weight) % weight is not zero
        if isscalar(obj.inputVars(i).weight) % weight is scalar
            weight = obj.inputVars(i).weight;
        else % weight is vector
            weight = obj.inputVars(i).weight(k);
        end
        input_interp = interpn(nextStateGrids{:}, optInputs_next{i,1}, endUpStateGrids{:});

        % Calc boundary line correction
        if strcmp(obj.boundaryMethod,'line') && obj.useMyGrid
            [corrInputs_btwL, corrInputs_btwU, betweenLower, betweenUpper] = calcBoundaryCorrection(obj, nextStateGrids, optInputs_next{i,1}, endUpStateGrids, k);
            input_interp(betweenLower) = corrInputs_btwL;
            input_interp(betweenUpper) = corrInputs_btwU;
        end

        inputDiff = dpInput.(obj.inputVars(i).name) - input_interp;

        switch true
            case (strcmp(obj.inputVars(i).norm,'lad')==1)
                regCost = weight .* abs(inputDiff);
            case (strcmp(obj.inputVars(i).norm,'lsq')==1)
                regCost = weight .* (inputDiff) .^ 2;
            otherwise
                error('Unknown norm for input regularisation selected!');
        end % end switch

        J_reg = J_reg + regCost;
    end
end

end % function

% EOF