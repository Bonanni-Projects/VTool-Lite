function CompareNames(obj1,obj2)

% COMPARENAMES - Compare names in two datasets or signal groups.
% CompareNames(Data1,Data2)
% CompareNames(Signals1,Signals2)
%
% Compare the names matrix for two datasets ('Data1','Data2') or 
% signal groups ('Signals1','Signals2') using a visual comparison 
% tool.  Also accepts homogeneous arrays of either datasets or 
% signal groups. 
%
% See also "CompareDisplays", "CheckNames".  
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

% Write to files
WriteNamesToFile(NAMES1,fname1);
WriteNamesToFile(NAMES2,fname2);

% Open comparison tool, and hold
visdiff(fname1,fname2)
pause(8)  % for blocking

% Delete temporary files
delete(fname1)
delete(fname2)



% ----------------------------------------------------------------
function WriteNamesToFile(NAMES,outfile)

% Write names matrix 'NAMES' to file 'outfile', 
% overwriting any existing file of the same name.

% Build text lines from names matrix
[nrows,ncols] = size(NAMES);            % matrix size
Rows = cellstr(num2str((1:nrows)'));
Rows = strcat(Rows,':');
C = [Rows,NAMES];  ncols=ncols+1;       % prepend ':' to rows
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
