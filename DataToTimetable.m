function Table = DataToTimetable(Data,layer)

% DATATOTIMETABLE - Convert a dataset to timetable form.
% Table = DataToTimetable(Data [,layer])
%
% Constructs an NxM timetable from a VTool dataset, where N is the 
% data length and M is the total number of signals. Signal names 
% must be unique.  Optional input 'layer' specifies the name layer 
% from which to extract variable names.  If missing or empty, the 
% default names are extracted (see "GetDefaultNames"). 
%
% See also "BuildDatasetFromData". 
%
% P.G. Bonanni
% 7/11/23

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 2
  layer = '';
end

% Check 'Data' argument
if numel(Data) > 1
  error('Works for scalar datasets only.')
end
[flag,valid] = IsDataset(Data);
if ~flag || ~valid
  error('Input ''Data'' is not a valid dataset.  See "IsDataset".')
end

% Collect signals into a master group
Signals = CollectSignals(Data);

% Extract signal names
if ~isempty(layer)
  layer = Source2Layer(layer);
  Names = Signals.(layer);
else
  Names = GetDefaultNames(Signals);
end

% Check that names are unique
if ~isequal(Names,unique(Names,'stable'))
  error('Signal names must be unique.')
end

% Get time vector
t = Data.Time.Values;
if isnumeric(t), t=seconds(t); end

% Extract data and remaining attributes
CData        = num2cell(Signals.Values,1);
Units        = Signals.Units;
Descriptions = Signals.Descriptions;

% Build the timetable
Table = timetable(t,CData{:},'VariableNames',Names);
Table.Properties.VariableUnits        = Units;
Table.Properties.VariableDescriptions = Descriptions;
