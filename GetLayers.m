function Layers = GetLayers(obj)

% GETLAYERS - List of name layers in a dataset or signal group.
% Layers = GetLayers(Data)
% Layers = GetLayers(DATA)
% Layers = GetLayers(Signals)
% Layers = GetLayers(SIGNALS)
%
% Returns the list of name layers found in a dataset 
% 'Data' or signal group 'Signals'.  Also works if input 
% is a dataset array 'DATA' or signal-group array 'SIGNALS'. 
%
% P.G. Bonanni
% 2/16/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check input
[flag1,valid1,errmsg1] = IsDataset(obj);
[flag2,valid2,errmsg2] = IsSignalGroup(obj);
[flag3,valid3,errmsg3] = IsDatasetArray(obj);
[flag4,valid4,errmsg4] = IsSignalGroupArray(obj);
if ~flag1 && ~flag2 && ~flag3 && ~flag4
  error('Input is not a valid dataset, signal group, or array.')
elseif flag1 && ~valid1
  error('Input is not a valid dataset: %s  See "IsDataset".',errmsg1)
elseif flag2 && ~valid2
  error('Input is not a valid signal group: %s  See "IsSignalGroup".',errmsg2)
elseif flag3 && ~valid3
  error('Input is not a valid dataset array: %s  See "IsDatasetArray".',errmsg3)
elseif flag4 && ~valid4
  error('Input is not a valid signal group array: %s  See "IsSignalGroupArray".',errmsg4)
end

% If input is a dataset ...
if IsDataset(obj)

  % Input is a dataset
  Data = obj;

  % Get layers from the 'Time' signal group
  Layers = GetLayers(Data.Time);

elseif IsSignalGroup(obj)

  % Input is a signal group
  Signals = obj;

  % Identify name layers
  fields = fieldnames(Signals);
  mask = ~cellfun(@isempty,regexp(fields,'Names$'));
  Layers = fields(mask);

elseif IsDatasetArray(obj) || IsSignalGroupArray(obj)

  % Get layers from first element
  Layers = GetLayers(obj(1));

end
