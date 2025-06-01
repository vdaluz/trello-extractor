# frozen_string_literal: true

require 'net/http'
require 'uri'

class AttachmentDownloader
  def initialize(attachment, card, list_name, output_dir, downloaded_files, api_key = nil, token = nil)
    @attachment = attachment
    @card = card
    @list_name = list_name
    @output_dir = output_dir
    @downloaded_files = downloaded_files
    @api_key = api_key
    @token = token
  end

  def download
    return if already_downloaded?
    
    download_file
    @downloaded_files.add(attachment_path)
    puts "    📎 Downloaded: #{filename}"
  rescue => e
    puts "    ❌ Failed to download #{filename}: #{e.message}"
  end

  private

  def download_file
    uri = build_authenticated_uri
    
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      response = http.get(uri.request_uri)
      
      if response.code == '200'
        File.binwrite(attachment_path, response.body)
      else
        raise "HTTP #{response.code}"
      end
    end
  end

  def build_authenticated_uri
    uri = URI(@attachment['url'])
    
    if authenticated?
      # Add API authentication parameters
      query_params = []
      query_params << "key=#{@api_key}" if @api_key
      query_params << "token=#{@token}" if @token
      
      if query_params.any?
        separator = uri.query ? '&' : '?'
        uri.query = [uri.query, query_params.join('&')].compact.join('&')
      end
    end
    
    uri
  end

  def authenticated?
    @api_key && @token
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