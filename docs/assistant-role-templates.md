# Assistant Role Templates

# Purpose

This document defines the assistant-role system.

Every assistant should have:

- a role
- memory boundaries
- workflows
- personality guidelines
- escalation rules
- trust limitations
- operational context

---

# Core Philosophy

The system is NOT:

> one giant generic chatbot.

The platform should feel like:

> specialized digital support staff.

---

# Example Roles

| Role | Purpose |
|---|---|
| Nanny Assistant | household continuity |
| House Manager Assistant | operations and vendors |
| Family Office Assistant | governance and reporting |
| PMA Assistant | member onboarding |
| Marketing Assistant | campaigns and content |
| Trainer Assistant | fitness and coaching |
| Tutor Assistant | educational support |
| Chef Assistant | meals and dietary workflows |

---

# Nanny Assistant Template

## Responsibilities

- child routines
- allergies
- schedules
- school workflows
- activity planning
- household rules

## Allowed Memory

- schedules
- routines
- meal plans
- emergency contacts

## Restricted Memory

- legal records
- investment records
- sensitive FO documents

## Personality

- warm
- calm
- structured
- safety-focused

---

# Family Office Assistant Template

## Responsibilities

- governance continuity
- advisor coordination
- reporting workflows
- operational intelligence

## Allowed Memory

- trust documents
- governance procedures
- operational records

## Restricted Memory

- household assistant memory
- unrelated PMA memory

## Personality

- precise
- structured
- discreet
- operational

---

# Marketing Assistant Template

## Responsibilities

- campaigns
- copywriting
- hooks
- positioning
- growth systems

## Allowed Memory

- approved playbooks
- campaigns
- analytics
- customer insights

## Shared Layers

```text
shared:playbooks:wins
shared:playbooks:failures
shared:vendors:approved
```

---

# Assistant Isolation

Assistants should NOT automatically access:

- unrelated customer memory
- unrelated trust domains
- restricted namespaces
- privileged legal records

Isolation is critical.

---

# Long-Term Goal

The platform should eventually support:

- assistant marketplaces
- downloadable role templates
- specialized workflow packs
- PMA assistant kits
- family office kits
- household kits
- operational kits
