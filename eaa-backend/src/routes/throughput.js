const express = require('express');
const router = express.Router();
const pool = require('../config/db');

router.get('/throughput', async (req, res) => {
  try {
    const query = `
      SELECT DISTINCT ON (indicateur) indicateur, valeur, date, source
      FROM throughput_vendor
      ORDER BY indicateur, date DESC
    `;

    const result = await pool.query(query);

    res.json(result.rows);
  } catch (error) {
    console.error('Erreur dans /throughput:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

router.get('/throughput/trend', async (req, res) => {
  try {
    const indicateur = req.query.indicateur;
    const source = req.query.source;
    const query = `
      SELECT date, valeur
      FROM throughput_vendor
      WHERE indicateur = $1 AND source = $2
      ORDER BY date ASC
    `;
    const result = await pool.query(query, [indicateur, source]);
    res.json(result.rows);
  } catch (error) {
    console.error('Erreur dans /throughput/trend:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;