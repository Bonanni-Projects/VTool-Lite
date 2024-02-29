function DisplaySignalGroup(Signals)

% DISPLAYSIGNALGROUP - Display contents of a signal group.
% DisplaySignalGroup(Signals)
%
% Displays the contents of a signal group as a chart that 
% includes signal names, units, descriptions, and array 
% size. 
%
% P.G. Bonanni
% 3/30/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check 'Signals' argument
if numel(Signals) > 1
  error('Works for scalar signal groups only.')
end
[flag,valid] = IsSignalGroup(Signals);
if ~flag || ~valid
  error('Input ''Signals'' is not a valid signal group.  See "IsSignalGroup".')
end

% Number of signals
nsignals = size(Signals.Values,2);

% Get signal names and layers
[NAMES,Layers] = GetNamesMatrix(Signals);

% Get units and descriptions
Units        = Signals.Units;
Descriptions = Signals.Descriptions;

% Print size and class description string
vsize = size(Signals.Values);
vclass = class(Signals.Values);
str = [sprintf('%d',vsize(1)), sprintf(' x %d',vsize(2:end))];
fprintf('%s %s\n',str,vclass);

% Build a table for display that includes a header row
Table = [[Layers';NAMES],['Units';Units],['Descriptions';Descriptions]];

% Get data and add status column
Values = Signals.Values;
C = cell(size(Values,2),1);  % initialize
if nsignals > 0 && ~strcmp(class(Values),'datetime')
  mask1=all(Values==0,1);                              [C{mask1}]=deal('0');  % mark signals that are all zero
  mask2=all(isnan(Values),1);                          [C{mask2}]=deal('x');  % mark signals that are all NaN
  mask3=any(isnan(Values),1)&~mask2;                   [C{mask3}]=deal('.');  % mark signals that are partially NaN
  mask4=all(isnan(Values)|Values==0,1)&~mask1&~mask2;  [C{mask4}]=deal('o');  % mark signals that are only 0 or NaN
end
Table = [['S';C],Table];  % add 'S' column at left

% Replace any empty cell entries with ''
mask = cellfun(@(x)isnumeric(x)&&isempty(x),Table);
[Table{mask}] = deal('');

% Add row numbers to the "data" rows only
if nsignals > 0
  nrows1 = size(Table,1)-1;
  Rows = cellstr(num2str((1:nrows1)'));
  Rows = strcat(Rows,':');
  Rows = [{''}; Rows];
  Table = [Rows,Table];
end

% Print results to screen as a chart
[nrows,ncols] = size(Table);            % total size
C = num2cell(Table,1);                  % separate columns
C1 = cellfun(@char,C,'Uniform',false);  % make character arrays
for k = 1:length(C1)
  Str = C1{k};
  n = size(Str,2);  % insert framing lines of length n, but ...
  if k==1, c=' '; else c='-'; end  % use blanks for first column
  Str = [repmat(c,1,n); Str(1,:); repmat(c,1,n); Str(2:end,:)];
  C1{k} = Str;
end
nrows = nrows+2;
Delim = repmat('  ',nrows,1);
C2 = [C1; repmat({Delim},1,ncols)];
C2 = C2(:);  C2(end)=[];
Str = cat(2,C2{:});  % add separation
C3 = cellstr(Str);
fprintf('%s\n',C3{:})
