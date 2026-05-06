#!/usr/bin/env python3
import argparse
import re
import sys
import yaml

# Match hostnames like: ems-129064_1, ems-170879_3, etc.
EMS_PATTERN = re.compile(r"^ems-(\d+(?:_\d+)?)$")

def load_yaml(path: str):
    try:
        with open(path, "r") as f:
            content = f.read().replace("{{BRANCH_NAME}}", "main")
            return yaml.safe_load(content)
    except Exception as e:
        print(f"Error reading/parsing YAML: {e}", file=sys.stderr)
        sys.exit(1)

def main():
    ap = argparse.ArgumentParser(
        description="Extract BUILDING_commercial IPs for ems-* into dnsmasq format."
    )
    ap.add_argument("topology", help="Path to topology YAML (e.g., aggtopology.yml)")
    ap.add_argument("--domain", default="sunshine.lab",
                    help="Domain to append (default: sunshine.lab)")
    ap.add_argument("--out", default="-",
                    help="Output file (default: stdout)")
    args = ap.parse_args()

    data = load_yaml(args.topology)
    nodes = (data or {}).get("spec", {}).get("nodes", [])

    lines = []
    for node in nodes:
        hostname = (node.get("general") or {}).get("hostname", "")
        m = EMS_PATTERN.match(hostname)
        if not m:
            continue
        ems_id = m.group(1)  # e.g., "129064_1"

        # Target VLAN must be exactly BUILDING_commercial-<ems_id>
        target_vlan = f"BUILDING_commercial-{ems_id}"

        interfaces = (node.get("network") or {}).get("interfaces", []) or []
        for iface in interfaces:
            vlan = str(iface.get("vlan", "")).strip()
            if vlan == target_vlan:
                addr = iface.get("address")
                if addr:
                    # Emit: address=/129064_1.sunshine.lab/40.4.0.90
                    lines.append(f"address=/{ems_id}.{args.domain}/{addr}")
                # We only expect one matching interface per ems node; break if found
                break

    # Sort for deterministic output
    lines.sort()

    if args.out == "-" or args.out.lower() == "stdout":
        for line in lines:
            print(line)
    else:
        try:
            with open(args.out, "w") as f:
                f.write("\n".join(lines) + ("\n" if lines else ""))
        except Exception as e:
            print(f"Error writing output file: {e}", file=sys.stderr)
            sys.exit(1)

if __name__ == "__main__":
    main()
