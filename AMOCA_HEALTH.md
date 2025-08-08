# AMOCA: Decentralized Rare Disease Research Framework

A Tripartite Model for Patients, Researchers, and Pharmaceutical Sponsors on Hedera

This document outlines a decentralized framework for accelerating rare disease research. It connects patients, academic researchers, and pharmaceutical sponsors (pharma/biotech) through a sophisticated AI agent, AMOCA (Autonomous Medical Orchestration & Curation Agent). The entire system is built on the Hedera Hashgraph public ledger to ensure transparency, security, and real-time, auditable incentives.

---

## Table of Contents

- Core Participants & Expanded Roles
- The Agent-Orchestrated Workflow
  - Phase 1: Sponsorship & Proposal
  - Phase 2: Cohort Formation & Research
  - Phase 3: Compensation & Reputation
- Smart Contract Architecture Overview
- Expanded Benefits for Each Stakeholder

---

## 1. Core Participants & Expanded Roles

- **Patients — Data Sovereigns & Research Partners**
  - Securely store health data in a private vault.
  - Use AMOCA to understand research calls, provide granular, time-locked consent via Hedera DID, and receive direct micropayments in $MDAI tokens for participation and structured data contributions.

- **Researchers — Insight Generators**
  - Submit research proposals or analytical models to AMOCA in response to pharma-sponsored calls.
  - Gain access to curated, pre-consented datasets without typical administrative overhead and are compensated for analytical work and discoveries.

- **Pharma/Biotech — Research Sponsors & Beneficiaries**
  - Act as primary funders. Submit Research Sponsorship Calls defining therapeutic area, data requirements, and budget.
  - Receive high-fidelity, real-world insights and identify patient cohorts for future clinical trials in a compliant manner.

- **AMOCA (AI Agent) — The Decentralized Orchestrator**
  - Validates and publishes sponsorship calls, discovers eligible patient cohorts anonymously, manages smart consent, curates data, automates payouts, and maintains a trust score for all participants.

- **Hedera Network — The Trust Layer**
  - Provides the immutable, auditable infrastructure for all critical events. It is not a database but a verifiable log of transactions and interactions.

---

## 2. The Agent-Orchestrated Workflow

This workflow details the end-to-end process, from funding to insight generation.

### Phase 1: Sponsorship & Proposal

- **Pharma Initiates Sponsorship**
  - A pharma company (e.g., "NovoGene") uses the dApp to create a Research Sponsorship Call.
  - Defines research goals, cohort criteria (e.g., "SMA Type 2, ages 5–12, non-ambulatory"), required data types (genomic, MRI, symptom logs), and locks the total research budget (e.g., 500,000 $MDAI) into the `ResearchSponsor` smart contract.
  - Hedera Interaction: The transaction to lock funds is recorded on the Hedera Token Service (HTS).

- **AMOCA Validates & Broadcasts**
  - Ethical Screen: Checks for red flags in the proposal's language or scope.
  - Feasibility Check: Anonymously queries the network of patient DIDs to confirm a viable number of potential participants exists without revealing identities.
  - Budget Validation: Ensures the locked funds are sufficient for the proposed scope.
  - Upon success, AMOCA publishes the call to the network and notifies relevant researchers and patient advocacy groups.
  - Hedera Interaction: The validated proposal's hash and its status (PUBLISHED) are logged via the Hedera Consensus Service (HCS).

### Phase 2: Cohort Formation & Research

- **Patient Opt-In & Smart Consent**
  - Patients meeting criteria are notified. AMOCA presents a simplified, interactive summary of the study.
  - If a patient agrees, they use their Hedera DID to sign a Verifiable Credential (VC) representing consent. This VC is specific, time-bound, and revocable.
  - Hedera Interaction: The hash of the signed consent VC is logged to HCS, creating an immutable link between the patient's DID and the specific research call.

- **Researcher Application & Selection**
  - Researchers submit analysis plans or pre-trained models to AMOCA.
  - Sponsors can review anonymized researcher profiles (based on reputation scores) and select a fit, or allow AMOCA to auto-select based on predefined criteria.

- **Federated Data Access & Analysis**
  - Raw data never leaves the patient's vault; models are sent to the data.
  - AMOCA's data curation module cleans, pseudonymizes, and structures consented data into a standardized format (e.g., FHIR).
  - Analyses run in a secure enclave, and only aggregated, non-identifiable results are returned.
  - Hedera Interaction: Every access event is logged to HCS by AMOCA, referencing the researcher's DID and the patient's consent hash.

### Phase 3: Compensation & Reputation

- **Milestone-Based Payouts**
  - The `ResearchSponsor` contract is programmed with milestones (e.g., "Cohort Formed," "Initial Analysis Complete," "Final Report Submitted").
  - When AMOCA verifies a milestone via HCS logs, it triggers the contract to automatically release portions of the $MDAI funds.
  - Hedera Interaction (HTS):
    - Researchers receive grant payments.
    - Patients receive data-sharing rewards directly to their wallets.
    - A small percentage (e.g., 1–2%) is sent to a treasury DAO to fund AMOCA operations and development.

- **Reputation Scoring**
  - Upon completion, all parties can rate the interaction.
  - AMOCA updates on-chain reputation scores (`AgentTrustScore` contract) for sponsors, researchers, and the quality of patient-provided data. High scores lead to preferential matching and lower platform fees.

---

## 3. Smart Contract Architecture Overview

| Smart Contract         | Purpose                                              | Key Functions                                                                                      |
|------------------------|------------------------------------------------------|-----------------------------------------------------------------------------------------------------|
| `ResearchSponsor.sol`  | Manages the funding lifecycle of a research call.    | `createSponsorship(criteria, budget, milestones)`, `lockFunds()`, `releaseMilestonePayment(researcherDID, patientDIDs)`, `cancelSponsorship()` |
| `ConsentManager.sol`   | On-chain registry for consent hashes.                | `logConsent(patientDID, sponsorDID, dataHash)`, `revokeConsent(consentLogID)`, `verifyConsent(patientDID, dataHash)`                        |
| `DataIncentive.sol`    | Handles the distribution logic for rewards.          | `calculatePatientReward(dataType, volume)`, `distribute(recipientAddress, amount, memo)`                                                  |
| `AgentTrustScore.sol`  | Non-transferable token or scoring system for reputation. | `updateScore(targetDID, rating, contextHash)`, `getScore(targetDID)`                                                                      |

---

## 4. Expanded Benefits for Each Stakeholder

| Stakeholder   | Key Benefits from this Model |
|---------------|-------------------------------|
| Patients      | Agency and fair compensation; move from passive subjects to active, compensated partners in research. Full transparency into who is funding the research and why. |
| Researchers   | Accelerated science; drastically reduced time spent on grant applications, data sourcing, and compliance checks. Access to high-quality, longitudinal data. |
| Pharma/Biotech| De-risked R&D; validate existence of viable patient cohorts before large investments. Faster, more affordable access to real-world evidence for drug development and clinical trial design. |
| Regulators    | Automated auditing; lifecycle of consent, data access, and funding immutably logged on Hedera, providing a single source of truth for audits. |
