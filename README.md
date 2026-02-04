# StableFlow 🚧

**Status:** Active Development (Hackmoney Project)

StableFlow is an intent-based, cross-chain stablecoin vault built around **Uniswap v4 hooks**.
The project is developed in clearly defined phases, with the hook logic implemented first, followed by a minimal vault and an event-driven architecture.

The core idea is simple and deliberate:

> Hooks generate intent. Execution happens elsewhere.

---

## Current Progress

### Phase 1 to Phase 3: Uniswap v4 Hook (COMPLETED)

The core Uniswap v4 hook is fully implemented and tested.

### Implemented functionality

* Dynamic fee adjustment based on observed swap flow
* Imbalance detection using `BalanceDelta` (flow-based heuristic)
* Time-windowed aggregation of swap pressure
* Threshold-gated rebalancing intent emission
* Cooldown-enforced intent rate limiting
* Explicit caps on imbalance magnitude
* Strict Uniswap v4 hook safety:

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

### On-chain Verification (Sepolia)
```
StableFlowHook:
0xeC1a67DeDA1574520C940736A1Ef31d8241E80C0
```
#### Verfied PoolId(sepolia)
0xf8591a339cba73a024246d7b1399e02d8b118826fc9861555fb1ea243691c95e

The hook has been deployed and exercised on Sepolia via a live Uniswap v4 pool.

Execution characteristics:

* Hook functions are invoked via `delegatecall` from `PoolManager`
* As expected for Uniswap v4, hooks do **not** appear as standalone transactions
* Correct execution is verified via:
  * deterministic storage updates keyed by `poolId`
  * event emission during swap execution
  * post-swap state inspection using `cast call`

Example (Sepolia):

```bash
cast call 0xeC1a67DeDA1574520C940736A1Ef31d8241E80C0 "lastFlowUpdate(bytes32)(uint256)" 0xf8591a339cba73a024246d7b1399e02d8b118826fc9861555fb1ea243691c95e
```
This confirms successful hook execution after swaps.
---



### Network

Current testing and validation has been performed on:

* Sepolia testnet
* Uniswap v4 PoolManager (official deployment on Sepolia)


## Why There Is No TWAP or Oracle Logic

Uniswap v4 does not expose a standalone oracle contract like Uniswap v3, and hooks are not designed to compute or depend on price-based TWAPs.

Instead of forcing oracle-style logic, StableFlow uses a v4-native approach:

* Swap flow direction and magnitude from `BalanceDelta`
* Time-windowed aggregation of net flow
* Thresholds and cooldowns to prevent manipulation
* Caps to bound extreme values

This produces a manipulation-resistant, deterministic signal that is compatible with Uniswap v4 constraints, cheap to compute, and safe inside hooks.

The hook never attempts to infer price. It only observes persistent liquidity pressure, which is sufficient for intent generation.

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

* Cross-chain execution via LI.FI is not yet wired
* Unified accounting via Arc is not yet wired
* Frontend is intentionally deferred

This is not a production deployment.
The goal is to demonstrate correct primitives, sound architecture, and safe protocol design in a hackathon context.

---

## High-Level Architecture

StableFlow cleanly separates:

* On-chain intent generation using Uniswap v4 hooks
* Off-chain asynchronous execution
* Cross-chain routing
* Unified accounting

This separation is intentional and fundamental to safety.

---

## Note for Reviewers and Judges

If you are reviewing this repository:

1. Start with `StableFlowHook.sol`
2. Review the flow-based imbalance logic
3. Review thresholding and cooldown enforcement
4. Review the minimal ERC-4626 vault
5. Note that execution layers are intentionally staged
6. Note that Uniswap v4 hooks execute via `delegatecall` and therefore do not
   appear as direct transactions on the hook address. Execution is proven
   through state changes and emitted events.

Each phase is built to be independently correct before moving forward.

---

*The flow will stabilize, one hook at a time.*

---
