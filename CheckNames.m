function out = CheckNames(obj)

% CHECKNAMES - Check for repeated names in a dataset or signal group.
% CheckNames(Data)
% CheckNames(DATA)
% CheckNames(Signals)
% CheckNames(SIGNALS)
% Info = CheckNames(...)
%
% Checks the NAMES matrix of the input object for names appearing 
% on multiple channels, and displays a table for each name showing 
% locations, name signatures, and whether duplicate instances are 
% all-zero, all-NaN, and/or different from the first, i.e., the 
% "primary"(*), instance.  Accepts datasets, signal groups, or 
% arrays of same.  If an array is provided, the operation is 
% repeated for all elements. 
%
% (*)The primary instance of a name is the only instance that is 
% retrievable by a 'name' reference in "GetSignal", "SelectFromGroup", 
% "RemoveFromGroup", "PlotDataset", etc. 
%
% If called with output argument 'Info', the function returns 
% the equivalent table information in the form of a structure array 
% (for datasets and signal groups), or a cell array of same (for 
% dataset or signal group arrays), and no output is displayed to 
% the screen. 
%
% See also "CompareNames". 
%
% P.G. Bonanni
% 9/27/18

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

% If input is an array ...
if numel(obj) > 1

  % Initialize
  Info = {};

  % Loop over array entries
  for k = 1:numel(obj)
    if ~nargout
      fprintf('\n');
      fprintf('==============================================================================================================\n');
      fprintf('Checking element %d of %d\n',k,numel(obj));
      fprintf('==============================================================================================================\n');
      fprintf('\n');
      CheckNames(obj(k))
      fprintf('\n');
      pause
    else
      Info1 = CheckNames(obj(k));
      if isempty(Info1), Info1={[]}; end
      Info = [Info; Info1];
    end
  end

  % Return output, if required
  if nargout
    out = Info;
  end

  return
end

% If input is a dataset ...
if IsDataset(obj)

  % Get dataset
  Data = obj;

  % Build master signal group
  Signals = CollectSignals(Data);

  % Total signal channels
  Nchannels = size(Signals.Values,2);

  % Find repeated signal names
  NAMES = GetNamesMatrix(Signals);
  names = NAMES(:);
  names(cellfun(@isempty,names)) = [];
  [~,i] = unique(names);
  j = setdiff(1:length(names),i);
  names = unique(names(j));

  % Number of unique names
  Nunique = length(i);

  % For each name, find all instances in the NAMES array, 
  % considering all name layers.  Record the row numbers 
  % corresponding to names{i} as vectors Index{i}. 
  Index = cell(size(names));  % initialize
  for k = 1:length(names)
    name = names{k};
    index1 = find(strcmp(name,NAMES(:)));  [index,~]=ind2sub(size(NAMES),index1);
    index = unique(index);  % (duplicates here correspond to same row, different layers)
    Index{k} = index;
  end

  % Mask out cases with only a single row index
  mask = cellfun(@isscalar,Index);
  names(mask) = [];
  Index(mask) = [];

  % Report results
  N = length(names);
  if N > 0
    if ~nargout
      fprintf('Total signal channels ...... %3d\n',Nchannels);
      fprintf('Number of unique names ..... %3d\n',Nunique);
      fprintf('Number of repeated names ... %3d\n',N);
    end
  else
    if ~nargout
      fprintf('Total signal channels ...... %3d\n',Nchannels);
      fprintf('Number of unique names ..... %3d\n',Nunique);
      fprintf('No repeated names.\n');
    else
      out = [];
    end
    return
  end

  % Check each case for differences in "name signatures" or data content 
  mask = false(size(names));  % initialize
  for k = 1:length(names)
    index = Index{k};
    NAMES1 = NAMES(index,:);
    VALUES1 = Signals.Values(:,index);
    C1 = num2cell(NAMES1,2);
    C2 = num2cell(VALUES1,1);
    if ~isequal(C1{:}) || ~isequaln(C2{:})
      mask(k) = true;
    end
  end

  % Reduce the set accordingly
  names = names(mask);
  Index = Index(mask);

  % Report new results
  N = length(names);
  if N > 0
    if ~nargout
      fprintf('Number of names with varying signatures or signal content ... %d\n',N);
      fprintf('\n');
    end
  else
    if ~nargout
      fprintf('All names have consistent signatures and signal content.\n')
    else
      out = [];
    end
    return
  end

  % Get the corresponding signature strings
  Strs = cell(size(names));  % initialize
  fun = @(x)GetNames(Signals,x);
  for k = 1:length(names)
    [~,Strs{k}] = arrayfun(fun,Index{k},'Uniform',false);
  end

  % Determine whether duplicate instances have the same data
  Status = cell(size(names));  % initialize
  for k = 1:length(names)
    xref = GetSignal(names{k},Signals);
    fun = @(x)isequaln(Signals.Values(:,x),xref);
    mask = arrayfun(fun,Index{k});
    Status{k} = cell(size(mask));  % initialize
    [Status{k}{ mask}] = deal('SAME');
    [Status{k}{~mask}] = deal('DIFFERENT');
    Status{k}{1} = '(primary)';
  end

  % Determine if signals are all-zero or all-nan
  Type = cell(size(names));  % initialize
  for k = 1:length(names)
    Values = Signals.Values(:,Index{k});
    Type{k} = repmat({' '},size(Values,2),1);  % initialize
    mask=all(Values==0);      [Type{k}{mask}]=deal('0');  % mark signals that are all zero
    mask=all(isnan(Values));  [Type{k}{mask}]=deal('x');  % mark signals that are all NaN
  end

  % Re-map names to signal channels, this time within groups
  [Index,Groups] = cellfun(@(x)FindName(x,Data),names,'Uniform',false);

  % Extend entries of 'Groups' to match entries of 'Index', 
  % and convert vector entries of 'Index' to cell arrays.
  fun = @(x,y)repmat({x},length(y),1);
  for k = 1:length(Groups)
    Groups{k} = cellfun(fun,Groups{k},Index{k},'Uniform',false);
    Index{k}  = cellfun(@num2cell,Index{k},    'Uniform',false);
  end
  % Concatenate results to a single list within each cell
  Groups = cellfun(@(x)cat(1,x{:}),Groups,'Uniform',false);
  Index  = cellfun(@(x)cat(1,x{:}),Index, 'Uniform',false);

  if ~nargout
    % ------------------------
    % PRINT RESULTS TO SCREEN
    % ------------------------

    % Convert 'Index' entries to equal-width strings
    fun = @(x)cellstr(num2str(cat(1,x{:})));
    Index = cellfun(fun,Index,'Uniform',false);

    % Print results to screen as a chart
    for k = 1:length(names)
      disp(names{k})
      Table = [{'S','Group','Index','Signature','Status'};
               [Type{k},Groups{k},Index{k},Strs{k},Status{k}]];
      C = num2cell(Table,1);  % split into columns
      C = cellfun(@char,C,'Uniform',false);  % make character arrays
      for j = 1:length(C)
        Str = C{j};
        n = size(Str,2);  % insert framing lines of length n
        Str = [repmat('-',1,n); Str(1,:); repmat('-',1,n); Str(2:end,:)];
        C{j} = Str;
      end
      nrows = size(Table,1) + 2;
      Delim = repmat('  ',nrows,1);
      C = [repmat({Delim},1,size(Table,2)); C];  C=C(:);
      Str = cat(2,C{:});  % add separation
      C = cellstr(Str);
      fprintf('%s\n',C{:})
      fprintf('\n');
    end
  else
    % ------------------------
    % RETURN OUTPUT
    % ------------------------

    % Build 'Info' structure array
    fun = @(k)struct('Type',Type{k},'Group',Groups{k},'Index',Index{k},'Signature',Strs{k},'Status',Status{k});
    C = arrayfun(fun,(1:length(names))','Uniform',false);
    Info = struct('name',names,'list',C);

    % Return output
    out = Info;
  end

else  % if IsSignalGroup(obj)

  % Get signal group
  Signals = obj;

  % Total signal channels
  Nchannels = size(Signals.Values,2);

  % Find repeated signal names
  NAMES = GetNamesMatrix(Signals);
  names = NAMES(:);
  names(cellfun(@isempty,names)) = [];
  [~,i] = unique(names);
  j = setdiff(1:length(names),i);
  names = unique(names(j));

  % Number of unique names
  Nunique = length(i);

  % For each name, find all instances in the NAMES array, 
  % considering all name layers.  Record the row numbers 
  % corresponding to names{i} as vectors Index{i}. 
  Index = cell(size(names));  % initialize
  for k = 1:length(names)
    name = names{k};
    index1 = find(strcmp(name,NAMES(:)));  [index,~]=ind2sub(size(NAMES),index1);
    index = unique(index);  % (duplicates here correspond to same row, different layers)
    Index{k} = index;
  end

  % Mask out cases with only a single row index
  mask = cellfun(@isscalar,Index);
  names(mask) = [];
  Index(mask) = [];

  % Report results
  N = length(names);
  if N > 0
    if ~nargout
      fprintf('Total signal channels ...... %3d\n',Nchannels);
      fprintf('Number of unique names ..... %3d\n',Nunique);
      fprintf('Number of repeated names ... %3d\n',N);
    end
  else
    if ~nargout
      fprintf('Total signal channels ...... %3d\n',Nchannels);
      fprintf('Number of unique names ..... %3d\n',Nunique);
      fprintf('No repeated names.\n');
    else
      out = [];
    end
    return
  end

  % Check each case for differences in "name signatures" or data content 
  mask = false(size(names));  % initialize
  for k = 1:length(names)
    index = Index{k};
    NAMES1 = NAMES(index,:);
    VALUES1 = Signals.Values(:,index);
    C1 = num2cell(NAMES1,2);
    C2 = num2cell(VALUES1,1);
    if ~isequal(C1{:}) || ~isequaln(C2{:})
      mask(k) = true;
    end
  end

  % Reduce the set accordingly
  names = names(mask);
  Index = Index(mask);

  % Report new results
  N = length(names);
  if N > 0
    if ~nargout
      fprintf('Number of names with varying signatures or signal content ... %d\n',N);
      fprintf('\n');
    end
  else
    if ~nargout
      fprintf('All names have consistent signatures and signal content.\n')
    else
      out = [];
    end
    return
  end

  % Get the corresponding signature strings
  Strs = cell(size(names));  % initialize
  fun = @(x)GetNames(Signals,x);
  for k = 1:length(names)
    [~,Strs{k}] = arrayfun(fun,Index{k},'Uniform',false);
  end

  % Determine whether duplicate instances have the same data
  Status = cell(size(names));  % initialize
  for k = 1:length(names)
    xref = GetSignal(names{k},Signals);
    fun = @(x)isequaln(Signals.Values(:,x),xref);
    mask = arrayfun(fun,Index{k});
    Status{k} = cell(size(mask));  % initialize
    [Status{k}{ mask}] = deal('SAME');
    [Status{k}{~mask}] = deal('DIFFERENT');
    Status{k}{1} = '(primary)';
  end

  % Determine if signals are all-zero or all-nan
  Type = cell(size(names));  % initialize
  for k = 1:length(names)
    Values = Signals.Values(:,Index{k});
    Type{k} = repmat({' '},size(Values,2),1);  % initialize
    mask=all(Values==0);      [Type{k}{mask}]=deal('0');  % mark signals that are all zero
    mask=all(isnan(Values));  [Type{k}{mask}]=deal('x');  % mark signals that are all NaN
  end

  % Convert 'Index' entries to cell arrays
  Index = cellfun(@num2cell,Index,'Uniform',false);

  if ~nargout
    % ------------------------
    % PRINT RESULTS TO SCREEN
    % ------------------------

    % Convert 'Index' entries to equal-width strings
    fun = @(x)cellstr(num2str(cat(1,x{:})));
    Index = cellfun(fun,Index,'Uniform',false);

    % Print results to screen as a chart
    for k = 1:length(names)
      disp(names{k})
      Table = [{'S','Index','Signature','Status'};
               [Type{k},Index{k},Strs{k},Status{k}]];
      C = num2cell(Table,1);  % split into columns
      C = cellfun(@char,C,'Uniform',false);  % make character arrays
      for j = 1:length(C)
        Str = C{j};
        n = size(Str,2);  % insert framing lines of length n
        Str = [repmat('-',1,n); Str(1,:); repmat('-',1,n); Str(2:end,:)];
        C{j} = Str;
      end
      nrows = size(Table,1) + 2;
      Delim = repmat('  ',nrows,1);
      C = [repmat({Delim},1,size(Table,2)); C];  C=C(:);
      Str = cat(2,C{:});  % add separation
      C = cellstr(Str);
      fprintf('%s\n',C{:})
      fprintf('\n');
    end
  else
    % ------------------------
    % RETURN OUTPUT
    % ------------------------

    % Build 'Info' structure array
    fun = @(k)struct('Type',Type{k},'Index',Index{k},'Signature',Strs{k},'Status',Status{k});
    C = arrayfun(fun,(1:length(names))','Uniform',false);
    Info = struct('name',names,'list',C);

    % Return output
    out = Info;
  end
end
