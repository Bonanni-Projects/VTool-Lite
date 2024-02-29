function [out1,out2] = ReplaceNameOnLayer(obj,name1,name2,layer)

% REPLACENAMEONLAYER - Replace a signal name in a dataset or signal group.
% Data = ReplaceNameOnLayer(Data,name1,name2,layer)
% DATA = ReplaceNameOnLayer(DATA,name1,name2,layer)
% Signals = ReplaceNameOnLayer(Signals,name1,name2,layer)
% SIGNALS = ReplaceNameOnLayer(SIGNALS,name1,name2,layer)
% [Data,ismatched] = ReplaceNameOnLayer(...)
%
% Replaces the name assigned to a given signal on a specified 
% name layer.  Input 'name1' defines the signal to be modified, 
% 'name2' specifies the name to assign, and 'layer' specifies 
% the name layer for modification. 
%
% The function accepts a dataset 'Data' or a signal group 
% 'Signals', or arrays of either, for modification.  If 'name1' 
% matches more than one signal within a dataset or signal group, 
% the replacement is performed for all matches. 
%
% When looking for a match, input 'name1' may refer to any name 
% layer, and not necessarily the name layer to be modified.  The 
% empty string ('') is also permissible; however, it is considered 
% a match only if it appears on all name layers.
%
% Names on all layers aside from the specified 'layer' are left 
% unmodified, even if other layers yielded the match to 'name1'. 
%
% An error is reported if the specified 'name1' is not matched.  
% Optionally, a second output argument 'ismatched' can be supplied 
% to suppress the error and return a binary flag to indicate whether 
% a match was found. 
%
% See also "ReplaceDescription" and "ReplaceUnits". 
%
% P.G. Bonanni
% 8/9/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if IsDataset(obj)

  % Determine which group(s) contain the specified name
  [~,groups] = FindName(name1,obj);

  % Loop over groups
  for k = 1:length(groups)
    group = groups{k};
    obj.(group) = ReplaceNameOnLayer(obj.(group),name1,name2,layer);
  end

  % Check if match occurred
  if isempty(groups)
    if nargout < 2
      error('Signal ''%s'' was not found in the dataset.\n',name1);
    end
    ismatched = false;
  else
    ismatched = true;
  end

elseif IsSignalGroup(obj)

  % Locate instances of the specified name in the signal group
  index = FindName(name1,obj);

  % In case 'layer' is a source string ...
  layer = Source2Layer(layer);

  % Check layer against the existing layers
  layers = GetLayers(obj);
  if ~ismember(layer,layers)
    error('Name layer ''%s'' is not present in the signal group.\n',layer);
  end

  % Modify the name(s) on the specified name layer
  [obj.(layer){index}] = deal(name2);

  % Check if match occurred
  if isempty(index)
    if nargout < 2
      error('Signal ''%s'' was not found in the signal group.\n',name1);
    end
    ismatched = false;
  else
    ismatched = true;
  end

elseif IsDatasetArray(obj) || IsSignalGroupArray(obj)

  % Loop over all elements in the array
  for k = 1:numel(obj)  % one 'ismatched' flag only, since arrays are homogeneous
    [obj(k),ismatched] = ReplaceNameOnLayer(obj(k),name1,name2,layer);
  end

  % Check if match occurred
  if ~ismatched && nargout < 2
    error('Signal ''%s'' was not found in the array.\n',name1);
  end

else
  error('Works for datasets, signal groups, and their arrays only.')
end

% Outputs
out1 = obj;
if nargout==2, out2=ismatched; end
