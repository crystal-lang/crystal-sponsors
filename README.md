# Crystal-sponsors
Track sponsors information from different sources. These scripts are supposed to run weekly.

## Data files

The _history files keep information about transactions and changes along the time.
The <sponsorship_platform>.json aligns with the current structure the website uses to expose sponsor information.

## Open collective

API is straightforward, this keeps most of the fields from the /all.json endpoint and keep track on a transaction log

## Github

API is a bit opaque, there's is not transaction data, replaced that with recording the observed state once per month, which is sufficient to track contribution changes given the weekly cadence.

## Usage

Set your GitHub token in a `.env` file:

GITHUB_TOKEN=your_token_here

Then run:
```bash
export $(grep -v '^#' .env | xargs)
crystal run src/main_github.cr
crystal run src/main_opencollective.cr
```