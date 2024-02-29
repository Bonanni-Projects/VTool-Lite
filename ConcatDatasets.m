function DataOut = ConcatDatasets(varargin)

% CONCATDATASETS - Concatenate datasets into a single dataset.
% DataOut = ConcatDatasets(Data1,Data2,Data3, ...)
% DataOut = ConcatDatasets(DATA1,DATA2,DATA3, ...)
% DataOut = ConcatDatasets(DATA)
%
% Accepts one or more datasets (Data1,Data2,Data3,...) or 
% dataset array inputs ('DATAi') and produces a single dataset 
% with the signals in all groups concatenated.  All inputs must 
% have the same fields.  If the "attribute"  fields of all datasets 
% (i.e., the non-signal-group fields) are equal, these attributes 
% are transfered directly to the output dataset.  If not, a new set 
% of attributes is derived by combining the attributes of the original 
% dataset inputs. 
%
% Note: no adjustment beyond concatenation is performed on the 
% 'Time' group.  See function "SequenceDatasets" and function 
% "ConvertToElapsedTime" for options on modifying 'Time' groups 
% before or after concatenation. 
%
% See also "ConcatSignalGroups". 
%
% P.G. Bonanni
% 3/16/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check calling syntax
args = varargin;  % initialize
mask = cellfun(@isstruct,args);
if isempty(args) || ~all(mask), error('Invalid usage.'); end

% Check that input structures/arrays have the same fields
Fields = cellfun(@fieldnames,args,'Uniform',false);
Fields = cellfun(@sort,Fields,'Uniform',false);
if length(Fields)>1 && ~all(isequal(Fields{:}))
  error('Input structures are not compatible.')
end

% Build complete 'DATA' structure array by stacking all inputs, including arrays
args = cellfun(@(x)x(:),args,'Uniform',false);  % ensure all arrays are columns
DATA = cat(1,args{:});

% Check that all elements are valid datasets
[Flag,Valid] = arrayfun(@IsDataset,DATA);
if ~all(Flag) || ~all(Valid)
  error('One or more inputs is an invalid dataset or dataset array.')
end

% Check that inputs are compatible
Fields = arrayfun(@(x)fieldnames(x.Time),DATA,'Uniform',false);
Fields = cellfun(@sort,Fields,'Uniform',false);
if length(Fields)>1 && ~all(isequal(Fields{:}))
  error('Inputs have missing/incompatible name layers.')
end
C = arrayfun(@GetNamesMatrix,DATA,'Uniform',false);
if length(DATA)>1 && ~all(isequal(C{:}))
  error('Non-homogeneous inputs. Names and/or name orders do not match.')
end
C = cell(size(DATA));  % initialize
for k = 1:numel(DATA)
  Signals = CollectSignals(DATA(k));
  C{k} = Signals.Units;
end
if length(DATA)>1 && ~all(isequal(C{:}))
  [DATA,success] = ReconcileUnits(DATA);
  if ~success
    error('Non-homogeneous inputs. Units do not match.')
  end
end
TimeUnits = arrayfun(@(x)x.Time.Units,DATA,'Uniform',false);
if length(TimeUnits)>1 && ~all(isequal(TimeUnits{:}))
  error('Inputs have incompatible time vectors. Possibly mixing absolute/elapsed time.')
end

% Identify signal-group fields
[~,fields] = GetSignalGroups(DATA(1));

% Rename 'pathname' field to 'pathnames' and make cell arrays, if necessary
if ismember('pathname',fieldnames(DATA))
  fprintf('Renaming ''pathname'' field(s) to ''pathnames''.\n');
  fields1 = fieldnames(DATA);  C = struct2cell(DATA);
  fields1{strcmp('pathname',fields1)} = 'pathnames';
  DATA = cell2struct(C,fields1,1);
  C = {DATA.pathnames};  % next, convert strings to cell arrays
  C = cellfun(@cellstr,C,'Uniform',false);
  [DATA.pathnames] = deal(C{:});
end

% Check if attribute fields are equal, 
% ... and combine attributes if necessary.
ATTRIB = rmfield(DATA,fields);
fields1 = fieldnames(ATTRIB);
for j = 1:length(fields1)
  field = fields1{j};
  if numel(ATTRIB) > 1 && ~isequaln(ATTRIB.(field))
    fprintf('WARNING: ''%s'' fields are not equal.  Concatenating those.\n',field)
    if ischar(DATA(1).(field))
      C = strcat('~',{DATA(2:end).(field)})';
      C = [DATA(1).(field); C(:)];
      DATA(1).(field) = strcat(C{:});
    else
      DATA(1).(field) = cat(1,DATA.(field));
    end
  end
end

% Concatenate
DataOut = DATA(1);  % initialize
for k = 2:length(DATA)
  for j = 1:length(fields)
    field = fields{j};
    DataOut.(field).Values = [DataOut.(field).Values; DATA(k).(field).Values];
  end
end
