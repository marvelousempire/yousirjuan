# Run the fleet campaign

1. Resolve each fleet ID to both transport address and reported on-host identity. Keep `.local` or
   `.lan` hostnames as transport/reporting facts; never infer the hardware model from the suffix.
2. Mark unreachable nodes explicitly. Do not invent zeroes or reuse another host's samples.
3. Install the same pinned Node release and deploy the same benchmark Git SHA to every target.
4. Run cold and warm `ci.git.fleet` receipts at concurrency 1.
5. Retain calibration failures. Correct portability defects, increment the tool build, and rerun
   every comparison host so all authoritative receipts share one tool SHA.
6. Copy receipts into `standard-benchmark-stack/receipts/runs`, rebuild its index, and write a
   campaign result under `receipts/campaigns`.
7. Project only the normalized decision into You-Sir Juan. The benchmark repository owns raw truth.

Current access notes:

- Onemac and Bigmac are LAN-reachable through `nephew-spark` as an SSH jump host.
- Twomac is reachable through WireGuard at `10.1.0.6` and reports `twomac.lan`.
- Gitea is loopback-bound on Spark; LAN Mac health probes use a temporary SSH reverse tunnel.
- Zeromac has no registered address or DNS/mDNS record.
