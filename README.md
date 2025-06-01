# Trello Board Extractor

A tool to extract and preserve Trello boards, creating organized folder structures with markdown files and comprehensive metadata preservation.

## Features

- ✅ **Complete Board Extraction**: Cards, lists, metadata, and attachments
- ✅ **Authenticated Downloads**: Trello API integration for attachment access
- ✅ **Organized Structure**: Clean folder hierarchy with markdown files
- ✅ **Modular Architecture**: SOLID principles with separate class files
- ✅ **Multiple Auth Methods**: Config file, environment variables, or CLI args
- ✅ **Error Handling**: Graceful fallback with detailed attachment information
- ✅ **Rich Metadata**: Board info, labels, members, and timestamps

## Attachment Downloads

**✅ Working**: Attachment downloads work reliably when you provide valid Trello API credentials. The tool will:

1. **Attempt multiple download methods** for each attachment
2. **Use the most reliable API endpoint** with OAuth authentication
3. **Download files with original names and metadata**
4. **Create fallback info files** only if downloads fail
5. **Continue processing** all other board content normally

**Setup Required**: You'll need to set up Trello API credentials (see Authentication Setup below) for attachment downloads to work.

## Quick Start

### 1. Extract Without Authentication (no attachments)
```bash
ruby src/trello_extractor.rb exports/your-board.json
```

### 2. Setup Authentication (recommended - enables attachment downloads)
```bash
ruby src/trello_extractor.rb setup
```

### 3. Extract With Authentication (includes attachments)
```bash
ruby src/trello_extractor.rb exports/your-board.json
```

## Installation

No external dependencies required! Uses only Ruby standard library.

```bash
git clone <repository>
cd trello-extractor
ruby src/trello_extractor.rb setup  # Optional: for attachment downloads
```

## Authentication Setup

To attempt attachment downloads, you need Trello API credentials:

### Option 1: Interactive Setup (Recommended)
```bash
ruby src/trello_extractor.rb setup
```
Follow the prompts to enter your API key and token.

### Option 2: Environment Variables
```bash
export TRELLO_API_KEY="your_api_key_here"
export TRELLO_TOKEN="your_token_here"
```

### Option 3: Command Line
```bash
ruby src/trello_extractor.rb exports/board.json extracted/board YOUR_API_KEY YOUR_TOKEN
```

### Getting API Credentials
1. Visit: https://trello.com/app-key
2. Copy your **API Key**
3. Click **"Token"** to generate a read-only token
4. Use these in the setup command

## Usage

```bash
# Show help
ruby src/trello_extractor.rb

# Setup authentication
ruby src/trello_extractor.rb setup

# Extract board (basic)
ruby src/trello_extractor.rb exports/board-export.json

# Extract to specific directory
ruby src/trello_extractor.rb exports/board-export.json extracted/my-board

# Extract with inline credentials
ruby src/trello_extractor.rb exports/board-export.json extracted/my-board API_KEY TOKEN
```

## Exporting from Trello

To get the JSON file that this tool processes:

1. Open your Trello board
2. Go to **Board Menu** → **More** → **Print and Export** → **Export as JSON**
3. Save the downloaded JSON file to the `exports/` directory
4. Run the extractor on that file

## Project Structure

```
trello-extractor/
├── exports/                    # Source JSON files from Trello export (gitignored)
├── extracted/                  # Converted boards output (gitignored)
├── src/                       # Tool source code
│   ├── trello_extractor.rb    # Main extractor class
│   └── lib/                   # Supporting classes
│       ├── card_markdown_builder.rb    # Card → Markdown conversion
│       ├── attachment_downloader.rb    # Authenticated file downloads
│       ├── readme_builder.rb          # Board README generation
│       ├── metadata_builder.rb        # Metadata extraction
│       └── trello_config.rb           # Configuration management
├── Gemfile                    # Ruby dependencies
├── .gitignore                 # Git ignore rules
├── .trello_config.json        # API credentials (gitignored)
└── README.md                 # This file
```

## Output Structure

Each extracted board creates:
```
extracted/{board-name}/
├── README.md                  # Board overview with stats
├── lists/                     # Cards organized by list
│   ├── {list-name}/
│   │   ├── {card-name}.md     # Individual card files
│   │   └── attachments/       # Downloaded files (when successful)
├── attachments/               # Global attachments directory
└── metadata/                  # Board configuration
    ├── board-info.json        # Board details
    ├── labels.json            # Label definitions
    └── members.json           # Member information
```

## Card Markdown Format

Each card is converted to markdown with:
- **Header**: Card name
- **Metadata**: List, creation date, due date, labels
- **Description**: Full card description
- **Checklists**: With completion status
- **Attachments**: Links to downloaded files or URLs when download fails
- **Comments**: Chronological comment history

## Architecture

The tool follows SOLID principles with separate classes for each responsibility:

- **`TrelloExtractor`**: Main orchestration and file operations
- **`CardMarkdownBuilder`**: Converts cards to markdown format
- **`AttachmentDownloader`**: Handles authenticated file downloads
- **`ReadmeBuilder`**: Generates board overview
- **`MetadataBuilder`**: Extracts board metadata
- **`TrelloConfig`**: Manages API credentials

## Security

- ✅ **API credentials gitignored** - Never committed to version control
- ✅ **Read-only tokens** - Minimal permissions required
- ✅ **Multiple auth methods** - Choose what works for you
- ✅ **Graceful fallback** - Works without authentication

## Credential Priority

1. **Command line arguments** (highest priority)
2. **Environment variables** (`TRELLO_API_KEY`, `TRELLO_TOKEN`)
3. **Configuration file** (`.trello_config.json`)

## Troubleshooting

### Attachments Not Downloading
If attachments fail to download:
- Ensure you've set up authentication with `ruby src/trello_extractor.rb setup`
- Verify your API key and token are correct at https://trello.com/app-key
- Check that your token has read permissions
- The tool will create `attachment_info.md` files with URLs for manual download if needed

### Authentication Setup Issues
- Run `ruby src/trello_extractor.rb setup` to configure credentials interactively
- Verify your API key and token are correct at https://trello.com/app-key
- Check that your token has read permissions

### Large Boards Take Time
- This is normal for boards with many cards/attachments
- The tool processes sequentially to avoid rate limits
- Progress is shown during extraction

### File Permission Errors
- Ensure you have write permissions to the output directory
- Check that the exports directory contains your JSON files

### Manual Attachment Download
If automatic download fails for specific attachments:
1. Check the `attachment_info.md` files in each list's attachments folder
2. Copy the URLs from these files
3. Manually download attachments while logged into Trello
4. Save them to the appropriate attachments folders

## Use Cases

- **Board Archival**: Preserve project history and documentation
- **Data Migration**: Move content between project management tools
- **Backup Creation**: Create local copies of important boards
- **Documentation**: Convert Trello boards to readable markdown format
- **Analysis**: Extract data for reporting or analysis

## Contributing

1. Follow SOLID principles
2. Keep classes focused and testable
3. Add error handling for edge cases
4. Update documentation for new features

