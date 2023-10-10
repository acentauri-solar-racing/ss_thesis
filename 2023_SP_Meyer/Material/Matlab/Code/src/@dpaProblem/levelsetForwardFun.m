%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   This function calculates current cost-to-go, optimal inputs and optimal
%   states as a forward DP for the case of levelset method. 
%   
%   [J, X, U, dpOutput] = levelsetForwardFun(obj, nextStateGrids
%   dpState, inputCell, currentDstrb, dpTs, k)
%
%   Inputs:     obj             Optimization problem as a dpaProblem object
%               nextStateGrids  state grids of time step k+1
%               dpState         current state as a structure
%               inputCell       possible inputs at time step k in cells
%               currentDstrb    current disturbance as a structure
%               dpTs            time lapse in each iteration
%               k               time step
%
%   Outputs:    J               cost-to-go matrix at time step k
%               X               state at time step k
%               U               optimal input at time step k
%               dpOutputs       outputs from modle function

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
%   20.06.2019  HC  created
%   05.02.2020  JR  remove indOptInputs
%   24.01.2021  KB  Extend dpState to get full dimensions reduced to one point
%                   for the input-dimensions (1 ... x n_u1 x n_u2 x ...)
%   02.02.2021  KB  Modifications for model function vector inputs & model
%                   function output dimension check
%   20.02.2021  KB  Modification of dimension check
%   07.07.2021  AS  moved function to dpaProblem and deleted pol as input
%                   argument as part of OptPrb/OptPol fusion
%   08.07.2021  AS  deleted input argument thisStateGrids as it is unused

function [J, X, U, dpOutput] = levelsetForwardFun(obj, ...
    nextStateGrids, dpState, inputCell, currentDstrb, dpTs, k)

% Retrieve input from the inputCell
dpInput = cell2struct(inputCell',{obj.inputVars.name},2);

% Get dimensions
full_dim = [ones(1,length(obj.stateVars)) [obj.inputVars.nGridPoints]];

% extend dpState to full dimension with ones in input dimensions when not
% using vectors
if obj.vectorMode
    dpState_extend = dpState;
else
    % corresponds to size(dpInput)
    dpState_extend = structfun(@(field)repmat(field,size(inputCell{1})),dpState,'UniformOutput',false);
end

% Call model function.
[dpStateNew, dpCost, dpIsFeasible, ~] = obj.modelFunction(dpState_extend, ...
    dpInput, currentDstrb, dpTs, obj.modelParameters);
% check order of states in dpStateNew
dpStateNew = orderfields(dpStateNew,{obj.stateVars(:).name});

% Check dimensions of dpStateNew, dpCost & dpIsFeasible
if ~all(structfun(@isscalar,dpState_extend)) || ~all(structfun(@isscalar,dpInput))
    dpStateNewDimCheck = structfun(@(x) (all(size(x) == full_dim)),dpStateNew,'UniformOutput',false);
    cellfun(@(x) assert(x,'Model function returned not full dimensional dpStateNew.'),...
        struct2cell(dpStateNewDimCheck),'UniformOutput',false);
    assert(all(size(dpCost) == full_dim),'Model function returned not full dimensional dpCost.');
    assert(all(size(dpIsFeasible) == full_dim),'Model function returned not full dimensional dpIsFeasible.');
else
    assert(all(structfun(@isscalar,dpStateNew)),'Model function returned not scalar dpStateNew.');
    assert(isscalar(dpCost),'Model function returned not scalar dpCost.');
    assert(isscalar(dpIsFeasible),'Model function returned not scalar dpIsFeasible.');
end

% New states as cell
endUpStateGrids = struct2cell(dpStateNew)';
gridPointIsFeasible = isStateFeasible(obj.stateVars, endUpStateGrids, k+1);

% Update level set function & get the control candidate
I_next = interpn(nextStateGrids{:}, obj.levelset{k+1}, endUpStateGrids{:});
I_next(~dpIsFeasible | ~gridPointIsFeasible) = max(1,max(I_next(:)));

if length(obj.inputVars) > 1 || obj.vectorMode
    I_next = reshape(I_next, [1, numel(I_next)]);
end
[~, uk_tild] = min(I_next, [], ndims(I_next));
U_k_F = I_next <= 0;

% Manipulate the cost such that infeasible states are respected
dpCost(~dpIsFeasible | ~gridPointIsFeasible) = obj.myInf;
dpCost = reshape(dpCost, [1, numel(dpCost)]);

if (isempty(find(U_k_F,1)))
    % Not backward-reachable
    dpCost_nbr = dpCost(uk_tild);
    J_nbr_next = interpn(nextStateGrids{:}, obj.costToGo{k+1},...
                         endUpStateGrids{:});
    J_nbr_next = reshape(J_nbr_next, [1, numel(J_nbr_next)]);
    J_nbr_next = J_nbr_next(uk_tild);
    % NaNs occure when an element of endUpStateGrids is outside the 
    % nextStateGrids
    J_nbr_next(isnan(J_nbr_next)) = obj.myInf;
    J = dpCost_nbr + J_nbr_next;
    indOptInputs = uk_tild;
else
    % Backward-reachable.
    dpCost_br = dpCost;
    dpCost_br(~U_k_F) = obj.myInf;
    J_br_next = interpn(nextStateGrids{:}, obj.costToGo{k+1}, endUpStateGrids{:});
    J_br_next = reshape(J_br_next, [1, numel(J_br_next)]);
    J_br_next(~U_k_F) = obj.myInf;
    J_br_Full = dpCost_br + J_br_next;
    % Limit the maximum cost to the customizable infinity cost.
    J_br_Full(J_br_Full > obj.myInf) = obj.myInf;
    % NaNs occure when an element of endUpStateGrids is outside the 
    % nextStateGrids
    J_br_Full(isnan(J_br_Full)) = obj.myInf;

    % Find the minimum cost-to-go.
    [J_br, indOptInputs_br] = min(J_br_Full,[],ndims(J_br_Full));
    J = J_br;
    indOptInputs = indOptInputs_br;
end % if

% Keep track of optimal states     
newState = cell(1,length(endUpStateGrids));
for u = 1:length(endUpStateGrids)
    newState{u} = endUpStateGrids{u}(indOptInputs);
end % for
dpState_next = cell2struct(newState,{obj.stateVars.name},2);
X = dpState_next;

% Keep track of optimal input
optInput = cell(1,length(inputCell));
if obj.vectorMode
    % Extend to full matrices and get optInput
    for u = 1:length(inputCell)
        shape = full_dim;
        shape(1,u + length(obj.stateVars)) = 1;
        inputFullDimensional = repmat((inputCell{u,1}),shape);
        optInput{u} = inputFullDimensional(indOptInputs);
    end
    clear inputFullDimensional;
else
    % Get optInput from full dimensional matrices
    for u = 1:length(inputCell)
        optInput{u} = inputCell{u}(indOptInputs);
    end % for
end
U = cell2struct(optInput,{obj.inputVars.name},2);

% Evaluate the dpOutput
[~, ~, ~, dpOutput] = obj.modelFunction(dpState, U, currentDstrb, dpTs, ...
    obj.modelParameters);

end % function