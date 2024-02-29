function [out1,out2] = ReplaceDescription(obj,name,description)

% REPLACEDESCRIPTION - Replace a description string in a dataset or signal group.
% Data = ReplaceDescription(Data,name,description)
% DATA = ReplaceDescription(DATA,name,description)
% Signals = ReplaceDescription(Signals,name,description)
% SIGNALS = ReplaceDescription(SIGNALS,name,description)
% [Data,ismatched] = ReplaceDescription(...)
%
% Replaces the description string assigned to a signal.  Input 
% 'name' defines the signal, and 'description' specifies the new 
% description string. 
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
% See also "ReplaceUnits" and "ReplaceNameOnLayer". 
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
    obj.(group) = ReplaceDescription(obj.(group),name,description);
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
  [obj.Descriptions{index}] = deal(description);

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
    [obj(k),ismatched] = ReplaceDescription(obj(k),name,description);
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
