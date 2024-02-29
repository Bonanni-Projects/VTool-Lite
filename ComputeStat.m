function stat = ComputeStat(SIGNALS,name,option)

% COMPUTESTAT - Compute a statistic for a named signal in a signal group or array.
% stat = ComputeStat(Signals,name,option)
% stat = ComputeStat(Signals,name,['mean','std','median','max','min','mode'])
% stat = ComputeStat(Signals,name,fun)
% stat = ComputeStat(SIGNALS,...)
%
% Computes a statistic for a named signal in signal group 'Signals' 
% or signal-group array 'SIGNALS'.  Input 'option' specifies either 
% a statistical function ('mean','std','median','max','min','mode') 
% or a scalar value signifying a percentile value between 0 and 100.  
% A user specified function 'fun' may also be provided, where fun(x) 
% accepts a vector input and returns a scalar output.  Input 'name' 
% specifies the desired signal name, for which the name entry from 
% any available name layer may be used.  Output 'stat' is scalar if 
% the input is a signal group; otherwise its size matches that of 
% the input signal-group array. 
%
% See also "ComputeStat2". 
%
% P.G. Bonanni
% 8/18/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


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
elseif isnumeric(option) && (~isscalar(option) || option < 0 || option > 100)
  error('Percentile values must be scalar, from 0 to 100.')
elseif ischar(option) && ~any(strcmp(option,{'mean','std','median','max','min','mode'}))
  error('Invalid statistic option.')
elseif ~isnumeric(option) && ~ischar(option) && ~isa(option,'function_handle')
  error('Invalid statistic option or function handle.')
end

% Build statistical function
if ischar(option)
  fun = str2func(option);
elseif isnumeric(option)
  pct = option;
  fun = @(x)prctile(x,pct);
else  % if function handle
  fun = option;
end

% Locate signal name
i = FindName(name,SIGNALS(1));
if isempty(i)
  error('Signal name not found.')
elseif numel(i) > 1
  fprintf('Signal name appears more than once. Using first instance.\n')
  i = i(1);
end

% Compute the statistic
C = cellfun(@(x)fun(x(:,i)),{SIGNALS.Values},'Uniform',false);
if ~all(cellfun(@isscalar,C))
  error('Specified function did not return scalar output(s).')
end

% Assemble as a vector
stat = cat(1,C{:});

% Match the input shape
stat = reshape(stat,size(SIGNALS));
