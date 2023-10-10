%% Initialization:
clc
clear
clearvars
close all

%% Include Path of idscDPfunction
addpath(genpath('.\..\'));

%%
load('Full_Race_Improved_Weather_20230625_safe.mat');

    s = params.S_vec;

    % Plotting
    E_bat_opt = OptRes.states.E_bat;
    V_opt = OptRes.states.V;
    t_opt = OptRes.states.t;
    P_mot_el_opt = OptRes.inputs.P_mot_el;

    LW = 1;
    LW_Plot = 0.5;
    Line_Type = '--';
    Line_Type_Red = ':r';
    Line_Type_ONS = '';
    Fond_Size = 5;
    Fond_Size_Axis = 5;
    aspec = [6 1 1];

    CS_indices(1) = 0;
    ONS_indices(1) = 0;
    % CS and ONS time and space vectors
    for i = 1:sum(params.CS_location<=params.S_final,'all')
        [~,CS_indices(i)] = min(abs(OptRes.time-(params.CS_location(i))));
    end

    for i = 1:sum(params.ONS_times<=OptRes.states.t(end),'all')
        [~,ONS_indices(i)] = min(abs(OptRes.states.t-params.ONS_times(i)));
    end

    % Plotting SoC in Space Domain
   
    plot1 = plot(s/1000,E_bat_opt/params.E_bat_max,'LineWidth',LW_Plot);
    hold on
    grid on
    box on
    xlim([0 params.S_final/1000])
    ylim([0 1.1])
    boundary = yline(1,Line_Type_Red,'LineWidth',LW);
    yline(0.1,Line_Type_Red,'LineWidth',LW)
    load('Full_Race_20230607_9h_30min_safety.mat');
    s = params.S_vec;
    E_bat_opt = OptRes.states.E_bat;
    V_opt = OptRes.states.V;
    t_opt = OptRes.states.t;
    P_mot_el_opt = OptRes.inputs.P_mot_el;
    plot2 = plot(s/1000,E_bat_opt/params.E_bat_max,'LineWidth',LW_Plot);
    load('Full_Race_Improved_Weather_20230625_safe.mat');
    s = params.S_vec;
    E_bat_opt = OptRes.states.E_bat;
    V_opt = OptRes.states.V;
    t_opt = OptRes.states.t;
    P_mot_el_opt = OptRes.inputs.P_mot_el;
    if (ONS_indices(1) ~= 0)
        xl_ONS = xline(OptRes.time(ONS_indices(1)-1)/1000,Line_Type_ONS,'LineWidth',LW);
        xline(OptRes.time(ONS_indices-1)/1000,Line_Type_ONS,'LineWidth',LW);
    end
    if (CS_indices(1) ~= 0)
        xl_CS = xline(OptRes.time(CS_indices(1))/1000,Line_Type,'LineWidth',LW);
        xline(OptRes.time(CS_indices)/1000,Line_Type,'LineWidth',LW)
    end
    set(gca,'FontSize',Fond_Size_Axis)
    title('SoC in space domain','FontSize',Fond_Size)
    xlabel('Distance [km]','FontSize',Fond_Size) 
    ylabel('SoC [%]','FontSize',Fond_Size) 
    pbaspect(aspec)
%     legend([xl_CS xl_ONS boundary],'CS','NS','Boundaries','FontSize',Fond_Size_Axis)
    legend([xl_CS xl_ONS boundary plot1 plot2],'CS','ONS of Improved Weather Case','Boundaries','Improved Weather','Normal Weather','location','southwest')
%     matlab2tikz('Day_Race_Comp_Weather_SoC.tex');