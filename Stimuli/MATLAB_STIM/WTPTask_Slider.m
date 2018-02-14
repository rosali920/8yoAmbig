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
% WTPTrials.txt is a text file with the header:
% TrialID, TrialType, Ambig, Risk
fid = fopen(fullfile(workdir, 'WTPTrials.txt'));
A = textscan(fid, '%d %d %d %d', 'CommentStyle', '#');
fclose(fid);
params.stimulus = double([A{1} A{2} A{3} A{4}]);
startLo = round(rand(1,size(params.stimulus,1)));%generate rand 0s and 1s for start Lo or High;
params.stimulus(:,5) = startLo;
params.numtrials = size(params.stimulus,1);
clear A;
if isempty(params.stimulus)
    error('Missing WTPTrials.txt in working directory');
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
params.text.size = 40;
params.text.color = dev.white;

% Timing
params.timing.iti = 1;

% Write to file
foutid = fopen(resultTxt, 'w');
fprintf(foutid, '#Sub\tCondition\tDate\tTime\tTrialNum\tTrialID\tTrialType\tAmbig\tRisk\tStartLo\tResp\tConfirmRT\n');

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
    xleftstart = floor(params.screen.width/4);
    xleftend = xleftstart + params.barwidth;
    xleftcenter = floor(mean([xleftstart, xleftend]));
    ambigleftstart = xleftstart - params.ambigoverlap;
    ambigleftend = xleftend + params.ambigoverlap;
    xrightend = floor(params.screen.width*3/4);
    xrightstart = xrightend - params.barwidth;
    xrightcenter = floor(mean([xrightend, xrightstart]));
    ambigrightstart = xrightstart - params.ambigoverlap;
    ambigrightend = xrightend + params.ambigoverlap;
    
    % 1/2, 1/2 bar
    leftAmbigBar = [xleftstart, ystart, xleftend, ycenter; xleftstart, ycenter, xleftend, yend];
    rightAmbigBar = [xrightstart, ystart, xrightend, ycenter; xrightstart, ycenter, xrightend, yend];
    
    % dimensions for top/bottom values
    params.maxVal = 12;
    params.minVal = 2;
    if condition == 1 %red is 20
        params.tNum = params.maxVal; %top color is 20
        params.bNum = params.minVal; %bottom color is 20
    elseif condition == 2 %blue is 20
        params.tNum = params.minVal;
        params.bNum = params.maxVal;
    end
    Screen('TextStyle', dev.win, 0);
    Screen('TextFont', dev.win, params.text.font);
    Screen('TextSize', dev.win, params.text.size);
    boundstNum = Screen('TextBounds', dev.win, num2str(params.tNum));
    boundsbNum = Screen('TextBounds', dev.win, num2str(params.bNum));
    tNumY = ystart - boundstNum(4);
    bNumY = yend;
    textbNumX = xleftcenter - boundsbNum(3)/2;
    texttNumX = xleftcenter - boundstNum(3)/2;
    
    %% Practice trials
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
    for practiceI = 1:2;
        rectMat = [xleftstart, ystart, xleftend, yend];
        if practiceI == 1
            colorMat = dev.red;
            Screen('DrawText', dev.win, num2str(params.tNum), texttNumX, tNumY, dev.white);
            
            if condition == 1 %red is winning, red bar should be worth max
                safeVal = params.minVal;
            else %blue is winning, red bar should be worth min
                safeVal = params.maxVal;
            end
        else
            colorMat = dev.blue;
            Screen('DrawText', dev.win, num2str(params.bNum), textbNumX, bNumY, dev.white);
            
            if condition == 2 %blue is winning, blue bar should be worth max
                safeVal = params.minVal;
            else %red is winning, blue bar should be worth min
                safeVal = params.maxVal;
            end
        end
        safeText = num2str(safeVal);
        boundsRect = Screen('TextBounds', dev.win, safeText);
        Screen('FillRect', dev.win, colorMat, rectMat);
        Screen('DrawText', dev.win, safeText, xrightcenter - boundsRect(3)/2, params.screen.centery - boundsRect(4)/2, dev.white);
        Screen('FillRect', dev.win, colorMat, rectMat);
        Screen('Flip', dev.win);
        confirm = 0;
        while KbCheck; end %wait until all keys are released
        
        while (confirm == 0) %code for selection key presses
            [keyIsDown, secs, keyCode] = KbCheck;
            if keyIsDown
                if (find(keyCode) == params.button.leftkey) %they chose left
                    if safeVal > params.minVal %don't let it go lower than lowest possible win
                        safeVal = safeVal - 1;
                        while KbCheck; end % Wait until all keys released
                    end
                elseif (find(keyCode) == params.button.rightkey) %they chose right
                    if safeVal < params.maxVal %don't let it go higher than highest possible win
                        safeVal = safeVal + 1;
                        while KbCheck; end % Wait until all keys released
                    end
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
                    confirm = 1;
                    break
                end
            end
            safeText = num2str(safeVal);
            boundsRect = Screen('TextBounds', dev.win, safeText);
            Screen('DrawText', dev.win, safeText, xrightcenter - boundsRect(3)/2, params.screen.centery - boundsRect(4)/2, dev.white);
            if practiceI == 1
                Screen('DrawText', dev.win, num2str(params.tNum), texttNumX, tNumY, dev.white);
            else
                Screen('DrawText', dev.win, num2str(params.bNum), textbNumX, bNumY, dev.white);
            end
            Screen('FillRect', dev.win, colorMat, rectMat);
            Screen('Flip', dev.win);
        end
        fprintf(foutid, ['# Practice trial ' num2str(practiceI) ': ' num2str(safeVal) '\n']);
    end
    
    
    %% Real trials
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
    
    [ keyIsDown, t, keyCode ] = KbCheck;
    
    for itrial = 1:params.numtrials
        if triallist(itrial, 5) == 1 %start lo
            safeVal = params.minVal;
        else %start hi
            safeVal = params.maxVal;
        end
        safeText = num2str(safeVal);
        boundsRect = Screen('TextBounds', dev.win, safeText);
        if triallist(itrial,2) == 1 % ambig trials
            colorMat = vertcat(dev.red, dev.blue, dev.gray)';
            ambigA = triallist(itrial,3);
            ambigtop = ycenter - ceil(params.hunit * ambigA/2);
            ambigbottom = ycenter + ceil(params.hunit * ambigA/2);
            ambigbox = [ambigleftstart, ambigtop, ambigleftend, ambigbottom];
            rectMat = vertcat(leftAmbigBar, ambigbox)';
        elseif triallist(itrial,2) == 2 %risk trials
            colorMat = vertcat(dev.red, dev.blue)';
            risk = triallist(itrial,4);
            riskswitch = ystart + floor(params.hunit * risk); %point where color switches
            riskred = [xleftstart, ystart, xleftend, riskswitch];
            riskblue = [xleftstart, riskswitch, xleftend, yend];
            rectMat = vertcat(riskred, riskblue)';
        end
        Screen('DrawText', dev.win, safeText, xrightcenter - boundsRect(3)/2, params.screen.centery - boundsRect(4)/2, dev.white);
        Screen('DrawText', dev.win, num2str(params.tNum), texttNumX, tNumY, dev.white);
        Screen('DrawText', dev.win, num2str(params.bNum), textbNumX, bNumY, dev.white);
        Screen('FillRect', dev.win, colorMat, rectMat);
        Screen('Flip', dev.win);
        
        stimstart = GetSecs;
        confirm = 0;
        data.confirmRT = 0; %RT for confirm spacebar
        data.choseAmbigA = NaN;
        
        while KbCheck; end %wait until all keys are released
        
        while (confirm == 0) %code for selection key presses
            [keyIsDown, secs, keyCode] = KbCheck;
            if keyIsDown
                if (find(keyCode) == params.button.leftkey) %they chose left
                    if safeVal > params.minVal %don't let it go lower than lowest possible win
                        safeVal = safeVal - 1;
                        while KbCheck; end % Wait until all keys released
                    end
                elseif (find(keyCode) == params.button.rightkey) %they chose right
                    if safeVal < params.maxVal %don't let it go higher than highest possible win
                        safeVal = safeVal + 1;
                        while KbCheck; end % Wait until all keys released
                    end
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
                    confirm = 1;
                    data.confirmRT = GetSecs - stimstart;
                    data.resp = safeVal;
                    break
                end
            end
            safeText = num2str(safeVal);
            boundsRect = Screen('TextBounds', dev.win, safeText);
            Screen('DrawText', dev.win, safeText, xrightcenter - boundsRect(3)/2, params.screen.centery - boundsRect(4)/2, dev.white);
            Screen('DrawText', dev.win, num2str(params.tNum), texttNumX, tNumY, dev.white);
            Screen('DrawText', dev.win, num2str(params.bNum), textbNumX, bNumY, dev.white);
            Screen('FillRect', dev.win, colorMat, rectMat);
            Screen('Flip', dev.win);
        end
        
        Screen('FillRect', dev.win, dev.black);
        Screen('Flip', dev.win);
        WaitSecs(params.timing.iti);
        
        % write output
        fprintf(foutid, '%g\t%g\t%s\t%s\t%g\t%g\t%g\t%g\t%g\t%g\t%g\t%1.4f\n',...
            data.subnum, data.condition, data.date, data.time, itrial, triallist(itrial,1), triallist(itrial,2), ...
            triallist(itrial,3),triallist(itrial,4), triallist(itrial,5), ...
            data.resp, data.confirmRT);
        
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


