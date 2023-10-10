%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   This function is used to set the method of final state cost with a 
%   custom function handle or a matlab syntax function handles.
%
%   setFinalStateCost(obj, functionHandle)
%
%   Inputs:     OptPrb          Optimization problem as a dpaProblem
%               functionHandle  custom function with char or matlab syntax
%                               function handle
%
%   See also dpaProblem/setFinalStateConstraint

%   Authors:
%   Hansi Ritzmann      (JR)    jritzman@ethz.ch
%   Stijn van Dooren    (SV)    stijnva@ethz.ch
%   Andreas Ritter      (AR)    anritter@idsc.mavt.ethz.ch
%   Dario Nastasi       (DN)    nastasid@ethz.ch
%   Hokwang Choi        (HC)    hochoi@ethz.ch
%
%   Revision:
%   30.06.2019  HC  created

function setFinalStateCost(obj, functionHandle)
% Set the finalcostFunction depending on the type of functionHandle.
if ischar(functionHandle)
    obj.finalStateCostFcn = obj.parseModelFunction(finalcostFunction);
else
    assert(isa(functionHandle,'function_handle'),'dpa:improper function handle',...
           ['Given argument is not a function handle. ',...
           'Try to give the correct function handle. ',...
           'Example. functionHandle = @(x) norm(x,2);']);
   assert(nargin(functionHandle) == length(obj.stateVars),...
          'dpa:improper function handle', ['Number of arguments for the ',...
          'function does not correspond to the number of states of the ',...
          'dpaProblem. Try to match the number of arguments for function',... 
          'handle. ', 'Example. functionHandle = @(x1,x2) x1+x2;(2 states)']);
    obj.finalStateCostFcn = functionHandle;
end % if
end % function