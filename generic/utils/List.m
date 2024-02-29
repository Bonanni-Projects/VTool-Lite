function List(spec,functionName)

% LIST - Display a hyperlinked file listing.
% List([folder])
% List(pathnames)
% List('*.mat')
% List(..., functionName)
%
% Displays a hyperlinked listing of filenames under 'folder', 
% or corresponding to 'pathnames', employing the appropriate 
% "load" command where possible.  Assumes the current working 
% directory if none is specified.  Also accepts wildcards, 
% e.g., '*.vtl' or 'work*.mat'. 
%
% The generated hyperlinks permit loading of selected files 
% using an appropriate reader function, resulting in a workspace 
% structure variable 's'.  Alternatively, if a string-valued 
% function name 'functionName' is provided as a second argument, 
% the function instead invokes the named function on the 
% file represented by the selected list entry.  Note that 
% 'functionName' may also have the format 'out = myfun', to 
% force an assignment of the function output to a desired 
% workspace variable. 
%
% P.G. Bonanni
% 2/3/21

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Defaults
if nargin < 1
  spec = '.';
end
if nargin < 2
  functionName = [];
end

% Check input
if ~ischar(spec) && ~iscellstr(spec)
  error('Invalid input specification.')
end

% Generate 'pathnames'
if iscell(spec)
  pathnames = spec;
else  % if ischar(spec)
  list = dir(spec);
  mask = ~[list.isdir];
  fnames = {list(mask).name}';
  if isfield(list,'folder')
    folders = {list(mask).folder}';
  elseif isdir(spec)
    folders = repmat({spec},size(fnames));
  else  % assume current working directory
    folders = repmat({'.'},size(fnames));
  end
  pathnames = cellfun(@fullfile,folders,fnames,'Uniform',false);
end

% Ensure that the files exist
if ~all(cellfun(@(x)exist(x,'file')==2,pathnames))
  error('One or more entries in ''pathnames'' does not exist.')
end

% Make column
pathnames = pathnames(:);

% Extract filenames
[~,rootnames,exts] = cellfun(@fileparts,pathnames,'Uniform',false);
fnames = strcat(rootnames,exts);

% Sort alphabetically by filename
[fnames,i] = sort(fnames);
pathnames = pathnames(i);

% Build the list
Hlist = BuildHlist(fnames,pathnames,functionName);

% Re-format if necessary
len = length(Hlist);
if len > 10 && len <= 50
  ncols = ceil(len/10);
  C = repmat({''},10,ncols);
  C(1:len)=Hlist;  Hlist=C;
  C(1:len)=fnames; fnames=C;
elseif len > 50
  nrows = ceil(len/4);
  C = repmat({''},nrows,4);
  C(1:len)=Hlist;  Hlist=C;
  C(1:len)=fnames; fnames=C;
end

% Display the list
fnames = reshape(fnames,size(Hlist));
maxlen = max(cellfun(@length,fnames(:)));
fun = @(x)blanks(maxlen-length(x));
C = strcat(Hlist,cellfun(fun,fnames,'Uniform',false));
fmt = repmat('   %s',1,size(Hlist,2));
fmt = [fmt,'\n'];
C=C'; fprintf(fmt,C{:});



% ----------------------------------------------------------
function Hlist = BuildHlist(fnames,pathnames,functionName)

% Extract filename extensions
[~,~,exts] = cellfun(@fileparts,fnames,'Uniform',false);

% Build hyperlinked list
Hlist = cell(size(fnames));  % initialize
for k = 1:length(fnames)
  if IsFileType(fnames{k},'vtool') || ...
     IsFileType(fnames{k},'S-array') || ...
     IsFileType(fnames{k},'xls') || ...
     IsFileType(fnames{k},'csv')
    if isempty(functionName), call='s = ExtractData'; else call=functionName; end
    cmd1 = sprintf('%s(''%s'');',call,pathnames{k});
    cmd = sprintf('matlab: disp(''>> %s''), %s',strrep(cmd1,'''',''''''),cmd1);
    Hlist{k} = sprintf('<a href="%s">%s</a>',cmd,fnames{k});
  elseif strcmpi(exts{k},'.mat')
    if isempty(functionName), call='s = load'; else call=functionName; end
    cmd1 = sprintf('%s(''%s'');',call,pathnames{k});
    cmd = sprintf('matlab: disp(''>> %s''), %s',strrep(cmd1,'''',''''''),cmd1);
    Hlist{k} = sprintf('<a href="%s">%s</a>',cmd,fnames{k});
  else
    Hlist{k} = fnames{k};
  end
end
