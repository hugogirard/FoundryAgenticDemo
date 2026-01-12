# Skyrim Knowledge Assistant - Multi-Agent Workflow

## Agent Summary

### Agent 1: The Courier (Request Handler)
**Role:** Entry point and request parser

**What it does:**
- Receives the user's question
- Extracts key information (topic, entities, intent)
- Identifies search keywords
- Structures the request into JSON format
- Passes structured data to the Court Wizard

**Input:** Raw user question  
**Output:** Structured JSON with topic, entities, intent, search keywords, and notes  
**Tool:** None (pure text processing)

---

### Agent 2: The Court Wizard (Knowledge Retrieval)
**Role:** Research and information gathering

**What it does:**
- Receives structured request from the Courier
- Uses file_search tool to query the knowledge base
- Retrieves relevant document excerpts
- Extracts key facts from multiple sources
- Organizes findings with source citations
- Passes research findings to the Jarl

**Input:** Structured JSON from Courier  
**Output:** Organized research with key findings, sources, and recommendations  
**Tool:** file_search (Azure AI's built-in vector search)

---

### Agent 3: The Jarl (Response Synthesizer)
**Role:** Final answer generation

**What it does:**
- Receives original question + Court Wizard's research
- Synthesizes information into coherent narrative
- Formats response for end user
- Adds context and helpful connections
- Delivers natural, conversational answer
- Returns final response to user

**Input:** Courier's parsed request + Wizard's research  
**Output:** Natural language response to user  
**Tool:** None (pure synthesis and generation)

---

## Workflow Diagram

```mermaid
graph TD
    A[User Question] --> B[Agent 1: The Courier]
    B -->|Structured JSON| C[Agent 2: The Court Wizard]
    C -->|file_search tool| D[(Knowledge Base<br/>Text Files)]
    D -->|Retrieved Documents| C
    C -->|Research Report| E[Agent 3: The Jarl]
    E -->|Final Answer| F[User Response]
    
    style B fill:#4A90E2,stroke:#2E5C8A,color:#fff
    style C fill:#7B68EE,stroke:#5A4CB8,color:#fff
    style E fill:#50C878,stroke:#3A9B5C,color:#fff
    style D fill:#FFD700,stroke:#CCA500,color:#000