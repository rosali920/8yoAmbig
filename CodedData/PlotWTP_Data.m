%% visualize WTP data

% save kidsWTPA, kidsWTPR, kidsWTP50, adultsWTPA, adultsWTPR, adultsWTP50


kidsRA = kidsWTPR - kidsWTPA;
meankidsRA = mean(kidsRA);
sekidsRA = std(kidsRA)/sqrt(length(kidsRA));

adultsRA = adultsWTPR - adultsWTPA;
meanadultsRA = mean(adultsRA);
seadultsRA = std(adultsRA)/sqrt(length(adultsRA));

adultTitle = ['Adults']% (N=' num2str(length(adultsRA)) ')'];
kidTitle = ['Children'] % (N=' num2str(length(kidsRA)) ')'];

hf = figure;
set(hf, 'color', 'white');
hold on
hb2 = bar(2, meanadultsRA, 'FaceColor', [.18, .56, 1]); %[0, 0.5, 0.75]
% hb1 = bar(1,0)
% hb2 = bar(2, 0)
hb1 = bar(1, meankidsRA, 'FaceColor', [.9, .5 0]); %[0, 0.75, 0.75]

% hb = bar([meanadultsRA, meankidsRA], 'FaceColor', [0 0.75 0.75]);
ha = gca;

set(ha, 'FontName', 'Arial', 'FontSize', 22);
ylim([-1 1]);
ylabel('Risky WTP - Ambiguous WTP');
set(ha, 'XTick', [1 2], 'XTickLabel', {kidTitle, adultTitle});
% hb2 = errorbar(meanadultsRA, seadultsRA);
hb2 = errorbar([meankidsRA,meanadultsRA], [sekidsRA, seadultsRA]);
set(hb2, 'color', 'k', 'LineStyle', 'none', 'LineWidth', 2)
