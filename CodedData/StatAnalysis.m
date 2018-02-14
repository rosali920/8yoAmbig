%analysis of all data

load('FinalData');
%kidsG is 35 kids' % chose risk on non-catch risk v ambig trials
%kidsChoseSm is 35 kids' % chose less ambiguous on ambig v ambig trials
%kidsWTPA is 34 kids' WTP ambiguous bars
%kidsWTPR is 34 kids' WTP risk bars

%adultsG is 39 adults' for % chose risk on non-catch risk v ambig trials
%adultsChoseSm is 39 adults' % chose less ambiguous on ambig v ambig trials'
%adultsWTPA is 39 adults' WTP ambiguous bars
%adultsWTPR is 39 adults' WTP risk bars


[h p ci stats] = ttest2(kidsG, adultsG);
[h p ci stats] = ttest2(kidsChoseSm, adultsChoseSm);


kidsWTPdiff = kidsWTPR - kidsWTPA;
adultsWTPdiff = adultsWTPR - adultsWTPA;

[h p ci stats ] = ttest(kidsWTPA, kidsWTPR);
[h p ci stats ] = ttest(adultsWTPA, adultsWTPR);
[h p ci stats ] = ttest2(adultsWTPdiff, kidsWTPdiff);