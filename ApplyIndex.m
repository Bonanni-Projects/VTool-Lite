function obj = ApplyIndex(obj,index,option)

% APPLYINDEX - Apply integer or binary index to signals or groups.
% Data = ApplyIndex(Data,index [,'all'])
% Data = ApplyIndex(Data,mask [,'all'])
% DATA = ApplyIndex(DATA, ...)
% Signals = ApplyIndex(Signals, ...)
% SIGNALS = ApplyIndex(SIGNALS, ...)
%
% Applies indexing to the full contents of dataset 'Data'. 
% The indexing is specified by an integer vector 'index', or 
% by a binary 'mask' vector of length matching the dataset's 
% data length. In the special case of an empty index vector, an 
% "empty" version of the dataset results, i.e., one containing 
% all groups, but with data length equal to 0.  The modified 
% dataset is returned as output. 
%
% The function works analogously for dataset arrays ('DATA'), 
% signal groups ('Signals'), or signal group arrays ('SIGNALS'). 
%
% The 'all' option applies to dataset inputs, and specifies that 
% indexing should also be applied to any non-signal-group fields 
% having dimensions matching the signals in the dataset, i.e., 
% Nx1, where N is the data length. 
%
% P.G. Bonanni
% 12/15/22

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 3
  option = '';
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

% Determine data length
if IsDatasetArray(obj)  % if dataset or dataset array
  N = length(obj(1).Time.Values);  % data length
else  % if signal group or signal group array
  N = size(obj(1).Values,1);  % data length
end

% Check 'index' input (Note: can be 'mask')
if ~isnumeric(index) && ~islogical(index)
  error('Invalid ''index'' input.')
elseif isnumeric(index) && (any(index < 1) || any(index > N))
  error('One or more ''index'' values is out of range.')
elseif isnumeric(index) && any(rem(index,1)~=0)
  error('One or more ''index'' values is not valid.')
elseif islogical(index) && (~isvector(index) || length(index)~=N)
  error('Invalid or wrong size ''mask'' input.')
end

% If input is a dataset ...
if IsDataset(obj)
  Data = obj;

  % Get signal group names and field names
  [~,Groups] = GetSignalGroups(Data);
  fields = fieldnames(Data);

  % Get dataset length
  N = GetDataLength(Data);

  % Loop over groups
  for k = 1:length(Groups)
    group = Groups{k};

    % Apply indexing to group
    Data.(group).Values = Data.(group).Values(index,:);
  end

  % If 'all' option specified
  if strcmp(option,'all')
    fields = setdiff(fields,Groups);
    for k = 1:length(fields)
      field = fields{k};
      if iscolumn(Data.(field)) && numel(Data.(field))==N
        Data.(field) = Data.(field)(index);
      end
    end
  end

  % Return the result
  obj = Data;

% If input is a dataset array ...
elseif IsDatasetArray(obj)
  DATA = obj;

  % Loop over datasets
  for k = 1:numel(DATA)
    try
      DATA(k) = ApplyIndex(DATA(k),index,option);
    catch
      error('Error occurred at dataset #%d.',k)
    end
  end

  % Return the result
  obj = DATA;

% If input is a signal group ...
elseif IsSignalGroup(obj)
  Signals = obj;

  % Apply indexing to group
  Signals.Values = Signals.Values(index,:);

  % Return the result
  obj = Signals;

% If input is a signal group array ...
elseif IsSignalGroupArray(obj)
  SIGNALS = obj;

  % Loop over signal groups
  for k = 1:numel(SIGNALS)
    try
      SIGNALS(k) = ApplyIndex(SIGNALS(k),index);
    catch
      error('Error occurred at signal group #%d.',k)
    end
  end

  % Return the result
  obj = SIGNALS;

end
