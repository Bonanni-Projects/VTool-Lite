function [out1,out2] = TimeLastModified(pathnames,option)

% TIMELASTMODIFIED - Get or plot file modification times.
% d = TimeLastModified(pathnames)
% [d,pathnames] = TimeLastModified(pathnames,'sort')
%
% Returns modification times for files specified in cell 
% array 'pathnames'.  Output 'd' is an array of datetime 
% values equal in size to 'pathnames'.  The 'sort' option 
% specifies chronological sorting, in which case both a 
% sorted 'd' and sorted 'pathnames' are returned.  If 
% called without output arguments, a timeline plot is 
% generated and no outputs are returned. 
%
% P.G. Bonanni
% 5/17/21

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 2
  option = '';
end

% If a single pathname string provided
if ischar(pathnames), pathnames=cellstr(pathnames); end

% Check input
if ~iscellstr(pathnames)
  error('Invalid ''pathnames'' input.')
elseif ~all(cellfun(@(x)exist(x,'file'),pathnames(:)))
  error('One or more entries in ''pathnames'' does not exist.')
elseif ~all(cellfun(@(x)exist(x,'file'),pathnames(:))==2)
  error('Input ''pathnames'' must contain pathnames to files only.')
end

% Initialize
pathnames1 = pathnames(:);

% Get file attributes
S = cellfun(@dir,pathnames1);

% Collect dates from the file listing
d = datetime([S.datenum]','ConvertFrom','datenum');

% If sorting is specified
if strcmp(option,'sort')
  [d,i] = sort(d);
  pathnames1 = pathnames1(i);
end

% Re-shape to match 'pathnames'
d          = reshape(d,         size(pathnames));
pathnames1 = reshape(pathnames1,size(pathnames));


if nargout
  out1 = d;
  out2 = pathnames1;

else
  figure
  set(gcf,'Pos',[473,462,779,432])

  subplot(211)
  plot(d(:),ones(size(d(:))),'.','MarkerSize',10)
  set(gca,'YTick',[])
  grid on
  title('Timeline')

  subplot(212)
  if all(diff(d(:)) > 0)
    plot(d(:),[0;diff(d(:))],'.-')
    grid on
    title('Time Between Files')
  else
    text(0.5,0.5,'(files are not in chronological order)','Horiz','center')
    axis off
  end
end
