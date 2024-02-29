function del = ComputeDEL(SIGNALS,name,slope,Nref)

% COMPUTEDEL - Compute DEL for a named signal in a signal group or array.
% del = ComputeDEL(Signals,name,slope)
% del = ComputeDEL(Signals,name,slope,Nref)
% del = ComputeDEL(SIGNALS,...)
%
% Computes the damage equivalent load value for a named signal in 
% signal group 'Signals' or signal group array 'SIGNALS'.  Input 
% 'slope' specifies the S-N fatigue curve slope, and optional 
% argument 'Nref' specifies the number of reference cycles, if the 
% default value based on actual cycles is not desired (see function 
% "DamageEquivLoad").  Input 'name' specifies the desired signal 
% name, for which the name entry from any available name layer may 
% be used.  Output 'del' is scalar if the input is a signal group; 
% otherwise its size matches that of the input signal array. 
%
% See also "ComputeStat". 
%
% P.G. Bonanni
% 7/19/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 4
  Nref = [];
end

% Check 'Signals' or 'SIGNALS' input
[flag,valid,errmsg] = IsSignalGroupArray(SIGNALS);
if ~flag
  error('Input ''Signals'' is not a signal group or signal-group array: %s',errmsg)
elseif ~valid
  error('Input ''Signals'' is not a valid signal group or signal-group array: %s  See "IsSignalGroup".',errmsg)
end

% Check other inputs
if ~ischar(name) || size(name,1)~=1
  error('Input ''name'' must be a scalar string.')
elseif ~isnumeric(slope) || ~isscalar(slope)
  error('Input ''slope'' must be numeric and scalar.')
elseif ~isempty(Nref) && (~isnumeric(Nref) || ~isscalar(Nref))
  error('Input ''Nref'' must be numeric and scalar.')
end

% Locate signal name
i = FindName(name,SIGNALS(1));
if isempty(i)
  error('Signal name not found.')
elseif numel(i) > 1
  fprintf('Signal name appears more than once. Using first instance.\n')
  i = i(1);
end

% Compute the DEL statistic
fun = @(x)DamageEquivLoad(x,[],slope,Nref);
C = cellfun(@(x)fun(x(:,i)),{SIGNALS.Values},'Uniform',false);
del = cat(1,C{:});

% Match the input shape
del = reshape(del,size(SIGNALS));
