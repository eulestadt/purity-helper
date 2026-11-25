/**
 * Mail stays on this service. SendGrid is not used.
 * Set SMTP_HOST (and usually SMTP_PORT, SMTP_USER, SMTP_PASS, MAIL_FROM)
 * on Railway so the service submits the message itself.
 * With SMTP unset, the code is written to the process log so a mailbox
 * vendor is not required to recover an account.
 */

const sent = [];

function remember(entry) {
  sent.push(entry);
  if (sent.length > 50) sent.shift();
}

function lastCodeFor(email) {
  for (let i = sent.length - 1; i >= 0; i -= 1) {
    if (sent[i].to === email) return sent[i].code;
  }
  return null;
}

async function sendResetCode({ to, code }) {
  const from = process.env.MAIL_FROM || 'Purity Help <account@localhost>';
  const subject = 'Your Purity Help reset code';
  const text = `Your Purity Help password reset code is ${code}. It expires in 10 minutes. If you did not ask for this, ignore this email.`;
  const html = `
    <div style="font-family:Georgia,serif;max-width:480px;margin:auto;padding:32px 24px;color:#1c2b24">
      <p style="letter-spacing:0.14em;text-transform:uppercase;font-size:12px;color:#1f6b4a">Purity Help</p>
      <h1 style="font-weight:500;font-size:28px;margin:8px 0 12px">Begin again with a new password</h1>
      <p style="line-height:1.5">Enter this code in the app or on the account page. It expires in 10 minutes.</p>
      <p style="font-size:36px;letter-spacing:8px;font-weight:600;margin:24px 0">${code}</p>
    </div>`;

  const host = process.env.SMTP_HOST;
  const mode = process.env.MAIL_MODE || (host ? 'smtp' : 'log');
  if (mode !== 'smtp' || !host) {
    console.log(`[purity-help mail] reset code for ${to}: ${code}`);
    remember({ to, code, delivered: false });
    return { delivered: false, logged: true };
  }

  const nodemailer = require('nodemailer');
  const port = Number(process.env.SMTP_PORT || 587);
  const transport = nodemailer.createTransport({
    host,
    port,
    secure: process.env.SMTP_SECURE === 'true' || port === 465,
    auth: process.env.SMTP_USER
      ? { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS || '' }
      : undefined,
  });
  await transport.sendMail({ from, to, subject, text, html });
  remember({ to, code, delivered: true });
  return { delivered: true, logged: false };
}

module.exports = { sendResetCode, lastCodeFor };
