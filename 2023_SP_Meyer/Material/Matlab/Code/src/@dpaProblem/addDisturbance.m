%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   Add disturbance variable to optimization problem as dpaDstrbVar.
%
%   addDisturbance(OprPrb, varName, signal)
%
%   Inputs:     OptPrb          Optimization problem as a dpaProblem
%               varName         String containing the name of the disturbance
%               signal          Scalar or vector of disturbance values
%
%   See also dpaProblem/ADDSTATEVARIABLE, dpaProblem/ADDINPUTVARIABLE

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
%   09.06.2021  AS  timeVector as input argument removed, constant
%                   disturbance is collapsed to scalar value

function addDisturbance(obj, varName, signal)
% Check whether the time vector for the problem has been defined
assert(~isempty(obj.timeVector), 'dpa:addDisturbance:TimeVectorMissing', ...
         'Define a time vector for the problem before defining disturbances.');  
assert(length(signal) == 1 || length(signal) == length(obj.timeVector) || ...
           length(signal) == (length(obj.timeVector)-1), ...
        'dpa:addDisturbance:InconsistentSize', ...
        'Signal is either a scalar or a vector of length N-1 or N, when the length of time vector is N.');

% Add the variable to the system and simultaneously ensure that the name
% has not been used before.
assert(~any(strcmp({obj.dstrbVars.name},varName)),... 
    'dpa:dpaProblem:DisturbanceAlreadyUsed',['Disturbance name is ',...
    'already used']);

% Define the new disturbance
obj.dstrbVars(end+1) = dpaDstrbVar(varName,signal);

if length(signal)~=1
    if length(signal) == length(obj.timeVector)
        obj.dstrbVars(end).signal = obj.dstrbVars(end).signal(1:end-1);
    end
    if (max(signal)-min(signal))<300*eps
        obj.dstrbVars(end).signal = obj.dstrbVars(end).signal(1);
    end
end
end % function