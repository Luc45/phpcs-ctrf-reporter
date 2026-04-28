#!/usr/bin/env bash
#
# Inject this package's reporter and tests into a PHPCS clone, rewriting
# namespaces to PHPCS-internal form so PHPCS's own PHPUnit + bashunit harness
# can run them as if the reporter were a built-in.
#
# Usage:
#   bin/inject-into-phpcs.sh /path/to/phpcs-clone
#
# After injection, run PHPCS's tests from the clone:
#   cd /path/to/phpcs-clone && composer install && composer test

set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <path-to-phpcs-clone>" >&2
  exit 1
fi

PHPCS_DIR="$(cd "$1" && pwd)"
PKG_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if [ ! -d "$PHPCS_DIR/src/Reports" ]; then
  echo "Not a PHPCS clone (missing src/Reports/): $PHPCS_DIR" >&2
  exit 1
fi
if [ ! -d "$PHPCS_DIR/tests/Core" ]; then
  echo "Not a PHPCS clone (missing tests/Core/): $PHPCS_DIR" >&2
  exit 1
fi

# Rewrite namespaces from this package's standalone form to PHPCS-internal form.
# The reporter class body is otherwise identical; only the namespace declaration,
# `use` import in the test, and the `@covers` annotation differ.
rewrite() {
  sed \
    -e 's|Luc45\\PhpcsCtrf\\Reports\\Ctrf|PHP_CodeSniffer\\Reports\\Ctrf|g' \
    -e 's|namespace Luc45\\PhpcsCtrf\\Reports|namespace PHP_CodeSniffer\\Reports|g' \
    -e 's|namespace Luc45\\PhpcsCtrf\\Tests|namespace PHP_CodeSniffer\\Tests\\Core\\Reports|g' \
    "$1"
}

# 1. Reporter source.
rewrite "$PKG_DIR/src/Reports/Ctrf.php" > "$PHPCS_DIR/src/Reports/Ctrf.php"

# 2. PHPUnit test (lives under tests/Core/Reports/, parallel to PHPCS's existing tests/Core/Reporter/).
mkdir -p "$PHPCS_DIR/tests/Core/Reports"
rewrite "$PKG_DIR/tests/CtrfTest.php" > "$PHPCS_DIR/tests/Core/Reports/CtrfTest.php"

# 3. Bash test for PHPCS's bashunit harness (uses --report=ctrf, the PHPCS shorthand
# for the now-injected PHP_CodeSniffer\Reports\Ctrf class).
cp "$PKG_DIR/tests/ctrf_test.sh" "$PHPCS_DIR/tests/EndToEndBash/ctrf_test.sh"

echo "Injected into $PHPCS_DIR:"
echo "  $PHPCS_DIR/src/Reports/Ctrf.php"
echo "  $PHPCS_DIR/tests/Core/Reports/CtrfTest.php"
echo "  $PHPCS_DIR/tests/EndToEndBash/ctrf_test.sh"
