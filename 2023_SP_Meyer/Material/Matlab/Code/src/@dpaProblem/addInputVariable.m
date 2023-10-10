%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   Add input variable to optimization problem as dpaInputVar. This defines
%   the grids which are used to solve the problem.
%
%   addInputVariable(OptPrb, varName, nGridPoints, minValue, maxValue, weight, lastInput, norm)
%
%   Inputs:     OptPrb          Optimization problem as a dpaProblem
%               varName         String containing the name of the input
%               nGridPoints     Number of sampling points
%               minValue        Lower limit as scalar or vector
%               maxValue        Upper limit as scalar or vector
%               weight          Weight for input regularisation
%               lastInput       Last input for input regularisation
%               norm            Norm for input regularisation
%
%   See also dpaProblem/ADDSTATEVARIABLE, dpaProblem/ADDDISTURBANCE

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
%   20.06.2019  HC  revision(interface setting)
%   16.06.2021  AS  delete inputType as an input argument as this is no longer required
%   08.03.2022  KB  Add weight and norm type for input regularisation
%   14.03.2022  KB  Add user selected last input for input regularisation

function addInputVariable(obj, varName, nGridPoints, minValue, maxValue, weight, lastInput, norm)
% Add the variable to the system and simultaneously ensure that the name
% has not been used before
assert(all(~strcmp({obj.inputVars.name},varName)),... 
    'dpa:dpaProblem:InputAlreadyUsed','Input name is already used');

% Define the new input variable
if nargin < 6
    obj.inputVars(end+1) = dpaInputVar(varName, nGridPoints, minValue, maxValue);
elseif nargin == 6
    error('Not enough arguments for input regularisation. Weight and lastInput are needed at least.')
elseif nargin == 7
    obj.inputVars(end+1) = dpaInputVar(varName, nGridPoints, minValue, maxValue, weight, lastInput);
elseif  nargin == 8
    obj.inputVars(end+1) = dpaInputVar(varName, nGridPoints, minValue, maxValue, weight, lastInput, norm);
else
    assert(nargin < 9, 'dpa:dpaProblem:TooManyArguments','Too many input arguments.')
end
end % function