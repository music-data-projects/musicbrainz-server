#!/bin/bash

# MusicBrainz Server Environment Setup for macOS
# This script sets up the required environment variables for running MusicBrainz Server tools
#
# Usage:
#   source macos_set_env.sh
#
# Note: This script must be sourced (not executed) to set variables in your current shell

# Add PostgreSQL client tools to PATH
# (libpq is keg-only in Homebrew, so it's not in PATH by default)
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

# Set up Perl local::lib environment
# This allows Perl to find modules installed in ~/perl5
export PERL5LIB="$HOME/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"
export PERL_LOCAL_LIB_ROOT="$HOME/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"
export PERL_MB_OPT="--install_base \"$HOME/perl5\""
export PERL_MM_OPT="INSTALL_BASE=$HOME/perl5"
export PATH="$HOME/perl5/bin:$PATH"

# Add PostgreSQL build flags (needed for compiling Perl modules)
export LDFLAGS="-L/opt/homebrew/opt/libpq/lib"
export CPPFLAGS="-I/opt/homebrew/opt/libpq/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/libpq/lib/pkgconfig"

# Print confirmation
echo "Environment variables set:"
echo "  PATH: PostgreSQL client tools and Perl modules added"
echo "  PERL5LIB: $PERL5LIB"
echo "  PERL_LOCAL_LIB_ROOT: $PERL_LOCAL_LIB_ROOT"
echo ""
echo "You can now run MusicBrainz Server commands, such as:"
echo "  ./admin/InitDb.pl --createdb --import /path/to/dump.tar.xz"
echo "  plackup -Ilib -r"
echo ""

# Verify key commands are available
if command -v psql &> /dev/null; then
    echo "✓ psql is available ($(psql --version | head -1))"
else
    echo "✗ psql not found - PostgreSQL client tools may not be installed correctly"
fi

if perl -MDBD::Pg -e 1 2>/dev/null; then
    echo "✓ DBD::Pg Perl module is available"
else
    echo "✗ DBD::Pg not found - run macos_setup.sh to install Perl dependencies"
fi

echo ""
