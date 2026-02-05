<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=0:1A1A2E,50:6A5BFF,100:8B7CFF&height=180&section=header&text=Monad%20Tools&fontSize=46&fontAlignY=50&fontColor=FFFFFF" />
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/astrosynx/Logo/main/monad.png" width="180" alt="Monad Logo"/>
</p>

<p align="center">
  <b>
    <i style="color:#2E2E2E;">
      Building and managing Monad nodes and tooling with speed and determinism.
    </i>
  </b>
</p>

---
# Monad Node Diagnostics

A small collection of **safe, read-only diagnostic tools**
for inspecting the health and correctness of a running Monad node.

These tools are intended for:
- node operators
- validators
- infrastructure providers

They focus on **early detection of misconfiguration and failure conditions**
without modifying node state.

---

## Design Principles

- Read-only by default  
- Safe to run on live mainnet nodes  
- Deterministic and idempotent  
- No installation, staking, or consensus actions  

All tools are designed to **fail fast** and provide actionable output.

---

## Available Tools

### 🔍 `node-health-check.sh`

Performs a high-level health inspection of a running Monad node.

#### Checks include
- required Monad systemd services are running
- consensus P2P port is listening (default: 8000)
- optional RPC endpoint reachability (if `RPC_ENDPOINT` is set)
- local system clock drift
- disk space availability

#### Usage
```bash
./node-health-check.sh
```

### 🔑  `keystore-integrity-check.sh`

Validates the presence and consistency of local keystores.

Checks include:
- SECP and BLS keystore existence
- file permissions
- basic structural integrity
- mismatch between expected and discovered keys

This tool does not expose or export private key material.

### 🧠 `sync-state-inspector.sh`

Inspects node synchronization state.

Reports:
- current block height
- peer connectivity indicators
- sync stagnation detection
- common stuck-state patterns

### 💾 `triedb-sanity-check.sh`

Performs non-destructive checks against the TrieDB device.

Checks include:
- correct device mapping (/dev/triedb)
- block device properties
- LBA size validation
- basic read latency sampling

No data is written to disk.
