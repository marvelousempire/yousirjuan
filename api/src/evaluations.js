exports.evaluate = async (req, res) => {
  const { benchmark, namespaceId, assistant } = req.body;

  res.json({
    success: true,
    evaluation: {
      benchmark,
      namespaceId,
      assistant,
      status: 'queued'
    }
  });
};
