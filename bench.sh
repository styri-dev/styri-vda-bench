#!/usr/bin/env bash
# Listen to a VDA 5050 broker, check the traffic, say PASS or FAIL.
# Exit codes: 0 pass, 1 fail, 2 usage, or nothing to check.
set -uo pipefail

VERSION=v0.1
broker=tcp://localhost:1883
seconds=60
selftest=""
args=()

usage() {
  cat <<TEXT
Styri VDA 5050 bench $VERSION: an unofficial self-check.

  docker run --rm --network host ghcr.io/styri-dev/styri-vda-bench:$VERSION --broker tcp://HOST:1883

  --broker URL       the broker to listen to (default $broker; ssl:// for TLS)
  --seconds N        how long to listen (default $seconds)
  --username NAME    broker login
  --password TEXT    broker login
  --interface NAME   interfaceName topic level (default uagv)
  --selftest         check the bench itself, with simulated vehicles and no broker
  --help

The bench only listens. It sends nothing to your vehicles. Run your own orders and
instant actions while it listens: a rule with no traffic to check shows "-".
Mount a folder at /out to keep the report and the recorded traffic.
TEXT
}

while (($#)); do
  case "$1" in
    --broker) broker=${2:?--broker needs a URL}; shift 2 ;;
    --seconds) seconds=${2:?--seconds needs a number}; shift 2 ;;
    --username|--password|--interface) args+=("$1" "${2:?$1 needs a value}"); shift 2 ;;
    --selftest) selftest=${2:-pass}; [[ $selftest == mistakes ]] && shift; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done
[[ $seconds =~ ^[1-9][0-9]*$ ]] || { echo "--seconds must be a whole number" >&2; exit 2; }

work=$(mktemp -d)
report=$work/report.txt
trace=$work/trace.jsonl
kit=(java -jar /opt/bench/vda5050-testkit.jar)

echo "Styri VDA 5050 bench $VERSION"
echo "UNOFFICIAL SELF-CHECK. Not a VDA or third-party conformance result."
echo

if [[ -n $selftest ]]; then
  extra=()
  [[ $selftest == mistakes ]] && extra=(--with-mistakes)
  "${kit[@]}" demo ${extra[@]+"${extra[@]}"} -o "$trace" --report "$report" >/dev/null 2>"$work/err"
else
  echo "Listening to $broker for $seconds s. The bench sends nothing."
  "${kit[@]}" record -b "$broker" -d "$seconds" -o "$trace" --check --report "$report" \
    ${args[@]+"${args[@]}"} >"$work/out" 2>"$work/err"
fi
code=$?

if [[ ! -s $report ]]; then
  echo "RESULT: NO RESULT. The bench couldn't finish:"
  cat "$work/err" "$work/out" 2>/dev/null | tail -5
  exit 2
fi

messages=0
[[ -f $trace ]] && messages=$(wc -l <"$trace")
cat "$report"
echo
if [[ -d /out && -w /out ]]; then
  cp "$report" "$trace" /out/ && echo "Saved report.txt and trace.jsonl to /out."
fi
if ((messages == 0)); then
  echo "RESULT: NO RESULT. No VDA 5050 messages seen on $broker. Check the broker and that a vehicle is running."
  exit 2
elif ((code == 0)); then
  echo "RESULT: PASS (unofficial self-check, $messages messages)"
  echo "Only what happened while the bench listened was checked."
else
  echo "RESULT: FAIL (unofficial self-check, $messages messages)"
  echo "Each FAIL above names the party responsible and the spec section."
fi
exit "$code"
