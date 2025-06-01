#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'set'
require_relative 'lib/card_markdown_builder'
require_relative 'lib/attachment_downloader'
require_relative 'lib/readme_builder'
require_relative 'lib/metadata_builder'
require_relative 'lib/trello_config'

class TrelloExtractor
  attr_reader :json_file, :output_dir, :board_data

  def initialize(json_file, output_dir = nil, api_key = nil, token = nil)
    @json_file = json_file
    @output_dir = output_dir || default_output_dir
    @board_data = nil
    @lists_by_id = {}
    @cards_by_list = {}
    @downloaded_files = Set.new
    
    # Load credentials: CLI args > env vars > config file
    credentials = TrelloConfig.load
    @api_key = api_key || credentials[:api_key]
    @token = token || credentials[:token]
  end

  def extract!
    load_board_data
    create_structure
    extract_content
    save_metadata
    
    auth_status = authenticated? ? " (authenticated)" : " (no auth - attachments may fail)"
    puts "✅ Extraction complete! #{card_count} cards in #{@output_dir}#{auth_status}"
  end

  private

  def authenticated?
    @api_key && @token
  end

  def load_board_data
    raise "JSON file not found: #{@json_file}" unless File.exist?(@json_file)
    
    @board_data = JSON.parse(File.read(@json_file))
    build_lookups
  rescue JSON::ParserError => e
    raise "Invalid JSON: #{e.message}"
  end

  def build_lookups
    @board_data['lists']&.each { |list| @lists_by_id[list['id']] = list }
    
    @board_data['cards']&.each do |card|
      next if card['closed']
      
      list_id = card['idList']
      @cards_by_list[list_id] ||= []
      @cards_by_list[list_id] << card
    end
  end

  def create_structure
    FileUtils.mkdir_p([@output_dir, lists_dir, attachments_dir, metadata_dir])
    
    active_lists.each do |list|
      list_name = sanitize_filename(list['name'])
      FileUtils.mkdir_p([
        File.join(lists_dir, list_name),
        File.join(lists_dir, list_name, 'attachments')
      ])
    end
  end

  def extract_content
    File.write(readme_path, build_readme)
    
    active_lists.each do |list|
      extract_list_cards(list)
    end
  end

  def extract_list_cards(list)
    list_name = sanitize_filename(list['name'])
    cards = @cards_by_list[list['id']] || []
    
    cards.each do |card|
      extract_card(card, list, list_name)
    end
  end

  def extract_card(card, list, list_name)
    # Download attachments first to know which ones succeeded
    downloaded_attachments = download_attachments(card, list_name) if has_attachments?(card)
    
    # Build markdown with knowledge of downloaded files
    card_path = File.join(lists_dir, list_name, "#{sanitize_filename(card['name'])}.md")
    File.write(card_path, build_card_markdown(card, list, downloaded_attachments || {}))
  end

  def build_card_markdown(card, list, downloaded_attachments = {})
    content = CardMarkdownBuilder.new(card, list, @board_data, downloaded_attachments).build
    content += extraction_footer
    content
  end

  def download_attachments(card, list_name)
    downloaded_attachments = {}
    
    card['attachments'].each do |attachment|
      next unless attachment['url'] && attachment['isUpload']
      
      downloader = AttachmentDownloader.new(
        attachment, card, list_name, @output_dir, @downloaded_files, @api_key, @token
      )
      
      success = downloader.download
      if success
        # Store the local path for this attachment
        downloaded_attachments[attachment['id']] = downloader.attachment_path
      end
    end
    
    downloaded_attachments
  end

  def save_metadata
    metadata = MetadataBuilder.new(@board_data, list_count, card_count).build
    
    metadata.each do |filename, data|
      File.write(File.join(metadata_dir, filename), JSON.pretty_generate(data))
    end
  end

  def build_readme
    ReadmeBuilder.new(@board_data, active_lists, @cards_by_list).build
  end

  def default_output_dir
    base_name = File.basename(@json_file, '.json')
    clean_name = base_name.gsub(/^[a-zA-Z0-9]+ - /, '').downcase.tr(' ', '-')
    File.join('extracted', clean_name)
  end

  def sanitize_filename(name)
    return 'unnamed' if name.nil? || name.empty?
    
    sanitized = name.gsub(/[<>:"\/\\|?*]/, '_').strip
    sanitized = sanitized[0..97] + '...' if sanitized.length > 100
    sanitized.empty? ? 'unnamed' : sanitized
  end

  def active_lists
    @board_data['lists']&.reject { |list| list['closed'] } || []
  end

  def list_count
    active_lists.length
  end

  def card_count
    @cards_by_list.values.sum(&:length)
  end

  def has_attachments?(card)
    card['attachments']&.any?
  end

  def lists_dir
    File.join(@output_dir, 'lists')
  end

  def attachments_dir
    File.join(@output_dir, 'attachments')
  end

  def metadata_dir
    File.join(@output_dir, 'metadata')
  end

  def readme_path
    File.join(@output_dir, 'README.md')
  end

  def extraction_footer
    "*Extracted from Trello on #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}*\n"
  end
end

def setup_credentials
  puts "🔧 Trello API Setup"
  puts "==================="
  puts
  puts "To download attachments, you need Trello API credentials:"
  puts "1. Visit: https://trello.com/app-key"
  puts "2. Copy your API key"
  puts "3. Click 'Token' to generate a read-only token"
  puts
  
  print "Enter your API key: "
  api_key = STDIN.gets.chomp.strip
  
  print "Enter your token: "
  token = STDIN.gets.chomp.strip
  
  if api_key.empty? || token.empty?
    puts "❌ Both API key and token are required"
    exit 1
  end
  
  TrelloConfig.create_config_file(api_key, token)
  puts
  puts "🎉 Setup complete! You can now extract boards with attachment downloads."
end

if __FILE__ == $0
  if ARGV.empty?
    puts <<~USAGE
      Trello Board Extractor
      ======================
      
      Usage: 
        ruby #{$0} <json_file> [output_dir] [api_key] [token]
        ruby #{$0} setup
      
      Commands:
        setup       - Configure Trello API credentials for attachment downloads
      
      Arguments:
        json_file   - Path to Trello JSON export file
        output_dir  - Optional: Output directory (default: extracted/<board-name>)
        api_key     - Optional: Trello API key (overrides config)
        token       - Optional: Trello token (overrides config)
      
      Examples:
        ruby #{$0} setup
        ruby #{$0} exports/board.json
        ruby #{$0} exports/board.json extracted/my-board
        ruby #{$0} exports/board.json extracted/my-board YOUR_API_KEY YOUR_TOKEN
      
      Credential Priority:
        1. Command line arguments
        2. Environment variables (TRELLO_API_KEY, TRELLO_TOKEN)
        3. Configuration file (.trello_config.json)
    USAGE
    exit 1
  end

  if ARGV[0] == 'setup'
    setup_credentials
    exit 0
  end

  begin
    extractor = TrelloExtractor.new(ARGV[0], ARGV[1], ARGV[2], ARGV[3])
    extractor.extract!
  rescue => e
    puts "Error: #{e.message}"
    exit 1
  end
end 