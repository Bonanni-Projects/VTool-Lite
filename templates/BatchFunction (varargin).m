function out = BatchFunction(pathname,outfolder,varargin)

% BATCHFUNCTION - Compute results from a single input data file.
% BatchFunction(pathname)
% BatchFunction(pathname,outfolder)
% BatchFunction(pathname,outfolder, <Option1>,<Value>,<Option2>,<Value>,...)
% BatchFunction(pathname,[],        <Option1>,<Value>,<Option2>,<Value>,...)
% out = BatchFunction(...)
%
% (SAMPLE)
%
% P.G. Bonanni
% 7/17/24

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 2
  outfolder = [];
end

% No outputs if 'outfolder' specified
if nargout && nargin > 1 && ~(isnumeric(outfolder) && isempty(outfolder))
  error('Invalid usage.  No outputs if ''outfolder'' specified.')
end

% Set default 'outfolder' if necessary
if isempty(outfolder), outfolder='.'; end

% Derive 'casename'
casename = GetRootname(pathname);

% Derive output file pathname
outfile = ['results_',casename,'.mat'];
outpath = fullfile(outfolder,outfile);

% Process option/value pairs
if ~isempty(varargin)
  % Check for pairing and option validity
  if rem(length(varargin),2) ~= 0
    error('Incomplete option/value pair(s).')
  elseif any(~cellfun('isclass',varargin(1:2:end),'char'))
    error('One or more invalid options specified.')
  end
  % Get options list
  Options = varargin(1:2:end);
  if length(unique(Options)) ~= length(Options)
    fprintf('WARNING: One or more options is repeated.\n')
  end
  % Make option/value assignments
  for k = 1:2:length(varargin)
    eval(sprintf('%s = varargin{%d};',varargin{k},k+1));
  end
end

% -----------------------------------------------------------
% To speed processing when results already exist, set global
% variable "NEW_ONLY" and uncomment the lines below: 
% -----------------------------------------------------------
% global NEW_ONLY  % set to TRUE to skip over existing files
% if ~isempty(NEW_ONLY) && NEW_ONLY && ~nargout && exist(outpath,'file')
%   fprintf('File "%s" exists. Skipping.\n',outfile);
%   return
% end

% Load data from file
s = LoadResults(pathname);

% Sample function call, passing any option/value pairs
[x,y,z] = myfun(s,varargin{:});


if nargout
  out.x = x;
  out.y = y;
  out.z = z;

else
  % Save results
  save(outpath,'x','y','z')
end
