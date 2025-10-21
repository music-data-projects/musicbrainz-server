#!/bin/bash

# MusicBrainz Server Setup Script for macOS
# This script installs all dependencies and Perl modules needed to run MusicBrainz Server on macOS

set -e  # Exit on error

echo "=========================================="
echo "MusicBrainz Server macOS Setup"
echo "=========================================="
echo ""

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "Error: Homebrew is not installed."
    echo "Please install Homebrew first: https://brew.sh"
    exit 1
fi

# Check if we're in the musicbrainz-server directory
if [ ! -f "admin/InitDb.pl" ]; then
    echo "Error: This script must be run from the musicbrainz-server directory"
    exit 1
fi

echo "Step 1: Installing Homebrew dependencies..."
echo "-------------------------------------------"

# Install cpanminus (Perl package manager)
if ! command -v cpanm &> /dev/null; then
    echo "Installing cpanminus..."
    brew install cpanminus
else
    echo "cpanminus already installed"
fi

# Install PostgreSQL client tools
if ! brew list libpq &> /dev/null; then
    echo "Installing libpq (PostgreSQL client tools)..."
    brew install libpq
else
    echo "libpq already installed"
fi

echo ""
echo "Step 2: Setting up Perl environment..."
echo "---------------------------------------"

# Set up local::lib environment
export PERL5LIB="$HOME/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"
export PERL_LOCAL_LIB_ROOT="$HOME/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"
export PERL_MB_OPT="--install_base \"$HOME/perl5\""
export PERL_MM_OPT="INSTALL_BASE=$HOME/perl5"
export PATH="$HOME/perl5/bin${PATH:+:${PATH}}"

# Install local::lib if not already installed
if ! perl -Mlocal::lib -e 1 2>/dev/null; then
    echo "Installing local::lib..."
    cpanm --local-lib=~/perl5 local::lib
else
    echo "local::lib already installed"
fi

# Add local::lib to shell configuration if not already present
if ! grep -q "eval.*perl.*local::lib" ~/.zshrc 2>/dev/null; then
    echo "Adding local::lib to ~/.zshrc..."
    echo 'eval $( perl -Mlocal::lib )' >> ~/.zshrc
    echo "Added to ~/.zshrc (restart shell or run 'source ~/.zshrc' to activate)"
else
    echo "local::lib already configured in ~/.zshrc"
fi

echo ""
echo "Step 3: Installing MusicBrainz Perl dependencies..."
echo "---------------------------------------------------"

# Install main dependencies
echo "Installing main Perl dependencies (this may take 10-30 minutes)..."
cpanm --local-lib=~/perl5 --installdeps --notest .

echo ""
echo "Step 4: Installing database drivers..."
echo "---------------------------------------"

# Set up build environment for database drivers
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/libpq/lib"
export CPPFLAGS="-I/opt/homebrew/opt/libpq/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/libpq/lib/pkgconfig"

# Install DBI and DBD::Pg
echo "Installing DBI module..."
cpanm --local-lib=~/perl5 --force DBI

echo "Installing DBD::Pg module..."
cpanm --local-lib=~/perl5 --force DBD::Pg

# Verify installation
echo ""
echo "Step 5: Verifying installation..."
echo "----------------------------------"

if perl -MDBD::Pg -e "print \"DBD::Pg version: \$DBD::Pg::VERSION\n\"" 2>/dev/null; then
    echo "✓ DBD::Pg installed successfully"
else
    echo "✗ DBD::Pg installation failed"
    exit 1
fi

if perl -MString::ShellQuote -e "print \"String::ShellQuote found\n\"" 2>/dev/null; then
    echo "✓ String::ShellQuote installed successfully"
else
    echo "✗ String::ShellQuote installation failed"
    exit 1
fi

echo ""
echo "Step 6: Creating configuration file..."
echo "---------------------------------------"

if [ ! -f "lib/DBDefs.pm" ]; then
    echo "Creating lib/DBDefs.pm from sample..."
    cp lib/DBDefs.pm.sample lib/DBDefs.pm
    echo "✓ Created lib/DBDefs.pm"
    echo ""
    echo "IMPORTANT: You need to edit lib/DBDefs.pm to configure your database connection!"
    echo "See MACOS_setup.md for detailed configuration instructions."
else
    echo "lib/DBDefs.pm already exists (skipping)"
fi

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Edit lib/DBDefs.pm to configure your database connection"
echo "   - Set REPLICATION_TYPE to RT_STANDALONE"
echo "   - Configure database host, port, username, and password"
echo ""
echo "2. Before running database import, set environment variables:"
echo "   source macos_set_env.sh"
echo ""
echo "3. Import database dump:"
echo "   ./admin/InitDb.pl --createdb --import /path/to/mbdump-sample.tar.xz --echo"
echo ""
echo "See MACOS_setup.md for complete documentation."
echo ""
