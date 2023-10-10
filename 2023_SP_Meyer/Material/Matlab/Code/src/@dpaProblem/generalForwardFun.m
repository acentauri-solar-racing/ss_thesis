%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   This function calculates current cost-to-go, optimal inputs and optimal
%   states as a forward DP when the levelset method is not used. 
%   
%   [J, X, U, dpOutput] = generalForwardFun(obj, nextStateGrids,
%   dpState, inputCell, currentDstrb, dpTs, k)
%
%   Inputs:     obj             Optimization problem as a dpaProblem object
%               nextStateGrids  state grids of time step k+1
%               dpState         current state as a structure
%               inputCell       possible inputs at time step k in cells
%               currentDstrb    current disturbance as a structure
%               dpTs            time lapse in each iteration
%               k               time step

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
%   16.07.2019  HC  created
%   05.02.2020  JR  remove indOptInputs
%   24.01.2021  KB  Extend dpState to get full dimensions reduced to one point
%                   for the input-dimensions (1 ... x n_u1 x n_u2 x ...)
%   05.02.2021  KB  Modifications for model function vector inputs & model
%                   function output dimension check
%   20.02.2021  KB  Modification of dimension check
%   14.04.2021  JR  Fix issue CostToGo for 'Line' and 'UseMyGrid'
%   07.07.2021  AS  moved function to dpaProblem and deleted pol as input
%                   argument as part of OptPrb/OptPol fusion
%   08.07.2021  AS  deleted input argument thisStateGrids as it is unused
%   08.03.2022  KB  Changes for adding input-regularisation

function [J, X, U, dpOutput] = generalForwardFun(obj, ...
    nextStateGrids, dpState, inputCell, currentDstrb, dpTs, k)

% extend dpState to full dimension with ones in input dimensions when not
% using vectors
if obj.vectorMode
    dpState_extend = dpState;
else
    % corresponds to size(dpInput)
    dpState_extend = structfun(@(field)repmat(field,size(inputCell{1})),dpState,'UniformOutput',false);
end

% Get dimensions
full_dim = [ones(1,length(obj.stateVars)) [obj.inputVars.nGridPoints]];

% Determine problem length
N = length(obj.timeVector);

% Call model function
dpInput = cell2struct(inputCell',{obj.inputVars.name},2);
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

% Identify where the model ends up after that iteration
endUpStateGrids = struct2cell(dpStateNew);

% Manipulate the cost such that infeasible states are respected
gridPointIsFeasible = isStateFeasible(obj.stateVars, endUpStateGrids, k+1);
dpCost(~dpIsFeasible | ~gridPointIsFeasible) = obj.myInf;

% Add the interpolated cost of the last iteration to the cost-to-go
JFull = dpCost + interpn(nextStateGrids{:}, obj.costToGo{k+1}, endUpStateGrids{:});

% Calc corrected cost taking into account the boundary line & useMyGrid
if strcmp(obj.boundaryMethod,'line') && obj.useMyGrid
    [corrCost_btwL, corrCost_btwU, betweenLower, betweenUpper] = calcBoundaryCorrection(obj, nextStateGrids, obj.costToGo{k+1}, endUpStateGrids, k);
    JFull(betweenLower) = corrCost_btwL + dpCost(betweenLower);
    JFull(betweenUpper) = corrCost_btwU + dpCost(betweenUpper);
end

% Add input-regularisation cost
J_reg = calcRegCost(obj, dpInput, nextStateGrids, obj.optInputs{1,k+1}, endUpStateGrids, k);
JFull = JFull + J_reg;

% Limit the maximum cost to the customizable infinity cost
JFull(JFull > obj.myInf) = obj.myInf;
JFull(isnan(JFull)) = obj.myInf;

% Find the minimum cost-to-go
[J, indOptInputs] = min(JFull(:));
if J > obj.myInf
    J = obj.myInf;
end

% Keep track of optimal state
newState = cell(1,length(endUpStateGrids));
for u = 1:length(endUpStateGrids)
    newState{u} = endUpStateGrids{u}(indOptInputs);
end
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

% Evaluate the model output
[~, ~, ~, dpOutput] = obj.modelFunction(dpState, U, currentDstrb, dpTs, ...
    obj.modelParameters);

end % function