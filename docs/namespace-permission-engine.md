# Namespace Permission Engine

# Purpose

This document defines how memory access is controlled across the platform.

The namespace engine is one of the most important parts of the architecture.

It protects:

- customer isolation
- family-office separation
- PMA separation
- assistant boundaries
- workflow security

---

# Core Principle

Assistants should only access:

> the minimum memory required to perform their role.

---

# Namespace Structure

Examples:

```text
client:smith-family:nanny
client:smith-family:coach
fo:legal:trusts
pma:members:active
shared:playbooks:wins
```

---

# Permission Layers

| Layer | Purpose |
|---|---|
| Tenant Permissions | customer isolation |
| Assistant Permissions | role isolation |
| Namespace Permissions | memory boundaries |
| Cloud Policy Permissions | API routing control |
| Workflow Permissions | execution limits |

---

# Example Rules

## Nanny Assistant

Allowed:

```text
client:smith-family:nanny
client:smith-family:household
```

Blocked:

```text
fo:*
shared:*
other-client:*
```

---

## Family Office Assistant

Allowed:

```text
fo:legal:*
fo:tax:*
fo:governance:*
```

Blocked:

```text
shared:*
pma:*
other-client:*
```

---

# Enforcement Points

Permissions should be enforced at:

- retrieval layer
- vector queries
- orchestration layer
- agent workflows
- UI layer
- API layer

---

# Long-Term Goal

The namespace engine eventually becomes:

> the trust-boundary enforcement core of the platform.
