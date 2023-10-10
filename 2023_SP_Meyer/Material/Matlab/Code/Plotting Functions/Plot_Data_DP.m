% This code was written with MATLAB R2022b. Errors may occur with other
% versions
% Written for the Semester Thesis of Severin Meyer (18-926-857) in FS23

%% Main Function
    % Plot_Data
function Plot_Data_DP(OptRes, s, params)
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

    % Time Domain
    figure ('Name','Time Domain')
    tiledlayout(3,1)
    % Plotting SoC in Time Domain
    nexttile
    plot(t_opt/3600,E_bat_opt/params.E_bat_max,'LineWidth',LW_Plot)
    grid on
    box on
    xlim([0 OptRes.states.t(end)/3600])
    ylim([0 1.1])
    boundary = yline(1,Line_Type_Red,'LineWidth',LW);
    yline(0.1,Line_Type_Red,'LineWidth',LW)
   if (ONS_indices(1) ~= 0)
        xl_ONS = xline(OptRes.states.t(ONS_indices(1)-1)/3600,Line_Type_ONS,'LineWidth',LW);
        xline(OptRes.states.t(ONS_indices-1)/3600,Line_Type_ONS,'LineWidth',LW);
    end
    if (CS_indices(1) ~= 0)
        xl_CS = xline(OptRes.states.t(CS_indices(1))/3600,Line_Type,'LineWidth',LW);
        xline(OptRes.states.t(CS_indices)/3600,Line_Type,'LineWidth',LW)
    end
    set(gca,'FontSize',Fond_Size_Axis)
    title('SoC in time domain','FontSize',Fond_Size)
    xlabel('Time [h]','FontSize',Fond_Size) 
    ylabel('SoC [%]','FontSize',Fond_Size) 
    pbaspect(aspec)
%     legend([xl_CS xl_ONS boundary],'CS','NS','Boundaries','FontSize',Fond_Size_Axis)
    
    % Plotting Velocity in Time Domain
    nexttile
    stairs((t_opt(2:end)-t_opt(2))/3600,V_opt(2:end),'LineWidth',LW_Plot)
    grid on
    box on
    xlim([0 OptRes.states.t(end)/3600])
    ylim([0 40])
    hold on
    boundary = stairs(OptRes.states.t/3600,params.Route.max_V,Line_Type_Red,'LineWidth',LW);
    hold on
    stairs(OptRes.states.t/3600,params.Route.min_V,Line_Type_Red,'LineWidth',LW)
   if (ONS_indices(1) ~= 0)
        xl_ONS = xline(OptRes.states.t(ONS_indices(1)-1)/3600,Line_Type_ONS,'LineWidth',LW);
        xline(OptRes.states.t(ONS_indices-1)/3600,Line_Type_ONS,'LineWidth',LW);
    end
    if (CS_indices(1) ~= 0)
        xl_CS = xline(OptRes.states.t(CS_indices(1))/3600,Line_Type,'LineWidth',LW);
        xline(OptRes.states.t(CS_indices)/3600,Line_Type,'LineWidth',LW)
    end
    set(gca,'FontSize',Fond_Size_Axis)
    title('Velocity in time domain','FontSize',Fond_Size)
    xlabel('Time [h]','FontSize',Fond_Size) 
    ylabel('Velocity [m/s]','FontSize',Fond_Size) 
    pbaspect(aspec)
%     legend([xl_CS xl_ONS boundary],'CS','ONS','Boundaries')


    % Plotting Input in Time Domain
    nexttile
    stairs(t_opt(1:length(s)-1)/3600,P_mot_el_opt/1000,'LineWidth',LW_Plot)
    grid on
    box on
    xlim([0 OptRes.states.t(end)/3600])
    ylim([-5.5 5.5])
    boundary = yline(5,Line_Type_Red,'LineWidth',LW);
    yline(-5,Line_Type_Red,'LineWidth',LW)
    yline(0,Line_Type,'LineWidth',LW)
   if (ONS_indices(1) ~= 0)
        xl_ONS = xline(OptRes.states.t(ONS_indices(1)-1)/3600,Line_Type_ONS,'LineWidth',LW);
        xline(OptRes.states.t(ONS_indices-1)/3600,Line_Type_ONS,'LineWidth',LW);
    end
    if (CS_indices(1) ~= 0)
        xl_CS = xline(OptRes.states.t(CS_indices(1))/3600,Line_Type,'LineWidth',LW);
        xline(OptRes.states.t(CS_indices)/3600,Line_Type,'LineWidth',LW)
    end
    set(gca,'FontSize',Fond_Size_Axis)
    title('Input in time domain','FontSize',Fond_Size)
    xlabel('Time [h]','FontSize',Fond_Size) 
    ylabel('Input [kW]','FontSize',Fond_Size) 
    pbaspect(aspec)
%     legend([xl_CS xl_ONS boundary],'CS','ONS','Boundaries')

    % Space Domain
    figure ('Name','SoC in Space Domain')
   
    % Plotting SoC in Space Domain
   
    plot(s/1000,E_bat_opt/params.E_bat_max,'LineWidth',LW_Plot)
    grid on
    box on
    xlim([0 params.S_final/1000])
    ylim([0 1.1])
    boundary = yline(1,Line_Type_Red,'LineWidth',LW);
    yline(0.1,Line_Type_Red,'LineWidth',LW)
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
    legend([xl_CS xl_ONS boundary],'CS','ONS','Boundaries','location','southwest')
%     matlab2tikz('FullRace_SpaceDomain_So.tex');

    % Plotting Velocity in Space Domain
    figure ('Name','Velocity in Space Domain')
    stairs((s(2:end)-params.S_step)/1000,V_opt(2:end),'LineWidth',LW_Plot)
    hold on
    stairs(s/1000,params.Route.max_V,Line_Type_Red,'LineWidth',LW)
    hold on
    stairs(s/1000,params.Route.min_V,Line_Type_Red,'LineWidth',LW)
    grid on
    box on
    ylim([0 40])
    if (ONS_indices(1) ~= 0)
        xl_ONS = xline(OptRes.time(ONS_indices(1)-1)/1000,Line_Type_ONS,'LineWidth',LW);
        xline(OptRes.time(ONS_indices-1)/1000,Line_Type_ONS,'LineWidth',LW);
    end
    if (CS_indices(1) ~= 0)
        xl_CS = xline(OptRes.time(CS_indices(1))/1000,Line_Type,'LineWidth',LW);
        xline(OptRes.time(CS_indices)/1000,Line_Type,'LineWidth',LW)
    end
    set(gca,'FontSize',Fond_Size_Axis)
    title('Velocity in space domain','FontSize',Fond_Size)
    xlabel('Distance [km]','FontSize',Fond_Size) 
    ylabel('Velocity [m/s]','FontSize',Fond_Size) 
    pbaspect(aspec)
%     matlab2tikz('FullRace_SpaceDomain_Velocity.tex');
%     legend([xl_CS xl_ONS boundary],'CS','ONS','Boundaries')

    % Plotting Input in Space Domain
    figure ('Name','Input in Space Domain')
    stairs(s(1:length(s)-1)/1000,P_mot_el_opt/1000,'LineWidth',LW_Plot)
    grid on
    box on
    ylim([-5.5 5.5])
    yline(5,Line_Type_Red,'LineWidth',LW)
    yline(-5,Line_Type_Red,'LineWidth',LW)
    yline(0,Line_Type,'LineWidth',LW)
    if (ONS_indices(1) ~= 0)
        xl_ONS = xline(OptRes.time(ONS_indices(1)-1)/1000,Line_Type_ONS,'LineWidth',LW);
        xline(OptRes.time(ONS_indices-1)/1000,Line_Type_ONS,'LineWidth',LW);
    end
    if (CS_indices(1) ~= 0)
        xl_CS = xline(OptRes.time(CS_indices(1))/1000,Line_Type,'LineWidth',LW);
        xline(OptRes.time(CS_indices)/1000,Line_Type,'LineWidth',LW)
    end
    set(gca,'FontSize',Fond_Size_Axis)
    title('Input in space domain','FontSize',Fond_Size)
    xlabel('Distance [km]','FontSize',Fond_Size) 
    ylabel('Input [kW]','FontSize',Fond_Size) 
    pbaspect(aspec)
%     legend([xl_CS xl_ONS boundary],'CS','ONS','Boundaries')
%     matlab2tikz('FullRace_SpaceDomain_Input.tex');

end