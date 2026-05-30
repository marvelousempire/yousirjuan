**Here's the cleanest and best version of the ASCII diagram based on our final 13-container setup:**


```
                                      You
                                       │
                                       ▼
                              ┌────────────────────┐
                              │   Open WebUI       │ ← MacBook Pro M5 Max (128GB)
                              └────────────────────┘
                                       │
                                       ▼
                              ┌────────────────────┐
                              │   LangGraph        │ ← MacBook Pro M5 Max (Orchestrator)
                              └────────────────────┘
                ┌──────────────┴──────────────┬──────────────┐
                ▼                             ▼              ▼
   ┌────────────────────┐         ┌────────────────────┐ ┌────────────────────┐
   │ Accounting Agent   │         │   Legal Agent      │ │   Family Agent     │ ← DGX Spark
   └────────────────────┘         └────────────────────┘ └────────────────────┘
           │          │                    │          │           │
           │          └─────────┬──────────┘          │           │
           │                    │                     │           │
           ▼                    ▼                     ▼           ▼
┌────────────────────┐ ┌────────────────────┐ ┌────────────────────┐
│ Financial Retrieval│ │  Legal Retrieval   │ │  Family Retrieval  │ ← DGX Spark
│       Node         │ │       Node         │ │       Node         │
└────────────────────┘ └────────────────────┘ └────────────────────┘
           │                    │                     │
           └─────────────┬──────┴──────────┬──────────┘
                         ▼                 ▼
                ┌────────────────────┐ ┌────────────────────┐
                │      Qdrant        │ │  Medical Retrieval │ ← UGREEN DXP4800 Plus NAS
                │   Vector Database  │ │       Node         │
                └────────────────────┘ └────────────────────┘
                         │
                         ▼
                ┌────────────────────┐
                │     Main LLM       │ ← DGX Spark
                │ (Qwen3-72B / etc.) │
                └────────────────────┘
                
   Other Machines:
   • 27-inch iMac                  → Monitoring / Secondary Interface
   • 21.5-inch Mac (64GB)          → Ingestion & Document Processing
   • MacBook M1 Silicon            → Light tasks / Testing
```

