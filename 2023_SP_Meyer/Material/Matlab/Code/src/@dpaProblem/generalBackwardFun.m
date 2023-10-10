%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   This function calculates one iteration of backward DP in the general
%   case.
%
%   [J, optInputs] = generalBackwardFun(obj, dpState, dpInput,
%   currentDstrb, dpTs, nextStateGrids, J_next, k, optInputs_next)
%
%   Inputs:     OptPrb          Optimization problem as a dpaProblem
%               dpState         state grids at time step k
%               dpInput         input grids at time step k
%               currentDstrb    current disturbance in struct
%               dpTs            time interval
%               nextStateGrids  state grids at time step k+1
%               J_next          Cost-to-go at time step k+1
%               k               time step
%               optInputs_next  Optimal inputs at time step k+1
%
%   Outputs:    J               Cost-to-go at time step k
%               optInputs       Optimal inputs at time step k
%
%   See also dpaProblem/levelsetBackwardFun

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
%   12.06.2019  HC  revision(include time-varying input limits)
%   20.02.2021  KB  Modification of dimension check
%   17.05.2021  AS  J and indOptInputs calculated directly rather than
%                   using minOverInputs (deleted function) 
%   30.06.2021  AS  Replaced output indOptInputs with optInputs
%   03.03.2022  KB  Changes for adding input-regularisation

function [J, optInputs] = generalBackwardFun(obj, dpState, dpInput, ...
        currentDstrb, dpTs, nextStateGrids, J_next, k, optInputs_next)

% Extract boundary line properties
if strcmp(obj.boundaryMethod,'line')
    upperLine = obj.boundaryVars.upper.x;
%     upperCost = obj.boundaryVars.upper.J;
    lowerLine = obj.boundaryVars.lower.x;
%     lowerCost = obj.boundaryVars.lower.J;
end % if

% Get full dimensions
full_dim1 = [obj.stateVars(:).nGridPoints];
full_dim2 = [obj.inputVars(:).nGridPoints];
full_dim = [full_dim1 full_dim2];

% Determine problem length
N = length(obj.timeVector);

% Call model function
[dpStateNew, dpCost, dpIsFeasible, ~] = obj.modelFunction(dpState, ...
    dpInput, currentDstrb, dpTs, obj.modelParameters);
% check order of states in dpStateNew
dpStateNew = orderfields(dpStateNew,{obj.stateVars(:).name});

% Check dimensions of dpStateNew, dpCost & dpIsFeasible
dpStateNewDimCheck = structfun(@(x) (all(size(x) == full_dim)),dpStateNew,'UniformOutput',false);
cellfun(@(x) assert(x,'Model function returned not full dimensional dpStateNew.'),...
    struct2cell(dpStateNewDimCheck),'UniformOutput',false);
assert(all(size(dpCost) == full_dim),'Model function returned not full dimensional dpCost.');
assert(all(size(dpIsFeasible) == full_dim),'Model function returned not full dimensional dpIsFeasible.');

% Identify where the model ends up after that iteration
endUpStateGrids = struct2cell(dpStateNew);

% Manipulate the cost such that infeasible states are respected
if obj.useMyGrid && strcmp(obj.boundaryMethod,'line')
    stateIsAboveLimit = endUpStateGrids{1} > upperLine(k+1);
    stateIsBelowLimit = endUpStateGrids{1} < lowerLine(k+1);
    gridPointIsFeasible = (~stateIsAboveLimit & ~stateIsBelowLimit);
else
    gridPointIsFeasible = isStateFeasible(obj.stateVars, endUpStateGrids, k+1);
end % if
dpCost(~dpIsFeasible | ~gridPointIsFeasible) = obj.myInf;

% check that dpCost is not NaN
assert(~any(isnan(dpCost(:))),'Model function returned NaN as stage cost.');

% Add the interpolated cost of the last iteration to the cost-to-go
JFull = dpCost + interpn(nextStateGrids{:}, J_next, endUpStateGrids{:});

% Calc corrected cost taking into account the boundary line & useMyGrid
if strcmp(obj.boundaryMethod,'line') && obj.useMyGrid
    [corrCost_btwL, corrCost_btwU, betweenLower, betweenUpper] = calcBoundaryCorrection(obj, nextStateGrids, J_next, endUpStateGrids, k);
    JFull(betweenLower) = corrCost_btwL + dpCost(betweenLower);
    JFull(betweenUpper) = corrCost_btwU + dpCost(betweenUpper);
end

% Add input-regularisation cost
J_reg = calcRegCost(obj, dpInput, nextStateGrids, optInputs_next, endUpStateGrids, k);
JFull = JFull + J_reg;

% Limit the maximum cost to the customizable infinity cost
JFull(JFull > obj.myInf) = obj.myInf;
% NaNs occur when an element of endUpStateGrids is outside the nextStateGrids
JFull(isnan(JFull)) = obj.myInf;

% Find the minimum cost-to-go.
JFull = reshape(JFull, [full_dim1, prod(full_dim2)]);
[J, indOptInputs] = min(JFull, [], ndims(JFull));

if obj.storeOptInputs == true
    % extract optimal inputs
    [StateDims{1:length(obj.stateVars)}] = obj.stateVars(:).nGridPoints;
    [InputDims{1:length(obj.inputVars)}] = obj.inputVars(:).nGridPoints;
    InputDims = cellfun(@(x)1:x,InputDims,'UniformOutput',false);
    if obj.vectorMode
        % get subscripts from linear index
        [InputVecIdx{1:length(obj.inputVars)}] = ind2sub(full_dim2,indOptInputs);
    end
    for Ind = 1:length(obj.inputVars)
         if obj.vectorMode
    %        vector mode
             optInp.(obj.inputVars(Ind).name) = reshape(dpInput.(obj.inputVars(Ind).name)(InputVecIdx{Ind}),size(indOptInputs));
        else
    %        array mode
             InputGrid = dpInput.(obj.inputVars(Ind).name)(StateDims{:},InputDims{:});
             optInp.(obj.inputVars(Ind).name) = reshape(InputGrid(indOptInputs),size(indOptInputs));
         end
    end
    optInputs = struct2cell(optInp);
else
    optInputs = {};
end
        
end % function