#!/usr/bin/env python3
"""
simple_requests_tester.py

Minimal GET/POST tester using requests.

Required:
    pip install requests

Example:
    python simple_requests_tester.py --base-url https://staging.example.com \
        --routes / /api/health /charging/v1/charging --method get
    python simple_requests_tester.py --base-url https://staging.example.com \
        --routes /api/login /api/data --method post --data '{"k":"v"}'
"""

import argparse
import time
import json
from typing import List, Optional
import requests

def parse_args():
    p = argparse.ArgumentParser(description="Simple GET/POST tester using requests.")
    p.add_argument("--base-url", required=True, help="Base URL (e.g. https://example.com)")
    p.add_argument("--routes", nargs="+", required=True, help="Routes (space-separated), e.g. / /api/health")
    p.add_argument("--method", choices=["get", "post"], default="get", help="HTTP method to use")
    p.add_argument("--data", help="JSON payload for POST (string). Example: '{\"k\":\"v\"}'")
    p.add_argument("--timeout", type=float, default=5.0, help="Request timeout in seconds")
    p.add_argument("--headers", help="Optional JSON string of extra headers, e.g. '{\"Authorization\":\"Bearer ...\"}'")
    return p.parse_args()

def build_url(base: str, route: str) -> str:
    if base.endswith("/") and route.startswith("/"):
        return base[:-1] + route
    if (not base.endswith("/")) and (not route.startswith("/")):
        return base + "/" + route
    return base + route

def main():
    args = parse_args()
    try:
        extra_headers = json.loads(args.headers) if args.headers else {}
    except json.JSONDecodeError:
        print("Invalid JSON for --headers")
        return

    payload = None
    if args.method == "post" and args.data:
        try:
            payload = json.loads(args.data)
        except json.JSONDecodeError:
            print("Invalid JSON for --data")
            return

    session = requests.Session()
    if extra_headers:
        session.headers.update(extra_headers)

    for route in args.routes:
        url = build_url(args.base_url, route)
        print(f"\n--> {args.method.upper()} {url}")
        start = time.monotonic()
        try:
            if args.method == "get":
                resp = session.get(url, timeout=args.timeout)
            else:  # post
                resp = session.post(url, json=payload, timeout=args.timeout)
            elapsed = time.monotonic() - start
            status = resp.status_code
            size = len(resp.content or b"")
            # print a short snippet of body up to 300 chars (safe for quick debugging)
            body_snippet = resp.text[:300].replace("\n", " ")
            print(f"Status: {status}  Time: {elapsed:.3f}s  Size: {size} bytes")
            print(f"Headers: {dict(resp.headers)}")
            if body_snippet:
                print(f"Body (truncated): {body_snippet}{'...' if len(resp.text) > 300 else ''}")
        except requests.Timeout:
            elapsed = time.monotonic() - start
            print(f"ERROR: timeout after {elapsed:.3f}s")
        except requests.RequestException as e:
            elapsed = time.monotonic() - start
            print(f"ERROR: request failed after {elapsed:.3f}s  Exception: {e}")

if __name__ == "__main__":
    main()