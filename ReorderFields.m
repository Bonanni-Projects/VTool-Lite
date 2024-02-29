function out = ReorderFields(obj)

% REORDERFIELDS - Re-order fields to standard order.
% Data = ReorderFields(Data)
% DATA = ReorderFields(DATA)
% Signals = ReorderFields(Signals)
% SIGNALS = ReorderFields(SIGNALS)
%
% Re-orders the fields of a dataset or signal group to 
% the standard order. Also works for arrays of same. 
%
% P.G. Bonanni
% 2/29/20

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check input
if isempty(obj)
  error('Works for non-empty arrays only.')
end

% Re-order according to input type
if IsDatasetArray(obj)  % if scalar dataset or dataset array
  DATA = obj;

  % Get fieldnames
  fields = fieldnames(DATA);

  % Get signal groups, and order 'Time' first
  [~,groups] = GetSignalGroups(DATA(1));
  groups = ['Time'; setdiff(groups,'Time','stable')];

  % First fix the field order within signal groups
  for j = 1:numel(DATA)
    for k = 1:length(groups)
      group = groups{k};
      DATA(j).(group) = ReorderFields(DATA(j).(group));
    end
  end

  % Non-signal-group fields
  fields = setdiff(fields,groups,'stable');

  % Build list of non-signal group fields
  fields1 = {};  % initialize
  if isfield(DATA,'casename')
    fields1 = [fields1; 'casename'];
  end
  if isfield(DATA,'pathnames')
    fields1 = [fields1; 'pathnames'];
  end
  if isfield(DATA,'start')
    fields1 = [fields1; 'start'];
  end
  % Order the non-signal-group fields
  fields1 = [fields1; setdiff(fields,fields1,'stable')];

  % Build the standard order
  fieldsS = [fields1',groups'];
  if isfield(DATA,'source')  % move 'source' to last, if present
    fieldsS = [setdiff(fieldsS,'source','stable'), 'source'];
  end

  % Apply the order
  DATA = orderfields(DATA,fieldsS);

  % Output
  out = DATA;

elseif IsSignalGroupArray(obj)  % if scalar signal group, or signal group array
  SIGNALS = obj;

  % Get name layers from the input
  layers = GetLayers(SIGNALS);

  % Read MASTER Look-Up Table from NameTables, if present
  if exist("NameTables.xlsx",'file')
    [~,~,Layers,~] = ReadMasterLookup;
  else  % no standard order for layers
    Layers = layers;
  end

  % Derive the new fieldname order, and apply it
  layersA = intersect(Layers,layers,'stable');
  layersB = setdiff(layers,layersA,'stable');
  fields1 = [layersA',layersB',{'Values','Units','Descriptions'}];
  SIGNALS = orderfields(SIGNALS,fields1);

  % Output
  out = SIGNALS;

else
  error('Input object not recognized.')
end
