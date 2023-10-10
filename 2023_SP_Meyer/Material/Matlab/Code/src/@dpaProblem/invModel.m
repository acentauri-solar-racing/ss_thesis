%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   Invert model function
%
%   [dpState, dpCost, dpFeasible] = invModel(obj, dpState, dpInput, dpDstrb, dpTs)
%
%   Inputs:     obj         Optimization problem as dpaProblem
%               dpState     Struct for state as input for the inverted
%                           model
%               dpInput     Struct for input
%               dpDstrb     Struct for distrubance
%               dpTs        Time step
%
%   Outputs:    dpState     Struct with the output states of the inverted
%                           model
%               dpCost      Stage costs
%               dpFeasible  Contains information about which states are
%                           feasible
%
%   See also dpaProblem/CALCBOUNDARYLINE

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

function [dpState, dpCost, dpFeasible] = invModel(obj, dpState, dpInput, dpDstrb, dpTs)

% Initialize correction variable
dX = {inf};

% Initialize counter
n = 1;

% Desired end state as cell
X0cell = struct2cell(dpState);

while n < obj.nMaxIterInversion && max(abs(dX{:}(:))) > obj.maxTolInversion
    % Apply inputs to current state candidates
    [dpStateNew, dpCost, dpFeasible, ~] = obj.modelFunction(dpState, ...
        dpInput, dpDstrb, dpTs, obj.modelParameters);
    
    % New end-up-states as cells
    endUpState = struct2cell(dpStateNew);
    
    % State candidates as cells
    thisState = struct2cell(dpState);
    for i = 1:length(thisState)
        % Get error of end-up-states
        dX{i} = endUpState{i} - X0cell{i};
        % Correct state candidates
        thisState{i} = thisState{i} - dX{i};
    end % for
    
    % Make state candidates structs
    dpState = cell2struct(thisState,{obj.stateVars.name},2);
    
    % Update counter
    n = n + 1;
end % while

end % function

% EOF