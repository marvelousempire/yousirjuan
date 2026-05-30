**Agent Design Document**

**Project Name:** Nephew – Private Enterprise Personal AI System  
**Document Type:** Agent Design  
**Version:** 1.0

### 1. Purpose of the Agent Layer
The agent layer exists to give Nephew specialized intelligence and behavior. Instead of one generic AI trying to handle everything, we have dedicated agents that deeply understand specific domains (finance, legal, family, lifestyle). This improves accuracy, reduces hallucinations, and allows for better long-term memory and task execution.

### 2. The Four Core Agents

| Agent Name          | Primary Domain          | Main Responsibilities                                      | Key Data Sources                  |
|---------------------|-------------------------|------------------------------------------------------------|-----------------------------------|
| Accounting Agent    | Finance & Money         | Budgeting, taxes, investments, bill tracking, financial planning | financial_collection             |
| Legal Agent         | Legal & Compliance      | Contract review, legal notices, compliance, attorney coordination | legal_collection                 |
| Family Agent        | Family & Household      | Medical, school, nanny/chef coordination, family scheduling, health records | family_collection                |
| Lifestyle Agent     | Daily Life & Personal   | Travel planning, shopping, home management, personal goals, reminders | general_collection + family      |

### 3. Agent Architecture Principles

Each agent must follow these rules:

- Every agent has **read access** to the SmartRetriever
- Every agent can request context from its primary collection(s)
- Every agent must respect metadata filters (never pull irrelevant domain data)
- Agents do **not** talk directly to each other unless routed through LangGraph
- All agents share the same strong system persona ("Nephew")
- Agents must return structured output when performing tasks (not just chat)

### 4. How Agents Use the SmartRetriever

When an agent receives a query, it follows this logic:

1. Determine the domain of the question
2. Call `get_relevant_context(query, domain=...)` from the SmartRetriever
3. Receive only relevant, metadata-filtered chunks
4. Pass the context + original query into the Main LLM
5. Return the final answer

This prevents the Accounting Agent from accidentally pulling family medical records, for example.

### 5. Inter-Agent Communication

Agents do **not** communicate directly with each other in v1.0.

Instead:
- LangGraph acts as the central router
- If a query requires multiple domains, LangGraph can call multiple agents in sequence or parallel
- Results are combined before being shown to the user

### 6. Tools Available to All Agents

Every agent should eventually have access to these tools (via LangGraph):

- SmartRetriever (already built)
- Web search (when needed for external information)
- Calendar / reminder tools (future)
- Email / notification tools (future)
- Document generation tools (future)

### 7. LangGraph Integration

LangGraph is responsible for:
- Routing the user’s message to the correct agent(s)
- Managing conversation state across multiple turns
- Deciding when retrieval is needed
- Combining results from multiple agents when necessary
- Maintaining the "Nephew" persona across all responses

---

**End of Agent Design Document**

---
