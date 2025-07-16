const express = require('express');
const router = express.Router();
const pool = require('../config/db');

router.get('/trafic_cable', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM trafic_cable_bpi_bh LIMIT 10');
    res.json(result.rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;