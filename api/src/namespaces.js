const demoNamespaces = {
  'smith-family': {
    id: 'smith-family',
    type: 'household',
    assistants: ['nanny', 'trainer'],
    policies: {
      externalMemoryAccess: false,
      cloudInferenceAllowed: false
    }
  }
};

exports.getNamespace = async (req, res) => {
  const namespace = demoNamespaces[req.params.id];

  if (!namespace) {
    return res.status(404).json({ success: false, error: 'Namespace not found' });
  }

  res.json({ success: true, namespace });
};

exports.resolve = async (req, res) => {
  const { namespaceId, assistantType } = req.body;

  const namespace = demoNamespaces[namespaceId];

  if (!namespace) {
    return res.status(404).json({ success: false, error: 'Namespace not found' });
  }

  const allowed = namespace.assistants.includes(assistantType);

  res.json({
    success: true,
    namespaceId,
    assistantType,
    allowed,
    policies: namespace.policies
  });
};
