"""Unit tests for .github/scripts/audit_docs.py in purpleair-matterbridge."""

from __future__ import annotations

import importlib.util
import sys
import tempfile
from pathlib import Path

_SCRIPT_PATH = Path(__file__).resolve().parent.parent / "audit_docs.py"
spec = importlib.util.spec_from_file_location("audit_docs", str(_SCRIPT_PATH))
audit_mod = importlib.util.module_from_spec(spec)
sys.modules["audit_docs"] = audit_mod
spec.loader.exec_module(audit_mod)

audit_file = audit_mod.audit_file
fix_file = audit_mod.fix_file


def test_audit_file_clean():
    clean_text = """
    \"\"\"This is a clean docstring using PurpleAirPlatform and PurpleAirClient.\"\"\"
    def receive_data():
        pass
    """
    with tempfile.NamedTemporaryFile(suffix=".ts", mode="w", delete=False) as tf:
        tf.write(clean_text)
        tf_path = Path(tf.name)

    try:
        issues = audit_file(tf_path)
        assert issues == []
    finally:
        tf_path.unlink(missing_ok=True)


def test_audit_file_with_issues_and_fix():
    dirty_text = """
    // We will recieve data here.
    // An error occured during export.
    // Check PurpleairPlatform initialization.
    // Configure PurpleairClient timeout.
    """
    with tempfile.NamedTemporaryFile(suffix=".ts", mode="w", delete=False) as tf:
        tf.write(dirty_text)
        tf_path = Path(tf.name)

    try:
        issues = audit_file(tf_path)
        assert len(issues) == 4
        descriptions = [i[2] for i in issues]
        assert any("recieve" in d for d in descriptions)
        assert any("occured" in d for d in descriptions)
        assert any("PurpleairPlatform" in d for d in descriptions)
        assert any("PurpleairClient" in d for d in descriptions)

        # Test fix_file
        changed = fix_file(tf_path)
        assert changed == 1

        fixed_content = tf_path.read_text(encoding="utf-8")
        assert "receive" in fixed_content
        assert "occurred" in fixed_content
        assert "PurpleAirPlatform" in fixed_content
        assert "PurpleAirClient" in fixed_content

        # Re-audit should now be clean
        issues_after = audit_file(tf_path)
        assert issues_after == []
    finally:
        tf_path.unlink(missing_ok=True)

