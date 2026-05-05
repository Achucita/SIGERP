// src/routes/expediente.routes.js
const router = require('express').Router();
const ctrl   = require('../controllers/expediente.controller');
const auth   = require('../middlewares/auth');
const roles  = require('../middlewares/roles');

// Solo admin puede ver expedientes
router.get('/',    auth, roles('admin'), ctrl.listar);
router.get('/:id', auth, roles('admin'), ctrl.detalle);

module.exports = router;