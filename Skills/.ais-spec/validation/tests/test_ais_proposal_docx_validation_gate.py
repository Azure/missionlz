from __future__ import annotations

import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[4]
SKILL_DIR = REPO_ROOT / "Skills" / "ais-proposal-docx"
GENERATOR = SKILL_DIR / "scripts" / "generate.py"
SKILL_MD = SKILL_DIR / "SKILL.md"

BYPASS_FLAG = "--skip-" + "validation"
BYPASS_DEST = "skip" + "_validation"
BYPASS_PHRASE = "skip " + "validation"


class ProposalDocxValidationGateTests(unittest.TestCase):
    def test_generator_does_not_expose_validation_bypass(self) -> None:
        source = GENERATOR.read_text(encoding="utf-8")

        self.assertNotIn(BYPASS_FLAG, source)
        self.assertNotIn(BYPASS_DEST, source)
        self.assertIn("validate_docx(output, strict=args.strict)", source)
        self.assertIn("Fix them before delivery", source)

    def test_skill_instructions_require_validation(self) -> None:
        instructions = SKILL_MD.read_text(encoding="utf-8")
        lower_instructions = instructions.lower()

        self.assertNotIn(BYPASS_FLAG, instructions)
        self.assertNotIn(BYPASS_PHRASE, lower_instructions)
        self.assertIn("Validation runs automatically after generation and must pass", instructions)
        self.assertIn("Tool Usage Declaration", instructions)
        self.assertIn("does not require MCP services", instructions)


if __name__ == "__main__":
    unittest.main()
