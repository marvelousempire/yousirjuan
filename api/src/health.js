exports.status = async (req, res) => {
  res.json({
    success: true,
    service: 'yousirjuan-full-runtime',
    status: 'healthy',
    timestamp: new Date().toISOString()
  });
};
