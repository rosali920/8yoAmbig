%% visualizing ambiguous vs ambiguity data
clear all
close all
load('FinalData')
adultTitle = {['Adults (N=' num2str(length(adultsChoseSm)) ')']};
kidTitle = {['Children (N=' num2str(length(kidsChoseSm)) ')']};

adultslabel = repmat(adultTitle, length(adultsChoseSm),1);
kidslabel = repmat(kidTitle, length(kidsChoseSm), 1);
hf = figure;
hb = boxplot([kidsG; adultsChoseSm], [kidslabel; adultslabel]);
ha = gca;

set(ha, 'FontName', 'Arial', 'FontSize', 22, 'LineWidth', 2);
ylim([0 1]);
ylabel('Proportion chose less ambiguous bar', 'FontSize', 22);

text_h = findobj(gca, 'Type', 'text');
for i = 1:2
    set(text_h(i), 'FontSize', 22, 'FontName', 'Arial', 'VerticalAlignment', 'top');
end

set(hf, 'color', 'white');
set(hb, 'linew', 2);
hold on
plot([xlim], [0.5, 0.5], '--k', 'LineWidth', 2)

meanKids = mean(kidsChoseSm);
seKids = std(kidsChoseSm)/sqrt(length(kidsChoseSm));
meanAdults = mean(adultsChoseSm);
seAdults = std(adultsChoseSm)/sqrt(length(adultsChoseSm));
adultTitle = ['Adults' ];%(N=' num2str(length(adultsChoseSm)) ')'];
kidTitle = ['Children' ];%(N=' num2str(length(kidsChoseSm)) ')'];


hf = figure;
set(hf, 'color', 'white');
hold on
% hb = bar(1, 0);
hb1 = bar(1, meanKids, 'FaceColor', [.9, .5 0]); % [0 .75 .75]);

hb2 = bar(2, meanAdults, 'FaceColor', [.18, .56, 1]); % [0 .5 .75]);
% hb2 = bar(2, 0);
ha = gca;

set(ha, 'FontName', 'Arial', 'FontSize', 22);
ylim([0 1]);
ylabel('Proportion chose less ambiguous bar');
set(ha, 'XTick', [1 2], 'XTickLabel', {kidTitle, adultTitle});
% hb2 = errorbar(meanAdults, seAdults);
hb2 = errorbar([meanKids, meanAdults], [seKids, seAdults ]);
set(hb2, 'color', 'k', 'LineStyle', 'none', 'LineWidth', 2)
plot([xlim], [0.5, 0.5], '--k', 'LineWidth', 2)

