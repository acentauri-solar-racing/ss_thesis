%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   Generate grids for state and input variables. The result can be used as
%   an argument for the model function. This function essentially performs
%   ndgrid() but instead with vectors with the dpa classes.
%
%   [dpState dpInput] = createDPGridsBackward(OptPrb, k, format)
%
%   Inputs:     OptPrb      dpaProblem object
%               k           time step
%               format      output grid format: full-dimensional arrays or vectors
%
%   Outputs:    dpState     Struct which has grids of states of the
%                           required format as its members. Can be
%                           given to the model function.
%               dpInput     Struct which has grids of inputs of the
%                           required format as its members. Can be
%                           given to the model function.

%   Authors:
%   Hansi Ritzmann      (JR)    jritzman@ethz.ch
%   Stijn van Dooren    (SV)    stijnva@ethz.ch
%   Andreas Ritter      (AR)    anritter@idsc.mavt.ethz.ch
%   Dario Nastasi       (DN)    nastasid@ethz.ch
%   Hokwang Choi        (HC)    hochoi@ethz.ch
%   Kerim Barhoumi      (KB)    bkerim@ethz.ch
%   Ashwin Sandeep      (AS)    asandeep@student.ethz.ch
%
%   30.06.2021  AS  created

function [dpState, dpInput] = createDPGridsBackward(OptPrb, k, format)
% Check for appropriate arguments
assert(nargin == 3,'dpa:createDPGridsBackward',...
    ['Three input arguments required - ',...
    'dpaProblem object, time step k, output grid format.']);
assert(isa(OptPrb, 'dpaProblem'),'dpa:createDPGrids',...
    'Object must belong to dpaProblem class.');
assert(isscalar(k), 'dpa:createDPGrids','Time step should be a scalar.');
assert(ischar(format) && any(strcmpi(format, {'arrays', 'vectors'})), ...
        'dpa:createDPGrids','Give format equal to "arrays" or "vectors".');

% Determine the number of state and input variables
nGrids = cellfun(@length, {OptPrb.stateVars,OptPrb.inputVars});

% Create vectors of all variables
arrayGrids = cellfun(@(x) arraygrid(x, k), {OptPrb.stateVars,OptPrb.inputVars}, ...
        'uniformOutput', false);
if ~isequal(nGrids,[1,1])
    arrayGrids = [arrayGrids{:}];
end

% Create grids that represent all given variables.
if strcmpi(format,'vectors')
    % create vectors in each dimension
    fullGrids = cell(1,sum(nGrids));
        for dim = 1:sum(nGrids)
            % arrange index for reshaping
            ind = ones(1,sum(nGrids));
            ind(1,dim) = size(arrayGrids{dim},2);
            % create vectors
            [fullGrids{dim}] = reshape(arrayGrids{dim},ind);
        end
else
    % create full arrays
        [fullGrids{1:sum(nGrids)}] = ndgrid(arrayGrids{:});
end

% Assign these grids to variables for the model function and return them as
% structs where the field names are the variable names.
dpState = cell2struct(fullGrids(1:nGrids(1)), {OptPrb.stateVars.name}, 2);
dpInput = cell2struct(fullGrids(nGrids(1)+1:end), {OptPrb.inputVars.name}, 2);
    
end % function