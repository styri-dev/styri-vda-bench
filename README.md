# styri-vda-bench

An unofficial self-check for VDA 5050 traffic, in one `docker run`. Preview: v0.1.

```bash
docker run --rm --network host ghcr.io/styri-dev/styri-vda-bench:v0.1 --broker tcp://localhost:1883
```

It listens to your broker for 60 seconds, checks what it sees, and ends with one line:
`RESULT: PASS`, `RESULT: FAIL` or `RESULT: NO RESULT`. Each failure names the party
responsible, vehicle or fleet control, and the section of the specification.

**This is an unofficial self-check.** It's not a VDA or third-party conformance result,
and a PASS doesn't mean a vehicle will work with any given fleet control.

## What to know

- **It only listens.** It sends nothing to your vehicles. Run your own orders and instant
  actions while it listens. A rule with no traffic to check shows `-`.
- **It works offline.** Nothing leaves your network.
- **VDA 5050 2.0, 2.1 and 3.0** traffic is checked against 15 rules.

## Options

| Option | |
|---|---|
| `--broker URL` | The broker to listen to, default `tcp://localhost:1883`; `ssl://` for TLS |
| `--seconds N` | How long to listen, default 60 |
| `--username NAME`, `--password TEXT` | Broker login |
| `--interface NAME` | `interfaceName` topic level, default `uagv` |
| `--selftest` | Check the bench itself with simulated vehicles, no broker needed |

Keep the report and the recorded traffic:

```bash
docker run --rm --network host -v "$PWD/out:/out" ghcr.io/styri-dev/styri-vda-bench:v0.1 --broker tcp://localhost:1883
```

Exit codes: 0 pass, 1 fail, 2 no result.

## What's inside

[vda5050-testkit](https://github.com/ksshen0000/vda5050-testkit) (Apache-2.0) at a pinned
commit, the same checks [Styri](https://github.com/styri-dev/styri) runs in its own CI.
The full release follows on Jan 5.

## License

Apache-2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE).
