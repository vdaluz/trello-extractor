# frozen_string_literal: true

require 'net/http'
require 'uri'

class AttachmentDownloader
  def initialize(attachment, card, list_name, output_dir, downloaded_files)
    @attachment = attachment
    @card = card
    @list_name = list_name
    @output_dir = output_dir
    @downloaded_files = downloaded_files
  end

  def download
    return if already_downloaded?
    
    download_file
    @downloaded_files.add(attachment_path)
  rescue => e
    puts "Failed to download #{filename}: #{e.message}"
  end

  private

  def download_file
    uri = URI(@attachment['url'])
    
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      response = http.get(uri.path)
      
      if response.code == '200'
        File.binwrite(attachment_path, response.body)
      else
        raise "HTTP #{response.code}"
      end
    end
  end

  def already_downloaded?
    @downloaded_files.include?(attachment_path)
  end

  def attachment_path
    @attachment_path ||= File.join(
      @output_dir, 'lists', @list_name, 'attachments',
      "#{sanitize_filename(@card['name'])}_#{filename}"
    )
  end

  def filename
    @filename ||= sanitize_filename(@attachment['name'])
  end

  def sanitize_filename(name)
    return 'unnamed' if name.nil? || name.empty?
    
    sanitized = name.gsub(/[<>:"\/\\|?*]/, '_').strip
    sanitized = sanitized[0..97] + '...' if sanitized.length > 100
    sanitized.empty? ? 'unnamed' : sanitized
  end
end 