
# StableFlow 🚧

**Status:** Active Development (Hackathon Project)

<<<<<<< HEAD
StableFlow is an **intent-based, cross-chain stablecoin vault** built around **Uniswap v4 hooks**.

The project is developed in clearly defined phases, starting with the **core hook logic**, which is the most safety-critical and non-replaceable component of the system.
=======
StableFlow is an intent-based, cross-chain stablecoin vault built around **Uniswap v4 hooks**.
The project is developed in clearly defined phases, with the hook logic implemented first, followed by a minimal vault and an event-driven architecture.

The core idea is simple and deliberate:

> Hooks generate intent. Execution happens elsewhere.
>>>>>>> 852f50f (docs: update README with current project progress)

---

## Current Progress

<<<<<<< HEAD
### **Phase 3 — Uniswap v4 Hook with Heuristic Hardening (COMPLETED)**

The StableFlow Uniswap v4 hook has been fully implemented and tested with **rate-limited, heuristic-based imbalance detection** and **dynamic fee control**.

### Implemented & Verified

* Liquidity imbalance detection using **cumulative swap flow**
* Time-windowed flow aggregation (`FLOW_WINDOW`)
* Hard imbalance thresholds and caps
* Cooldown-enforced intent emission
* Dynamic fee escalation during imbalance periods
* Per-pool state isolation
=======
### Phase 1 to Phase 3: Uniswap v4 Hook (COMPLETED)

The core Uniswap v4 hook is fully implemented and tested.

### Implemented functionality

* Dynamic fee adjustment based on observed swap flow
* Imbalance detection using `BalanceDelta` (flow-based heuristic)
* Time-windowed aggregation of swap pressure
* Threshold-gated rebalancing intent emission
* Cooldown-enforced intent rate limiting
* Explicit caps on imbalance magnitude
>>>>>>> 852f50f (docs: update README with current project progress)
* Strict Uniswap v4 hook safety:

  * no external calls
  * deterministic execution
<<<<<<< HEAD
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
=======
  * bounded storage per pool

Core file:

```
contracts/hooks/StableFlowHook.sol
```

Tests:

```
test/hooks/StableFlowHook.t.sol
```

---

## Why There Is No TWAP or Oracle Logic

Uniswap v4 does not expose a standalone oracle contract like Uniswap v3, and hooks are not designed to compute or depend on price-based TWAPs.

Instead of forcing oracle-style logic, StableFlow uses a v4-native approach:

* Swap flow direction and magnitude from `BalanceDelta`
* Time-windowed aggregation of net flow
* Thresholds and cooldowns to prevent manipulation
* Caps to bound extreme values

This produces a manipulation-resistant, deterministic signal that is compatible with Uniswap v4 constraints, cheap to compute, and safe inside hooks.

The hook never attempts to infer price. It only observes persistent liquidity pressure, which is sufficient for intent generation.
>>>>>>> 852f50f (docs: update README with current project progress)

---

## Phase 4: Vault Contract (COMPLETED)

A minimal **OpenZeppelin ERC-4626 vault** has been added to handle deposits and withdrawals.

### Vault properties

* 1:1 share to asset ratio (initially)
* Safe custody of USDC
* No liquidity deployment
* No hook interaction
* No cross-chain logic

Core file:

```
contracts/vault/StableFlowVault.sol
```

Tests:

```
test/vault/StableFlowVault.t.sol
```

---

## Next Phase

### Phase 5: Intent to Executor Loop (In Progress)

Planned work:

* Permissionless off-chain executor
* Listen for `RebalanceIntent` events
* Decode and log intent parameters
* No LI.FI execution yet (simulation only)

This phase validates the event-driven architecture without introducing async risk into the hook.

---

## Work in Progress

This repository is under active development:

<<<<<<< HEAD
* Interfaces may evolve as later phases are integrated
* Off-chain executors, cross-chain routing, and accounting layers are **not yet wired**
* The current focus is correctness, safety, and architectural clarity

This is **not a production deployment**.
It is a hackathon project focused on building a **sound protocol primitive first**.
=======
* Cross-chain execution via LI.FI is not yet wired
* Unified accounting via Arc is not yet wired
* Frontend is intentionally deferred

This is not a production deployment.
The goal is to demonstrate correct primitives, sound architecture, and safe protocol design in a hackathon context.
>>>>>>> 852f50f (docs: update README with current project progress)

---

## High-Level Architecture

<<<<<<< HEAD
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
=======
StableFlow cleanly separates:

* On-chain intent generation using Uniswap v4 hooks
* Off-chain asynchronous execution
* Cross-chain routing
* Unified accounting

This separation is intentional and fundamental to safety.
>>>>>>> 852f50f (docs: update README with current project progress)

---

## Note for Reviewers and Judges

If you are reviewing this repository:
<<<<<<< HEAD
=======

1. Start with `StableFlowHook.sol`
2. Review the flow-based imbalance logic
3. Review thresholding and cooldown enforcement
4. Review the minimal ERC-4626 vault
5. Note that execution layers are intentionally staged

Each phase is built to be independently correct before moving forward.
>>>>>>> 852f50f (docs: update README with current project progress)

1. Start with `StableFlowHook.sol`
2. Review imbalance detection, cooldown logic, and fee control
3. Examine Foundry tests validating safety and correctness

Later phases are **intentionally staged** to avoid unsafe complexity inside the hook.


<<<<<<< HEAD
=======
*The flow will stabilize, one hook at a time.*

---
>>>>>>> 852f50f (docs: update README with current project progress)
