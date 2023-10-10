%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   This function calculates one iteration of backward DP in the level set
%   method case.
%
%   [J, I, optInputs] = levelsetBackwardFun(obj, dpState, dpInput,
%   currentDstrb, dpTs, nextStateGrids, I_next, J_next, k)
%
%   Inputs:     OptPrb          Optimazition problem as a dpaProblem
%               dpState         state grids at time step k
%               dpInput         input grids at time step k
%               currentDstrb    current disturbance in struct
%               dpTs            time interval
%               nextStateGrids  state grids at time step k+1
%               I_next          level set values at time step k+1
%               J_next          Cost-to-go at time step k+1
%               k               time step
%
%   Outputs:    J               Cost-to-go at time step k
%               I               level set values at time step k
%               optInputs       Optimal inputs at time step k
%
%   See also dpaProblem/generalBackwardFun

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
%   02.02.2021  KB  Add model function outputs dimension check
%   20.02.2021  KB  Modification of dimension check
%   30.06.2021  AS  Replaced output indOptInputs with optInputs

function [J, I, optInputs] = levelsetBackwardFun(obj, dpState, dpInput, ...
        currentDstrb, dpTs, nextStateGrids, I_next, J_next, k)
     
% Get full dimensions
full_dim1 = [obj.stateVars(:).nGridPoints];
full_dim2 = [obj.inputVars(:).nGridPoints];
full_dim = [full_dim1 full_dim2];

% Call model function.
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

% check that dpCost is not NaN
assert(~any(isnan(dpCost(:))),'Model function returned NaN as stage cost.');

% Identify where the model ends up after that iteration.
endUpStateGrids = struct2cell(dpStateNew)';
gridPointIsFeasible = isStateFeasible(obj.stateVars, endUpStateGrids, k+1);

% Update level set function & get the control candidate (extrapolation)
I_current = interpn(nextStateGrids{:}, I_next, endUpStateGrids{:});

% Deal with the case that all inputs send states out of grids.
I_current(~dpIsFeasible | ~gridPointIsFeasible) = max(1,max(I_current(:)));

% Upper bound for the level set cost
I_current(I_current>obj.myInf) = obj.myInf;

% Reshape to make a matrix of the dimension with number of states + 1(input).
if length(obj.inputVars) > 1
    I_current = reshape(I_current, [obj.stateVars(:).nGridPoints, ...
                              prod([obj.inputVars(:).nGridPoints])]);
end
% Get the minimum values of level set cost and save the index of it.
[I, uk_tild] = min(I_current, [], ndims(I_current));

% Deal with the case that all inputs send states out of grids.
if any(isnan(I(:)))
    warning(['NaN exists in the level set. States with all possible '...
        'inputs end up outside the grid. Extrapolation is excuted.']);
    % Positive value should be assigned to the not backward-reachable point
    I(isnan(I)) = max(1,max(I(:)));
end % if

% Distinguish the backward reachable set and the one which is not.
uk_ind = I <= 0;
U_k_F = I_current <= 0;

% Manipulate the cost such that infeasible states are respected.
dpCost(~dpIsFeasible | ~gridPointIsFeasible) = obj.myInf;
dpCost = reshape(dpCost, [obj.stateVars(:).nGridPoints, ...
                          prod([obj.inputVars(:).nGridPoints])]);
costToGo = interpn(nextStateGrids{:}, J_next, endUpStateGrids{:});
costToGo = reshape(costToGo, [obj.stateVars(:).nGridPoints, ...
                                  prod([obj.inputVars(:).nGridPoints])]);

% Not backward-reachable.
nbr_subs = cellfun(@(x) 1:x, {obj.stateVars(:).nGridPoints},...
                   'UniformOutput', false);
[nbr_subs_grid{1:length(obj.stateVars)}] = ndgrid(nbr_subs{:});
nbr_ind = sub2ind([obj.stateVars(:).nGridPoints, ...
                   prod([obj.inputVars(:).nGridPoints])],...
                   nbr_subs_grid{:}, uk_tild);
dpCost_nbr = dpCost(nbr_ind);
dpCost_nbr(uk_ind) = 0;
J_nbr_next = costToGo;
J_nbr_next = J_nbr_next(nbr_ind);
J_nbr_next(uk_ind) = 0;
J_nbr = dpCost_nbr + J_nbr_next;
uk_tild(uk_ind) = 0;
indOptInputs_nbr = uk_tild;
% Limit the maximum cost to the customizable infinity cost.
J_nbr(J_nbr > obj.myInf) = obj.myInf;
% NaNs occur when an element of endUpStateGrids is outside the nextStateGrids
J_nbr(isnan(J_nbr)) = obj.myInf;

% Backward-reachable.
dpCost_br = dpCost;
dpCost_br(~U_k_F) = obj.myInf;
J_br_next = costToGo;
J_br_next(~U_k_F) = obj.myInf;
J_br_Full = dpCost_br + J_br_next;
% Limit the maximum cost to the customizable infinity cost.
J_br_Full(J_br_Full > obj.myInf) = obj.myInf;
% NaNs occure when an element of endUpStateGrids is outside the 
% nextStateGrids
J_br_Full(isnan(J_br_Full)) = obj.myInf;

% Find the minimum cost-to-go.
[J_br, indOptInputs_br] = min(J_br_Full,[],ndims(J_br_Full));
J_br(~uk_ind) = 0;
indOptInputs_br(~uk_ind) = 0;

% Merge the cost and optimal input.
J = J_nbr + J_br;
indOptInputs = indOptInputs_nbr + indOptInputs_br;

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

% catch infeasible problem
assert( any(J(:)<obj.myInf), ...
    'dpa:BackwardInfeasible', ...
    sprintf('Infeasible problem detected during backward calculation (k=%0.0f).',k) );

end % function