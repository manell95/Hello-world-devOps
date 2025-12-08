const express = require("express");
const path = require("path");
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware pour servir les fichiers statiques
app.use(express.static(path.join(__dirname, "public")));

// Route principale
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "index.html"));
});

// Route API pour info système
app.get("/api/info", (req, res) => {
  res.json({
    message: "Hello World API",
    timestamp: new Date().toISOString(),
    hostname: require("os").hostname(),
    platform: process.platform,
    version: process.version,
  });
});

// Route de santé pour monitoring
app.get("/health", (req, res) => {
  res.status(200).json({ status: "OK", uptime: process.uptime() });
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`✅ Serveur démarré sur http://0.0.0.0:${PORT}`);
  console.log(`📅 Date: ${new Date().toISOString()}`);
});
