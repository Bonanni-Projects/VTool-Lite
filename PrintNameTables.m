function PrintNameTables(pathname,outfile)

% PRINTNAMETABLES - Print NameTables.xlsx to a text file.
% PrintNameTables(outfile)
% PrintNameTables(pathname,outfile)
%
% Prints the contents of "NameTables.xlsx" in text file format 
% to enable text comparisons for change tracking.    The file 
% includes information from the MASTER tab and all source tabs.  
% The output file is specified by 'outfile'. 
%
% If the optional 'pathname' argument is supplied, the function reads 
% the specified file in place of the default "NameTables.xlsx" file. 
%
% P.G. Bonanni
% 4/10/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 2
  outfile = pathname;
  pathname = 'NameTables.xlsx';
end

% Open file for writing
fid = fopen(outfile,'w');

% Read raw data from MASTER tab, and get size
[~,~,C] = xlsread(pathname,'MASTER');
[nrows,ncols] = size(C);

% Convert non-string entries
for k = 1:numel(C)
  if isnumeric(C{k}) && isscalar(C{k}) && isnan(C{k})
    C{k} = '';
  elseif isnumeric(C{k}) && isscalar(C{k})
    C{k} = sprintf('%g',C{k});
  elseif ~ischar(C{k})
    fclose(fid);  % close file
    error('The ''MASTER'' tab has one or more invalid entries.')
  end
end

% Determine tab names
[~,sheets] = xlsfinfo(pathname);
Tabs = setdiff(sheets,'MASTER');

% Print MASTER TAB
Rows = cellstr(num2str((1:nrows)'));
Rows = strcat(Rows,':');
C = [Rows,C];  ncols=ncols+1;           % annotate rows
C = num2cell(C,1);                      % separate array columns
C1 = cellfun(@char,C,'Uniform',false);  % make character arrays
Delim = repmat('  ',nrows,1);
C2 = [C1; repmat({Delim},1,ncols)];
C2 = C2(:);  C2(end)=[];
Str = cat(2,C2{:});                     % add separation
C3 = cellstr(Str);
fprintf(fid,'%s',repmat('-',1,size(Str,2)));  fprintf(fid,'\n');
fprintf(fid,' MASTER\n');
fprintf(fid,'%s',repmat('-',1,size(Str,2)));  fprintf(fid,'\n');
fprintf(fid,'%s\n',C3{:});

% Loop over tabs
for k = 1:length(Tabs)
  tab = Tabs{k};

  % Read raw data and get size
  [~,~,C] = xlsread(pathname,tab);
  [nrows,ncols] = size(C);

  % Convert non-string entries
  for k = 1:numel(C)
    if isnumeric(C{k}) && isscalar(C{k}) && isnan(C{k})
      C{k} = '';
    elseif isnumeric(C{k}) && isscalar(C{k})
      C{k} = sprintf('%g',C{k});
    elseif ~ischar(C{k})
      fclose(fid);  % close file
      error('The ''%s'' tab has one or more invalid entries.',tab)
    end
  end

  % Separator
  fprintf(fid,'\n');
  fprintf(fid,'\n');

  % Print data
  Rows = cellstr(num2str((1:nrows)'));
  Rows = strcat(Rows,':');
  C = [Rows,C];  ncols=ncols+1;           % annotate rows
  C = num2cell(C,1);                      % separate array columns
  C1 = cellfun(@char,C,'Uniform',false);  % make character arrays
  Delim = repmat('  ',nrows,1);
  C2 = [C1; repmat({Delim},1,ncols)];
  C2 = C2(:);  C2(end)=[];
  Str = cat(2,C2{:});                     % add separation
  C3 = cellstr(Str);
  fprintf(fid,'%s',repmat('-',1,size(Str,2)));  fprintf(fid,'\n');
  fprintf(fid,' %s\n',tab);
  fprintf(fid,'%s',repmat('-',1,size(Str,2)));  fprintf(fid,'\n');
  fprintf(fid,'%s\n',C3{:});
end

% Close file
fclose(fid);
