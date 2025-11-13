#!/usr/bin/env python3

import argparse
import sys
import time
from datetime import datetime

try:
    import requests
except ImportError:
    print("Missing dependency 'requests'. Install: pip install requests")
    sys.exit(2)


def ts():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def check_url(url, timeout=5, retries=2):
    attempt = 0
    last_exc = None
    while attempt <= retries:
        try:
            resp = requests.get(url, timeout=timeout, allow_redirects=True)
            return resp.status_code, len(resp.content)
        except requests.RequestException as e:
            last_exc = e
            attempt += 1
            time.sleep(1 + attempt)  
    # all retries failed
    return None, str(last_exc)


def main():
    parser = argparse.ArgumentParser(description="HTTP app health checker")
    parser.add_argument("urls", nargs="*", help="URLs to check (if not using --urls file)")
    parser.add_argument("--urls-file", dest="urls_file", help="File with URLs, one per line")
    parser.add_argument("--log", default="logs/app_health.log", help="Log file")
    parser.add_argument("--timeout", type=int, default=5)
    parser.add_argument("--retries", type=int, default=2)
    args = parser.parse_args()

    url_list = []
    if args.urls_file:
        try:
            with open(args.urls_file, "r") as f:
                url_list = [line.strip() for line in f if line.strip() and not line.startswith("#")]
        except FileNotFoundError:
            print(f"URLs file not found: {args.urls_file}")
            sys.exit(2)
    if args.urls:
        url_list.extend(args.urls)
    if not url_list:
        print("No URLs supplied. Use positional URLs or --urls-file.")
        sys.exit(1)

    with open(args.log, "a") as lf:
        for url in url_list:
            sc, info = check_url(url, timeout=args.timeout, retries=args.retries)
            if sc is None:
                line = f"[{ts()}] DOWN  {url}  error={info}\n"
                print(line.strip())
                lf.write(line)
            else:
                if 200 <= sc < 300:
                    line = f"[{ts()}] UP    {url}  status={sc} bytes={info}\n"
                    print(line.strip())
                    lf.write(line)
                else:
                    line = f"[{ts()}] DEGRADED {url} status={sc} bytes={info}\n"
                    print(line.strip())
                    lf.write(line)


if __name__ == "__main__":
    main()
