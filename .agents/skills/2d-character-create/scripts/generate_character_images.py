#!/usr/bin/env python3
"""Documented placeholder for non-normal generation fallback.

Normal visual generation must use $imagegen. This script intentionally does not synthesize
production character art. It exists so the workflow has an explicit place to document any
future secondary fallback without silently fabricating row strips.
"""
from __future__ import annotations

raise SystemExit(
    "Normal path is $imagegen only. Do not fabricate character visuals locally. "
    "Use this skill's prepare/record/extract/compose scripts around real generated outputs."
)
