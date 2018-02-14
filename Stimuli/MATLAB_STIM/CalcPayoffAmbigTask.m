%%PsychToolBox Script to generate payouts for AmbiguityTask.m
%%Rosa Li June 2013

clear all;
close all;
RandStream('mt19937ar', 'seed', sum(100*clock));

workdir = fileparts(which(mfilename));
datadir = [workdir filesep 'data_AmbiguityTask'];
if ~exist(datadir, 'dir')
    mkdir(datadir);
end

subnum = input('\n\n Enter participant number\n');
resultTxt = fullfile(datadir, sprintf('%s-%03g.txt', 'AmbiguityTask', subnum));
subdata = importdata(resultTxt);

trialNum = input('\n\n Enter trial #. If multiple trials, enter as vector [X, Y, Z, etc]\n');
possibleOut = [50, 55, 45, 60, 40, 66, 33, 75, 25, 90, 10, 100, 0];
outRange = possibleOut;

for i = 1:length(trialNum)
    trial = subdata.data(trialNum(i),:);
    ambigVal = NaN;
    riskVal = NaN;
    ambigRange = NaN;
    
    if trial(9) == 1 %chose AmbigA
        selectType = 'Ambig';
        ambigVal = trial(5); %value for AmbigA
    else %chose Risk or AmbigB
        if trial(3) == 1 %risk v. ambig; chose ambig
            selectType = 'Risk';
            riskVal = trial(4); %value for risk
        elseif trial(3) == 2 %ambig v. ambig; chose ambigB
            selectType = 'Ambig';
            ambigVal = trial(6); %chose ambig B
        end
    end
    
    if ambigVal == 100
        outRange = possibleOut;
    elseif ambigVal == 80
        outRange = possibleOut(1:11);
    elseif ambigVal == 50
        outRange = possibleOut(1:9);
    elseif ambigVal == 33
        outRange = possibleOut(1:7);
    end
    barOutcome = randsample(outRange,1); %determines what final bar looks like for ambiguous values
    
    if isnan(ambigVal)
        barOutcome = riskVal; %possible outcome is just risk val
    end
    
    randOutcome = randi(100); %random number between 1 and 100
    
    if randOutcome <= barOutcome
        payoff = 'R';
    else
        payoff = 'B';
    end
    fprintf('\n');
    fprintf('For trial %g, you selected the %s option.\n', trialNum(i), selectType);
    if isnan(ambigVal) %risk trial
        fprintf('The computer has randomly determined your outcome to be: \n %s_%g_%s.mov\n\n', selectType, barOutcome, payoff);
    else %ambig trial
        fprintf('The computer has randomly determined your outcome to be: \n %s_%g_%g_%s.mov\n\n', selectType, ambigVal, barOutcome, payoff);
    end
end
