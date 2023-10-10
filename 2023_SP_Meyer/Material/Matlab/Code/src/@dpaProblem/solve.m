%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   Execute backward DP algorithem to get the input policy for the given
%   optimization problem. This function checks the properties of the
%   problem and selects a backward function accordingly.
%
%   Inputs:     OptPrb      Optimization problem as dpaProblem
%
%   Outputs:    OptPrb      Updated dpaProblem object including optimal control law 
%                           for every state at every  time step (defined by timeVector) 
%
%   See also dpaProblem/EVALUATE

%   Authors:
%   Hansi Ritzmann      (JR)    jritzman@ethz.ch
%   Stijn van Dooren    (SV)    stijnva@ethz.ch
%   Andreas Ritter      (AR)    anritter@idsc.mavt.ethz.ch
%   Dario Nastasi       (DN)    nastasid@ethz.ch
%   Hokwang Choi        (HC)    hochoi@ethz.ch
%   Ashwin Sandeep      (AS)    asandeep@student.ethz.ch
%   Kerim Barhoumi      (KB)    bkerim@ethz.ch
%
%   Revision:
%   14.02.2019  DN  created
%   19.06.2019  HC  revision(Level set method included)
%   30.06.2021  AS  replaced indOptInputs with optInputs
%   07.07.2021  AS  deleted output argument and the creation of dpaPolicy object 
%                   as part of OptPrb/OptPol fusion
%   09.03.2022  KB  Input regularisation: if weights ~= 0, then set storeOptInputs

function solve(obj)

sanity_check(obj);

% Input regularisation: if weights ~= 0, then set storeOptInputs
if any([obj.inputVars(:).weight])
    obj.storeOptInputs = true;
end % if

% Check whether terminal limits have been set
for iState = 1:length(obj.stateVars)
    % If not, the state limits are used as terminal limits
    if isempty(obj.stateVars(iState).targetMax)
        obj.stateVars(iState).targetMax = obj.stateVars(iState).max(end);
    end
    if isempty(obj.stateVars(iState).targetMin)
        obj.stateVars(iState).targetMin = obj.stateVars(iState).min(end);
    end
end

backwardTimer = tic;

if strcmp(obj.boundaryMethod,'line')
    % Calculate boundary line
    [upper, lower] = calcBoundaryLine(obj);
    % Update dpaProblem
    obj.boundaryVars.lower.x = lower.Line;
%     obj.boundaryVars.lower.J = lower.Cost;
    obj.boundaryVars.upper.x = upper.Line;
%     obj.boundaryVars.upper.J = upper.Cost;
end

if isempty(obj.stateVars) || isempty(obj.inputVars)
    % Simple backward simulation without optimization.
    error('There is no state or input');
elseif strcmp(obj.boundaryMethod,'levelset')
    % N-dimensional backward DP using Levelset method.
    runBackwardFunction = @LevelsetMethodBackwardDP;
else
    % N-dimensional backward DP without using Levelset method.(boundary
    % line method is included for 1-d problem.)
    runBackwardFunction = @GeneralBackwardDP;
end % if
    

if strcmp(obj.boundaryMethod,'levelset')
    [J, I, optInputs] = runBackwardFunction(obj);
else
    [J, optInputs] = runBackwardFunction(obj);
end % if

obj.costToGo = J;
obj.optInputs = optInputs;
obj.usedBackwardFunction = func2str(runBackwardFunction);
obj.solveDuration = toc(backwardTimer);

if strcmp(obj.boundaryMethod,'levelset')
    obj.levelset = I;
end % if

end % function