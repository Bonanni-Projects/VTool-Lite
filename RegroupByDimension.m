function Data1 = RegroupByDimension(Data,varargin)

% REGROUPBYDIMENSION - Regroup a dataset by signal dimension.
% Data1 = RegroupByDimension(Data)
% Data1 = RegroupByDimension(Data,layer)
% Data1 = RegroupByDimension(...,'stable')
%
% Redefines signal groups in a dataset according to signal 
% dimension. Input 'Data' is a dataset containing a combination 
% of 1-dimensional and multi-dimensional signals, the latter being
% identified by signal names having a common base name and ending 
% in numerals.  Examples are {'deflection1', 'deflection2', ...}, 
% or {'pos11', 'pos12', 'pos21', 'pos22').  The numerals need 
% not be contiguous.  Output dataset 'Data1' is returned with 
% 1-dimensional signals grouped into signal group 'Scalars', and 
% multi-dimentional signals grouped according to base name. 
%
% Optional input 'layer' specifies the name layer to use when 
% classifying signals.  If 'layer' is specified as [] or not 
% provided, the default signal names are used (see function 
% "GetDefaultNames").  The signals and groups are assembled 
% alphabetically by default; however, if the 'stable' option is 
% specified , they are assembled in the order encountered in the 
% original dataset. 
%
% P.G. Bonanni
% 8/28/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


args = varargin;
if isempty(args)
  layer = [];
  option = '';
else
  if ischar(args{end}) && strcmp(args{end},'stable')
    option = 'stable';
    args(end) = [];
  else
    option = '';
  end
  if isempty(args)
    layer = [];
  elseif length(args) == 1
    layer = args{1};
  else
    error('Too many input arguments.')
  end
end

% Collect signals into a master group
Master = CollectSignals(Data);

% Get signal names
if ~isempty(layer)
  layer = Source2Layer(layer);  % in case 'layer' is a source string
  Names = Master.(layer);
else
  % Get the default names
  Names = GetDefaultNames(Master);
end

% Remove duplicates, and alphabetize if required
if strcmp(option,'stable')
  Names1 = unique(Names,'stable');
else  % (default)
  % Sort using method that accounts for trailing numbers
  Names1 = SortNames(Names);
end

% ------------------------------------
% Identify multi-dimensional signals
% ------------------------------------

% Collect the base names
Basenames = regexprep(Names1,'[_]?[0-9]+$','');

% Find the repeated set
if strcmp(option,'stable')
  names = unique(Basenames,'stable');
else  % Sort using "unique", because there are no trailing numbers
  names = unique(Basenames);
end
n = zeros(size(names));  % initialize
for k = 1:length(names)
  mask = strcmp(names{k},Basenames);
  n(k) = sum(mask);
end
% Repeated basenames
BasenamesR = names(n > 1);

% Detect the names ending in numerals
mask1 = ~cellfun(@isempty,regexp(Names1,'[0-9]+$','match'));

% Mark the scalar signals (include names ending in numerals, but base name not repeated)
maskS = ~mask1 | (mask1 & ~ismember(Basenames,BasenamesR));

% ------------------------------------
% Build output dataset
% ------------------------------------

% Determine group and non-group field names
[~,groups] = GetSignalGroups(Data);         % groups
fields  = fieldnames(Data);                 % all fields (preserving order)
fields1 = setdiff(fields,groups,'stable');  % non-group fields, preserving order

% Transfer fields that precede the signal groups
for k = 1:length(fields)
  field = fields{k};
  if ismember(field,groups), break, end
  Data1.(field) = Data.(field);
  fields1 = setdiff(fields1,field,'stable');
end

% Transfer the 'Time' group
Data1.Time = Data.Time;

% Add new 'Scalars' group
if any(maskS)
  group = 'Scalars';
  selections = Names1(maskS);
  Data1.(group) = SelectFromGroup(selections,Master);
end

% Add groups representing multidimensional signals
for k = 1:length(BasenamesR)
  group = BasenamesR{k};
  mask = strcmp(group,Basenames);
  selections = Names1(mask);
  Data1.(group) = SelectFromGroup(selections,Master);
end

% Transfer remaining non-group fields
for k = 1:length(fields1)
  field = fields1{k};
  Data1.(field) = Data.(field);
end



% -------------------------------------------------------------
function names = SortNames(names)

% Sorts the list of names in alphabetic order, accounting 
% for trailing numerals that have varying number of digits. 
% For example, {'a1','a10','a9'} becomes {'a1','a9','a10'}. 

% Get base names
Basenames = regexprep(names,'[0-9]+$','');

% Get trailing numerals
C = regexp(names,'([0-9]+)$','tokens');
mask = ~cellfun(@isempty,C);
Numbers = repmat({''},size(names));  % initialize
C1 = cellfun(@(x)x{:}{:},C(mask),'Uniform',false);
[Numbers{mask}] = deal(C1{:});

% Add leading zeros where needed
mask = ~cellfun(@isempty,Numbers);
x = str2double(Numbers(mask));
digits = ceil(log10(max(x)));
format = sprintf('%%0%dd',digits);
C = cellstr(num2str(x,format));
[Numbers{mask}] = deal(C{:});

% Determine sort order with leading zeros added
[~,i] = sort(strcat(Basenames,Numbers));

% Sort the names
names = names(i);
