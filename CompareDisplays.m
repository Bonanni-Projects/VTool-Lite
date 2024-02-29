function CompareDisplays(obj1,obj2)

% COMPAREDISPLAYS - Compare display info for two datasets or signal groups.
% CompareDisplays(Data1,Data2)
% CompareDisplays(Signals1,Signals2)
%
% Compare the "Display" screen info for two datasets ('Data1','Data2') 
% or signal groups ('Signals1','Signals2') using a visual comparison 
% tool.  The info includes all names, units, and description strings 
% for all signals, plus signal status (i.e., all-nan/all-zero indicators).  
% Also accepts homogeneous arrays of either datasets or signal groups. 
%
% See also "Display", "CompareNames". 
%
% P.G. Bonanni
% 9/19/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check inputs
[flag1a,valid1a] = IsDatasetArray(obj1);
[flag2a,valid2a] = IsDatasetArray(obj2);
[flag1b,valid1b] = IsSignalGroupArray(obj1);
[flag2b,valid2b] = IsSignalGroupArray(obj2);
if ~((flag1a && flag2a) || (flag1b && flag2b))
  error('Valid for two datasets, or two signal groups, or their arrays, only.')
elseif numel(obj1)>1 && ~(valid1a || valid1b)
  error('Input #1 is not a valid dataset or signal group array.')
elseif numel(obj1)>1 && ~(valid2a || valid2b)
  error('Input #2 is not a valid dataset or signal group array.')
end

% Define temporary filenames
fname1 = '.temporary_file1.txt';
fname2 = '.temporary_file2.txt';

% Get names matrices (use first element if array)
NAMES1 = GetNamesMatrix(obj1(1));
NAMES2 = GetNamesMatrix(obj2(1));

% Append status, units, and description string entries
if IsDataset(obj1(1)), Signals1=CollectSignals(obj1(1)); else Signals1=obj1(1); end
if IsDataset(obj2(1)), Signals2=CollectSignals(obj2(1)); else Signals2=obj2(1); end
Status1 = cell(size(Signals1.Values,2),1);  % initialize
Status2 = cell(size(Signals2.Values,2),1);  % initialize
mask1=all(Signals1.Values==0,1);                                       [Status1{mask1}]=deal('0');  % mark signals that are all zero
mask2=all(isnan(Signals1.Values),1);                                   [Status1{mask2}]=deal('x');  % mark signals that are all NaN
mask3=any(isnan(Signals1.Values),1)&~mask2;                            [Status1{mask3}]=deal('.');  % mark signals that are partially NaN
mask4=all(isnan(Signals1.Values)|Signals1.Values==0,1)&~mask1&~mask2;  [Status1{mask4}]=deal('o');  % mark signals that are only 0 or NaN
mask1=all(Signals2.Values==0,1);                                       [Status2{mask1}]=deal('0');  % mark signals that are all zero
mask2=all(isnan(Signals2.Values),1);                                   [Status2{mask2}]=deal('x');  % mark signals that are all NaN
mask3=any(isnan(Signals2.Values),1)&~mask2;                            [Status2{mask3}]=deal('.');  % mark signals that are partially NaN
mask4=all(isnan(Signals2.Values)|Signals2.Values==0,1)&~mask1&~mask2;  [Status2{mask4}]=deal('o');  % mark signals that are only 0 or NaN
TEXT1 = [Status1, NAMES1, Signals1.Units, Signals1.Descriptions];
TEXT2 = [Status2, NAMES2, Signals2.Units, Signals2.Descriptions];

% Replace any empty cell entries with ''
mask = cellfun(@(x)isnumeric(x)&&isempty(x),TEXT1); [TEXT1{mask}] = deal('');
mask = cellfun(@(x)isnumeric(x)&&isempty(x),TEXT2); [TEXT2{mask}] = deal('');

% Write to files
WriteTextMatrixToFile(TEXT1,fname1);
WriteTextMatrixToFile(TEXT2,fname2);

% Open comparison tool, and hold
visdiff(fname1,fname2)
pause(8)  % for blocking

% Delete temporary files
delete(fname1)
delete(fname2)



% ----------------------------------------------------------------
function WriteTextMatrixToFile(TEXT,outfile)

% Write text matrix 'TEXT' to file 'outfile', 
% overwriting any existing file of the same name.

% Build text lines from TEXT matrix
[nrows,ncols] = size(TEXT);             % matrix size
Rows = cellstr(num2str((1:nrows)'));
Rows = strcat(Rows,':');
C = [Rows,TEXT];  ncols=ncols+1;        % prepend ':' to rows
C = num2cell(C,1);                      % separate array columns
C1 = cellfun(@char,C,'Uniform',false);  % make character arrays
Delim = repmat('  ',nrows,1);
C2 = [C1; repmat({Delim},1,ncols)];
C2 = C2(:);  C2(end)=[];
Str = cat(2,C2{:});                     % add separation
lines = cellstr(Str);

% Append <newline> to all lines but the last (avoids extra line in "visdiff")
lines(1:end-1) = cellfun(@(x)[x,newline],lines(1:end-1),'Uniform',false);

% Write lines to file
fid = fopen(outfile,'w');
fprintf(fid,'%s',lines{:});
fclose(fid);
