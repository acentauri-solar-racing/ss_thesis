%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   Get disturbance variables as vector or grid.
%
%   outDstrbVars = getDstrbVars(OptPrb)
%
%   Inputs:     OptPrb          Optimization problem as dpaProblem
%
%   Outputs:    outDstrbVars    Struct of disturbances as vectors
%
%   See also dpaProblem/GETSTATELIMIT, dpaProblem/GETINPUTVARS

%   Authors:
%   Hansi Ritzmann      (JR)    jritzman@ethz.ch
%   Stijn van Dooren    (SV)    stijnva@ethz.ch
%   Andreas Ritter      (AR)    anritter@idsc.mavt.ethz.ch
%   Dario Nastasi       (DN)    nastasid@ethz.ch
%   Hokwang Choi        (HC)    hochoi@ethz.ch
%
%   Revision:
%   14.02.2019  DN  created

function outDstrbVars = getDstrbVars(OptPrb)
    outDstrbVars = cell(1,length(OptPrb.dstrbVars));
    for i = 1:length(OptPrb.dstrbVars)
        outDstrbVars{i} = OptPrb.dstrbVars(i).signal;
    end
    outDstrbVars = cell2struct(outDstrbVars,{OptPrb.dstrbVars.name},2);
end