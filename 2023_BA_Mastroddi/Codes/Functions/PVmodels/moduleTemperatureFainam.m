function tempModule = moduleTemperatureFainam(G,tempAmb,WS)

U0 = 25;
U1 = 6.84;

tempModule = G./(U0 + U1*WS) + tempAmb;

end % fct