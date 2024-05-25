function obj = RenameLayer(obj,oldlayers,newlayers)

% RENAMELAYER - Rename one or more name layers.
% Data = RenameLayer(Data,'oldlayer','newlayer')
% Data = RenameLayer(Data,{'oldlayer1','oldlayer2',...},{'newlayer1','newlayer2',...})
% Signals = RenameLayer(Signals,'oldlayer','newlayer')
% Signals = RenameLayer(Signals,{'oldlayer1','oldlayer2',...},{'newlayer1','newlayer2',...})
% DATA = RenameLayer(DATA, ...)
% SIGNALS = RenameLayer(SIGNALS, ...)
%
% Rename one or more name layers within a dataset, dataset array, 
% signal group or signal group array. Accepts either single strings 
% (e.g., 'oldname' and 'newname') or equal-length cell arrays of 
% strings specifying the old and corresponding new layer names. 
%'
% See also "RenameField". 
%
% P.G. Bonanni
% 5/24/24

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check arguments
flag1 = IsDatasetArray(obj);
flag2 = IsSignalGroupArray(obj);
if ~flag1 && ~flag2
  error('Works for datasets, signal groups, and their arrays only.')
elseif ~ischar(oldlayers) && ~iscellstr(oldlayers)
  error('Input ''oldlayers'' is invalid.')
elseif ~ischar(newlayers) && ~iscellstr(newlayers)
  error('Input ''newlayers'' is invalid.')
end

% Make cell arrays if single strings provided
if ischar(oldlayers), oldlayers={oldlayers}; end
if ischar(newlayers), newlayers={newlayers}; end

% Make lists
oldlayers = oldlayers(:);
newlayers = newlayers(:);

% In case "source strings" provided in place of "layer names"
oldlayers = cellfun(@Source2Layer,oldlayers,'Uniform',false);
newlayers = cellfun(@Source2Layer,newlayers,'Uniform',false);

% Get fieldnames
layers = GetLayers(obj);

% Check lengths
if length(oldlayers)~=length(newlayers)
  error('Number of old and new layer names must match.')
end

% Check that all specified (old) name layers are present
if any(~ismember(oldlayers,layers))
  error('One or more specified name layers not present in the input object.')
end

% If a dataset or dataset array
if IsDatasetArray(obj)

  % Get signal group names
  [~,groups] = GetSignalGroups(obj(1));

  % Loop over groups
  for k = 1:length(groups)
    group = groups{k};
    SIGNALS = [obj.(group)];
    SIGNALS = RenameField(SIGNALS,oldlayers,newlayers);
    C=num2cell(SIGNALS);  [obj.(group)]=deal(C{:});
  end

% If a signal group or signal group array
elseif IsSignalGroupArray(obj)

  % Only one set of field names to change
  obj = RenameField(obj,oldlayers,newlayers);

end

% Output
out = obj;
