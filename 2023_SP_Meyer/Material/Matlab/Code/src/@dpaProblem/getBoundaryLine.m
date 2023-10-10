%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   Get the boundary line as a vector. Works only for single state
%   problems.
%
%   [upperLine, lowerLine] = getBoundaryLine(OptPrb)
%
%   Inputs:     OptPrb      Optimization problem as dpaProblem
%
%   Outputs:    upperLine   Upper boundary line as vector
%               lowerLine   Lower boundary line as vector
%
%   See also dpaProblem/GETSTATEVARS, dpaProblem/GETINPUTVARS

%   Authors:
%   Hansi Ritzmann      (JR)    jritzman@ethz.ch
%   Stijn van Dooren    (SV)    stijnva@ethz.ch
%   Andreas Ritter      (AR)    anritter@idsc.mavt.ethz.ch
%   Dario Nastasi       (DN)    nastasid@ethz.ch
%   Hokwang Choi        (HC)    hochoi@ethz.ch
%
%   Revision:
%   14.02.2019  DN  created

function [upperLine, lowerLine] = getBoundaryLine(OptPrb)
if strcmp(OptPrb.boundaryMethod,'line')
    upperLine = OptPrb.boundaryVars.upper.x;
    lowerLine = OptPrb.boundaryVars.lower.x;
else
    upperLine = [];
    lowerLine = [];
end
end