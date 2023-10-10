%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   Get state variables as vector or grid.
%
%   outStateVars = getStateVars(OptPrb)
%
%   Inputs:     OptPrb          Optimization problem as dpaProblem
%
%   Outputs:    outStateVars    Struct of states as vectors if state limits 
%                               are constant or as grids if not. The 
%                               grid/vector will be equally spaced 
%                               according to the specifications in 
%                               dpaStateVar
%
%   See also dpaProblem/GETSTATELIMIT, dpaProblem/GETINPUTVARS

%   Authors:
%   Hansi Ritzmann      (JR)    jritzman@ethz.ch
%   Stijn van Dooren    (SV)    stijnva@ethz.ch
%   Andreas Ritter      (AR)    anritter@idsc.mavt.ethz.ch
%   Dario Nastasi       (DN)    nastasid@ethz.ch
%   Hokwang Choi        (HC)    hochoi@ethz.ch
%   Ashwin Sandeep      (AS)    asandeep@student.ethz.ch
%
%   Revision:
%   14.02.2019  DN  created
%   20.06.2019  HC  revision(different nGridpoints for multiple states)
%   16.06.2021  AS  correction to indexing

function outStateVars = getStateVars(OptPrb)
    outStateVars = cell(1,length(OptPrb.stateVars));
    for i = 1:length(OptPrb.stateVars)
        if all([OptPrb.stateVars(:).stateIsConst]) && ~strcmp(OptPrb.boundaryMethod,'line')
            outStateVars{i} = linspace(OptPrb.stateVars(i).min,OptPrb.stateVars(i).max,OptPrb.stateVars(i).nGridPoints);
        else
            if OptPrb.useMyGrid || ~strcmp(OptPrb.boundaryMethod,'line')
                for k = 1:length(OptPrb.stateVars(i).min)
                    outStateVars{i} = [outStateVars{i};linspace(OptPrb.stateVars(i).min(k), OptPrb.stateVars(i).max(k), OptPrb.stateVars(i).nGridPoints)];
                end
            else
                for k = 1:length(OptPrb.boundaryVars.lower.x)
                    outStateVars{i} = [outStateVars{i};linspace(OptPrb.boundaryVars.lower.x(k), OptPrb.boundaryVars.upper.x(k), OptPrb.stateVars(i).nGridPoints)];
                end
            end
        end
    end
    outStateVars = cell2struct(outStateVars,{OptPrb.stateVars.name},2);
end