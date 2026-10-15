#!/usr/bin/env python3
"""One-shot JSON bridge; clipboard payloads never cross the command-line boundary."""

import json
import re
import subprocess
import sys
import unicodedata


class ClipboardError(Exception):
    """Only static, public-safe messages may be used here."""


def command(arguments, *, data=None, capture=True):
    try:
        result = subprocess.run(
            arguments,
            input=data,
            stdin=subprocess.DEVNULL if data is None else None,
            stdout=subprocess.PIPE if capture else subprocess.DEVNULL,
            stderr=subprocess.PIPE if capture else subprocess.DEVNULL,
            timeout=8,
            check=False,
        )
    except FileNotFoundError:
        raise ClipboardError("Clipboard tools are unavailable.") from None
    except subprocess.TimeoutExpired:
        raise ClipboardError("Clipboard request timed out. Try again.") from None
    except OSError:
        raise ClipboardError("Clipboard tools could not be started.") from None
    return result


def require_success(result):
    if result.returncode != 0:
        # Never forward tool errors: they may contain stored clipboard content.
        raise ClipboardError("Clipboard request failed. Refresh and try again.")
    return result.stdout


def safe_preview(text):
    # Qt must see plain text, without terminal controls or bidi formatting marks.
    return "".join(
        character if not unicodedata.category(character).startswith("C") else "\ufffd"
        for character in text
    )[:2000]


def history():
    result = command(["cliphist", "-preview-width", "2000", "list"])
    if result.returncode and b"please store something first" in result.stderr:
        return []
    output = require_success(result).decode("utf-8", errors="replace")
    entries = []
    for line in output.split("\n"):
        if not line:
            continue
        identifier, separator, preview = line.partition("\t")
        if not separator or not re.fullmatch(r"[0-9]+", identifier):
            raise ClipboardError("Clipboard history returned an invalid response.")
        # IDs stay decimal strings to avoid losing uint64 precision in JavaScript.
        entries.append(
            {
                "id": identifier,
                "preview": safe_preview(preview),
                "kind": "binary" if preview.startswith("[[ binary data ") else "text",
            }
        )
    return entries


def copy_entry(identifier):
    payload = require_success(
        command(["cliphist", "decode"], data=identifier.encode("ascii"))
    )
    mime = (
        require_success(command(["file", "--brief", "--mime-type", "-"], data=payload))
        .decode("ascii", errors="replace")
        .strip()
    )
    if not re.fullmatch(r"[a-z0-9!#$&^_.+-]+/[a-z0-9!#$&^_.+-]+", mime):
        raise ClipboardError("Clipboard format could not be identified.")
    if mime.startswith("text/"):
        mime = "text/plain;charset=utf-8"
    require_success(command(["wl-copy", "--type", mime], data=payload, capture=False))


def main(arguments):
    if arguments == ["list"]:
        return {"ok": True, "entries": history()}
    if arguments == ["clear", "--confirm"]:
        require_success(command(["cliphist", "wipe"]))
        return {"ok": True, "entries": history()}
    if (
        len(arguments) == 2
        and arguments[0] in {"copy", "delete"}
        and re.fullmatch(r"[0-9]{1,20}", arguments[1])
        and 0 < int(arguments[1]) < 2**64
    ):
        action, identifier = arguments
        if action == "copy":
            copy_entry(identifier)
            return {"ok": True}
        require_success(
            command(["cliphist", "delete"], data=(identifier + "\n").encode("ascii"))
        )
        return {"ok": True, "entries": history()}
    raise ClipboardError("Invalid clipboard request.")


if __name__ == "__main__":
    try:
        response = main(sys.argv[1:])
    except ClipboardError as error:
        response = {"ok": False, "error": str(error)}
    except Exception:
        # Do not print tracebacks or exception strings containing clipboard data.
        response = {"ok": False, "error": "Clipboard request could not be completed."}
    print(json.dumps(response, ensure_ascii=True, separators=(",", ":")))
    sys.exit(0 if response["ok"] else 1)
