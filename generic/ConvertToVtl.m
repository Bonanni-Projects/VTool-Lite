function ConvertToVtl(inp,sourcetype,varargin)

% CONVERTTOVTL - Convert files to VTool .vtl format.
% ConvertToVtl(pathname,sourcetype)
% ConvertToVtl({'pathname1','pathname2',...},sourcetype)
% ConvertToVtl(folder,filetype,sourcetype)
% ConvertToVtl(..., TS,Trange)
%
% Bulk file conversion function. 
%
% Converts data files to VTool .vtl format.  Operates on either 
% 1) the single file pointed to by 'pathname', or 2) a list of files 
% of matching file type, designated by a cell array of pathnames, e.g.,  
% {'pathname1','pathname2',...}, or 3) files contained with a specified 
% 'folder' and matching a specified 'filetype' (see function "IsFileType"). 
%
% Input 'sourcetype' is a string-valued input corresponding to a "source 
% tab" within the applicable "NameTables.xls" file. During each conversion, 
% all group definitions, signal scaling, units conversions, and description 
% modifications consistent with the definition of 'sourcetype' within 
% "NameTables.xlsx" are applied to retrieved signals before storing to 
% the output file.  However, if 'sourcetype' is empty, all signals are 
% assigned to a master signal group 'All', and no modification of the 
% attributes is applied. 
%
% Optional inputs 'TS' and 'Trange' specify re-sampling and time range 
% limiting, and if supplied, are passed through to the conversion 
% function (see function "ExtractData"). 
%
% Output file naming
% -------------------
% The output .mat file for each input file is named using the convention 
% "<rootname>.vtl", where <rootname> is the root name of the input file, 
% and the file is saved to the same folder where the input file resides.  
%
% See also "ConvertToSarray". 
%
% P.G. Bonanni
% 10/24/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 2
  error('Input ''sourcetype'' not specified.')
end

% If a single file pathname given ...
if ischar(inp) && ~isdir(inp)
  inp = cellstr(inp);
end

% Check for 'filetype' argument
if ischar(inp) && nargin < 3
  error('Input ''filetype'' or ''sourcetype'' is missing.')
end

% Derive input pathnames
if ischar(inp)  % if folder specified ...

  % Shift arguments
  args = varargin;
  filetype = sourcetype;
  sourcetype = args{1};
  args(1) = [];

  % Get full directory listing
  list = dir(inp);

  % Mask for the specified 'filetype' only
  mask = IsFileType({list.name},filetype);

  % Extract file names
  fnames = {list(mask).name}';

  % Extract folder names
  if isfield(list,'folder')
    folders = {list(mask).folder}';
  elseif isdir(inp)
    folders = repmat({inp},size(fnames));
  else
    folders = {};
  end

  % Build 'pathnames1' list
  if ~isempty(folders)
    pathnames1 = cellfun(@fullfile,folders,fnames,'Uniform',false);
  else
    pathnames1 = {};
  end

  % Sort alphabetically
  if ~isempty(pathnames1)
    [~,i] = sort(fnames);
    pathnames1 = pathnames1(i);
  end

elseif iscell(inp)  % if cell-array specified ...

  % Extra arguments
  args = varargin;

  % Pathnames specified directly
  pathnames1 = inp;

else
  error('Invalid input.')
end

% If list is empty
if isempty(pathnames1)
  fprintf('No files to convert!\n');
  return
end

% Determine/revise file type based on the first list entry
if IsFileType(pathnames1{1},    'vtool')
  filetype = 'vtool';
elseif IsFileType(pathnames1{1},'S-array')
  filetype = 'S-array';
elseif IsFileType(pathnames1{1},'xls')
  filetype = 'xls';
elseif IsFileType(pathnames1{1},'csv')
  filetype = 'csv';
else  % otherwise reject
  error('Unsupported input file type.')
end

% Warn about filetype being assumed the same
if iscell(inp) && length(inp) > 1
  fprintf('NOTE: All files assumed to be of same type (''%s''). ',filetype);
  fprintf('Results not guaranteed otherwise.\n');
end

% Return immediately if .vtl type
if strcmp(filetype,'vtool')
  fprintf('Format .vtl file exists. Exiting.\n');
  return
end

% Extract folder names
folders = cellfun(@fileparts,pathnames1,'Uniform',false);
mask = cellfun(@isempty,folders);  [folders{mask}]=deal('.');

% Extract rootnames
[~,rootnames1,~] = cellfun(@fileparts,pathnames1,'Uniform',false);

% Derive output pathnames
rootnames2 = rootnames1;
fnames2 = cellfun(@(x)sprintf('%s.vtl',x),rootnames2,'Uniform',false);
pathnames2 = cellfun(@fullfile,folders,fnames2,'Uniform',false);

% Loop over pathnames
for k = 1:length(pathnames1)

  % Get and report pathnames
  pathname1 = pathnames1{k};
  pathname2 = pathnames2{k};
  fprintf('Converting %s\n', pathname1);
  fprintf('    to     %s\n', pathname2);

  % Extract/convert data from the file
  s = ExtractData(pathname1,sourcetype,args{:});

  % Save to output file
  save(pathname2,'-struct','s')
end
