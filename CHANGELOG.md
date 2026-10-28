# Changelog

## 2026-10-20

Fixes that make the checks match the [official Monad node layout](https://docs.monad.xyz/node-ops/full-node-installation).

### Fixed

- **triedb-sanity-check:** the expected logical block size is now **512 bytes**, as the install guide requires. The old check demanded 4096 or more, so it failed on correctly prepared drives. It now also fails if `/dev/triedb` is mounted as a filesystem.
- **keystore-integrity-check:** default paths are now `/home/monad/monad-bft/config/id-secp` and `id-bls`, instead of `/var/lib/monad/keystore`.
- **keystore-integrity-check:** the permission check now looks at the actual group and other bits. A world-readable `444` keystore used to pass.
- **sync-state-inspector:** stall detection now works from cron. The saved timestamp only moves when the height moves. Before, it was reset on every run, so a node that ran every minute was never reported as stalled.
- **node-health-check**, **sync-state-inspector:** the RPC is checked with a JSON-RPC `POST`. A plain `GET` could fail on a healthy node.

### Added

- **node-health-check:** prints the chain ID and network: `143` mainnet, `10143` testnet.
- **sync-state-inspector:** reports `eth_syncing` and the peer count.
- **keystore-integrity-check:** warns when a keystore is not owned by `monad`.
- Every threshold and path can be overridden with an environment variable. See the README.

## Earlier

- First release of the four read-only checks.
