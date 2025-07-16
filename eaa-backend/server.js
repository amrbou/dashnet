const express = require('express');
const app = express();
const port = 3000;

const networkRoutes = require('./src/routes/network');
const throughputRoutes = require('./src/routes/throughput');
const traficCableRoutes = require('./src/routes/trafic_cable');
const bpiTrafficRoutes = require('./src/routes/bpi_traffic');

app.use('/api', networkRoutes);
app.use('/api', throughputRoutes);
app.use('/api', traficCableRoutes);
app.use('/api', bpiTrafficRoutes);

app.get('/', (req, res) => {
  res.send('Bienvenue sur le backend EAA !');
});

app.listen(port, () => {
  console.log(`Serveur backend démarré sur http://localhost:${port}`);
});