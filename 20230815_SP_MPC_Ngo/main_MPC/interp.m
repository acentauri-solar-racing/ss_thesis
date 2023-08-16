step = linspace(0,1000000,1000000/50)
DP_step = linspace(0,1000000, 1000000/10000)
E_bat = interp1(DP_step, OptRes.states.E_bat(1:end-1),step)

plot(DP_step,OptRes.states.E_bat(1:end-1),'o',step,E_bat,':.')

save('SoC_target_DP',"E_bat");