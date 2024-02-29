function DATA = SequenceDatasets(varargin)

% SEQUENCEDATASETS - Sequence datasets contiguously in time.
% DATA = SequenceDatasets(Data1,Data2,Data3, ...)
% DATA = SequenceDatasets(DATA1,DATA2,DATA3, ...)
%
% Accepts one or more datasets (Data1,Data2,Data3,...) or dataset 
% array inputs ('DATA1','DATA2','DATA3',...) and produces a single 
% dataset array 'DATA' representing the input datasets contiguously 
% ordered in elapsed time.  All inputs must have the same fields.  
% Inputs may have time in any real-valued units ('sec', 'min', etc., 
% or unitless), provided all units are the same.  One or more of the 
% inputs may also be in absolute time units (e.g., 'datetime') 
% convertible to elapsed 'sec'.  Time in the output dataset array is 
% expressed in the elapsed-time units of the inputs, or in elapsed 
% 'sec' by default. 
%
% See also "SequenceTime". 
%
% P.G. Bonanni
% 11/11/20

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
  error('One or more inputs is an invalid dataset or dataset array')
end

% Convert from absolute time, as necessary
DATA = arrayfun(@ConvertToElapsedTime,DATA);

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
TimeUnits = arrayfun(@(x)x.Time.Units,DATA,'Uniform',false);
if length(TimeUnits)>1 && ~all(isequal(TimeUnits{:}))
  error('Inputs have incompatible time vectors.')
end

% Perform the sequencing operation
for k = 2:length(DATA)
  Tprev = DATA(k-1).Time.Values(end);
  DATA(k).Time.Values = Tprev + DATA(k).Time.Values;
end
