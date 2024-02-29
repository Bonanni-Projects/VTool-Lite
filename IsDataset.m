function varargout = IsDataset(Data)

% ISDATASET - Identify and check a dataset for validity.
% [flag,valid,errmsg] = IsDataset(Data)
% IsDataset(Data)
%
% Returns a 'flag' value of TRUE if 'Data' is a 1x1 dataset, 
% and FALSE if not.  To be identified as a dataset, input 
% 'Data' must be a 1x1 structure that includes at least a 
% valid 'Time' signal group. 
%
% Returns a 'valid' value of TRUE if all identifiable signal 
% groups contained in the dataset are valid, have matching 
% name layers, name layer orders, data types, and data lengths.  
% If the dataset is determined to be invalid, output string 
% 'errmsg' indicates the type of error found. 
%
% If called without output arguments, the function reports 
% the results of error checking without returning any outputs. 
%
% See also "IsDatasetArray". 
%
% P.G. Bonanni
% 4/4/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargout == 0
  % Report the results of error checking
  [flag,valid,errmsg] = IsDataset(Data);
  if flag && valid
    fprintf('Input is a valid dataset.\n');
  else
    fprintf('Not a valid dataset: %s\n',errmsg)
  end

else
  % Initialize
  flag  = true;
  valid = true;
  errmsg = '';
  varargout = {flag,valid,errmsg};

  % Check if a structure and scalar
  if ~isstruct(Data)
    flag  = false;
    valid = false;
    errmsg = 'Not a structure.';
    varargout = {flag,valid,errmsg};
    return
  elseif numel(Data)~=1
    flag  = false;
    valid = false;
    errmsg = 'Not a scalar structure.';
    varargout = {flag,valid,errmsg};
    return
  end

  % Check for a valid 'Time' signal group
  if ~isfield(Data,'Time')
    flag  = false;
    valid = false;
    errmsg = 'Missing ''Time'' field.';
    varargout = {flag,valid,errmsg};
    return
  end
  [flagT,validT] = IsSignalGroup(Data.Time,'Time');
  if ~flagT || ~validT
    flag  = false;
    valid = false;
    errmsg = 'The ''Time'' field is not a valid signal group.';
    varargout = {flag,valid,errmsg};
    return
  end

  % Identify and collect signal groups
  [s,fields] = GetSignalGroups(Data);

  % Check for at least one non-Time signal group
  if isempty(setdiff(fields,'Time'))
    flag  = false;
    valid = false;
    errmsg = 'Dataset must contain at least one non-Time signal group.';
    varargout = {flag,valid,errmsg};
    return
  end

  % Check that all groups are valid
  [~,Valid] = structfun(@IsSignalGroup,s);
  if ~all(Valid)
    valid = false;
    str = sprintf('''%s'',',fields{~Valid}); str(end)=[];
    errmsg = sprintf('Contains invalid signal group(s): {%s}.',str);
    varargout = {flag,valid,errmsg};
    return
  end

  % Get name layers for all signal groups
  C = struct2cell(s);  % cell array of signal groups
  Layers  = cellfun(@GetLayers,C,'Uniform',false);  % unsorted
  Layers1 = cellfun(@sort,Layers,'Uniform',false);  % sorted

  % Check that all groups have the same name layers
  if length(Layers) > 1 && ~isequal(Layers1{:})
    valid = false;
    errmsg = 'Signal group name layers do not match.';
    varargout = {flag,valid,errmsg};
    return
  end

  % Check that all groups have the same name layer order
  if length(Layers) > 1 && ~isequal(Layers{:})
    valid = false;
    errmsg = 'Order of name layers does not match across all signal groups.';
    varargout = {flag,valid,errmsg};
    return
  end

  % Check that all groups (except 'Time') have the same data type
  C = struct2cell(rmfield(s,'Time'));  % cell array of signal groups
  Class = cellfun(@(x)class(x.Values),C,'Uniform',false);
  if length(Class) > 1 && ~isequal(Class{:})
    valid = false;
    errmsg = 'Data types do not match across all signal groups.';
    varargout = {flag,valid,errmsg};
    return
  end

  % Check that all groups have the same data length
  C = struct2cell(s);  % cell array of signal groups, including 'Time'
  Lengths = cellfun(@(x)size(x.Values,1),C,'Uniform',false);
  if ~isequal(Lengths{:})
    valid = false;
    errmsg = 'Signal groups have incompatible data lengths.';
    varargout = {flag,valid,errmsg};
    return
  end
end
