%%PsychToolBox Script
%%Rosa Li June 2013

clear all;
close all;
RandStream('mt19937ar', 'seed', sum(100*clock));

%Open output file for writing
workdir = fileparts(which(mfilename));
datadir = [workdir, filesep, 'data_' mfilename];
if ~exist(datadir, 'dir')
    mkdir(datadir);
end

subnum = input('\n\n Enter participant number\n');
condition = input('\n\n Enter condition, 1 for R, 2 for B\n');

resultMat = fullfile(datadir, sprintf('%s-debug-%03g.mat', mfilename, subnum));
resultTxt = fullfile(datadir, sprintf('%s-%03g.txt', mfilename, subnum));

%Make sure result file doesn't already exist
while exist(resultMat, 'file') || exist(resultTxt, 'file')
    overwrite = input('File exists. Overwrite y/n? ', 's');
    if strcmpi(overwrite, 'Y')
        break;
    else
        fprintf('Ending program');
        return;
    end
end
clear overwrite;

%Make data structure
data.subnum = subnum;
data.condition = condition;
data.date = datestr(now,2);
data.time = datestr(now,13);

% Get stim dimensions
% BarPropTrials.txt is a text file with the header:
% TrialID, TrialType, Ambig, Risk
fid = fopen(fullfile(workdir, 'BarProbTrials.txt'));
A = textscan(fid, '%d %d %d %d', 'CommentStyle', '#');
fclose(fid);
params.stimulus = double([A{1} A{2} A{3} A{4}]);
params.numtrials = size(params.stimulus,1);
clear A;
if isempty(params.stimulus)
    error('Missing BarProbTrials.txt in working directory');
end
triallist = params.stimulus;
permThese = triallist(3:params.numtrials,:);
triallist(3:params.numtrials,:) = permThese(randperm(length(permThese)),:); %randomize stim order for tirals 3-13


%%=============================================
%               PARAMETERS
%%=============================================
%use 2ndary monitor if exists
params.screenindex = max(Screen('Screens'));
Screen('Preference', 'ConserveVRAM', 4096);

% Keys
if isunix %run on Mac
    params.button.leftkey = KbName('LeftArrow');
    params.button.rightkey = KbName('RightArrow');
    params.button.spacebar = 44;
    params.button.quitQ = 20;
    params.button.esckey = 41;
else %windows
    params.button.leftkey = KbName('left');
    params.button.rightkey = KbName('right');
    params.button.spacebar = 32;
    params.button.quitQ = 81;
    params.button.esckey = 27;
end
%get colors
dev.white = WhiteIndex(params.screenindex);
dev.black = BlackIndex(params.screenindex);
dev.gray = [127 127 127];
dev.red = [255 0 0];
dev.blue = [0 0 255];
% Text
params.text.font = 'Arial';
params.text.size = 20;
params.text.color = dev.white;

% Timing
params.timing.iti = 1;

% Write to file
foutid = fopen(resultTxt, 'w');
fprintf(foutid, '#Sub\tCondition\tDate\tTime\tTrialNum\tTrialID\tTrialType\tAmbig\tRisk\n');

try
    % Open window
    dev.win = Screen('OpenWindow', params.screenindex, dev.black);
    
    % Disable keyboard input
    ListenChar(2);
    HideCursor;
    
    % Get flip interval and set waitframes
    dev.flipint = Screen('GetFlipInterval', dev.win);
    dev.waitframes = 1;
    
    % Get screen dimensions in pixels
    [params.screen.width params.screen.height] = Screen('WindowSize', dev.win);
    params.screen.centerx = params.screen.width/2;
    params.screen.centery = params.screen.height/2;
    params.barheight = ceil(params.screen.height/4); %make bars total height 1/4 of screen
    params.barwidth = floor(params.barheight/4); %make bars 4 times taller than they are wide
    params.ambigwidth = floor(params.barwidth*1.5); %make ambig box 1.5x as wide as bar
    params.ambigoverlap = params.ambigwidth-params.barwidth; %calculates how much overlap per side
    params.hunit = params.barheight/100;
    
    ystart = floor(params.screen.height * 3/8);
    yend = floor(params.screen.height * 5/8);
    ycenter = params.screen.centery;
    xstart = floor(params.screen.width/4) + params.barwidth/2;
    xend = xstart + params.barwidth;
    ambigstart = xstart - params.ambigoverlap;
    ambigend = xend + params.ambigoverlap;
    
    % 1/2, 1/2 bar
    AmbigBar = [xstart, ystart, xend, ycenter; xstart, ycenter, xend, yend];
    
    Screen('TextStyle', dev.win, 0);
    Screen('TextFont', dev.win, params.text.font);
    Screen('TextSize', dev.win, params.text.size);
    
    %ready
    itrial = 1;
    DrawFormattedText(dev.win, 'Press any key to begin', 'center', 'center', params.text.color, 60, [], [], 1.5);
    Screen('Flip', dev.win);
    
    while KbCheck; end % Wait until all keys released
    response = 0;
    while (response==0)
        [keyIsDown, secs, keyCode] = KbCheck;
        if keyIsDown
            response = 1;
            break
        end
    end
    
    [ keyIsDown, t, keyCode ] = KbCheck;
    while itrial <= params.numtrials
        if triallist(itrial,2) == 1; %ambiguous trial
            ambigVal = triallist(itrial,3);
            colorMat = vertcat(dev.red, dev.blue, dev.gray)';
            ambigtop = ycenter - ceil(params.hunit * ambigVal/2);
            ambigbottom = ycenter + ceil(params.hunit * ambigVal/2);
            ambigbox = [ambigstart, ambigtop, ambigend, ambigbottom];
            rectMat = vertcat(AmbigBar, ambigbox)';
        else %risk trial
            riskVal = triallist(itrial,4);
            colorMat = vertcat(dev.red, dev.blue)';
            riskswitch = ystart + floor(params.hunit * riskVal); %point where color switches
            riskred = [xstart, ystart, xend, riskswitch];
            riskblue = [xstart, riskswitch, xend, yend];
            rectMat = vertcat(riskred, riskblue)';
        end
        DrawFormattedText(dev.win, [num2str(itrial) ': Pretend we played this bar 100 times.\n\n\nHow many times do you think\n\n...it will land on red?\n\n...it will land on blue?'], xend + params.barheight, ystart, dev.white, 60);
        Screen('FillRect', dev.win, colorMat, rectMat);
        Screen('Flip', dev.win);
        
        % write output
        fprintf(foutid, '%g\t%g\t%s\t%s\t%g\t%g\t%g\t%g\t%g\n',...
            data.subnum, data.condition, data.date, data.time, itrial, ...
            triallist(itrial,1), triallist(itrial,2), triallist(itrial,3), ...
            triallist(itrial,4));
        
        while KbCheck; end %wait until all keys are released
        confirm = 0;
        while (confirm == 0) %code for selection key presses
            [keyIsDown, secs, keyCode] = KbCheck;
            if keyIsDown
                if (find(keyCode) == params.button.quitQ) | (find(keyCode) == params.button.esckey) %q or esc to quit
                    Screen('CloseAll');
                    fclose(foutid);
                    ShowCursor;
                    ListenChar(0);
                    Priority(0);
                    save(resultMat);
                    assignin('base', 'data', data);
                    assignin('base', 'dev', dev);
                    assignin('base', 'params', params);
                    return
                elseif (find(keyCode) == params.button.leftkey);
                    if itrial > 1
                        itrial = itrial-1;
                        confirm = 1;
                    end
                elseif (find(keyCode) == params.button.rightkey)
                    if itrial < params.numtrials %not the final trial
                        itrial = itrial + 1;
                        confirm = 1;
                    elseif itrial == params.numtrials %final trial - force spacebar to end
                        if (find(keyCode) == params.button.spacebar);
                            confirm = 1;
                            break
                        end
                    end
                end
            end
        end
        
    end
    
    DrawFormattedText(dev.win, 'Thank you!', 'center', 'center', params.text.color, 60, [], [], 1.5);
    Screen('Flip', dev.win);
    WaitSecs(2);
    Screen('CloseAll');
    fclose(foutid);
    ShowCursor;
    ListenChar(0);
    Priority(0);
    
catch
    Screen('CloseAll');
    fclose(foutid);
    ShowCursor;
    ListenChar(0);
    Priority(0);
    save(resultMat);
    assignin('base', 'data', data);
    assignin('base', 'dev', dev);
    assignin('base', 'params', params);
    psychrethrow(psychlasterror);
end


