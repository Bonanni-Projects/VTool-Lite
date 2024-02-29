function MakeSarrayFile(pathname,varargin)

% MAKESARRAYFILE - Make an S-array .mat file from signal data.
% MakeSarrayFile(pathname,'Sampling',Ts,'Data',Data)
% MakeSarrayFile(pathname,'Sampling',Sampling,'Data',Data)
% MakeSarrayFile(pathname,'Sampling',Sampling,'Data',Data,<property>,<value>,<property>,<value>, ...)
%
% Saves an S-array .mat file constructed from signal data.  The S-array 
% supports signals that may be regularly or irregularly sampled, and in 
% addition may be "non time-synchronized", implying that different sampling 
% may apply to different signal data.  Output file contains a single 
% structure array 'S', with each S(i) having fields: 
%   'name'         -  signal name string
%   'data'         -  data vector
%   'dt'           -  sample time (constant or vector)
%   'unitsT'       -  time units string
%   'units'        -  signal units string
%   'description'  -  signal description string
%   'trigger'      -  start time (scalar value or date vector, see below)
% Type "help formats" and see function "IsSarray" for additional 
% information on S-array format. 
%
% Input 'pathname' specifies the pathname for the output file.  If the 
% specified pathname does not adhere to the S-array naming standard 
% (see "IsFileType"), an error is generated.  If the file indicated 
% by 'pathname' already exists, it is overwritten. 
%
% Signal information is provided via property/value pairs, as follows. 
% The 'Sampling' and 'Data' specifications are required.  The additional 
% property/value pairs are optional. 
%
%   Property           Value(*)
% ------------         -------------------------------------------------
%  'Sampling'     -    Cell array of sample times, one per signal, or a
%                      scalar value 'Ts' if sampling times are the same. 
%                      If a signal has non-uniform sampling, its sampling 
%                      is specified by a vector of length(data)-1. 
%  'Data'         -    Cell array of signal data, each cell containing 
%                      a single column vector, or a multidimensional array 
%                      whose columns represent time series (see below). 
%  'Names'         -   (OPTIONAL) Cell array of signal names, each cell 
%                      containing a single character string. Defaults to 
%                      {'x1','x2',...,'xM'} if [] is specified, or if 
%                      no 'Names' information provided. 
%  'Units'         -   (OPTIONAL) Cell array of signal units strings, each 
%                      cell containing a single character string. Defaults 
%                      to empty strings {'','',...} if [] is specified, or 
%                      if no 'Units' information provided. 
%  'Descriptions'  -   (OPTIONAL) Cell array of signal descriptions, each 
%                      cell containing a single character string. Defaults 
%                      to empty strings {'','',...} if [] is specified, or 
%                      if no 'Descriptions' information provided. 
%  'start'         -   (OPTIONAL) date string, or datetime value, or datenum 
%                      value, or 6-element date vector specifying an absolute 
%                      start time for the signals, or a scalar value specifiying 
%                      a start time offset.  Defaults to 0 if [] is specified 
%                      or no information provided. 
%
% (*) All cell arrays must be length-M, where M is the number of 
% represented signals. 
%
% If 'Data' contains a 2- or higher dimensional array, the array is 
% expanded into an equivalent set of 1-dimensional column vectors to 
% produce a new set of 1-dimensional signals.  The corresponding 'Names' 
% entry is interpreted as a root name, and appropriate subscripting with 
% trailing numerals is used to name the individual signals. The underscore 
% character '_' is employed where necessary to separate the subscripts.  
% All other attributes are replicated across the expanded set of signals. 
%
% See also "MakeSarray", "MakeVtlFile". 
%
% P.G. Bonanni
% 7/13/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check 'pathname' input
if ~ischar(pathname)
  error('Input ''pathname'' is invalid.')
end
[~,~,ext] = fileparts(pathname);
if ~strcmp(ext,'.mat')
  pathname = [pathname,'.mat'];
end
if ~IsFileType(pathname,'S-array')
  error('Specified filename does not match the naming standard.  See "IsFileType".')
end

% Build S-array from provided inputs
S = MakeSarray(varargin{:});

% Save results to S-array .mat file
save(pathname,'S')
