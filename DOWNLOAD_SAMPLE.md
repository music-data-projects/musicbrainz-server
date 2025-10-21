# Downloading MusicBrainz Sample Database

## Sample Database URL

**Main URL**: https://data.metabrainz.org/pub/musicbrainz/data/sample/

The sample database is published monthly (around the 1st of each month).

## Download Methods

### Option 1: Direct Download

Visit https://data.metabrainz.org/pub/musicbrainz/data/sample/ and download the latest `mbdump-sample.tar.xz` file.

Example with `wget`:

```bash
mkdir -p ~/musicbrainz_dumps
cd ~/musicbrainz_dumps

# Replace date with the latest available
wget https://data.metabrainz.org/pub/musicbrainz/data/sample/20251001-000001_sample/mbdump-sample.tar.xz
```

### Option 2: Recursive Download (Entire Directory)

Download the complete sample directory including all files:

```bash
mkdir -p ~/musicbrainz_dumps
cd ~/musicbrainz_dumps

# Replace date with the latest available
wget -r -np -nH --cut-dirs=4 -R "index.html*" \
  https://ftp.musicbrainz.org/pub/musicbrainz/data/sample/20251001-000001/
```

## Verify Download (Optional)

```bash
# Download checksums
wget https://data.metabrainz.org/pub/musicbrainz/data/sample/20251001-000001_sample/MD5SUMS

# Verify
md5sum -c MD5SUMS
```

## Import the Database

After downloading:

```bash
# Set environment variables
source macos_set_env.sh

# Import
./admin/InitDb.pl --createdb --import ~/musicbrainz_dumps/20251001-000001_sample/mbdump-sample.tar.xz --echo
```

## File Size

- **Compressed**: ~380-400 MB
- **Database after import**: ~3-4 GB

## Resources

- [MusicBrainz Database Download Documentation](https://musicbrainz.org/doc/MusicBrainz_Database/Download)
- [MACOS_setup.md](MACOS_setup.md) - Setup guide
