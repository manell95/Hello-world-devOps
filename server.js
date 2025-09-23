const express = require("express");
const app = express();
const port = 3000;

app.get("/api/health", (req, res) => {
  res.json({
    status: "OK",
    message: "Hello World DevOps App is running!",
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || "development",
  });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Server is running on port ${port}`);
});
