function obj = ApplyFunction2(obj1,obj2,fun,Selections)

% APPLYFUNCTION2 - Apply a function of two datasets, signal groups, or arrays.
% Data = ApplyFunction2(Data1,Data2,fun,{'group1','group2',...})
% Data = ApplyFunction2(Data1,Data2,fun,{'signal1','signal2',...})
% Data = ApplyFunction2(Data1,Data2,fun,Selections)
% Data = ApplyFunction2(Data1,Data2,fun,'all')
% Data = ApplyFunction2(Data1,Data2,fun)
% DATA = ApplyFunction2(DATA1,DATA2, ...)
% Signals = ApplyFunction2(Signals1,Signals2, ...)
% SIGNALS = ApplyFunction2(SIGNALS1,SIGNALS2, ...)
%
% Applies a user-specified function 'fun' to two datasets, signal 
% groups, dataset arrays, or signal group arrays, yielding a single 
% output object of the same type (e.g., "differencing two datasets). 
% The two input objects must be equal in structure (i.e., groups, 
% layers, ordering and namings of signals) and in data length. 
% For datasets, the 'Selections' input is a cell array specifying a 
% list of signal and/or group names to which the function should be 
% applied. If 'Selections' is omitted, the function is applied to 
% all groups in the dataset except 'Time'; if 'all' is specified, 
% then 'Time' is included as well. 
%
% Outputs of the specified function replace the signal or group data 
% to which they are applied, forming an equally structured output 
% object. Functions applied to signals should accept two equal-
% length column vector arguments and produce a column vector matching 
% in size. Functions applied to groups should accept two equal-sized 
% matrix inputs and return a matrix with the same number of rows and 
% columns. Valid choices include arithmetic function handles @plus, 
% @minus, @times, @rdivide, etc., anonymous functions @(x,y), or 
% handles to any m-functions obeying the size preservation rule. 
%
% APPLYFUNCTION2 works analogously for dataset arrays ('DATA'), signal 
% groups ('Signals'), or signal group arrays ('SIGNALS'), with the 
% 'Selections' argument appropriately specified. Dataset arrays or 
% signal groups arrays are not restricted to dimension 1, and their 
% data length sequences are not required to be uniform, provided 
% a match across the two provided inputs is preserved. 
%
% P.G. Bonanni
% 7/30/26

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 4
  Selections = '';
end

% Check first two inputs
% ---
[flag1,valid1,errmsg1] = IsSignalGroupArray(obj1);
[flag2,valid2,errmsg2] = IsDatasetArray(obj1);
if ~flag1 && ~flag2
  error('Input #1 is not a valid signal group, dataset, or array.')
elseif flag1 && ~valid1
  error('Input #1 is not a valid signal group or signal group array: %s  See "IsSignalGroup".',errmsg1)
elseif flag2 && ~valid2
  error('Input #1 is not a valid dataset or dataset array: %s  See "IsDataset".',errmsg2)
elseif isempty(obj1)
  error('Input array #1 is empty.')
end
% ---
[flag1,valid1,errmsg1] = IsSignalGroupArray(obj2);
[flag2,valid2,errmsg2] = IsDatasetArray(obj2);
if ~flag1 && ~flag2
  error('Input #2 is not a valid signal group, dataset, or array.')
elseif flag1 && ~valid1
  error('Input #2 is not a valid signal group or signal group array: %s  See "IsSignalGroup".',errmsg1)
elseif flag2 && ~valid2
  error('Input #2 is not a valid dataset or dataset array: %s  See "IsDataset".',errmsg2)
elseif isempty(obj2)
  error('Input array #2 is empty.')
end
% ---
if ~isequal(GetLayers(obj1),GetLayers(obj2))
  error('Inputs 1 and 2 have incompatible name layers.')
end
try
  OBJ = [obj1(1),obj2(1)];
catch
  error('Inputs 1 and 2 differ in type.')
end
[flag1,valid1,errmsg1] = IsSignalGroupArray(OBJ);
[flag2,valid2,errmsg2] = IsDatasetArray(OBJ);
if flag1 && ~valid1
  error('The combination of 1 and 2 is not valid: %s',errmsg1)
elseif flag2 && ~valid2
  error('The combination of 1 and 2 is not valid: %s',errmsg2)
elseif ~isequal(size(obj1),size(obj2))
  error('Inputs 1 and 2 differ in size or dimension.')
elseif isscalar(obj1) && GetDataLength(obj1)~=GetDataLength(obj2)
  error('Inputs 1 and 2 have different data length.')
elseif ~isequal(GetDataLength(obj1),GetDataLength(obj2))
  error('One or more data lengths in Input #2 does not match Input #1.')
end

% Check other inputs
if ~isa(fun,'function_handle')
  error('Input ''fun'' is not a valid function handle.')
elseif ~(ischar(Selections) && isempty(Selections)) && ...
       ~(ischar(Selections) && strcmpi(Selections,'all')) && ...
       ~(iscell(Selections) && all(cellfun(@ischar,Selections)))
  error('Invalid ''Selections'' input.')
end

% Data type checker function
isvalidtype = @(x)isnumeric(x) || isdatetime(x);

% If inputs are datasets ...
if IsDataset(obj1)
  Data1 = obj1;
  Data2 = obj2;

  % Initialize output
  Data = Data1;

  % Get signal group names
  [~,Groups] = GetSignalGroups(Data1);

  % If 'Selections' is not a list
  if ~iscell(Selections) && strcmp(Selections,'all')
    Selections = Groups;                           % all groups, including 'Time'
  elseif isempty(Selections)
    Selections = setdiff(Groups,'Time','stable');  % all groups except 'Time'
  end

  % Loop over selections
  for k = 1:length(Selections)
    selection = Selections{k};

    % If selection is a group ...
    if ismember(selection,Groups)

      % Get input data and apply function
      X1 = Data1.(selection).Values;
      X2 = Data2.(selection).Values;
      Y = fun(X1,X2);

      % Check result
      if ~isvalidtype(Y)
        error('Function ''fun'' is not valid.')
      elseif ~all(size(Y)==size(X1))
        error('Function ''fun'' is not valid for groups.')
      end

      % Load result
      Data.(selection).Values = Y;

    else  % assume selection is a signal name

      % Get input data and apply function
      x1 = GetSignal(selection,Data1);
      x2 = GetSignal(selection,Data2);
      y = fun(x1,x2);

      % Check result
      if ~isvalidtype(y)
        error('Function ''fun'' is not valid.')
      elseif ~all(size(y)==size(x1))
        error('Function ''fun'' is not valid for signals.')
      end

      % Load result
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

% If inputs are dataset arrays ...
elseif IsDatasetArray(obj1)
  DATA1 = obj1;
  DATA2 = obj2;

  % Initialize output
  DATA = DATA1;

  % Loop over datasets
  for k = 1:numel(DATA1)
    try
      DATA(k) = ApplyFunction2(DATA1(k),DATA2(k),fun,Selections);
    catch
      error('Error occurred at dataset #%d.',k)
    end
  end

  % Return the result
  obj = DATA;

% If inputs are signal groups ...
elseif IsSignalGroup(obj1)
  Signals1 = obj1;
  Signals2 = obj2;

  % Initialize output
  Signals = Signals1;

  % If 'Selections' list specified
  if iscell(Selections)

    % Loop over selections
    for k = 1:length(Selections)
      selection = Selections{k};

      % Get input data and apply function
      x1 = GetSignal(selection,Signals1);
      x2 = GetSignal(selection,Signals2);
      y = fun(x1,x2);

      % Check result
      if ~isvalidtype(y)
        error('Function ''fun'' is not valid.')
      elseif ~all(size(y)==size(x))
        error('Function ''fun'' is not valid for signals.')
      end

      % Load result
      Signals = ReplaceSignalInGroup(Signals,selection,y);
    end

  else  % if 'all', or no 'Selections' specified

    % Try the function two ways
    X1 = Signals1.Values;
    X2 = Signals2.Values;
    flag1 = false;  % initialize
    flag2 = false;  % initialize
    try
      x1 = X1(:,1);  % first signal
      x2 = X2(:,1);  % first signal
      y = fun(x1,x2);  % apply to signal data
      if isvalidtype(y) && all(size(y)==size(x))
        flag1 = true;
      end
    catch
      flag1 = false;
    end
    try
      Y = fun(X1,X2);  % apply to group data
      if isvalidtype(Y) && ismatrix(Y) && all(size(Y)==size(X1))
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
      for k = 1:size(Signals1.Values,2)

        % Get input data and apply function
        x1 = Signals1.Values(:,k);
        x2 = Signals2.Values(:,k);
        y = fun(x1,x2);

        % Check result
        if ~isvalidtype(y) || ~all(size(y)==size(x1))
          error('Function ''fun'' is not valid.')
        end

        % Load result
        Signals.Values(:,k) = y;
      end
    end
  end

  % Return the result
  obj = Signals;

% If inputs are signal group arrays ...
elseif IsSignalGroupArray(obj1)
  SIGNALS1 = obj1;
  SIGNALS2 = obj2;

  % Initialize output
  SIGNALS = SIGNALS1;

  % Loop over signal groups
  for k = 1:numel(SIGNALS1)
    try
      SIGNALS(k) = ApplyFunction(SIGNALS1(k),SIGNALS2(k),fun,Selections);
    catch
      error('Error occurred at signal group #%d.',k)
    end
  end

  % Return the result
  obj = SIGNALS;

end
