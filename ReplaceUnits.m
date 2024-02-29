function [out1,out2] = ReplaceUnits(obj,name,units)

% REPLACEUNITS - Replace a units string in a dataset or signal group.
% Data = ReplaceUnits(Data,name,units)
% DATA = ReplaceUnits(DATA,name,units)
% Signals = ReplaceUnits(Signals,name,units)
% SIGNALS = ReplaceUnits(SIGNALS,name,units)
% [Data,ismatched] = ReplaceUnits(...)
%
% Replaces the units string attribute assigned to a signal.  Input 
% 'name' defines the signal, and 'units' specifies the new units 
% string. 
%
% The function accepts a dataset 'Data' or a signal group 
% 'Signals', or arrays of either, for modification.  If 'name' 
% matches more than one signal within a dataset or signal group, 
% the replacement is performed for all matches. 
%
% When looking for a match, input 'name' may refer to any name 
% layer, and not necessarily the name layer to be modified.  The 
% empty string ('') is also permissible; however, it is considered 
% a match only if it appears on all name layers.
%
% An error is reported if the specified 'name' is not matched.  
% Optionally, a second output argument 'ismatched' can be supplied 
% to suppress the error and return a binary flag to indicate whether 
% a match was found. 
%
% See also "ReplaceDescription" and "ReplaceNameOnLayer". 
%
% P.G. Bonanni
% 8/9/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if IsDataset(obj)

  % Determine which group(s) contain the specified name
  [~,groups] = FindName(name,obj);

  % Loop over groups
  for k = 1:length(groups)
    group = groups{k};
    obj.(group) = ReplaceUnits(obj.(group),name,units);
  end

  % Check if match occurred
  if isempty(groups)
    if nargout < 2
      error('Signal ''%s'' was not found in the dataset.\n',name);
    end
    ismatched = false;
  else
    ismatched = true;
  end

elseif IsSignalGroup(obj)

  % Locate instances of the specified name in the signal group
  index = FindName(name,obj);

  % Modify the name(s) on the specified name layer
  [obj.Units{index}] = deal(units);

  % Check if match occurred
  if isempty(index)
    if nargout < 2
      error('Signal ''%s'' was not found in the signal group.\n',name);
    end
    ismatched = false;
  else
    ismatched = true;
  end

elseif IsDatasetArray(obj) || IsSignalGroupArray(obj)

  % Loop over all elements in the array
  for k = 1:numel(obj)  % one 'ismatched' flag only, since arrays are homogeneous
    [obj(k),ismatched] = ReplaceUnits(obj(k),name,units);
  end

  % Check if match occurred
  if ~ismatched && nargout < 2
    error('Signal ''%s'' was not found in the array.\n',name);
  end

else
  error('Works for datasets, signal groups, and their arrays only.')
end

% Outputs
out1 = obj;
if nargout==2, out2=ismatched; end
