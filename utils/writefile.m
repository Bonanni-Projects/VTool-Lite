function writefile(lines,varargin)

% WRITEFILE - Write text lines to a file.
% writefile(lines,outfile)
% writefile(lines,outfile,'DOS')
%
% Write text lines in cell array or character array 'lines' to 
% the file specified by 'outfile'.  Overwrites any existing file 
% of the same name.  By default, terminates lines with '\n' alone.  
% If the 'DOS' option is specified as a final argument, terminates 
% lines with '\r\n'. 
%
% If parameter 'outfile' is omitted or empty, the cell array 
% contents are written to standard out. 
%
% P.G. Bonanni
% 5/10/13

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


option = '';
if ~isempty(varargin) && strcmpi(varargin{end},'DOS')
  option = 'DOS';
  varargin(end) = [];
end

if isempty(varargin)
  outfile = '';
elseif length(varargin) == 1
  outfile = varargin{1};
else
  error('Too many arguments.')
end

% Make cell array if required
if ischar(lines)
  lines = cellstr(lines);
end

% If 'outfile' not specified ...
if isempty(outfile)

  % Standard out
  fid = 1;

  % Write text lines
  if strcmp(option,'DOS')
    fprintf(fid,'%s\r\n',lines{:});
  else  % if strcmp(option,'UNIX')
    fprintf(fid,'%s\n',lines{:});
  end

else
  % Open output file
  fid = fopen(outfile,'w');

  % Write text lines
  if strcmp(option,'DOS')
    fprintf(fid,'%s\r\n',lines{:});
  else  % if strcmp(option,'UNIX')
    fprintf(fid,'%s\n',lines{:});
  end

  % Close file
  fclose(fid);
end
