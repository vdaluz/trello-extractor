# Trello Board Extractor

A tool to extract and preserve Trello boards, creating organized folder structures with markdown files and downloaded attachments.

## Folder Structure

```
trello-extractor/
├── exports/                    # Source JSON files from Trello export (gitignored)
├── extracted/                  # Converted boards output (gitignored)
├── src/                       # Tool source code
│   ├── trello_extractor.rb    # Main extractor class
│   └── lib/                   # Supporting classes
│       ├── card_markdown_builder.rb
│       ├── attachment_downloader.rb
│       ├── readme_builder.rb
│       └── metadata_builder.rb
├── Gemfile                    # Ruby dependencies
├── .gitignore                 # Git ignore rules
└── README.md                 # This file
```

## Naming Conventions

### Export Files (Input)
- Keep original Trello export names: `{board-id} - {board-name}.json`
- Example: `abc123XY - my-project-board.json`

### Extracted Folders (Output)
- Clean board names: Remove Trello ID prefix
- Lowercase with hyphens: `my-project-board`
- No special characters for filesystem compatibility
- Descriptive and web-friendly

### Generated Structure
Each extracted board creates:
```
extracted/{board-name}/
├── README.md                  # Board overview
├── lists/                     # Cards organized by list
│   ├── {list-name}/
│   │   ├── {card-name}.md
│   │   └── attachments/
├── attachments/               # All files organized by card
└── metadata/                  # Board configuration
    ├── board-info.json
    ├── labels.json
    └── members.json
```

## Usage

```bash
ruby src/trello_extractor.rb exports/board-export.json
```

## Architecture

The tool follows SOLID principles with separate classes for each responsibility:

- **`TrelloExtractor`**: Main orchestration and file operations
- **`CardMarkdownBuilder`**: Converts cards to markdown format
- **`AttachmentDownloader`**: Handles file downloads
- **`ReadmeBuilder`**: Generates board overview
- **`MetadataBuilder`**: Extracts board metadata

## Features

- ✅ Organized folder structure
- ✅ Markdown conversion for cards
- ✅ Attachment downloading
- ✅ Metadata preservation
- ✅ Modular architecture
- ✅ Error handling 