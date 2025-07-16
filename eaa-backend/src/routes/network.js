const express = require('express');
const router = express.Router();
const pool = require('../config/db');

router.get('/network', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM network_synthese');
    res.json(result.rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;