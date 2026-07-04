#!/usr/bin/env python3

from __future__ import annotations

import os
import json
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SERVER_URL = "http://192.168.86.88:8096"
DEFAULT_DESTINATION = "platform=tvOS Simulator,name=FinStream-tvOS"
DEFAULTS_DOMAINS = ("com.mrweic.finstream", "com.mrweic.finstream.tests")
AUTOMATION_KEYS = (
    "FINSTREAM_AUTOMATION_SERVER_URL",
    "FINSTREAM_AUTOMATION_USERNAME",
    "FINSTREAM_AUTOMATION_PASSWORD",
)


def parse_env(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue

        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip()

        if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
            value = value[1:-1]

        values[key] = value

    return values


def require(value: str | None, name: str) -> str:
    if value:
        return value

    raise SystemExit(f"Missing {name} in .env")


def destination_value(destination: str, name: str) -> str | None:
    for part in destination.split(","):
        key, _, value = part.strip().partition("=")
        if key == name and value:
            return value
    return None


def simulator_udid(destination: str) -> str:
    explicit_id = destination_value(destination, "id")
    if explicit_id:
        return explicit_id

    simulator_name = destination_value(destination, "name")
    if not simulator_name:
        raise SystemExit("FINSTREAM_AUTOMATION_DESTINATION must include a simulator name or id")

    output = subprocess.check_output(
        ["xcrun", "simctl", "list", "devices", "available", "-j"],
        text=True,
    )
    devices = json.loads(output)

    for runtime_devices in devices.get("devices", {}).values():
        for device in runtime_devices:
            if device.get("name") == simulator_name:
                return device["udid"]

    raise SystemExit(f"Cannot find simulator named {simulator_name!r}")


def write_simulator_defaults(udid: str, values: dict[str, str]) -> None:
    subprocess.run(["xcrun", "simctl", "boot", udid], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    subprocess.run(["xcrun", "simctl", "bootstatus", udid, "-b"], check=True)
    subprocess.run(["xcrun", "simctl", "uninstall", udid, "com.mrweic.finstream"], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    for domain in DEFAULTS_DOMAINS:
        for key, value in values.items():
            subprocess.run(
                ["xcrun", "simctl", "spawn", udid, "defaults", "write", domain, key, value],
                check=True,
            )


def clear_simulator_defaults(udid: str) -> None:
    for domain in DEFAULTS_DOMAINS:
        for key in AUTOMATION_KEYS:
            subprocess.run(
                ["xcrun", "simctl", "spawn", udid, "defaults", "delete", domain, key],
                check=False,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )


def main() -> int:
    env_path = Path(sys.argv[1]).expanduser() if len(sys.argv) > 1 else ROOT / ".env"
    if not env_path.exists():
        raise SystemExit(f"Cannot find .env file: {env_path}")

    env_values = parse_env(env_path)
    username = require(env_values.get("USERNAME"), "USERNAME")
    password = require(env_values.get("PASSWORD"), "PASSWORD")
    server_url = (
        env_values.get("FINSTREAM_AUTOMATION_SERVER_URL")
        or env_values.get("JELLYFIN_SERVER_URL")
        or DEFAULT_SERVER_URL
    )

    if "://" not in server_url:
        server_url = f"http://{server_url}"

    destination = os.environ.get("FINSTREAM_AUTOMATION_DESTINATION", DEFAULT_DESTINATION)
    automation_values = {
        "FINSTREAM_AUTOMATION_SERVER_URL": server_url,
        "FINSTREAM_AUTOMATION_USERNAME": username,
        "FINSTREAM_AUTOMATION_PASSWORD": password,
    }
    udid = simulator_udid(destination)

    command = [
        "xcodebuild",
        "test",
        "-skipMacroValidation",
        "-scheme",
        "Swiftfin tvOS Tests",
        "-destination",
        destination,
        "-only-testing:Swiftfin tvOS Tests/FirstTimeAccountFlowAutomationTests/testDevServerCanBeAddedFromEmptyLocalState",
    ]

    print(f"Running first-time account flow automation against {server_url}")
    write_simulator_defaults(udid, automation_values)
    try:
        return subprocess.run(command, cwd=ROOT, env=os.environ.copy(), check=False).returncode
    finally:
        clear_simulator_defaults(udid)


if __name__ == "__main__":
    raise SystemExit(main())
