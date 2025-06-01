#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'set'
require_relative 'lib/card_markdown_builder'
require_relative 'lib/attachment_downloader'
require_relative 'lib/readme_builder'
require_relative 'lib/metadata_builder'

class TrelloExtractor
  attr_reader :json_file, :output_dir, :board_data

  def initialize(json_file, output_dir = nil)
    @json_file = json_file
    @output_dir = output_dir || default_output_dir
    @board_data = nil
    @lists_by_id = {}
    @cards_by_list = {}
    @downloaded_files = Set.new
  end

  def extract!
    load_board_data
    create_structure
    extract_content
    save_metadata
    
    puts "✅ Extraction complete! #{card_count} cards in #{@output_dir}"
  end

  private

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
    card_path = File.join(lists_dir, list_name, "#{sanitize_filename(card['name'])}.md")
    File.write(card_path, build_card_markdown(card, list))
    
    download_attachments(card, list_name) if has_attachments?(card)
  end

  def build_card_markdown(card, list)
    content = CardMarkdownBuilder.new(card, list, @board_data).build
    content += extraction_footer
    content
  end

  def download_attachments(card, list_name)
    card['attachments'].each do |attachment|
      next unless attachment['url'] && attachment['isUpload']
      
      AttachmentDownloader.new(attachment, card, list_name, @output_dir, @downloaded_files).download
    end
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

if __FILE__ == $0
  if ARGV.empty?
    puts "Usage: ruby #{$0} <json_file> [output_dir]"
    exit 1
  end

  begin
    extractor = TrelloExtractor.new(ARGV[0], ARGV[1])
    extractor.extract!
  rescue => e
    puts "Error: #{e.message}"
    exit 1
  end
end 