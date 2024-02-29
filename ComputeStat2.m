function stat = ComputeStat2(SIGNALS1,SIGNALS2,name,option)

% COMPUTESTAT2 - Compute a statistic for a named signal in two signal groups or arrays.
% stat = ComputeStat2(Signals1,Signals2,name,option)
% stat = ComputeStat2(Signals1,Signals2,name,fun)
% stat = ComputeStat2(SIGNALS1,SIGNALS2,...)
%
% Computes a comparison statistic for a named signal appearing in two 
% signal groups ('Signals1' and 'Signals2') or in two signal-group 
% arrays ('SIGNALS1' and 'SIGNALS2'), with no requirement regarding 
% the position of the signal or name-layer membership within the two 
% supplied inputs.  Arrays, if supplied, must be equal in size and 
% dimension, and data lengths must be uniform throughout.  Input 
% 'option' specifies one of the following options: 
%   'meandiff'     -  mean difference
%   'meanabsdiff'  -  mean absolute difference
%   'rmsdiff'      -  root-mean-square difference
%   'stddev'       -  standard deviation
%   'corrcoef'     -  correlation coefficient
% A user specified function 'fun' may also be provided, where fun(x,y) 
% accepts two n x 1 vector inputs (x,y) and returns a scalar output. 
% Input 'name' specifies the desired signal name, for which the name 
% entry from any available name layer may be used.  Output 'stat' is 
% scalar in the case of signal groups; otherwise its size is set to 
% match that of the two input signal-group arrays. 
%
% See also "ComputeStat". 
%
% P.G. Bonanni
% 5/15/21

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check 'Signals' or 'SIGNALS' inputs
[flag1,valid1,errmsg1] = IsSignalGroupArray(SIGNALS1);
[flag2,valid2,errmsg2] = IsSignalGroupArray(SIGNALS2);
if ~flag1
  error('Input ''Signals1'' is not a signal group or signal-group array: %s',errmsg1)
elseif ~flag2
  error('Input ''Signals2'' is not a signal group or signal-group array: %s',errmsg2)
elseif ~valid1
  error('Input ''Signals1'' is not a valid signal group or signal-group array: %s  See "IsSignalGroup".',errmsg1)
elseif ~valid2
  error('Input ''Signals2'' is not a valid signal group or signal-group array: %s  See "IsSignalGroup".',errmsg2)
end
C1 = cellfun(@(x)size(x,1),{SIGNALS1.Values},'Uniform',false);  C1=reshape(C1,size(SIGNALS1));
C2 = cellfun(@(x)size(x,1),{SIGNALS2.Values},'Uniform',false);  C2=reshape(C2,size(SIGNALS2));
if (~isscalar(C1) || ~isscalar(C2)) && (ndims(C1) ~= ndims(C2) || ~all(size(C1) == size(C2)))
  error('Arrays ''SIGNALS1'' and ''SIGNALS2'' must be equal in size.')
elseif ~isscalar(C1) && ~isequal(C1{:})
  error('Data lengths in ''SIGNALS1'' array are not uniform.')
elseif ~isscalar(C2) && ~isequal(C2{:})
  error('Data lengths in ''SIGNALS2'' array are not uniform.')
elseif isscalar(C1) && C1{1} ~= C2{1}
  error('Inputs ''Signals1'' and ''Signals2'' must have equal data length.')
elseif ~isscalar(C1) && C1{1} ~= C2{1}
  error('Arrays ''SIGNALS1'' and ''SIGNALS2'' must have uniform and equal data length.')
end

% Check other inputs
if ~ischar(name) || size(name,1)~=1
  error('Input ''name'' must be a scalar string.')
elseif ~ischar(option) && ~isa(option,'function_handle')
  error('Invalid statistic option or function handle.')
elseif ischar(option) && ~any(strcmp(option,{'meandiff','meanabsdiff','rmsdiff','stddev','corrcoef'}))
  error('Invalid statistic option.')
end

% Build statistical function
if ischar(option)
  switch option
    case 'meandiff'
      fun = @(x,y)mean(y-x,'omitnan');
    case 'meanabsdiff'
      fun = @(x,y)mean(abs(y-x),'omitnan');
    case 'rmsdiff'
      fun = @(x,y)rmsdiff_fun(x,y);
    case 'stddev'
      fun = @(x,y)std(y-x,'omitnan');
    case 'corrcoef'
      fun = @(x,y)corrcoef_fun(x,y);
  end
else  % if function handle
  fun = option;
end

% Locate signal name
i = FindName(name,SIGNALS1(1));
j = FindName(name,SIGNALS2(1));
if isempty(i)
  error('Signal name not found in ''Signals1'' input.')
elseif isempty(j)
  error('Signal name not found in ''Signals2'' input.')
elseif numel(i) > 1
  fprintf('Signal name appears more than once in ''Signals1'' input. Using first instance.\n')
  i = i(1);
elseif numel(j) > 1
  fprintf('Signal name appears more than once in ''Signals2'' input. Using first instance.\n')
  j = j(1);
end

% Compute the statistic
C = cellfun(@(x,y)fun(x(:,i),y(:,j)),{SIGNALS1.Values},{SIGNALS2.Values},'Uniform',false);
if ~all(cellfun(@isscalar,C))
  error('Specified function did not return scalar output(s).')
end

% Assemble as a vector
stat = cat(1,C{:});

% Match the input shape
stat = reshape(stat,size(SIGNALS1));



% ------------------------------------------------------------------------
function val = rmsdiff_fun(x,y)

% RMS difference, ignoring nans.

mask = isnan(x) | isnan(y);
x(mask) = [];
y(mask) = [];
val = norm(y-x)/sqrt(length(x));



% ------------------------------------------------------------------------
function val = corrcoef_fun(x,y)

% Correlation coefficient, ignoring nans.

mask = isnan(x) | isnan(y);
x(mask) = [];
y(mask) = [];
X = corrcoef(x,y);
val = X(2,1);
