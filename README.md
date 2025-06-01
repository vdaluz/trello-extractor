# Trello Board Extractor

A tool to extract and preserve Trello boards before account deletion, creating organized folder structures with markdown files and downloaded attachments.

## Features

- ✅ **Complete Board Extraction**: Cards, lists, metadata, and attachments
- ✅ **Authenticated Downloads**: Trello API integration for attachment access
- ✅ **Organized Structure**: Clean folder hierarchy with markdown files
- ✅ **Modular Architecture**: SOLID principles with separate class files
- ✅ **Multiple Auth Methods**: Config file, environment variables, or CLI args
- ✅ **Error Handling**: Graceful fallback when attachments fail
- ✅ **Rich Metadata**: Board info, labels, members, and timestamps

## Quick Start

### 1. Extract Without Attachments
```bash
ruby src/trello_extractor.rb exports/your-board.json
```

### 2. Setup Authentication (for attachments)
```bash
ruby src/trello_extractor.rb setup
```

### 3. Extract With Attachments
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

To download attachments, you need Trello API credentials:

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
│   │   └── attachments/       # Downloaded files
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
- **Attachments**: Links to downloaded files
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

### Attachments Fail with HTTP 401
- Run `ruby src/trello_extractor.rb setup` to configure authentication
- Verify your API key and token are correct
- Check that your token has read permissions

### Large Boards Take Time
- This is normal for boards with many cards/attachments
- The tool processes sequentially to avoid rate limits
- Progress is shown during extraction

### File Permission Errors
- Ensure you have write permissions to the output directory
- Check that the exports directory contains your JSON files

## Contributing

1. Follow SOLID principles
2. Keep classes focused and testable
3. Add error handling for edge cases
4. Update documentation for new features

## License

[Add your license here] 