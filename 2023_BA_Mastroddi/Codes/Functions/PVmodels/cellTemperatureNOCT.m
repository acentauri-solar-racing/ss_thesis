function tempCell = cellTemperatureNOCT(G,tempAmb,WS,eff)

Gnoct = 800;
Tnoct = 45;
talpha = 0.9;
Tambnoct = 20;

tempCell = tempAmb + 9.5./(5.7 + 3.8*WS) * G./Gnoct * (Tnoct - Tambnoct) * (1 - eff./talpha);

end % fct