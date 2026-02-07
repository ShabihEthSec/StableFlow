# StableFlow 🚧

**Status:** Active Development (HackMoney Project)

StableFlow is an **intent-based, cross-chain stablecoin system** built around **Uniswap v4 hooks**, with **ENS-governed execution** and **Arc-based settlement**.

The protocol is designed around a strict safety rule:

> **Hooks generate intent. Execution happens elsewhere.**

This separation is intentional and fundamental.

---

## Current Progress

### Phase 1–3: Uniswap v4 Hook (COMPLETED)

The core Uniswap v4 hook is fully implemented, deployed, and exercised on-chain.

### Implemented functionality

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

Tests:

```
test/hooks/StableFlowHook.t.sol
```

---

## On-chain Verification (Sepolia)

**StableFlowHook (Sepolia):**
[https://sepolia.etherscan.io/address/0x6cbc5627c02c69302c2453ad8b7fb29fd91680c0](https://sepolia.etherscan.io/address/0x6cbc5627c02c69302c2453ad8b7fb29fd91680c0)

### Active Pool

Currently, StableFlow is exercised against **one Uniswap v4 pool**:

* **Pair:** native ETH / USDC (Sepolia)
* **PoolId:**

```
0x7ed33865497eadd088abeb177a5b9d3e4976ead35f6c103b9679a53ad6971ae2
```

### Execution characteristics

* Hook functions execute via `delegatecall` from `PoolManager`
* Hooks do **not** appear as standalone transactions (expected Uniswap v4 behavior)
* Correct execution is verified via:

  * deterministic storage updates keyed by `poolId`
  * event emission during swaps
  * post-swap state inspection

Example:

```bash
cast call 0x6cbc5627c02c69302c2453ad8b7fb29fd91680c0 \
  "lastFlowUpdate(bytes32)(uint256)" \
  0x7ed33865497eadd088abeb177a5b9d3e4976ead35f6c103b9679a53ad6971ae2
```

This confirms successful hook execution after swaps.

---

## Why There Is No TWAP or Oracle Logic

Uniswap v4 does **not** expose a standalone oracle contract like Uniswap v3, and hooks are **not designed** to compute or depend on price-based TWAPs.

Instead of forcing oracle-style logic into hooks, StableFlow uses a **v4-native heuristic**:

### Flow-based heuristic design

* Net swap flow direction and magnitude from `BalanceDelta`
* Time-windowed aggregation of swap pressure
* Minimum thresholds to ignore noise
* Cooldowns to prevent rapid re-triggering
* Hard caps to bound worst-case behavior

### Why this is correct

* Hooks remain **deterministic**
* No external dependencies or async calls
* No price inference inside the hook
* Resistant to short-term manipulation
* Cheap to compute and safe under Uniswap v4 constraints

The hook does **not** attempt to infer price or fair value.
It only observes **persistent liquidity pressure**, which is sufficient to generate a safe rebalancing **intent**, not an execution.

---

## ENS Control Plane (COMPLETED)

StableFlow uses **ENS as a live protocol control plane**, not as a vanity name.

ENS directly governs executor behavior.

### ENS name

```
stableflow-sepolia.eth
```

### ENS-controlled parameters

Stored as ENS text records:

* `stableflow:hook` → canonical hook address
* `stableflow:threshold:bps` → intent emission threshold
* `stableflow:status` → active / paused protocol switch
* `stableflow:execution` → execution enable / disable
* `stableflow:mode` → `demo` vs `live`
* `stableflow:chain` → target execution chain
* `stableflow:executor` → authorized executor address

### What this enables

* Hot configuration without redeployments
* Executor authorization via ENS
* Immediate pause / resume capability
* Transparent, on-chain governance rules

ENS is actively resolved by the executor on **every intent**.

---

## Arc Settlement Layer (COMPLETED)

StableFlow uses **Arc** as the settlement and liquidity hub for executed intents.

### StableFlowArcVault

**Deployed on Arc Testnet:**
[https://testnet.arcscan.app/address/0x5618F6541328ca1FdCf1838f1Bc4d3D14558E29f](https://testnet.arcscan.app/address/0x5618F6541328ca1FdCf1838f1Bc4d3D14558E29f)

The Arc vault:

* Holds USDC on Arc
* Receives settlements from the executor
* Acts as the canonical accounting endpoint for rebalances

Core contract:

```
contracts/arc/StableFlowArcVault.sol
```

### What is proven

* Off-chain executor consumes on-chain intents
* Execution is gated by ENS configuration
* Idempotency is enforced via execution registry
* Settlement is finalized on Arc using USDC
* Ethereum execution and Arc settlement are cleanly separated

This satisfies the Arc bounty requirement:

> *Treat multiple chains as one liquidity surface, using Arc as a liquidity hub.*

---

## Intent Execution Pipeline (COMPLETED)

End-to-end flow:

1. Swap occurs on Uniswap v4 (Sepolia)
2. Hook observes persistent imbalance
3. `RebalanceIntent` event is emitted
4. Permissionless executor listens off-chain
5. ENS config is resolved and enforced
6. Execution is authorized
7. Intent is marked executed on Ethereum
8. Settlement is finalized on Arc

This pipeline is fully operational and verifiable via on-chain transactions.

---

## Vault Note (ERC-4626)

A minimal ERC-4626 vault exists in the repository as a **reference implementation**:

```
contracts/vault/StableFlowVault.sol
```

It is **not used** in the active execution path.

The live settlement and accounting layer is **StableFlowArcVault** on Arc.

---

## Network

Validated on:

* Ethereum Sepolia
* Uniswap v4 PoolManager (Sepolia)
* Arc Testnet (USDC-native gas)

---

## Work Remaining

* Frontend (next phase)
* Optional advanced accounting

This repository focuses on **correct primitives, safe architecture, and working execution**, not UI polish.

---

## Note for Reviewers and Judges

To review this project:

1. Start with `StableFlowHook.sol`
2. Review flow-based imbalance detection
3. Review thresholding and cooldown logic
4. Review ENS-governed execution control
5. Review executor → Arc settlement flow
6. Verify Arc `settleRebalance` transactions

Each phase is independently correct and validated before advancing.

---

*The flow stabilizes — one intent at a time.*

---
