function varargout = CheckNameTables(varargin)

% CHECKNAMETABLES - Check NameTables.xlsx file for errors.
% CheckNameTables
% CheckNameTables(pathname)
% [valid,Errors] = CheckNameTables(...)
% [valid,Errors] = CheckNameTables(..., 'no_update')
%
% Checks the "NameTables.xlsx" file for errors and updates the 
% corresponding .dat file in the same folder.  Alternatively, 
% applies the checks to the file specified by 'pathname'. 
%
% If called with output arguments, error messages are suppressed.  
% Output 'valid' is set to TRUE if the file is deemed to be without 
% errors and FALSE if not.  Output 'Errors' is a cell array listing 
% the errors detected. 
%
% The .dat file is a text file representation of the input file 
% used for change tracking.  both the location and the root name 
% are taken from the input file.  The .dat file update can be 
% suppressed by supplying the string 'no_update' as a final argument. 
%
% P.G. Bonanni
% 4/10/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if ~all(cellfun(@ischar,varargin))
  error('Invalid usage.')
end

args = varargin;
if isempty(args)
  pathname = '';
  option = 'update';
else
  if strcmp(args{end},'no_update')
    option = '';
    args(end) = [];
  else
    option = 'update';
  end
  if isempty(args)
    pathname = '';
  elseif length(args) == 1
    pathname = args{1};
  else
    error('Invalid usage.')
  end
end

% Default pathname
if isempty(pathname)
  pathname = 'NameTables.xlsx';
end

% Locate the file on the Matlab path or using pathname parts
[folder,rootname,ext] = fileparts(which(pathname));
if isempty(folder)  % in case folder is not on path
  [folder,rootname,ext] = fileparts(pathname);
end

% Rebuild pathname from parts
pathname = fullfile(folder,[rootname,ext]);

if nargout == 0
  % Report the results of error checking
  fprintf('Checking file %s\n',pathname);
  [valid,Errors] = CheckNameTables(pathname,'no_update');
  if valid
    fprintf('No errors detected.\n');
  else
    fprintf('These errors were found:\n');
    fprintf('  %s\n',Errors{:})
  end

else

  % ------------------------------------------------
  %  CHECK MASTER TAB
  % ------------------------------------------------

  % Perform basic checks on the MASTER tab
  [valid,Errors] = CheckMasterTab(pathname);

  % Stop here if MASTER tab is not valid
  if ~valid
    varargout = {valid, Errors};
    return
  end

  % Read data structures from the MASTER tab
  [Names,SourceType] = ReadMasterLookup(pathname);

  % Reduce 'SourceType' to fields with non-empty values
  fields = fieldnames(SourceType);
  mask = structfun(@isempty,SourceType);
  SourceType1 = rmfield(SourceType,fields(mask));

  % List of source tabs
  Tabs = ListSourceTypes(pathname);

  % ------------------------------------------------
  %  CHECK SOURCE TABS
  % ------------------------------------------------

  % Perform basic checks on the source tabs
  for k = 1:length(Tabs)
    [valid1,Errors1] = CheckSourceTab(pathname,Tabs{k});
    if ~valid1, valid=false; end
    Errors = [Errors; Errors1];
  end

  % Stop here if any source tab is not valid
  if ~valid
    varargout = {valid, Errors};
    return
  end

  % -------------------------------------------------------------
  %  CHECK THAT ALL SIGNAL NAMES ARE REGISTERED ON SOURCE TABS
  % -------------------------------------------------------------

  % Get group names
  Groups = fieldnames(Names);

  % List of "source-assigned" layers
  Layers1 = fieldnames(SourceType1);

  % Loop over source-assigned layers
  for k = 1:length(Layers1)
    layer = Layers1{k};
    tab = SourceType1.(layer);

    % Read names from the source tab
    NamesT = ReadSourceTab(tab,pathname);
    C = struct2cell(NamesT);
    NAMES = cat(1,C{:});

    % Loop over groups
    for j = 1:length(Groups)
      group = Groups{j};

      % Get names for this group and layer
      names = Names.(group).(layer);
      names(cellfun(@isempty,names)) = [];

      % Check the names
      mask = ~ismember(names,NAMES);
      if any(mask)
        valid = false;
        str = sprintf('''%s'',',names{mask}); str(end)=[];
        errmsg = sprintf('MASTER tab: Layer ''%s'': Group ''%s'': Unregistered names: {%s}.',layer,group,str);
        Errors = [Errors; errmsg];
      end
    end
  end

  % Output results
  varargout = {valid, Errors};
end

% Update the .dat file
if strcmp(option,'update')
  outfile = fullfile(folder,[rootname,'.dat']);
  PrintNameTables(pathname,outfile)
  if nargout==0, fprintf('File %s written.\n',outfile); end
end



% --------------------------------------------------------------------------------
function [valid,Errors] = CheckMasterTab(pathname)

% Performs basic checks on the MASTER tab, which includes testing 
% that column headers, source types, groups names, and all signal 
% names are valid identifiers.  Also checks that no spurious text 
% exists on spacer lines, i.e., othat all signals have a group name 
% assigned in the leftmost column. 

% Initialize
valid = true;
Errors = {};

% Read raw data from Excel file
[~,~,C] = xlsread(pathname,'MASTER');
C(:,end) = [];  % remove last column, containing "<---- ..." and comments

% Replace NaNs by ''
mask = cellfun(@(x)isnumeric(x)&&isnan(x),C(:));
[C{mask}] = deal('');

% Read column headers, then remove first line
Headers = C(1,2:end);  C(1,:)=[];
if any(cellfun(@isempty,Headers))
  valid = false;
  errmsg = 'MASTER tab: One or more name columns is not labeled.';
  Errors = [Errors; errmsg];
end

% Check that headers (i.e., source or layer strings) are valid identifiers
mask = cellfun(@isempty,regexp(Headers,'^[A-Za-z]\w*$'));
if any(mask)
  valid = false;
  str = sprintf('''%s'',',Headers{mask}); str(end)=[];
  errmsg = sprintf('The MASTER tab contains these invalid column headers: {%s}.',str);
  Errors = [Errors; errmsg];
end

% Read (then remove) "Source Types" line
SourceTypes = C(1,2:end);  C(1,:)=[];
SourceTypes(cellfun(@isempty,SourceTypes)) = [];
SourceTypes = unique(SourceTypes,'stable');

% Check that source types are valid identifiers
mask = cellfun(@isempty,regexp(SourceTypes,'^[A-Za-z]\w*$'));
if any(mask)
  valid = false;
  str = sprintf('''%s'',',SourceTypes{mask}); str(end)=[];
  errmsg = sprintf('MASTER tab: Invalid source types: {%s}.',str);
  Errors = [Errors; errmsg];
end

% Collect group names
Groups = C(:,1);
Groups(cellfun(@isempty,Groups)) = [];
Groups = unique(Groups,'stable');

% Record the rows with no group name, 
% then remove the first column
maskU = cellfun(@isempty,C(:,1));
C(:,1) = [];

% Check that group names are valid identifiers
mask = cellfun(@isempty,regexp(Groups,'^[A-Za-z]\w*$'));
if any(mask)
  valid = false;
  str = sprintf('''%s'',',Groups{mask}); str(end)=[];
  errmsg = sprintf('MASTER tab: Invalid group names: {%s}.',str);
  Errors = [Errors; errmsg];
end

% Check signal names
for k = 1:length(Headers)
  header = Headers{k};

  % Check that signal names are valid identifiers
  names = C(:,k);  names(cellfun(@isempty,names))=[];
  mask = cellfun(@isempty,regexp(names,'^[A-Za-z]\w*$'));
  if any(mask)
    valid = false;
    str = sprintf('''%s'',',names{mask}); str(end)=[];
    errmsg = sprintf('MASTER tab: Column ''%s'': Invalid signal names: {%s}.',header,str);
    Errors = [Errors; errmsg];
  end

  % Check for signals with no group name assigned
  names = C(maskU,k);
  mask = ~cellfun(@isempty,names);
  if any(mask)
    valid = false;
    str = sprintf('''%s'',',names{mask}); str(end)=[];
    errmsg = sprintf('MASTER tab: Column ''%s'': No group assigned: {%s}.',header,str);
    Errors = [Errors; errmsg];
  end
end



% --------------------------------------------------------------------------------
function [valid,Errors] = CheckSourceTab(pathname,tab)

% Performs basic checks on the specified source 'tab', which includes 
% testing that column headers are valid, that all group and signal names 
% are valid identifiers appearing only once, that all conversion factors 
% are numerical, that all "units" entries are string type, and that all 
% "units" entries are accompanied by conversion factors.  Also checks that 
% no spurious text exists on spacer lines, i.e., that all signals have a 
% group name assigned in the leftmost column. 

% Initialize
valid = true;
Errors = {};

% Check if tab exists
[~,Sheets] = xlsfinfo(pathname);
if ~ismember(tab,Sheets)
  valid = false;
  errmsg = sprintf('Source tab ''%s'' does not exist.',tab);
  Errors = [Errors; errmsg];
  return  % cannot proceed
end

% Read raw data from Excel file
[~,~,C] = xlsread(pathname,tab);

% Discard columns with no header
mask = cellfun(@(x)~ischar(x)||isempty(x), C(1,:));
C(:,mask) = [];

% Check for missing columns
Headers0 = {'Group','Signal','Factor','Units','Comments','Descriptions'};
Headers = C(1,:);
if ~all(ismember(Headers0,Headers))
  valid = false;
  errmsg = sprintf('Source tab ''%s'': Column headers are invalid. Missing one or more required columns.',tab);
  Errors = [Errors; errmsg];
  return  % cannot proceed
end

% Retain only the required columns
[~,i] = ismember(Headers0,Headers);
C = C(:,i);  % re-order
C = C(:,[1:4,6]);

% Remove header row
C(1,:) = [];

% Replace NaNs by '' in columns 1, 2, and 4
mask = cellfun(@(x)isnumeric(x)&&isnan(x),C(:,1));  [C{mask,1}]=deal('');
mask = cellfun(@(x)isnumeric(x)&&isnan(x),C(:,2));  [C{mask,2}]=deal('');
mask = cellfun(@(x)isnumeric(x)&&isnan(x),C(:,4));  [C{mask,4}]=deal('');

% Collect group names
Groups = C(:,1);
Groups(cellfun(@isempty,Groups)) = [];
Groups = unique(Groups,'stable');

% Record the rows with no group name, 
% then remove the first column
maskU = cellfun(@isempty,C(:,1));
C(:,1) = [];

% Check that group names are valid identifiers
mask = cellfun(@isempty,regexp(Groups,'^[A-Za-z]\w*$'));
if any(mask)
  valid = false;
  str = sprintf('''%s'',',Groups{mask}); str(end)=[];
  errmsg = sprintf('Source tab ''%s'': Invalid group names: {%s}.',tab,str);
  Errors = [Errors; errmsg];
end

% Check that signal names are valid identifiers, and not repeated
names = C(:,1);  names(cellfun(@isempty,names))=[];
mask = cellfun(@isempty,regexp(names,'^[A-Za-z]\w*$'));
if any(mask)
  valid = false;
  str = sprintf('''%s'',',names{mask}); str(end)=[];
  errmsg = sprintf('Source tab ''%s'': Invalid signal names: {%s}.',tab,str);
  Errors = [Errors; errmsg];
end
if ~isequal(names,unique(names,'stable'))
  valid = false;
  [~,i] = unique(names);
  j = setdiff(1:length(names),i);
  namesR = unique(names(j));
  str = sprintf('''%s'',',namesR{:}); str(end)=[];
  errmsg = sprintf('Source tab ''%s'': Repeated signal names: {%s}.',tab,str);
  Errors = [Errors; errmsg];
end

% Check for missing signal names
mask = ~maskU & cellfun(@(x)(isnumeric(x)&&isnan(x))||isempty(x),C(:,1));
if any(mask)
  valid = false;
  str = sprintf('%d, ', 1+find(mask));  str(end-1:end)=[];
  errmsg = sprintf('Source tab ''%s'': Missing signal name on lines: %s.',tab,str);
  Errors = [Errors; errmsg];
end

% Check for signals with no group name assigned
names = C(maskU,1);
mask = ~cellfun(@isempty,names);
if any(mask)
  valid = false;
  str = sprintf('''%s'',',names{mask}); str(end)=[];
  errmsg = sprintf('Source tab ''%s'': No group assigned: {%s}.',tab,str);
  Errors = [Errors; errmsg];
end

% Check for valid conversion factors
Factors = C(:,2);  % cell array
mask = ~cellfun(@isnumeric,Factors) & ...               % only numeric values, or 
       ~cellfun(@(x)ischar(x)&&strcmp(x,'*'),Factors);  % '*' characters, are allowed
if any(mask)
  valid = false;
  str = sprintf('''%s'',',Factors{mask}); str(end)=[];
  errmsg = sprintf('Source tab ''%s'': Non-numeric conversion factor entries: {%s}.',tab,str);
  Errors = [Errors; errmsg];
end

% Check for valid "units" strings
Units = C(:,3);  % cell array
mask = cellfun(@isnumeric,Units);
if any(mask)
  valid = false;
  Units1 = cellfun(@(x)num2str(x,'%g'),Units,'Uniform',false);  % convert to strings
  str = sprintf('''%s'',',Units1{mask}); str(end)=[];
  errmsg = sprintf('Source tab ''%s'': Invalid "units" string etries: {%s}.',tab,str);
  Errors = [Errors; errmsg];
end

% Check for spurious text on spacer lines
C1 = C(maskU,2:3);  % cell array
mask = ~cellfun(@(x)(isnumeric(x)&&isnan(x))||isempty(x),C1(:));
if any(mask)
  valid = false;
  C2 = cellfun(@(x)num2str(x,'%g'),C1(:),'Uniform',false);  % convert to strings
  str = sprintf('''%s'',',C2{mask}); str(end)=[];
  errmsg = sprintf('Source tab ''%s'': Spurious text on spacer lines: {%s}.',tab,str);
  Errors = [Errors; errmsg];
end
