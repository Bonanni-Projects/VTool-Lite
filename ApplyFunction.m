function obj = ApplyFunction(obj,fun,Selections)

% APPLYFUNCTION - Apply a function to data in datasets or signal groups.
% Data = ApplyFunction(Data,fun,{'group1','group2',...})
% Data = ApplyFunction(Data,fun,{'signal1','signal2',...})
% Data = ApplyFunction(Data,fun,Selections)
% Data = ApplyFunction(Data,fun,'all')
% Data = ApplyFunction(Data,fun)
% DATA = ApplyFunction(DATA, ...)
% Signals = ApplyFunction(Signals, ...)
% SIGNALS = ApplyFunction(SIGNALS, ...)
%
% Applies a user-specified function 'fun' to a dataset, signal 
% group, dataset array, or signal group array.  For datasets, the 
% 'Selections' input is a cell array specifying a list of signal 
% and/or group names to which the function should be applied. If 
% 'Selections' is omitted (or if the character string 'all' is 
% specified in its place), the function is applied to all groups 
% in the dataset, including 'Time'. 
%
% Functions are applied "in place", replacing the signal or 
% group data to which they are applied.  Functions applied to 
% signals should accept a single column vector argument and 
% produce a column vector output. Functions applied to groups 
% should accept a matrix input and return a matrix with the same 
% number of columns. 
%
% Caution should be taken to ensure that applying the function 
% does not result in a violation of the dataset structure. For 
% example, if a function is applied to signals, it should preserve 
% the signal length.  If a function applies to only a selection of 
% groups, it should preserve the signal length for the dataset as 
% a whole.  However, functions applied to the entire dataset may  
% alter the signal length, provided that the effect on length is 
% the same for all groups, including 'Time'. 
%
% The function works analogously for dataset arrays ('DATA'), 
% signal groups ('Signals'), or signal group arrays ('SIGNALS'), 
% with the 'Selections' argument appropriately specified. 
%
% P.G. Bonanni
% 2/5/20

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 3
  Selections = 'all';
end

% Check first input
[flag1,valid1,errmsg1] = IsSignalGroupArray(obj);
[flag2,valid2,errmsg2] = IsDatasetArray(obj);
if ~flag1 && ~flag2
  error('Input is not a valid signal group, dataset, or array.')
elseif flag1 && ~valid1
  error('Input is not a valid signal group or signal group array: %s  See "IsSignalGroup".',errmsg1)
elseif flag2 && ~valid2
  error('Input is not a valid dataset or dataset array: %s  See "IsDataset".',errmsg2)
elseif isempty(obj)
  error('Input array is empty.')
end

% Check other inputs
if ~isa(fun,'function_handle')
  error('Input ''fun'' is not a valid function handle.')
elseif ~(ischar(Selections) && strcmpi(Selections,'all')) && ...
       ~(iscell(Selections) && all(cellfun(@ischar,Selections)))
  error('Invalid ''Selections'' input.')
end

% Data type checker function
isvalidtype = @(x)isnumeric(x) || isdatetime(x);

% If input is a dataset ...
if IsDataset(obj)
  Data = obj;

  % Get signal group names
  [~,Groups] = GetSignalGroups(Data);

  % If 'Selections' is specified as 'all'
  if ~iscell(Selections)
    Selections = Groups;  % all groups, including 'Time'
  end

  % Loop over selections
  for k = 1:length(Selections)
    selection = Selections{k};

    % If selection is a group ...
    if ismember(selection,Groups)

      % Get input data and apply function
      X = Data.(selection).Values;
      Y = fun(X);

      % Check result
      if ~isvalidtype(Y)
        error('Function ''fun'' is not valid.')
      elseif size(Y,2) ~= size(X,2)
        error('Function ''fun'' is not valid for groups.')
      end

      % Load result in place
      Data.(selection).Values = Y;

    else  % assume selection is a signal name

      % Get input data and apply function
      x = GetSignal(selection,Data);
      y = fun(x);

      % Check result
      if ~isvalidtype(y)
        error('Function ''fun'' is not valid.')
      elseif ~all(size(y)==size(x))
        error('Function ''fun'' is not valid for signals.')
      end

      % Load result in place
      Data = ReplaceSignalInDataset(Data,selection,y);
    end
  end

  % Re-check the dataset
  [flag,valid,errmsg] = IsDataset(Data);
  if ~flag || ~valid
    error('Output dataset is not valid: %s\n',errmsg)
  end

  % Return the result
  obj = Data;

% If input is a dataset array ...
elseif IsDatasetArray(obj)
  DATA = obj;

  % Loop over datasets
  for k = 1:numel(DATA)
    try
      DATA(k) = ApplyFunction(DATA(k),fun,Selections);
    catch
      error('Error occurred at dataset #%d.',k)
    end
  end

  % Return the result
  obj = DATA;

% If input is a signal group ...
elseif IsSignalGroup(obj)
  Signals = obj;

  % If 'Selections' list specified
  if iscell(Selections)

    % Loop over selections
    for k = 1:length(Selections)
      selection = Selections{k};

      % Get input data and apply function
      x = GetSignal(selection,Signals);
      y = fun(x);

      % Check result
      if ~isvalidtype(y)
        error('Function ''fun'' is not valid.')
      elseif ~all(size(y)==size(x))
        error('Function ''fun'' is not valid for signals.')
      end

      % Load result in place
      Signals = ReplaceSignalInGroup(Signals,selection,y);
    end

  else  % if 'all' specified

    % Try the function two ways
    X = Signals.Values;
    flag1 = false;  % initialize
    flag2 = false;  % initialize
    try
      x = X(:,1);  % first signal
      y = fun(x);  % apply to signal data
      if isvalidtype(y) && all(size(y)==size(x))
        flag1 = true;
      end
    catch
      flag1 = false;
    end
    try
      Y = fun(X);  % apply to group data
      if isvalidtype(Y) && ismatrix(Y) && size(Y,2)==size(X,2)
        flag2 = true;
      end
    catch
      flag2 = false;
    end
    if ~flag1 && ~flag2
      error('Function ''fun'' is not valid.')
    end

    % Favor usage on group data
    if flag2

      % Replace group data
      Signals.Values = Y;

    else
      % Loop over all signals
      for k = 1:size(Signals.Values,2)

        % Get input data and apply function
        x = Signals.Values(:,k);
        y = fun(x);

        % Check result
        if ~isvalidtype(y) || ~all(size(y)==size(x))
          error('Function ''fun'' is not valid.')
        end

        % Load result in place
        Signals.Values(:,k) = y;
      end
    end
  end

  % Return the result
  obj = Signals;

% If input is a signal group array ...
elseif IsSignalGroupArray(obj)
  SIGNALS = obj;

  % Loop over signal groups
  for k = 1:numel(SIGNALS)
    try
      SIGNALS(k) = ApplyFunction(SIGNALS(k),fun,Selections);
    catch
      error('Error occurred at signal group #%d.',k)
    end
  end

  % Return the result
  obj = SIGNALS;

end
