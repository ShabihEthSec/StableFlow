# StableFlow 🚧

**Status:** Active Development (Hackathon Project)

StableFlow is an **intent-based, cross-chain stablecoin vault** built around **Uniswap v4 hooks**.

The project is developed in clearly defined phases, starting with the **core hook logic**, which is the most safety-critical and non-replaceable component of the system.

---

## ✅ Current Progress

### **Phase 3 — Uniswap v4 Hook with Heuristic Hardening (COMPLETED)**

The StableFlow Uniswap v4 hook has been fully implemented and tested with **rate-limited, heuristic-based imbalance detection** and **dynamic fee control**.

### Implemented & Verified

* Liquidity imbalance detection using **cumulative swap flow**
* Time-windowed flow aggregation (`FLOW_WINDOW`)
* Hard imbalance thresholds and caps
* Cooldown-enforced intent emission
* Dynamic fee escalation during imbalance periods
* Per-pool state isolation
* Strict Uniswap v4 hook safety:

  * no external calls
  * deterministic execution
  * synchronous logic only

The hook **observes pool behavior**, adjusts swap fees, and emits **on-chain rebalancing intents**.
It does **not** execute rebalancing, bridging, or accounting.

📍 **Core contract**

```
contracts/hooks/StableFlowHook.sol
```

📍 **Tests**

```
test/hooks/StableFlowHook.t.sol
```

The test suite validates:

* imbalance accumulation and decay
* cooldown enforcement
* intent emission correctness
* dynamic fee application
* safety under repeated swaps

---

## 🔜 Next Phase

### **Phase 4 — Oracle & TWAP Hardening (Planned)**

The next phase will strengthen manipulation resistance by incorporating price-based signals:

* TWAP-based normalization of imbalance signals
* Tick-aware price checks
* Tighter fee smoothing based on time-weighted price movement

This phase will **augment**, not replace, the existing flow-based logic.

---

## ⚠️ Work in Progress

This repository is under active development:

* Interfaces may evolve as later phases are integrated
* Off-chain executors, cross-chain routing, and accounting layers are **not yet wired**
* The current focus is correctness, safety, and architectural clarity

This is **not a production deployment**.
It is a hackathon project focused on building a **sound protocol primitive first**.

---

## 🧠 High-Level Architecture

StableFlow follows a strict separation of responsibilities:

* **On-chain intent generation**

  * Uniswap v4 hook observes swaps
  * Adjusts fees
  * Emits rebalancing intents

* **Off-chain execution** *(planned)*

  * Permissionless executors consume intents
  * Decide whether execution is profitable
  * Perform cross-chain actions

* **Cross-chain routing & accounting** *(planned)*

  * LI.FI for execution
  * Arc for unified accounting

This architecture ensures:

* hook safety
* composability
* permissionless execution
* minimal trust assumptions

---

## 📌 Note for Reviewers / Judges

If you are reviewing this repository:

1. Start with `StableFlowHook.sol`
2. Review imbalance detection, cooldown logic, and fee control
3. Examine Foundry tests validating safety and correctness

Later phases are **intentionally staged** to avoid unsafe complexity inside the hook.


