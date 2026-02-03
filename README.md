# StableFlow 🚧

**Status:** Active Development (Hackathon Project)

StableFlow is an intent-based, cross-chain stablecoin vault built around **Uniswap v4 hooks**.  
The project is being developed in clearly defined phases, with the core hook logic implemented first.

---

## ✅ Current Progress

**Phase 2 — Uniswap v4 Hook (COMPLETED)**

The following functionality is implemented and tested:

- Dynamic fee adjustment based on on-chain swap pressure  
- Imbalance detection using `BalanceDelta`  
- Rate-limited rebalancing intent emission (cooldown enforced)  
- Strict Uniswap v4 hook safety (no external calls, deterministic execution)

📍 Core file:
```
src/hooks/StableFlowHook.sol
```
📍 Tests:

---

## 🔜 Next Phase (In Progress)

**Phase 3 — Hook Hardening**
- TWAP-based manipulation resistance
- Fee caps and smoothing
- Improved normalization of imbalance signals

---

## ⚠️ Work in Progress

This repository is under active development:
- Interfaces may change
- Later phases (executor, cross-chain routing, accounting) are not yet wired
- The focus is currently on building a correct and safe protocol primitive

This is **not** a production deployment — it is a hackathon project focused on correctness, architecture, and extensibility.

---

## 🧠 High-Level Architecture

StableFlow separates:
- **On-chain intent generation** (Uniswap v4 hooks)
- **Off-chain execution** (planned)
- **Cross-chain routing and accounting** (planned)

Full architecture details will be added as subsequent phases are completed.

---

## 📌 Note for Reviewers / Judges

If you are reviewing this repository:
- Start with `StableFlowHook.sol`
- Review Phase 2 hook logic and tests
- Phase 3 and beyond are intentionally staged

---

*The flow will stabilize — one hook at a time.*
