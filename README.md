<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=0:1A1A2E,50:6A5BFF,100:8B7CFF&height=180&section=header&text=Monad%20Tools&fontSize=46&fontAlignY=50&fontColor=FFFFFF" />
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/astrosynx/Logo/main/monad.png" width="180" alt="Monad Logo"/>
</p>

<p align="center">
  <b>
    <i>
      Read-only diagnostic tools for inspecting the health and correctness of Monad nodes.
    </i>
  </b>
</p>

---

# Monad Node Diagnostics

A collection of **safe, read-only diagnostic tools**
for inspecting the health and correctness of a running Monad node.

These tools are designed for:

- node operators
- validators
- infrastructure providers
- monitoring and automation workflows

They focus on **early detection of misconfiguration and failure conditions**
*before* issues surface at the consensus or RPC layer.

---

## Design Principles

- **Read-only by default**
- **Safe to run on live mainnet nodes**
- **Deterministic and idempotent**
- **No installation, staking, signing, or consensus actions**
- **Suitable for cron jobs, CI, and automated monitoring**

All tools are designed to **fail fast** and provide actionable output.

---

## Relation to Official Monad Node Ops

Official Monad documentation focuses on **operator-driven workflows**
using CLI commands, systemd inspection, logs, and live RPC queries.

This repository complements the official toolset by providing:

- automated and scriptable diagnostics
- early detection of infrastructure-level issues
- pre-flight checks for node correctness
- non-invasive validation suitable for continuous execution

These tools **do not replace** official utilities such as `monlog`,
`monad-status`, or `monad-ledger-tail`.

Instead, they aim to catch problems **before**
they become visible at the application or consensus level.

Official documentation:
- https://docs.monad.xyz/node-ops

---

## Available Tools

### 🔍 `node-health-check.sh`

Performs a high-level health inspection of a running Monad node.

#### Checks include

- required Monad systemd services are running
- consensus P2P port is listening (default: `8000`)
- optional RPC endpoint reachability (if `RPC_ENDPOINT` is set)
- local system clock drift
- disk space availability

This tool does **not** assume statesync completion
and does **not** require RPC availability.

### 🔑  `keystore-integrity-check.sh`

Validates the presence and consistency of local keystores.

#### Checks include:
- SECP and BLS keystore existence
- file ownership and permissions
- basic structural integrity
- mismatch between expected and discovered keys

This tool does not:
- export private key material
- derive keys
- perform signing
- verify on-chain validator identity

It only validates local keystore correctness and safety.

### 🧠 `sync-state-inspector.sh`

Inspects the synchronization state of a Monad node.

#### Reports:
- current block height
- peer connectivity indicators
- sync stagnation detection
- common stuck-state patterns

Designed to detect silent sync failures
before RPC or consensus degradation becomes visible.

### 💾 `triedb-sanity-check.sh`

Performs non-destructive checks against the TrieDB device.

#### Checks include:
- correct device mapping (/dev/triedb)
- block device properties
- LBA size validation
- basic read latency sampling

No data is written to disk.

This tool is **complementary** to:
```bash
monad-mpt --storage /dev/triedb
```
It focuses on **OS-level and block-device correctness**,
not internal MPT metadata.

---

## Quick Usage (One-Liners)

All tools can be executed directly without cloning the repository.

> ⚠️ These scripts are read-only, but always review remote scripts before execution.

### Node Health Check
```bash
bash <(curl -s https://raw.githubusercontent.com/astrosynx/Monad-Tools/main/tools/node-health-check.sh)
```

### Keystore Integrity Check
```bash
bash <(curl -s https://raw.githubusercontent.com/astrosynx/Monad-Tools/main/tools/keystore-integrity-check.sh)
```

### Sync State Inspector
```bash
RPC_ENDPOINT=http://localhost:8080 \
bash <(curl -s https://raw.githubusercontent.com/astrosynx/Monad-Tools/main/tools/sync-state-inspector.sh)
```

### TrieDB Sanity Check
```bash
bash <(curl -s https://raw.githubusercontent.com/astrosynx/Monad-Tools/main/tools/triedb-sanity-check.sh)
```

---

## Related Official Tools

For live consensus and application-level diagnostics,
refer to official Monad tooling:
- `monlog` — BFT log analysis and health suggestions
- `monad-status` — comprehensive node status overview
- `monad-ledger-tail` — consensus ledger stream inspection

This repository intentionally avoids:
- parsing consensus logs
- interacting with validator identity
- querying mutable chain state

Its scope is limited to **system, storage, service,
and configuration sanity checks.**

  <p align="center">
  <i>Maintained with 💙 by <b>Astrosynx</b> — Validator Infrastructure & Tools</i><br>
  <a href="https://astrosynx.com" target="_blank">🌐 astrosynx.com</a> •
  <a href="https://github.com/astrosynx" target="_blank">
    <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/github/github-original.svg"
         width="18"
         style="vertical-align:middle; margin-right:4px;">
    GitHub / Astrosynx
  </a>
</p>

<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=0:1A1A2E,50:6A5BFF,100:8B7CFF&height=120&section=footer"/>
</p>
