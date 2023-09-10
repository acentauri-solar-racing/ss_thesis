function tempCell = cellTemperatureSOWANOCT(G,tempAmb)

Gnoct = 800;
Tnoct = 45;
talpha = 0.9;
Tambnoct = 20;
hNOCT = 20;
h = 40;

tempCell = tempAmb + (Tnoct - Tambnoct) * G/Gnoct * hNOCT/h;

end % fct