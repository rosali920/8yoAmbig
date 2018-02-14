%%PsychToolBox Script to generate payouts for WTPTask_Slider.m
%%Rosa Li June 2013

clear all;
close all;
RandStream('mt19937ar', 'seed', sum(100*clock));

workdir = fileparts(which(mfilename));
datadir = [workdir filesep 'data_WTPTask_Slider'];
if ~exist(datadir, 'dir')
    mkdir(datadir);
end

subnum = input('\n\n Enter participant number\n');
resultTxt = fullfile(datadir, sprintf('%s-%03g.txt', 'WTPTask_Slider', subnum));
subdata = importdata(resultTxt);

trialNum = input('\n\n Enter trial #.\n');
barPrice = input('\n\n Enter price of bar.\n');

possibleOut = [50, 55, 45, 60, 40, 66, 33, 75, 25, 90, 10, 100, 0];
outRange = possibleOut;

for i = 1:length(trialNum)
    trial = subdata.data(trialNum(i),:);
    ambigVal = NaN;
    riskVal = NaN;
  
    maxPrice = trial(7);
    fprintf('For trial %g, you said you would pay up to %g coins for the bar.\n\n', trialNum(i), maxPrice);

    if barPrice <= maxPrice %if willing to buy the bar at that price
        fprintf('The bar cost %g coins. Please pay %g coins to buy this bar.\n\n', barPrice, barPrice);
        wait = input('Press any key to see the outcome of this bar.\n\n');
        
        if trial(3) == 1 %Ambig Trial
            selectType = 'Ambig';
            ambigVal = trial(4); %value for AmbigA
        else %Risk Trial
            selectType = 'Risk';
            riskVal = trial(5); %value for risk
            
        end
        
        if ambigVal == 100
            outRange = possibleOut;
        elseif ambigVal == 80
            outRange = possibleOut(1:7);
        elseif ambigVal == 50
            outRange = possibleOut(1:5);
        elseif ambigVal == 33
            outRange = possibleOut(1:3);
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
        if isnan(ambigVal) %risk trial
            fprintf('The computer has randomly determined your outcome to be: \n %s_%g_%s.mov\n\n', selectType, barOutcome, payoff);
        else %ambig trial
            fprintf('The computer has randomly determined your outcome to be: \n %s_%g_%g_%s.mov\n\n', selectType, ambigVal, barOutcome, payoff);
        end
    else %if unwilling to buy at this price
        fprintf('The bar cost %g coins. This is more than you said you would pay.\n\n', barPrice);
        fprintf('You will not buy this bar.\n\n');
    end
    
end
