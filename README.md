# phpcs-ctrf-reporter

A [PHP_CodeSniffer](https://github.com/PHPCSStandards/PHP_CodeSniffer) reporter that emits results in the [Common Test Report Format (CTRF)](https://ctrf.io/) — an open JSON standard for test results consumed by GitHub Actions summaries, dashboards, and other CI tooling.

## Why

PHPCS ships with JUnit XML output, but JUnit XML is older, has looser semantics, and isn't as well-supported by modern CI surfaces. CTRF is a tighter JSON schema that's validatable end-to-end (`ctrf-cli validate`) and feeds into the same reporting pipelines as test runs.

## Install

```bash
composer require --dev luc45/phpcs-ctrf-reporter
```

## Usage

```bash
vendor/bin/phpcs --report='Luc45\PhpcsCtrf\Reports\Ctrf' src/
```

Or write to a file:

```bash
vendor/bin/phpcs --report-Luc45\\PhpcsCtrf\\Reports\\Ctrf=report.json src/
```

(Escape the backslashes in the report flag according to your shell.)

## Mapping

| PHPCS finding              | CTRF test status |
| -------------------------- | ---------------- |
| ERROR violation            | `failed`         |
| WARNING violation          | `other`          |
| Clean file (no violations) | `passed`         |

PHPCS-native metadata (sniff source, severity, fixability, column) is preserved via CTRF's `rawStatus`, `tags`, and `extra` extension fields.

## Example output

Given a fixture with one violation, the reporter emits:

```json
{
    "reportFormat": "CTRF",
    "specVersion": "1.0.0",
    "reportId": "c236c666-f286-457f-82da-b5074eaec7ec",
    "timestamp": "2026-04-28T13:26:26Z",
    "generatedBy": "PHP_CodeSniffer 4.0.2",
    "results": {
        "tool": { "name": "PHP_CodeSniffer", "version": "4.0.2" },
        "summary": {
            "tests": 1, "passed": 0, "failed": 1,
            "skipped": 0, "pending": 0, "other": 0,
            "suites": 1,
            "start": 1777382786761, "stop": 1777382786761, "duration": 0,
            "extra": { "fixable": 1 }
        },
        "tests": [
            {
                "name": "Squiz.Functions.MultiLineFunctionDeclaration.BraceOnSameLine at example.php (7:34)",
                "status": "failed",
                "message": "Opening brace should be on a new line",
                "filePath": "example.php",
                "line": 7,
                "rawStatus": "ERROR",
                "type": "lint",
                "tags": ["ERROR", "fixable"],
                "extra": {
                    "column": 34,
                    "severity": 5,
                    "fixable": true,
                    "source": "Squiz.Functions.MultiLineFunctionDeclaration.BraceOnSameLine"
                }
            }
        ]
    }
}
```

## Validation

Output passes both `ctrf-cli validate` and the stricter `ctrf-cli validate-strict` (which enforces `additionalProperties: false`):

```bash
npx --package=ctrf-cli@latest -- ctrf-cli validate report.json
npx --package=ctrf-cli@latest -- ctrf-cli validate-strict report.json
```

## Testing

CI runs the reporter through PHPCS's own test infrastructure: every commit clones the latest `4.x` branch of [PHPCSStandards/PHP_CodeSniffer](https://github.com/PHPCSStandards/PHP_CodeSniffer), injects this package's reporter and tests via [`bin/inject-into-phpcs.sh`](bin/inject-into-phpcs.sh), and runs PHPCS's full PHPUnit + bashunit suite (4,000+ tests) against the modified tree on PHP 7.2 → 8.5.

This means the reporter is exercised in the exact harness it would face if merged into PHPCS itself, and any breaking change in PHPCS's API is caught the day it lands upstream — not when a user reports a bug.

To reproduce locally:

```bash
git clone https://github.com/PHPCSStandards/PHP_CodeSniffer.git phpcs
(cd phpcs && composer install)
./bin/inject-into-phpcs.sh phpcs
(cd phpcs && ./vendor/bin/phpunit)
```

## Compatibility

- Requires PHP 7.2+
- Requires PHP_CodeSniffer 4.x

## License

BSD-3-Clause — see [LICENSE](LICENSE).
