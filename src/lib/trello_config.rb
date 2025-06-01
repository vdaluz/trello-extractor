# frozen_string_literal: true

require 'json'

class TrelloConfig
  CONFIG_FILE = '.trello_config.json'
  
  def self.load
    new.load_credentials
  end
  
  def load_credentials
    # Priority: 1. Environment variables, 2. Config file, 3. nil
    {
      api_key: ENV['TRELLO_API_KEY'] || config_file_value('api_key'),
      token: ENV['TRELLO_TOKEN'] || config_file_value('token')
    }
  end
  
  def self.create_config_file(api_key, token)
    config = {
      api_key: api_key,
      token: token,
      created_at: Time.now.iso8601
    }
    
    File.write(CONFIG_FILE, JSON.pretty_generate(config))
    puts "✅ Configuration saved to #{CONFIG_FILE}"
    puts "⚠️  Keep this file secure and don't commit it to version control!"
  end
  
  def self.config_exists?
    File.exist?(CONFIG_FILE)
  end
  
  private
  
  def config_file_value(key)
    return nil unless File.exist?(CONFIG_FILE)
    
    config = JSON.parse(File.read(CONFIG_FILE))
    config[key.to_s]
  rescue JSON::ParserError, Errno::ENOENT
    nil
  end
end 