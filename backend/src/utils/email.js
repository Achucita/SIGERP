// src/utils/email.js
const nodemailer = require('nodemailer');
const env        = require('../config/env');
const path       = require('path');
const fs         = require('fs');

const transporter = nodemailer.createTransport({
  host:   env.smtp.host,
  port:   env.smtp.port,
  secure: env.smtp.port === 465,
  auth: {
    user: env.smtp.user,
    pass: env.smtp.pass,
  },
});

/**
 * Envía el correo al responsable del proyecto cuando un alumno se postula.
 * Si el alumno subió su CV, se adjunta al correo.
 *
 * @param {object} datos
 * @param {string}  datos.empresa
 * @param {string}  datos.proyecto
 * @param {string}  datos.correoEmpresa   - destinatario
 * @param {object}  datos.alumno          - { nombre, correo, matricula, carrera }
 * @param {string|null} datos.cvRuta      - ruta relativa en disco, p.ej. "uploads/cvs/archivo.pdf"
 */
async function enviarCorreoPostulacion({ empresa, proyecto, alumno, correoEmpresa, cvRuta = null }) {
  const fecha = new Date().toLocaleDateString('es-MX', {
    day: '2-digit', month: 'long', year: 'numeric',
  });

  const cvFila = cvRuta
    ? `<tr style="background:#f0f5fa;">
         <td style="padding:10px 14px; font-weight:bold; color:#1B6CA8;">CV adjunto</td>
         <td style="padding:10px 14px;">✅ Sí — ver archivo adjunto</td>
       </tr>`
    : `<tr style="background:#f0f5fa;">
         <td style="padding:10px 14px; font-weight:bold; color:#1B6CA8;">CV adjunto</td>
         <td style="padding:10px 14px; color:#9aa0a6;">No proporcionado</td>
       </tr>`;

  const html = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <div style="background: #0D1B2A; padding: 20px; text-align: center;">
        <span style="background: #00D4AA; color: #0D1B2A; font-weight: bold;
          padding: 4px 12px; border-radius: 4px; font-size: 14px;">SIGERP</span>
        <p style="color: rgba(255,255,255,.7); margin: 8px 0 0; font-size: 12px;">
          Instituto Tecnológico de León — Residencias Profesionales
        </p>
      </div>

      <div style="padding: 28px 24px; background: #fff; border: 1px solid #e0e0e0;">
        <h2 style="color: #0D1B2A; font-size: 18px; margin-bottom: 8px;">
          Nueva postulación: ${proyecto}
        </h2>
        <p style="color: #5f6368; font-size: 14px; margin-bottom: 20px;">
          Estimado equipo de <strong>${empresa}</strong>, un alumno del Instituto
          Tecnológico de León se ha postulado a su proyecto de residencia profesional.
        </p>

        <table style="width:100%; border-collapse:collapse; font-size:13px;">
          <tr style="background:#f0f5fa;">
            <td style="padding:10px 14px; font-weight:bold; width:40%; color:#1B6CA8;">Proyecto</td>
            <td style="padding:10px 14px;">${proyecto}</td>
          </tr>
          <tr>
            <td style="padding:10px 14px; font-weight:bold; color:#1B6CA8;">Alumno</td>
            <td style="padding:10px 14px;">${alumno.nombre}</td>
          </tr>
          <tr style="background:#f0f5fa;">
            <td style="padding:10px 14px; font-weight:bold; color:#1B6CA8;">Matrícula</td>
            <td style="padding:10px 14px;">${alumno.matricula}</td>
          </tr>
          <tr>
            <td style="padding:10px 14px; font-weight:bold; color:#1B6CA8;">Carrera</td>
            <td style="padding:10px 14px;">${alumno.carrera}</td>
          </tr>
          <tr style="background:#f0f5fa;">
            <td style="padding:10px 14px; font-weight:bold; color:#1B6CA8;">Correo del alumno</td>
            <td style="padding:10px 14px;">
              <a href="mailto:${alumno.correo}">${alumno.correo}</a>
            </td>
          </tr>
          <tr>
            <td style="padding:10px 14px; font-weight:bold; color:#1B6CA8;">Fecha de postulación</td>
            <td style="padding:10px 14px;">${fecha}</td>
          </tr>
          ${cvFila}
        </table>

        <p style="font-size:13px; color:#5f6368; margin-top:20px; line-height:1.6;">
          Para aceptar o rechazar al alumno, responda este correo o escríbale directamente.
          El administrador del ITL actualizará el estado de la postulación en el sistema.
        </p>
      </div>

      <div style="background:#f5f5f5; padding:14px; text-align:center;
        font-size:11px; color:#9aa0a6; border-top:1px solid #e0e0e0;">
        Correo automático generado por SIGERP · No requiere cuenta para responder ·
        <a href="mailto:residencias@itl.edu.mx" style="color:#1B6CA8;">residencias@itl.edu.mx</a>
      </div>
    </div>
  `;

  // Construir adjuntos si existe CV
  const attachments = [];
  if (cvRuta) {
    const rutaAbsoluta = path.join(__dirname, '..', '..', cvRuta);
    if (fs.existsSync(rutaAbsoluta)) {
      attachments.push({
        filename: `CV_${alumno.nombre.replace(/\s+/g, '_')}_${alumno.matricula}${path.extname(cvRuta)}`,
        path:     rutaAbsoluta,
      });
    }
  }

  await transporter.sendMail({
    from:        `"SIGERP — ITL" <${env.smtp.from}>`,
    to:          correoEmpresa,
    subject:     `Nueva postulación al proyecto: ${proyecto}`,
    html,
    attachments,
  });
}

/**
 * Correo genérico de notificación interna (para futuras expansiones).
 */
async function enviarCorreoGenerico({ to, subject, html }) {
  await transporter.sendMail({
    from: `"SIGERP — ITL" <${env.smtp.from}>`,
    to,
    subject,
    html,
  });
}

module.exports = { enviarCorreoPostulacion, enviarCorreoGenerico };