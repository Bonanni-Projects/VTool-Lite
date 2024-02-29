function mask = ComputeFilterMask(SIGNALS,nameF,rangesF)

% ComputeFilterMask - Compute a filter mask from a signal group array.
% mask = ComputeFilterMask(SIGNALS,nameF,rangesF)
% mask = ComputeFilterMask(SIGNALS,nameF,valuesF)
%
% Computes a binary filter mask indicating which elements of signal 
% group array 'SIGNALS' meet an acceptance criterion applied to a 
% the named signal 'nameF'.  The criterion is specified by providing 
% one of the following two inputs as a third argument to the function: 
%   'rangesF'   -  nx2 matrix of "valid ranges" for the 'nameF' 
%                  signal, each row defining a [min,max] interval. 
%                  A case is considered valid if the 'nameF' signal 
%                  remains within valid intervals for the full 
%                  signal duration. 
%   'valuesF'   -  vector of "valid values" for the 'nameF' signal. 
%                  Similar to 'rangesF', but applicable if the 
%                  'nameF' signal is discrete. A case is considered 
%                  valid if the 'nameF' signal takes on only values 
%                  specified in this vector for the full signal 
%                  duration.  (Note: a 2-element vector should be 
%                  provided in column format to distinguish it from 
%                  a range specification.) 
% The output 'mask' has dimensions matching those of the input 
% signal group array. 
%
% P.G. Bonanni
% 4/7/20

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check 'SIGNALS' argument
[flag,valid] = IsSignalGroupArray(SIGNALS);
if ~flag || ~valid
  error('Input ''SIGNALS'' is not a valid signal group array.  See "IsSignalGroupArray".')
end

% Check remaining arguments
if ~ischar(nameF) || isempty(nameF)
  error('Specified ''nameF'' is not valid.')
elseif ~isnumeric(rangesF) || isempty(rangesF) || ~ismatrix(rangesF)
  error('Specified ''rangesF'' or ''valuesF'' is not valid.')
elseif ~isvector(rangesF) && (size(rangesF,2)~=2 || any(diff(rangesF,[],2) < 0))
  error('Specified ''rangesF'' is not valid.')
end

% Get input size
v = size(SIGNALS);

% Locate the filtering signal
if ~isempty(nameF)
  i = FindName(nameF,SIGNALS(1));
  if isempty(i)
    error('Signal ''%s'' not found.',nameF);
  elseif numel(i) > 1
    fprintf('Signal ''%s'' appears more than once. Using first instance.\n',nameF);
    i = i(1);
  end
end

% Collect filtering signal from all cases
C = arrayfun(@(x)x.Values(:,i),SIGNALS,'Uniform',false);
X = cat(2,C{:});

% If 'rangesF' specified ...
if size(rangesF,2) == 2
  Mask = false(size(X));  % initialize
  for k = 1:size(rangesF,1)
    Mask = Mask | (X >= rangesF(k,1) & X <= rangesF(k,2));
  end
else  % if 'valuesF' specified ...
  valuesF = rangesF;
  Mask = ismember(X,valuesF);
end

% Mark columns meeting criterion
mask = all(Mask);

% Reshape 'mask' to match input size
mask = reshape(mask,v);
