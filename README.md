# Crystal-sponsors
Track sponsors information from different sources. These scripts are supposed to run weekly.

## Data files

The _history files keep information about transactions and changes along the time.
The <sponsorship_platform>.json aligns with the current structure the website uses to expose sponsor information.

`bountysource.json` and `others.json` are maintained by hand (change them in a PR). `others.json` also accepts `overrides` entries that patch a sponsor from another source, and its amounts advance one monthly payment per elapsed month each time `main_export.cr` runs.

`main_export.cr` merges all the sources into the CSVs the website consumes: `sponsors.csv` and `sponsor_logos_{corporate,gold,silver}.csv`. The `logo` column only has a URL for sponsors paying $75 or more; the website downloads the logos.

## Open collective

API is straightforward, this keeps most of the fields from the /all.json endpoint and keep track on a transaction log

## Github

API is a bit opaque, there's is not transaction data, replaced that with recording the observed state once per month, which is sufficient to track contribution changes given the weekly cadence.

## Weekly flow

1. Every Monday the `weekly_sponsors_update` workflow runs the three scripts and opens a data PR.
2. After a person merges it, `notify-website.yml` tells `crystal-lang/crystal-website` (event `sponsors-updated`, with the merge commit).
3. The website downloads the CSVs at that commit and opens its own PR for review.

Nothing is merged automatically. GitHub can start scheduled runs hours late.

Secrets: `SPONSORS_PAT` (read GitHub Sponsors) and `WEBSITE_DISPATCH_TOKEN` (fine-grained token, Contents read/write on `crystal-website`, only used to notify it; when it expires the website must be run by hand).

## Usage

Set your GitHub token in a `.env` file:

GITHUB_TOKEN=your_token_here

Then run:
```bash
export $(grep -v '^#' .env | xargs)
crystal run src/main_github.cr
crystal run src/main_opencollective.cr
crystal run src/main_export.cr
```