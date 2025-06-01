# frozen_string_literal: true

require 'date'
require 'uri'

class CardMarkdownBuilder
  def initialize(card, list, board_data, downloaded_attachments = {})
    @card = card
    @list = list
    @board_data = board_data
    @downloaded_attachments = downloaded_attachments
  end

  def build
    content = "# #{@card['name']}\n\n"
    content += basic_info
    content += description_section
    content += checklists_section
    content += attachments_section
    content += comments_section
    content
  end

  private

  def basic_info
    content = "**List**: #{@list['name']}\n"
    content += "**Created**: #{format_date(@card['dateLastActivity'])}\n"
    content += due_date_info if @card['due']
    content += labels_info if @card['labels']&.any?
    content + "\n"
  end

  def due_date_info
    status = @card['dueComplete'] ? '✅' : '❌'
    "**Due Date**: #{format_date(@card['due'])} #{status}\n"
  end

  def labels_info
    labels = @card['labels'].map { |label| "`#{label['name'] || label['color']}`" }
    "**Labels**: #{labels.join(', ')}\n"
  end

  def description_section
    return '' unless @card['desc'] && !@card['desc'].empty?
    
    "## Description\n\n#{@card['desc']}\n\n"
  end

  def checklists_section
    return '' unless @card['checklists']&.any?
    
    content = "## Checklists\n\n"
    @card['checklists'].each do |checklist|
      content += "### #{checklist['name']}\n\n"
      checklist['checkItems']&.each do |item|
        status = item['state'] == 'complete' ? '✅' : '❌'
        content += "- #{status} #{item['name']}\n"
      end
      content += "\n"
    end
    content
  end

  def attachments_section
    return '' unless @card['attachments']&.any?
    
    content = "## Attachments\n\n"
    @card['attachments'].each do |attachment|
      if @downloaded_attachments[attachment['id']]
        # Use relative path to the downloaded file with exact filename
        filename = File.basename(@downloaded_attachments[attachment['id']])
        relative_path = "attachments/#{filename}"
        
        # Use image syntax for image files, link syntax for others
        if image_file?(attachment['name'])
          content += "![#{attachment['name']}](#{relative_path})\n\n"
        else
          content += "- [#{attachment['name']}](#{relative_path})\n"
        end
      elsif attachment['url']
        # Use original URL for failed downloads
        content += "- [#{attachment['name']}](#{attachment['url']}) *(remote - download failed)*\n"
      end
    end
    content + "\n"
  end

  def comments_section
    comments = extract_comments
    return '' unless comments.any?
    
    content = "## Comments\n\n"
    comments.each do |comment|
      content += "**#{comment[:author]}** - #{comment[:date]}\n\n"
      content += "#{comment[:text]}\n\n---\n\n"
    end
    content
  end

  def extract_comments
    comments = []
    
    @board_data['actions']&.each do |action|
      next unless action['type'] == 'commentCard'
      next unless action.dig('data', 'card', 'id') == @card['id']
      
      comments << {
        author: action.dig('memberCreator', 'fullName') || 'Unknown',
        date: format_date(action['date']),
        text: action.dig('data', 'text') || ''
      }
    end
    
    comments.sort_by { |c| c[:date] }
  end

  def format_date(date_string)
    return 'N/A' unless date_string
    
    Date.parse(date_string).strftime('%Y-%m-%d')
  rescue
    date_string
  end

  def image_file?(filename)
    return false unless filename
    
    ext = File.extname(filename.downcase)
    ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.svg', '.webp'].include?(ext)
  end
end 