# StableFlow 🚧

**Status:** Active Development (HackMoney Project)

StableFlow is an **intent-based, cross-chain stablecoin system** built around **Uniswap v4 hooks**, with **ENS-governed execution**, **idempotent execution guarantees**, and **Arc-based settlement**.

The protocol follows a strict safety rule:

> **Hooks generate intent. Execution happens elsewhere.**

Each layer is deliberately isolated.

---

## Current Progress

### Phase 1–3: Uniswap v4 Hook (COMPLETED)

The core Uniswap v4 hook is fully implemented, deployed, and exercised on-chain.

#### Implemented functionality

* Dynamic fee adjustment based on observed swap flow
* Imbalance detection using `BalanceDelta` (flow-based heuristic)
* Time-windowed aggregation of swap pressure
* Threshold-gated rebalancing intent emission
* Cooldown-enforced intent rate limiting
* Explicit caps on imbalance magnitude
* **Strict Uniswap v4 hook safety**

  * no external calls
  * deterministic execution
  * bounded storage per pool

Core file:

```
contracts/hooks/StableFlowHook.sol
```

---

## On-chain Verification (Sepolia)

**StableFlowHook (Sepolia):**
[https://sepolia.etherscan.io/address/0x6cbc5627c02c69302c2453ad8b7fb29fd91680c0](https://sepolia.etherscan.io/address/0x6cbc5627c02c69302c2453ad8b7fb29fd91680c0)

### Active Pool

Currently exercised against **one Uniswap v4 pool**:

* **Pair:** native ETH / USDC (Sepolia)
* **PoolId:**

```
0x7ed33865497eadd088abeb177a5b9d3e4976ead35f6c103b9679a53ad6971ae2
```

Hooks execute via `delegatecall` from `PoolManager` and do not appear as standalone transactions, as expected in Uniswap v4.

---

## Why There Is No TWAP or Oracle Logic

Uniswap v4 does not expose a standalone oracle like Uniswap v3, and hooks are not designed to compute price-based TWAPs.

StableFlow instead uses a **v4-native heuristic**:

* Net swap flow from `BalanceDelta`
* Time-windowed aggregation
* Thresholds to ignore noise
* Cooldowns to prevent rapid retriggering
* Hard caps to bound behavior

The hook **does not infer price**.
It observes **persistent liquidity pressure**, which is sufficient to generate a safe **intent**, not an execution.

---

## ENS Control Plane (COMPLETED)

StableFlow uses **ENS as a live protocol control plane**.

ENS directly governs executor behavior and protocol configuration.

### ENS name

```
stableflow-sepolia.eth
```

### ENS-controlled parameters

Stored as ENS text records:

* `stableflow:hook` → canonical hook address
* `stableflow:threshold:bps` → intent emission threshold
* `stableflow:status` → active / paused
* `stableflow:execution` → execution enabled / disabled
* `stableflow:mode` → `demo` vs `live`
* `stableflow:chain` → target execution chain
* `stableflow:executor` → authorized executor address

Executors **resolve ENS on every intent**, making configuration transparent and hot-swappable.

---

## RebalanceExecutionRegistry (COMPLETED)

To ensure **safe, idempotent execution**, StableFlow introduces an on-chain execution registry.

### RebalanceExecutionRegistry (Sepolia)

**Deployed at:**
[https://sepolia.etherscan.io/address/0xcbbEcB538615ED8e26f74a84cCE7Ae721A2CA86E](https://sepolia.etherscan.io/address/0xcbbEcB538615ED8e26f74a84cCE7Ae721A2CA86E)

### Why this contract exists

Uniswap v4 hooks emit **events**, not transactions.
Off-chain executors are **permissionless** and **may retry** execution.

Without a registry:

* The same intent could be executed multiple times
* Executors could race
* Settlement safety would be compromised

### What the registry guarantees

* Each intent is uniquely identified (`intentId`)
* Execution is **recorded on-chain**
* Duplicate execution attempts revert
* Execution becomes **idempotent by construction**

### How it is used

1. Executor computes a deterministic `intentId`
2. Executor calls `markExecuted(intentId, poolId, imbalanceBps)`
3. If already executed → transaction reverts
4. If successful → executor proceeds to settlement (Arc)

This contract is **chain-agnostic**, minimal, and intentionally boring — exactly what execution safety requires.

---

## Arc Settlement Layer (COMPLETED)

StableFlow uses **Arc** as the settlement and liquidity hub.

### StableFlowArcVault

**Deployed on Arc Testnet:**
[https://testnet.arcscan.app/address/0x5618F6541328ca1FdCf1838f1Bc4d3D14558E29f](https://testnet.arcscan.app/address/0x5618F6541328ca1FdCf1838f1Bc4d3D14558E29f)

The Arc vault:

* Holds USDC on Arc
* Receives settlements from the executor
* Acts as the canonical accounting endpoint

Core file:

```
contracts/arc/StableFlowArcVault.sol
```

### What is proven

* Intent execution is gated by ENS
* Idempotency is enforced on Ethereum (registry)
* Settlement is finalized independently on Arc
* Ethereum and Arc concerns remain cleanly separated

---

## Intent Execution Pipeline (COMPLETED)

End-to-end flow:

1. Swap occurs on Uniswap v4 (Sepolia)
2. Hook emits `RebalanceIntent`
3. Off-chain executor listens
4. ENS config is resolved
5. Executor authorized via ENS
6. Intent marked executed in `RebalanceExecutionRegistry`
7. Settlement finalized on Arc via `StableFlowArcVault`

All steps are verifiable via on-chain transactions.

---

## Vault Note (ERC-4626)

A minimal ERC-4626 vault exists as a **reference implementation**:

```
contracts/vault/StableFlowVault.sol
```

It is **not used** in the active execution path.

The live settlement layer is **StableFlowArcVault** on Arc.

---

## Network

Validated on:

* Ethereum Sepolia
* Uniswap v4 PoolManager (Sepolia)
* Arc Testnet (USDC-native gas)

---

## Note for Reviewers and Judges

To review this project:

1. Start with `StableFlowHook.sol`
2. Review flow-based intent logic
3. Review ENS-governed execution controls
4. Review `RebalanceExecutionRegistry` for idempotency
5. Review executor → Arc settlement flow
6. Verify Arc `settleRebalance` transactions

Each component is independently correct and intentionally minimal.

---

*The flow stabilizes — one intent at a time.*

---

