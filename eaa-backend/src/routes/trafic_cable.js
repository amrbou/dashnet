const express = require('express');
const router = express.Router();
const pool = require('../config/db');

router.get('/trafic_cable', async (req, res) => {
  try {
    const query = `
      SELECT DISTINCT ON (indicateur) *
      FROM trafic_cable_bpi_bh
      ORDER BY indicateur, date DESC
    `;
    const result = await pool.query(query);
    res.json(result.rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;