"""Unit tests for .github/scripts/generate_release_notes.py in purpleair-matterbridge."""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path
from typing import Any

# Dynamically import generate_release_notes from .github/scripts/
_SCRIPT_PATH = Path(__file__).resolve().parent.parent / "generate_release_notes.py"
spec = importlib.util.spec_from_file_location(
    "generate_release_notes", str(_SCRIPT_PATH)
)
gen_mod = importlib.util.module_from_spec(spec)
sys.modules["generate_release_notes"] = gen_mod
spec.loader.exec_module(gen_mod)

clean_title = gen_mod.clean_title
rewrite_to_natural_language = gen_mod.rewrite_to_natural_language
categorize_item = gen_mod.categorize_item
parse_semver = gen_mod.parse_semver
determine_base_tag = gen_mod.determine_base_tag
parse_existing_prs = gen_mod.parse_existing_prs
synthesize_summary = gen_mod.synthesize_summary
build_release_notes = gen_mod.build_release_notes


def test_clean_title():
    raw1 = "✨ Fix rate limit header parsing (#123) by @carlkidcrypto in https://github.com/carlkidcrypto/purpleair-matterbridge/pull/123"
    assert clean_title(raw1) == "Fix rate limit header parsing"

    raw2 = "[docs] Update documentation for setup #456"
    assert clean_title(raw2) == "[docs] Update documentation for setup"


def test_rewrite_to_natural_language_prefixes_and_verbs():
    # Conventional commit prefixes stripped and verb conjugated
    assert (
        rewrite_to_natural_language("feat(endpoint): add air quality cluster mapping")
        == "Adds air quality cluster mapping"
    )
    assert (
        rewrite_to_natural_language("fix: resolve timeout on purpleair sensor fetch")
        == "Resolves timeout on purpleair sensor fetch"
    )
    assert (
        rewrite_to_natural_language("chore(deps): bump typescript from 5.3 to 5.4")
        == "Bumps typescript from 5.3 to 5.4"
    )
    assert (
        rewrite_to_natural_language("[coverage-autofix] improve endpoint test coverage")
        == "Improves endpoint test coverage"
    )

    # Past tense verbs conjugated to 3rd person singular present
    assert (
        rewrite_to_natural_language("Fixed connection handling in PurpleAirClient")
        == "Fixes connection handling in PurpleAirClient"
    )
    assert (
        rewrite_to_natural_language("Added support for temperature unit conversion")
        == "Adds support for temperature unit conversion"
    )
    assert (
        rewrite_to_natural_language("Updated dependencies in package.json")
        == "Updates dependencies in package.json"
    )

    # Prefix with noun gets inferred active verb
    assert (
        rewrite_to_natural_language("fix: header error in matter endpoint")
        == "Fixes header error in matter endpoint"
    )
    assert (
        rewrite_to_natural_language("feat: matterbridge plugin integration")
        == "Adds matterbridge plugin integration"
    )

    # Already third person present unchanged
    assert (
        rewrite_to_natural_language("Adds support for humidity sensor cluster")
        == "Adds support for humidity sensor cluster"
    )


def test_categorize_item():
    # Dependencies
    assert categorize_item("Bump typescript from 5.3 to 5.4", []) == "Dependencies"
    assert (
        categorize_item(
            "Update packages",
            ["package-lock.json"],
        )
        == "Dependencies"
    )

    # CI / Workflows (priority over docs)
    assert (
        categorize_item(
            "Update CI workflow for Node 22",
            [".github/workflows/tests.yml"],
        )
        == "CI / Workflows"
    )
    assert (
        categorize_item(
            "Update changelog workflow",
            [".github/workflows/auto_change_log.md"],
        )
        == "CI / Workflows"
    )

    # Documentation
    assert (
        categorize_item(
            "Update README.md with Docker usage",
            ["README.md"],
        )
        == "Documentation"
    )
    assert (
        categorize_item(
            "Add troubleshooting tips for Linux",
            ["TROUBLESHOOTING-LINUX.md"],
        )
        == "Documentation"
    )

    # Tests
    assert (
        categorize_item(
            "Add unit tests for PurpleAirClient",
            ["vitest/purpleair-client.test.ts"],
        )
        == "Tests"
    )

    # Containers / Packaging
    assert (
        categorize_item(
            "Update Dockerfile base image",
            ["docker/Dockerfile"],
        )
        == "Containers / Packaging"
    )

    # Runtime / Plugin / Features / Bug Fixes
    assert (
        categorize_item(
            "Fix sensor indexing when key is missing",
            ["src/purpleair-client.ts"],
        )
        == "Bug Fixes"
    )
    assert (
        categorize_item(
            "Add humidity cluster to matter endpoint",
            ["src/purpleair-endpoint.ts"],
        )
        == "Features / Enhancements"
    )
    assert (
        categorize_item(
            "Internal refactor of platform registration",
            ["src/module.ts"],
        )
        == "Runtime / Plugin"
    )

    # Chores / Misc
    assert categorize_item("Clean up repository whitespace", []) == "Chores / Misc"


def test_parse_semver():
    assert parse_semver("v1.0.9") == (1, 0, 9, 1, "")
    assert parse_semver("1.0.9") == (1, 0, 9, 1, "")
    assert parse_semver("v1.1.0-alpha.1") == (1, 1, 0, 0, "alpha.1")
    assert parse_semver("invalid_tag") is None


def test_determine_base_tag_override():
    curr = {
        "tag_name": "v1.0.9",
        "body": "Some body <!-- BASE_TAG: v1.0.7 --> with override",
        "prerelease": False,
    }
    base = determine_base_tag(curr, [curr], {"v1.0.7", "v1.0.9"})
    assert base == "v1.0.7"


def test_determine_base_tag_stable():
    releases = [
        {"tag_name": "v1.0.0", "prerelease": False, "body": ""},
        {"tag_name": "v1.0.1-rc1", "prerelease": True, "body": ""},
        {"tag_name": "v1.0.1", "prerelease": False, "body": ""},
        {"tag_name": "v1.0.2", "prerelease": False, "body": ""},
    ]
    curr = releases[3]  # v1.0.2
    base = determine_base_tag(curr, releases, {r["tag_name"] for r in releases})
    assert base == "v1.0.1"


def test_determine_base_tag_prerelease():
    releases = [
        {"tag_name": "v1.0.0", "prerelease": False, "body": ""},
        {"tag_name": "v1.0.1-rc1", "prerelease": True, "body": ""},
        {"tag_name": "v1.0.1-rc2", "prerelease": True, "body": ""},
    ]
    curr = releases[2]  # v1.0.1-rc2
    base = determine_base_tag(curr, releases, {r["tag_name"] for r in releases})
    assert base == "v1.0.1-rc1"


def test_determine_base_tag_semver_fallback():
    releases = [{"tag_name": "v1.0.5", "prerelease": False, "body": ""}]
    git_tags = {"v1.0.0", "v1.0.4", "v1.0.5", "v1.0.6"}
    base = determine_base_tag(releases[0], releases, git_tags)
    assert base == "v1.0.4"


def test_parse_existing_prs():
    raw_body = """
    ## What's Changed
    * Fix sensor polling crash by @carlkidcrypto in https://github.com/carlkidcrypto/purpleair-matterbridge/pull/10
    * Add AirQuality cluster by @carlkidcrypto in https://github.com/carlkidcrypto/purpleair-matterbridge/pull/11
    """
    git_commits = {
        "abcdef1": {
            "title": "Fix sensor polling crash (#10)",
            "files": ["src/purpleair-client.ts"],
        },
        "abcdef2": {
            "title": "Add AirQuality cluster (#11)",
            "files": ["src/purpleair-endpoint.ts"],
        },
    }
    prs, seen = parse_existing_prs(raw_body, git_commits)
    assert len(prs) == 2
    assert prs[0]["pr"] == "10"
    assert prs[0]["title"] == "Fix sensor polling crash"
    assert prs[0]["files"] == ["src/purpleair-client.ts"]
    assert "10" in seen
    assert "11" in seen


def test_synthesize_summary():
    cats: dict[str, list[str]] = {
        "Features / Enhancements": ["- Adds new feature (#1)"],
        "Bug Fixes": ["- Fixes bug (#2)"],
        "Runtime / Plugin": ["- Updates platform registration (#3)"],
        "Containers / Packaging": [],
        "Tests": [],
        "CI / Workflows": [],
        "Documentation": [],
        "Dependencies": [],
        "Chores / Misc": [],
    }
    s = synthesize_summary(cats, is_prerelease=False)
    assert "features and enhancements" in s
    assert "bug fixes" in s
    assert "purpleair-matterbridge" in s

    # With additional context
    s_extra = synthesize_summary(
        cats, is_prerelease=False, additional_context="Includes stability fix."
    )
    assert s_extra.endswith("Includes stability fix.")


def test_build_release_notes():
    release = {
        "id": 12345,
        "tag_name": "v1.0.9",
        "prerelease": False,
        "body": "* Add AirQuality cluster by @carlkidcrypto in https://github.com/carlkidcrypto/purpleair-matterbridge/pull/11",
    }
    base_tag = "v1.0.8"
    git_commits = {
        "commit1": {
            "title": "Add AirQuality cluster (#11)",
            "files": ["src/purpleair-endpoint.ts"],
        },
        "commit2": {
            "title": "Fix sensor polling crash (#12)",
            "files": ["src/purpleair-client.ts"],
        },
    }
    notes = build_release_notes(release, base_tag, git_commits)

    assert "Compared to: v1.0.8" in notes
    assert "npm install purpleair-matterbridge@1.0.9" in notes
    assert "docker pull carlkidcrypto/purpleair-matterbridge-images:1.0.9" in notes
    assert "https://www.npmjs.com/package/purpleair-matterbridge/v/1.0.9" in notes
    assert "## Features / Enhancements" in notes
    assert "## Bug Fixes" in notes
    assert (
        "**Full Changelog**: https://github.com/carlkidcrypto/purpleair-matterbridge/compare/v1.0.8...v1.0.9"
        in notes
    )
