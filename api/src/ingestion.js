exports.ingest = async (req, res) => {
  const { namespaceId, sourceType, source } = req.body;

  res.json({
    success: true,
    ingestion: {
      namespaceId,
      sourceType,
      source,
      status: 'queued'
    }
  });
};
