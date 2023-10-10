%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   This constructor initalizes the input with a given name, number of grid points,
%   mimimum and maximum values and a logical of whether it it constant. The input 
%   will be accessable via its name.
%
%   obj = dpaInputVar(name,nGridPoints,min,max,weight,lastInput,norm)
%
%   Inputs:     name          String containing the name of the input
%               nGridPoints   Scalar of number of grid points
%               min           Scalar or vector of lower bound of input
%               max           Scalar or vector of upper bound of input
%
%   Outputs:    obj           dpaInputVar which is initialized with 'name'
%
%   See also dpaStateVar/dpaStateVar.m, dpaInputVar/dpaInputVar.m

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
%   20.06.2019  HC  revision(consider time-varing input limits)
%   17.05.2021  AS  deleted ndgrid function (unused)
%   17.05.2021  AS  transferred the functionality of arraygrid to dpaEveryVar.m
%   18.05.2021  AS  deleted the function gridSize
%   09.06.2021  AS  deleted isconst function and added inputIsConst property
%   16.06.2021  AS  deleted inputType property and its set method
%   08.03.2022  KB  Add properties weight and norm type for input regularisation
%   14.03.2022  KB  Add user selected last input for input regularisation
%   03.05.2022  KB  Moved checks to sanity_check, only type check here

classdef (Sealed=true) dpaInputVar < dpaEveryVar
    
    properties (Access={?dpaProblem, ?dpaEveryVar})
        nGridPoints = [];           % Number of grid points 
        min = [];                   % Lower limit (scalar or vector)
        max = [];                   % Upper limit (scalar or vector)
        inputIsConst;               % Logical for if input value is constant
        weight = 0;                 % Weight for input regularisation (scalar or vector)
        lastInput;                  % Last input for input regularisation choosen by user
        norm = 'lsq';               % Norm type for input regularisation
    end % restricted properties
    
    methods (Access=?dpaProblem)
        function obj = dpaInputVar(name, nGridPoints, min, max, weight, lastInput, norm)
            % Constructor with no input argument will give empty array of
            % dpaInputVar objects.
            if nargin == 0
                obj = dpaInputVar.empty(1,0);
            else
                % here only type checks, more checks in 'sanity_check.m'
                obj.name = name;
                
                assert(isnumeric(nGridPoints) && isscalar(nGridPoints) && isfinite(nGridPoints) && ...
                all(round(nGridPoints) == nGridPoints & nGridPoints > 0), ...
                'dpa:dpaInputVar:Internal', ...
                'The number of grid points must be element of N (Z>0).');
                obj.nGridPoints = nGridPoints;
                
                assert(isvector(min) && all(isnumeric(min)) && all(isfinite(min)), ...
                'dpa:dpaInputVar:Internal', ...
                'The lower boundary must be a scalar or vector containing finite numeric values.');
                assert(isvector(max) && all(isnumeric(max)) && all(isfinite(max)), ...
                'dpa:dpaInputVar:Internal', ...
                'The upper boundary must be a scalar or vector containing finite numeric values.');
                dpaEveryVar.checkBoundaries(obj, min, max);
                obj.min = min(:);
                obj.max = max(:);
                
                obj.inputIsConst = size(obj.min,1) == 1 && size(obj.max,1) == 1;
                
                
                if nargin > 4
                    % weight (default see above)
                    assert(isvector(weight) && all(isnumeric(weight)) && all(isfinite(weight)), ...
                        'dpa:dpaInputVar:Internal', ...
                        'The input weight must be a scalar or vector containing finite numeric values.');
                    obj.weight = weight;
                    % lastInput
                    assert(isnumeric(lastInput) && isscalar(lastInput) && isfinite(lastInput), ...
                        'dpa:dpaInputVar:Internal', ...
                        'The lastInput must be a scalar and a finite numeric value.');
                    obj.lastInput = lastInput;
                end

                % norm: default set above in properties
                if nargin > 6
                    assert(ischar(norm) && (strcmp(norm,'lad') || strcmp(norm,'lsq')), ...
                        'dpa:dpaInputVar:Internal', ...
                        "The norm for the input regularisation must be either 'lad' (absolute) or 'lsq' (quadratic, default).");
                    obj.norm = norm;
                end
            end % if
        end % constructor function
    end % constructor method
    
    methods (Access=public)
        function thisGrid = arraygrid(obj, k)
            thisGrid = dpaEveryVar.arraygrid(obj,k);
        end % function
    end % public methods
end % class