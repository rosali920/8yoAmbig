%%PsychToolBox Script
%%Rosa Li June 2013
%

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
% AmbigTrials.txt is a text file with the header:
% TrialNo, TrialType, Risk1, Ambig1, Ambig2, Ambig1L
fid = fopen(fullfile(workdir, 'AmbigTrials.txt'));
A = textscan(fid, '%d %d %d %d %d %d', 'CommentStyle', '#');
fclose(fid);
params.stimulus = double([A{1} A{2} A{3} A{4} A{5} A{6}]);
params.numtrials = size(params.stimulus,1);
clear A;
if isempty(params.stimulus)
    error('Missing AmbigTrials.txt in working directory');
end
triallist = params.stimulus;
triallist = triallist(randperm(params.numtrials),:); %randomize stim order

%%=============================================
%               PARAMETERS
%%=============================================
%use 2ndary monitor if exists
params.screenindex = max(Screen('Screens'));
Screen('Preference', 'ConserveVRAM', 4096);

% Keys
if isunix %run on Mac
    params.button.leftkey = 9; %f
    params.button.rightkey = 13; %j
    params.button.spacebar = 44;
    params.button.quitQ = 20;
    params.button.esckey = 41;
else %windows
    params.button.leftkey = 70; %f
    params.button.rightkey = 74; %j
    params.button.spacebar = 32;
    params.button.quitQ = 81;
    params.button.esckey = 27;
end

% Text
params.text.font = 'Arial';
params.text.size = 24;
params.text.color = [255 255 255];

% Timing
params.timing.iti = 1;

% Write to file
foutid = fopen(resultTxt, 'w');
fprintf(foutid, '#Sub\tCondition\tDate\tTime\tTrialNum\tTrialID\tTrialType\tRisk\tAmbigA\tAmbigB\tAmbigALeft\tResp\tChoseAmbigA\tFirstRT\tConfirmRT\tChoiceCount\n');

try
    %get colors
    dev.white = WhiteIndex(params.screenindex);
    dev.black = BlackIndex(params.screenindex);
    dev.gray = [127 127 127];
    dev.red = [255 0 0];
    dev.blue = [0 0 255];
    
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
    params.screen.leftx = params.screen.centerx - params.screen.width/8 - 50;
    params.screen.rightx = params.screen.centerx + params.screen.width/8 + 50;
    params.screen.fixrect = [params.screen.centerx - 5, params.screen.centery - 5, params.screen.centerx + 5, params.screen.centery + 5];
    
    params.barheight = ceil(params.screen.height/4); %make bars total height 1/4 of screen
    params.barwidth = floor(params.barheight/4); %make bars 4 times taller than they are wide
    params.ambigwidth = floor(params.barwidth*1.5); %make ambig box 1.5x as wide as bar
    params.ambigoverlap = params.ambigwidth-params.barwidth; %calculates how much overlap per side
    params.hunit = params.barheight/100;
    
    ystart = floor(params.screen.height * 3/8);
    yend = floor(params.screen.height * 5/8);
    ycenter = params.screen.centery;
    xleftstart = floor(params.screen.width/4);
    xleftend = xleftstart + params.barwidth;
    ambigleftstart = xleftstart - params.ambigoverlap;
    ambigleftend = xleftend + params.ambigoverlap;
    xrightend = floor(params.screen.width*3/4);
    xrightstart = xrightend - params.barwidth;
    ambigrightstart = xrightstart - params.ambigoverlap;
    ambigrightend = xrightend + params.ambigoverlap;
    
    % dimensions for choice frames
    xleftboxstart = xleftstart - params.barwidth * 1.25;
    xleftboxend = xleftend + params.barwidth * 1.25;
    xrightboxstart = xrightstart - params.barwidth * 1.25;
    xrightboxend = xrightend + params.barwidth * 1.25;
    yboxstart = ystart - params.barwidth * 1.25;
    yboxend = yend + params.barwidth * 1.25;
    leftchoice = [xleftboxstart, yboxstart, xleftboxend, yboxend];
    rightchoice = [xrightboxstart, yboxstart, xrightboxend, yboxend];
    
    % 1/2, 1/2 bar
    leftAmbigBar = [xleftstart, ystart, xleftend, ycenter; xleftstart, ycenter, xleftend, yend];
    rightAmbigBar = [xrightstart, ystart, xrightend, ycenter; xrightstart, ycenter, xrightend, yend];
    
    % Ready
    Screen('TextStyle', dev.win, 0);
    Screen('TextFont', dev.win, params.text.font);
    Screen('TextSize', dev.win, params.text.size);
    DrawFormattedText(dev.win, 'Press any key to begin your practice.', 'center', 'center', params.text.color, 60, [], [], 1.5);
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
    
    %% practice trials, all red v. all blue
    for practiceI = 1:2;
        colorMat = vertcat(dev.red, dev.blue)';
        if practiceI ==1
            allred = [xrightstart, ystart, xrightend, yend];
            allblue = [xleftstart, ystart, xleftend, yend];
        else
            allblue = [xrightstart, ystart, xrightend, yend];
            allred = [xleftstart, ystart, xleftend, yend];
        end
        rectMat = vertcat(allred, allblue)';
        Screen('FillRect', dev.win, colorMat, rectMat);
        Screen('Flip', dev.win);
        confirm = 0;
        data.resp = 0;
        while KbCheck; end %wait until all keys are released
        while (confirm == 0) %code for selection key presses
            [keyIsDown, secs, keyCode] = KbCheck;
            if keyIsDown
                if (find(keyCode) == params.button.leftkey) %they chose left
                    data.resp = 1;
                elseif (find(keyCode) == params.button.rightkey) %they choice right
                    data.resp = 2;
                elseif (find(keyCode) == params.button.quitQ) | (find(keyCode) == params.button.esckey) %q or esc to quit
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
                elseif (find(keyCode) == params.button.spacebar) %space to confirm selection
                    if data.resp ~= 0
                        confirm = 1;
                        break
                    end
                end
            end
            if (data.resp == 1) % chose left
                Screen('FillRect', dev.win, colorMat, rectMat);
                Screen('FrameRect', dev.win, dev.white, leftchoice, 5);
                Screen('Flip', dev.win);
            elseif (data.resp == 2) %choice right
                Screen('FillRect', dev.win, colorMat, rectMat);
                Screen('FrameRect', dev.win, dev.white, rightchoice, 5);
                Screen('Flip', dev.win);
            end
        end
        Screen('FillRect', dev.win, dev.black);
        Screen('Flip', dev.win);
        WaitSecs(params.timing.iti);
    end
    
    DrawFormattedText(dev.win, 'Press any key to begin real choices.', 'center', 'center', params.text.color, 60, [], [], 1.5);
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
    %% real trials
    [ keyIsDown, t, keyCode ] = KbCheck;
    
    for itrial = 1:params.numtrials
        if triallist(itrial,2) == 1 % risk-ambig trials
            colorMat = vertcat(dev.red, dev.blue, dev.red, dev.blue, dev.gray)';
            risk = triallist(itrial,3);
            ambigA = triallist(itrial,4);
            riskswitch = ystart + floor(params.hunit * risk); %point where color switches
            ambigtop = ycenter - ceil(params.hunit * ambigA/2);
            ambigbottom = ycenter + ceil(params.hunit * ambigA/2);
            if triallist(itrial,6) == 1 %ambigA on left
                riskred = [xrightstart, ystart, xrightend, riskswitch];
                riskblue = [xrightstart, riskswitch, xrightend, yend];
                ambigbox = [ambigleftstart, ambigtop, ambigleftend, ambigbottom];
                rectMat = vertcat(leftAmbigBar, riskred, riskblue, ambigbox)';
            else %ambigA on right
                riskred = [xleftstart, ystart, xleftend, riskswitch];
                riskblue = [xleftstart, riskswitch, xleftend, yend];
                ambigbox = [ambigrightstart, ambigtop, ambigrightend, ambigbottom];
                rectMat = vertcat(rightAmbigBar, riskred, riskblue, ambigbox)';
            end
        elseif triallist(itrial,2) == 2 %ambig-ambig trials
            colorMat = vertcat(dev.red, dev.blue, dev.red, dev.blue, dev.gray, dev.gray)';
            ambigA = triallist(itrial,4);
            ambigAtop = ycenter - ceil(params.hunit * ambigA/2);
            ambigAbottom = ycenter + ceil(params.hunit * ambigA/2);
            ambigB = triallist(itrial,5);
            ambigBtop = ycenter - ceil(params.hunit * ambigB/2);
            ambigBbottom = ycenter + ceil(params.hunit * ambigB/2);
            if triallist(itrial,6) == 1 %ambigA on left
                ambigAbox = [ambigleftstart, ambigAtop, ambigleftend, ambigAbottom];
                ambigBbox = [ambigrightstart, ambigBtop, ambigrightend, ambigBbottom];
            else %ambigA on right
                ambigAbox = [ambigrightstart, ambigAtop, ambigrightend, ambigAbottom];
                ambigBbox = [ambigleftstart, ambigBtop, ambigleftend, ambigBbottom];
            end
            rectMat = vertcat(rightAmbigBar, leftAmbigBar, ambigAbox, ambigBbox)';
        end
        
        % This works; probably not necessary
        %         StimWin = Screen('OpenOffscreenWindow', dev.win);
        %         ChoiceWin = Screen('OpenOffscreenWindow', dev.win);
        %         Screen('FillRect', StimWin, colorMat, rectMat);
        %         Screen('CopyWindow', StimWin, dev.win);
        
        Screen('FillRect', dev.win, colorMat, rectMat);
        Screen('Flip', dev.win);
        
        stimstart = GetSecs;
        confirm = 0;
        data.prevresp = 0;
        data.resp = 0;
        data.choiceCount = 0; % number of choices made before confirmed
        data.firstRT = 0; %RT for first button press
        data.confirmRT = 0; %RT for confirm spacebar
        data.choseAmbigA = NaN;
        
        while KbCheck; end %wait until all keys are released
        
        while (confirm == 0) %code for selection key presses
            [keyIsDown, secs, keyCode] = KbCheck;
            if keyIsDown
                if data.choiceCount == 0; %first key press
                    data.firstRT = GetSecs - stimstart;
                end
                if (find(keyCode) == params.button.leftkey) %they chose left
                    data.resp = 1;
                    if data.resp ~= data.prevresp
                        data.choiceCount = data.choiceCount + 1;
                    end
                    data.prevresp = data.resp;
                elseif (find(keyCode) == params.button.rightkey) %they choice right
                    data.resp = 2;
                    if data.resp ~= data.prevresp
                        data.choiceCount = data.choiceCount + 1;
                    end
                    data.prevresp = data.resp;
                elseif (find(keyCode) == params.button.quitQ) | (find(keyCode) == params.button.esckey) %q or esc to quit
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
                elseif (find(keyCode) == params.button.spacebar) %space to confirm selection
                    if data.resp ~= 0
                        confirm = 1;
                        data.confirmRT = GetSecs - stimstart;
                        break
                    end
                end
            end
            
            if (data.resp == 1) % chose left
                Screen('FillRect', dev.win, colorMat, rectMat);
                Screen('FrameRect', dev.win, dev.white, leftchoice, 5);
                Screen('Flip', dev.win);
                if triallist(itrial,6) %ambigA on left
                    data.choseAmbigA = 1;
                else
                    data.choseAmbigA = 0;
                end
            elseif (data.resp == 2) %choice right
                Screen('FillRect', dev.win, colorMat, rectMat);
                Screen('FrameRect', dev.win, dev.white, rightchoice, 5);
                Screen('Flip', dev.win);
                if triallist(itrial,6) %ambigA on left
                    data.choseAmbigA = 0;
                else %ambigA on right
                    data.choseAmbigA = 1;
                end
            end
        end
        Screen('FillRect', dev.win, dev.black);
        Screen('Flip', dev.win);
        WaitSecs(params.timing.iti);
        
        % write output
        fprintf(foutid, '%g\t%g\t%s\t%s\t%g\t%g\t%g\t%g\t%g\t%g\t%g\t%g\t%g\t%1.4f\t%1.4f\t%g\n',...
            data.subnum, data.condition, data.date, data.time, itrial, triallist(itrial,1), triallist(itrial,2), ...
            triallist(itrial,3),triallist(itrial,4), triallist(itrial,5), triallist(itrial,6),...
            data.resp, data.choseAmbigA, data.firstRT, data.confirmRT, data.choiceCount);
        
        % break screen
        if (mod(itrial,11) == 0) %gives break every 11th trial
            DrawFormattedText(dev.win, 'You may take a break.\n Press any key to continue.', 'center', 'center', params.text.color, 60, [], [], 1.5);
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


