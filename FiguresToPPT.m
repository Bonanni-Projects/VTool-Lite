function FiguresToPPT(outfile,varargin)

% FIGURESTOPPT - Save current figures to PowerPoint.
% FiguresToPPT(outfile)
% FiguresToPPT(outfile,<Option>,<Value>,<Option>,<Value>,...)
%
% Saves the currently displayed figures to a new or existing 
% PowerPoint file using the "exportToPPTX" utility.  Input 
% 'outfile' specifies the output file name or path. 
%
% Control of figure scaling and outlining can be accomplished 
% by providing Option/Value pairs compatible with the "addpicture" 
% command within "exportToPPTX". 
%
% Examples:
%   >> FiguresToPPT('example.pptx')
%      Save figures to file "example.pptx", using the maximum 
%      picture size while preserving the existing aspect ratio 
%      (default). 
%
%   >> FiguresToPPT('example.pptx','Position',[0,1,5,3])
%      Save figures using a picture size of 3" x 5" with upper 
%      left corner 1" below upper left corner of slide. 
%                                     
%   >> FiguresToPPT('example.pptx','Position',[0,1,5,3],'EdgeColor',[1,0,0])
%      Save figures as 3" x 5" with a red boundary. 
%
% P.G. Bonanni
% 9/11/18, updated 2/2/22

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Get handles to displayed figures
handles = get(0,'Children');

% Return immediately if no figures
if isempty(handles)
  fprintf('No figures to save!\n');
  return
end

% Order handles according to figure number
C = get(handles,'Number');
if isscalar(C), num=C; else num=cat(1,C{:}); end
[~,i] = sort(num);  handles=handles(i);

% Add file extension if not present
[~,~,ext] = fileparts(outfile);
if ~strcmp(ext,'.pptx')
  outfile = [outfile,'.pptx'];
end

% Open and initialize file
if exist(outfile,'file')
  prompt = sprintf('File "%s" exists and will be overwritten.  Append instead (y/n)? ',outfile);
  resp = input(prompt,'s');
  if strcmp(resp,'y')
    exportToPPTX('open',outfile);
  else
    exportToPPTX('new','Dimensions',[13.33,7.5]);
  end
else
  exportToPPTX('new','Dimensions',[13.33,7.5]);
end

% Loop over figures
for h = handles'
  c = get(h,'Color');
  set(h,'Color','w')
  exportToPPTX('addslide');
  exportToPPTX('addpicture',h,'Scale','maxfixed',varargin{:});
  set(h,'Color',c)
  figure(h)
end

% Save and close
exportToPPTX('save',outfile);
exportToPPTX('close');
fprintf('Done.\n');
