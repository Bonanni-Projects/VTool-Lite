function s = ExtractData(pathname,varargin)

% EXTRACTDATA - Extract data from a file (PRIMARY USER INTERFACE FUNCTION).
% s = ExtractData(pathname)
% s = ExtractData(pathname,sourcetype)
% s = ExtractData(..., TS,Trange,'nowarn')
%
% Extracts data from a file of any supported format, returning 
% output 's' in a generic VTool dataset format. This is a dispatch 
% function, permitting extraction of signal data independent of 
% "source type" or data file format. 
%
% The list of valid source types can be obtained from function 
% "ListSourceTypes".  These correspond to names of "source tabs" 
% within the applicable "NameTables.xls" file.  Multiple file 
% formats are supported for each source type.  Type "help formats" 
% and see function "IsFileType" for more information on supported 
% file formats. 
% 
% If a 'sourcetype' is specified, all grouping, signal scaling, 
% units conversions, and description modifications consistent with 
% the definition of 'sourcetype' within the "NameTables.xlsx" file 
% are applied to the result.  However, if no 'sourcetype' is specified 
% (or if file is in .vtl format), no modification of the contents is 
% performed. 
%
% A warning normally results if one or more signal names specified in 
% "NameTables.xlsx" is not present in the file.  The 'nowarn' option, 
% specified as a final argument, suppresses this warning. 
%
% Optional inputs 'TS' (sample time) and 'Trange' (1x2 time range 
% vector specifying [Tmin,Tmax]) provide for re-sampling of the 
% extracted data.  If either is specified as [], the corresponding 
% operation is not performed. 
%
% P.G. Bonanni
% 7/13/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


args = varargin;
if isempty(args)
  sourcetype = [];
  TS         = [];
  Trange     = [];
  option     = '';
else
  if ischar(args{end}) && strcmp(args{end},'nowarn')
    option = 'nowarn';
    args(end) = [];
  else
    option = '';
  end
  if isempty(args)
    sourcetype = [];
  elseif ischar(args{1})
    sourcetype = args{1};
    args(1) = [];
  else
    sourcetype = [];
  end
  if isempty(args)
    TS     = [];
    Trange = [];
  elseif length(args) == 1
    if numel(args{1})==1
      TS     = args{1};
      Trange = [];
    else
      Trange = args{1};
      TS     = [];
    end
  elseif length(args) == 2
    TS     = args{1};
    Trange = args{2};
  else
    error('Too many input arguments.')
  end
end

% If single-entry cell array 'pathname' provided
if iscellstr(pathname) && numel(pathname)==1
  pathname = pathname{1};
end

% Check 'pathname' input
if ~ischar(pathname)
  error('Input ''pathname'' is not valid.')
elseif ~exist(pathname,'file')
  error('File "%s" does not exist.',pathname)
end

% Default 'sourcetype' value
if isempty(sourcetype), sourcetype=''; end

% Check 'sourcetype' input
if ~ischar(sourcetype)
  error('Input ''sourcetype'' is not valid.')
end

% Check (TS,Trange) inputs
if ~isempty(TS) && (numel(TS) ~= 1 || TS <= 0)
  error('Sample time must be a positive scalar value.')
elseif ~isempty(Trange) && numel(Trange) ~= 2
  error('Input ''Trange'' must be a 2-element vector.')
end

% --------- EXTRACTION BY SOURCE AND FILE TYPE -------------

% If VTool file type, allow any 'sourcetype', but if a non-empty 
% sourcetype is specified, it must match the value in the file. 
% ---
if IsFileType(pathname,'vtool')

  % Load data from file
  s = load('-mat',pathname);

  % Make 'sourcetype' field first, then 'Time'
  fields = fieldnames(s);
  fields1 = setdiff(fields,{'sourcetype','Time'});
  fields = {'sourcetype','Time',fields1{:}};
  s = orderfields(s,fields);

  % Return an error if specified 'sourcetype' does not match 'sourcetype' in file
  if ~isempty(sourcetype) && ~strcmp(s.sourcetype,sourcetype)
    error('Input file ''%s'' does not match specified source type ''%s''.',pathname,sourcetype)
  end

  % Warn about direct use of .vtl files
  fprintf('NOTE: File is .vtl type.  No units conversions or description modifications applied.\n');

  % Re-sample and limit time range as needed
  if ~isempty(TS) || ~isempty(Trange)
    s = ResampleDataset(s,TS,Trange);
  end
  return
end

% If a .mat file, check if it already contains 
% extracted data from the correct 'sourcetype'
if IsFileType(pathname,'.mat')
  s = load(pathname);
  if isfield(s,'sourcetype') && strcmp(s.sourcetype,sourcetype)
    fprintf('NOTE: File is .vtl type.  No units conversions or description modifications applied.\n');
    fprintf('WARNING: Change extension to .vtl for future use.\n');
    % ---
    % Make 'sourcetype' field first, then 'Time'
    fields = fieldnames(s);
    fields1 = setdiff(fields,{'sourcetype','Time'});
    fields = {'sourcetype','Time',fields1{:}};
    s = orderfields(s,fields);
    % ---
    % Re-sample and limit time range as needed
    if ~isempty(TS) || ~isempty(Trange)
      s = ResampleDataset(s,TS,Trange);
    end
    return
  elseif isfield(s,'sourcetype') && ~strcmp(s.sourcetype,sourcetype)
    error('Input file ''%s'' does not match specified source type ''%s''.',pathname,sourcetype)
  elseif ~IsFileType(pathname,'S-array')  % the only other recognized .mat format is S-array
    error('Input mat-file ''%s'' does not match any supported formats.',pathname)
  end
end

% Check for valid 'sourcetype'
if ~isempty(which('NameTables.xlsx'))
  sourcetypes = ListSourceTypes;  % get sourcetypes from "NameTables.xlsx"
else  % if no "NameTables.xlsx" exists
  sourcetypes = {};
end
if ~ismember(sourcetype,sourcetypes) && ~isempty(sourcetype)
  error('Source type ''%s'' is not recognized/supported.',sourcetype)
end

% Read file according to file type
if IsFileType(pathname,'S-array')
  S = ReadSarrayFile(pathname);
elseif IsFileType(pathname,'xls') || IsFileType(pathname,'csv')
  S = ReadXlsFile(pathname);
else  % otherwise
  error('Format of file ''%s'' is not recognized.',pathname)
end

% Collapse 'S' into dataset form, according to 'sourcetype'
s = CollapseSarray(S,sourcetype,option);

% Re-sample and limit time range as needed
if ~isempty(TS) || ~isempty(Trange)
  s = ResampleDataset(s,TS,Trange);
end
