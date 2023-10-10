%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   Get input variables as vector or grid.
%
%   outInputVars = getInputVars(OptPrb)
%
%   Inputs:     OptPrb          Optimization problem as dpaProblem
%
%   Outputs:    outInputVars    Struct of inputs as vectors if input limits 
%                               are constant or as grids if not. The 
%                               grid/vector will be equally spaced 
%                               according to the specifications in 
%                               dpaInputVar
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
%   20.06.2019  HC  revision(consider time-varying input limits)
%   16.06.2021  AS  correction to indexing

function outInputVars = getInputVars(OptPrb)
    outInputVars = cell(1,length(OptPrb.inputVars));
    for i = 1:length(OptPrb.inputVars)
        for k = 1:length(OptPrb.inputVars(i).min)
            outInputVars{i} = [outInputVars{i};linspace(OptPrb.inputVars(i).min(k), OptPrb.inputVars(i).max(k), OptPrb.inputVars(i).nGridPoints)];
        end
    end
    outInputVars = cell2struct(outInputVars,{OptPrb.inputVars.name},2);
end