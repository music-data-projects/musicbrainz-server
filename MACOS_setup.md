# MusicBrainz Server Setup Guide for macOS

This guide documents the steps required to set up MusicBrainz Server on macOS, particularly when using PostgreSQL in Docker.

## Prerequisites

- macOS (tested on macOS Sequoia)
- Homebrew installed
- Docker running with PostgreSQL container
- Git repository cloned

## Overview

Setting up MusicBrainz Server on macOS requires several steps:

1. Install system dependencies via Homebrew
2. Configure Perl environment with local::lib
3. Install Perl dependencies
4. Configure database connection
5. Import database dump

## Step 1: Install Homebrew Dependencies

Install required packages:

```bash
# Install cpanminus (Perl package manager)
brew install cpanminus

# Install PostgreSQL client tools (for psql command)
brew install libpq
```

## Step 2: Set Up Perl Environment

Install and configure local::lib for managing Perl modules in your home directory:

```bash
# Install local::lib and initial dependencies
cpanm --local-lib=~/perl5 local::lib
eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)

# Add to your shell configuration
echo 'eval $( perl -Mlocal::lib )' >> ~/.zshrc
source ~/.zshrc
```

## Step 3: Install Perl Dependencies

Install all required Perl modules:

```bash
# Install MusicBrainz Server dependencies
cpanm --installdeps --notest .

# Install database drivers (with libpq support)
export LDFLAGS="-L/opt/homebrew/opt/libpq/lib"
export CPPFLAGS="-I/opt/homebrew/opt/libpq/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/libpq/lib/pkgconfig"

cpanm --local-lib=~/perl5 --force DBI
cpanm --local-lib=~/perl5 --force DBD::Pg
```

**Note**: The `--force` flag is needed because some tests may fail on macOS, but the modules work correctly.

## Step 4: Configure MusicBrainz Server

### 4.1 Create Configuration File

```bash
cp lib/DBDefs.pm.sample lib/DBDefs.pm
```

### 4.2 Edit Configuration

Edit `lib/DBDefs.pm` and configure the following:

1. **Set the replication type** (line ~113):
   ```perl
   sub REPLICATION_TYPE { RT_STANDALONE }
   ```

2. **Configure database connections** for Docker PostgreSQL:

   Update the `READWRITE` section:
   ```perl
   READWRITE => {
       database    => 'musicbrainz',
       username    => 'musicbrainz',
       password    => 'musicbrainz_password_change_me',
       host        => 'localhost',
       port        => '5432',
   },
   ```

   Update the `READONLY` section:
   ```perl
   READONLY => {
       database    => 'musicbrainz',
       username    => 'musicbrainz',
       password    => 'musicbrainz_password_change_me',
       host        => 'localhost',
       port        => '5432',
       read_only   => 1,
   },
   ```

   Update the `SYSTEM` section:
   ```perl
   SYSTEM => {
       database    => 'template1',
       username    => 'musicbrainz',
       password    => 'musicbrainz_password_change_me',
       host        => 'localhost',
       port        => '5432',
   },
   ```

   Update the `TEST` section:
   ```perl
   TEST => {
       database    => 'musicbrainz_test',
       username    => 'musicbrainz',
       password    => 'musicbrainz_password_change_me',
       host        => 'localhost',
       port        => '5432',
   },
   ```

**Important**: Replace the password with your actual PostgreSQL password from your Docker container.

### 4.3 Verify PostgreSQL Docker Container

Check your PostgreSQL container is running and get credentials:

```bash
# List running containers
docker ps | grep postgres

# Get container environment variables
docker inspect <container_name> --format='{{json .Config.Env}}' | python3 -m json.tool | grep POSTGRES
```

## Step 5: Download Database Dump

Download the sample database dump from MusicBrainz:

```bash
# Create a directory for dumps
mkdir -p ~/musicbrainz_dumps
cd ~/musicbrainz_dumps

# Download sample dump (published monthly)
# Visit: http://ftp.musicbrainz.org/pub/musicbrainz/data/sample/
# Or use wget/curl to download the latest sample
```

## Step 6: Import Database

### 6.1 Set Environment Variables

Before running the import, set the required environment variables:

```bash
# Add PostgreSQL client tools to PATH
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

# Add Perl local::lib to PATH
export PERL5LIB="$HOME/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"
export PERL_LOCAL_LIB_ROOT="$HOME/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"
export PATH="$HOME/perl5/bin:$PATH"
```

### 6.2 Run the Import

```bash
# If database already exists, drop it first
docker exec <postgres_container> psql -U musicbrainz -d postgres -c "DROP DATABASE IF EXISTS musicbrainz;"

# Run the import
./admin/InitDb.pl --createdb --import /path/to/mbdump-sample.tar.xz --echo
```

The import process will:
1. Create the database
2. Create schemas and tables
3. Load data from the dump files
4. Create indexes and constraints
5. Set up functions and triggers

This can take 5-15 minutes depending on your machine.

## Troubleshooting

### "Can't locate DBDefs.pm"
- Make sure you created `lib/DBDefs.pm` from the sample file
- Verify you're in the musicbrainz-server directory

### "psql: command not found"
- Install libpq: `brew install libpq`
- Add to PATH: `export PATH="/opt/homebrew/opt/libpq/bin:$PATH"`

### "Can't locate DBD/Pg.pm"
- Install the module: `cpanm --local-lib=~/perl5 --force DBD::Pg`
- Make sure environment variables are set (see `macos_set_env.sh`)

### "Database already exists"
- Drop the existing database first:
  ```bash
  docker exec <postgres_container> psql -U musicbrainz -d postgres -c "DROP DATABASE IF EXISTS musicbrainz;"
  ```

### Connection Refused
- Verify PostgreSQL container is running: `docker ps`
- Check port mapping is correct (5432:5432)
- Verify credentials in `lib/DBDefs.pm` match your container

## Automated Setup

For convenience, use the provided scripts:

```bash
# Run full setup (installs dependencies and Perl modules)
./macos_setup.sh

# Set environment variables (run this before each import)
source macos_set_env.sh
```

## Next Steps

After successful import:

1. Build static resources: `./script/compile_resources.sh`
2. Start the development server: `plackup -Ilib -r`
3. Access the server at: `http://localhost:5000`

## Additional Configuration

### Making Environment Variables Permanent

Add these lines to your `~/.zshrc`:

```bash
# PostgreSQL client tools
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

# Perl local::lib
eval $( perl -Mlocal::lib )
```

Then reload your shell: `source ~/.zshrc`

## References

- [MusicBrainz Server Installation Guide](INSTALL.md)
- [Database Download](https://musicbrainz.org/doc/MusicBrainz_Database/Download)
- [MusicBrainz Docker](https://github.com/metabrainz/musicbrainz-docker)
