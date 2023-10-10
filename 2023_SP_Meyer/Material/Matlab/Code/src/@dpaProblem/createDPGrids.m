%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   Generate grids for state or input variables. The result can be used as
%   an argument for the model function. This function essentially performs
%   ndgrid() but instead with vectors with the dpa classes.
%
%   grid = createDPGrids(OptPrb, k, type, format)
%
%   Inputs:     OptPrb      dpaProblem object
%               k           time step
%               type        output grid type: state grids or input grids
%               format      output grid format: full-dimensional arrays or vectors
%
%   Outputs:    grid        Struct which has grids as defined in
%                           the input arguments as its members. Can be
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
%   Revision:
%   30.06.2021  AS  created

function grids = createDPGrids(OptPrb, k, type, format)
% Check for appropriate arguments.
assert((nargin == 4),'dpa:createDPGrids',...
    ['Four input arguments required - ',...
    'dpaProblem object, time step k, output grid type, output grid format.']);
assert(isa(OptPrb, 'dpaProblem'),'dpa:createDPGrids',...
    'Object must belong to dpaProblem class.');
assert(isscalar(k), 'dpa:createDPGrids','Time step should be a scalar.');
assert(ischar(type) && any(strcmpi(type, {'states', 'inputs'})), ...
        'dpa:createDPGrids','Give type equal to "states" or "inputs".');
assert(ischar(format) && any(strcmpi(format, {'arrays', 'vectors'})), ...
        'dpa:createDPGrids','Give format equal to "arrays" or "vectors".');
    
% Determine the number of state and input variables
nGrids = cellfun(@length, {OptPrb.stateVars,OptPrb.inputVars});

% Create vectors of required type
if strcmpi(type, 'states')
    arrayGrids = cellfun(@(x) arraygrid(x, k), {OptPrb.stateVars}, 'uniformOutput', false);
    if ~isequal(nGrids(1),1)
        arrayGrids = [arrayGrids{:}];
    end
else
    arrayGrids = cellfun(@(x) arraygrid(x, k), {OptPrb.inputVars}, 'uniformOutput', false);
    if ~isequal(nGrids(2),1)
        arrayGrids = [arrayGrids{:}];
    end
end

% Create grids of required type and format
if strcmpi(type, 'states')
    if strcmpi(format,'vectors')
        % create vectors in each dimension
        fullGrids = cell(1,nGrids(1));
            for dim = 1:nGrids(1)
                % arrange index for reshaping
                ind = ones(1,sum(nGrids));
                ind(1,dim) = size(arrayGrids{dim},2);
                % create vectors
                [fullGrids{dim}] = reshape(arrayGrids{dim},ind);
            end
    else
        % create full arrays
        [fullGrids{1:nGrids(1)}] = ndgrid(arrayGrids{:});
    end
else
    if strcmpi(format,'vectors')
    % create vectors in each dimension
    fullGrids = cell(1,nGrids(2));
        for dim = 1:nGrids(2)
            % arrange index for reshaping
            ind = ones(1,sum(nGrids));
            ind(1,dim+nGrids(1)) = size(arrayGrids{dim},2);
            % create vectors
            [fullGrids{dim}] = reshape(arrayGrids{dim},ind);
        end
    else
        % create full arrays
        [Grids{1:nGrids(2)}] = ndgrid(arrayGrids{:});
        StateSize = repmat({1},1,nGrids(1));
        InputSize = num2cell(cellfun(@length,arrayGrids));
        fullGrids = cellfun(@(x)reshape(x,StateSize{:},InputSize{:}),Grids,'uniformOutput',false);
    end
end

% Assign these grids to variables for the model function and return them as
% structs where the field names are the variable names
if strcmpi(type, 'states')
    grids = cell2struct(fullGrids, {OptPrb.stateVars.name}, 2);
else
    grids = cell2struct(fullGrids, {OptPrb.inputVars.name}, 2);
    
end % function