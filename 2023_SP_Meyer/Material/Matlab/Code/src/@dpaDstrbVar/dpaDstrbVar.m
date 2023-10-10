%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   This constructor initalizes the disturbance with its name, value(s) and a 
%   logical of whether it is constant. The disturbance 
%   will be accessable via its name.
%
%   obj = dpaDstrbVar(name,signal)
%
%   Inputs:     name        String containing the name of the disturbance
%               signal      Scalar or vector of disturbance values
%
%   Outputs:    obj         dpaDstrbVar which is initialized with its name
%                           Values and a logical of whether it is constant
%
%   See also dpaStateVar/dpaStateVar.m, dpaInputVar/dpaInputVar.m

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
%   20.06.2019  HC  revision(timeVector treatment)
%   09.06.2021  AS  timeVector removed and dstrbIsConst added

classdef (Sealed=true) dpaDstrbVar < dpaEveryVar
    
    properties (Access={?dpaProblem, ?dpaEveryVar})
        signal = [];                % Distrurbance values
        dstrbIsConst                % Logical for if disturbance value is constant
    end % restricted properties
    
    methods (Access=?dpaProblem)
        function obj = dpaDstrbVar(name,signal)
            % Constructor with no input argument will give empty array of
            % dpaDstrbVar objects
            if nargin == 0
                obj = dpaDstrbVar.empty(1,0);
            else
                obj.name = name;
                
                assert(isnumeric(signal) && isvector(signal), ...
                'dpa:dpaDstrbVar:Internal', ...
                'The signal must be a numeric scalar or vector.');
                obj.signal = signal(:);
            
                obj.dstrbIsConst = length(signal)==1 || range(signal)<300*eps;
            end % if
        end % constructor function
    end % constructor method
end % class