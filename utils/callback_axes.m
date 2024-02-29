function callback_axes(hObject,EventData)

% CALLBACK_AXES - Axes callback function.
% callback_axes(hObject,EventData)
%
% On LEFT-CLICK:
%   Modifies and marks the ROI time range on linked axes.  
%   Left-click once for left boundary and once for right, 
%   or any other button to exit. 
% On MIDDLE-CLICK:
%   Sets time range variable 'Trange' for the marked 
%   time range in the base workspace. 
%
% See "ActivateEvents". 
%
% P.G. Bonanni
% 10/5/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% If left click ...
if EventData.Button == 1

  while 1
    % Select start point
    [x1,~,button] = ginput(1);
    if button~=1, break, end

    % Select stop point
    [x2,~,button] = ginput(1);
    if button~=1, break, end

    % Swap if necessary
    if x2 < x1
      x = x2;
      x2 = x1;
      x1 = x;
    end

    % Move lines within the current figure, then retrieve 
    % the bounding datetime values (since "ginput" only 
    % returns normalized values)
    h = findobj(hObject,'Tag','lineL');
    set(h,'XData',[x1,x1],'Color','k'), x=get(h,'XData');  x1=x(1);
    h = findobj(hObject,'Tag','lineR');
    set(h,'XData',[x2,x2],'Color','k'), x=get(h,'XData');  x2=x(1);

    % Move lines within all active figures
    h = findobj('Tag','lineL');
    set(h,'XData',[x1,x1],'Color','k')
    h = findobj('Tag','lineR');
    set(h,'XData',[x2,x2],'Color','k')

    % Display time range
    fprintf('Time markers:\n');
    disp([x1;x2])
  end

% ... Else if middle click ...
elseif EventData.Button == 2

  % Retrieve the ROI bounding values
  h = findobj(hObject,'Tag','lineL');
  x=get(h,'XData');  x1=x(1);
  h = findobj(hObject,'Tag','lineR');
  x=get(h,'XData');  x2=x(1);

  % Define data window in workspace
  if isa(x1,'datetime')
    str1 = sprintf('datetime(''%s'')',datestr(x1));
    str2 = sprintf('datetime(''%s'')',datestr(x2));
  else  % if real units
    str1 = num2str(x1,'%g');
    str2 = num2str(x2,'%g');
  end
  cmd = sprintf('Trange = [%s,%s];',str1,str2);  disp(cmd)
  evalin('base',cmd);

end
