#!/usr/bin/env python3
import argparse
import re
import sys
import yaml

PATTERN = re.compile(r"^router-building_commercial-(\d+(?:_\d+)?)$")

def load_yaml(path):
    try:
        with open(path, "r") as f:
            # If your file has {{BRANCH_NAME}} placeholders, replace here if needed:
            content = f.read().replace("{{BRANCH_NAME}}", "main")
            return yaml.safe_load(content)
    except Exception as e:
        print(f"Error reading/parsing YAML: {e}", file=sys.stderr)
        sys.exit(1)

def main():
    ap = argparse.ArgumentParser(
        description="Extract WAN IPs for router-building_commercial-* into dnsmasq format."
    )
    ap.add_argument("topology", help="Path to topology YAML (e.g., topology.yml)")
    ap.add_argument("--domain", default="sunshine.lab", help="Domain to append (default: sunshine.lab)")
    ap.add_argument("--out", default="-", help="Output file (default: stdout)")
    args = ap.parse_args()

    data = load_yaml(args.topology)
    nodes = data.get("spec", {}).get("nodes", [])

    lines = []
    for node in nodes:
        hostname = node.get("general", {}).get("hostname", "")
        m = PATTERN.match(hostname)
        if not m:
            continue  # skip non-matching hostnames

        router_id = m.group(1)  # e.g., "357101_1"
        interfaces = node.get("network", {}).get("interfaces", []) or []

        # Find interface(s) on VLAN WAN
        for iface in interfaces:
            if str(iface.get("vlan", "")).strip().upper() == "WAN":
                addr = iface.get("address")
                if addr:
                    # address=/357101_1.sunshine.lab/100.0.0.171
                    lines.append(f"address=/{router_id}.{args.domain}/{addr}")

    # Sort for stable output (optional)
    lines.sort()

    # Write output
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


##############
#python3 extract_dnsmasq_wan.py topology_get_ips.yml > dnsmasq.conf.snippet
# or specify domain/out:
#python3 extract_dnsmasq_wan.py topology.yml --domain sunshine.lab --out wan_hosts.conf
##############


