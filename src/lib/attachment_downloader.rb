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
    
    puts "    🔍 Attempting: #{@attachment['name']} (#{format_size(@attachment['bytes'])})"
    
    success = try_download_methods
    
    if success
      @downloaded_files.add(attachment_path)
      puts "    📎 Downloaded: #{filename}"
      return true
    else
      # Still create a metadata file with download info
      create_attachment_info_file
      puts "    📋 Saved attachment info: #{filename} (download failed - see attachment_info.md)"
      return false
    end
  rescue => e
    puts "    ❌ Error processing #{filename}: #{e.message}"
    create_attachment_info_file
    return false
  end

  def attachment_path
    @attachment_path ||= File.join(
      @output_dir, 'lists', @list_name, 'attachments',
      "#{sanitize_filename(@card['name'])}_#{filename}"
    )
  end

  private

  def try_download_methods
    # Try API endpoint first since it's the most reliable method
    if authenticated?
      return true if try_api_endpoint
      return true if try_direct_download_with_auth
    end
    
    # Try direct URL without auth as last resort
    return true if try_direct_download_no_auth
    
    false
  end

  def try_direct_download_no_auth
    puts "    🌐 Trying direct download..." if ENV['DEBUG']
    
    uri = URI(@attachment['url'])
    
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      response = http.get(uri.request_uri)
      
      puts "    📡 Direct Response (no auth): #{response.code}" if ENV['DEBUG']
      
      if response.code == '200'
        File.binwrite(attachment_path, response.body)
        return true
      elsif response.code == '302' || response.code == '301'
        # Follow redirect
        return try_redirect(response['location']) if response['location']
      end
    end
    
    false
  rescue => e
    puts "    ⚠️  Direct download failed: #{e.message}" if ENV['DEBUG']
    false
  end

  def try_direct_download_with_auth
    puts "    🔑 Trying authenticated direct download..." if ENV['DEBUG']
    
    uri = URI(@attachment['url'])
    
    # Add query parameters
    query_params = ["key=#{@api_key}", "token=#{@token}"]
    separator = uri.query ? '&' : '?'
    uri.query = [uri.query, query_params.join('&')].compact.join('&')
    
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      response = http.get(uri.request_uri)
      
      puts "    📡 Auth Direct Response: #{response.code}" if ENV['DEBUG']
      
      if response.code == '200'
        File.binwrite(attachment_path, response.body)
        return true
      end
    end
    
    false
  rescue => e
    puts "    ⚠️  Authenticated direct download failed: #{e.message}" if ENV['DEBUG']
    false
  end

  def try_api_endpoint
    puts "    🔧 Trying via API endpoint..." if ENV['DEBUG']
    
    # This endpoint may not exist, but worth trying
    encoded_filename = URI.encode_www_form_component(@attachment['name'])
    api_url = "https://api.trello.com/1/cards/#{@card['id']}/attachments/#{@attachment['id']}/download/#{encoded_filename}"
    
    uri = URI(api_url)
    
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      request = Net::HTTP::Get.new(uri.request_uri)
      request['Authorization'] = "OAuth oauth_consumer_key=\"#{@api_key}\", oauth_token=\"#{@token}\""
      
      response = http.request(request)
      
      puts "    📡 API Response: #{response.code}" if ENV['DEBUG']
      
      if response.code == '200'
        File.binwrite(attachment_path, response.body)
        return true
      end
    end
    
    false
  rescue => e
    puts "    ⚠️  API endpoint failed: #{e.message}" if ENV['DEBUG']
    false
  end

  def try_redirect(location)
    return false unless location
    
    uri = URI(location)
    
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      response = http.get(uri.request_uri)
      
      if response.code == '200'
        File.binwrite(attachment_path, response.body)
        return true
      end
    end
    
    false
  rescue
    false
  end

  def create_attachment_info_file
    info_file = File.join(File.dirname(attachment_path), 'attachment_info.md')
    
    content = if File.exist?(info_file)
      File.read(info_file)
    else
      "# Attachment Download Information\n\n" \
      "**Note**: Some attachments could not be downloaded due to Trello API limitations.\n" \
      "You may need to download these manually from Trello while you have access.\n" \
      "All attachment metadata and direct URLs are preserved below for manual download.\n\n" \
      "## Failed Downloads\n\n"
    end
    
    content += "### #{@attachment['name']}\n"
    content += "- **Card**: #{@card['name']}\n"
    content += "- **Size**: #{format_size(@attachment['bytes'])}\n"
    content += "- **URL**: #{@attachment['url']}\n"
    content += "- **Type**: #{@attachment['mimeType'] || 'unknown'}\n"
    content += "- **Upload Date**: #{@attachment['date']}\n\n"
    
    File.write(info_file, content)
  end

  def format_size(bytes)
    return 'unknown' unless bytes.respond_to?(:to_i)
    
    size = bytes.to_i
    return "#{size} bytes" if size < 1024
    return "#{(size / 1024.0).round(1)} KB" if size < 1024 * 1024
    return "#{(size / (1024.0 * 1024)).round(1)} MB" if size < 1024 * 1024 * 1024
    "#{(size / (1024.0 * 1024 * 1024)).round(1)} GB"
  end

  def authenticated?
    @api_key && @token
  end

  def already_downloaded?
    @downloaded_files.include?(attachment_path)
  end

  def filename
    @filename ||= sanitize_filename(@attachment['name'])
  end

  def sanitize_filename(name)
    return 'unnamed' if name.nil? || name.empty?
    
    # Replace spaces with hyphens and remove problematic characters
    sanitized = name.gsub(/[<>:"\/\\|?*]/, '_').gsub(/\s+/, '-').strip
    sanitized = sanitized[0..97] + '...' if sanitized.length > 100
    sanitized.empty? ? 'unnamed' : sanitized
  end
end 