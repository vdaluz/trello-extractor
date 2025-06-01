# frozen_string_literal: true

require 'date'

class ReadmeBuilder
  def initialize(board_data, active_lists, cards_by_list)
    @board = board_data
    @active_lists = active_lists
    @cards_by_list = cards_by_list
  end

  def build
    content = "# #{@board['name']}\n\n"
    content += description_section
    content += board_info_section
    content += lists_section
    content += labels_section
    content += footer
    content
  end

  private

  def description_section
    return '' unless @board['desc'] && !@board['desc'].empty?
    
    "#{@board['desc']}\n\n"
  end

  def board_info_section
    content = "## Board Information\n\n"
    content += "- **Created**: #{format_date(@board['dateLastActivity'])}\n"
    content += "- **URL**: #{@board['url'] || 'N/A'}\n"
    content += "- **Lists**: #{@active_lists.length}\n"
    content += "- **Cards**: #{@cards_by_list.values.sum(&:length)}\n\n"
    content
  end

  def lists_section
    content = "## Lists\n\n"
    @active_lists.each do |list|
      card_count = (@cards_by_list[list['id']] || []).length
      content += "- **#{list['name']}** (#{card_count} cards)\n"
    end
    content
  end

  def labels_section
    labels = @board['labelNames'] || {}
    return '' unless labels.any? { |_, name| name && !name.empty? }
    
    content = "\n## Labels\n\n"
    labels.each do |color, name|
      next if name.nil? || name.empty?
      content += "- **#{color}**: #{name}\n"
    end
    content
  end

  def footer
    "\n---\n*Extracted from Trello on #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}*\n"
  end

  def format_date(date_string)
    return 'N/A' unless date_string
    
    Date.parse(date_string).strftime('%Y-%m-%d')
  rescue
    date_string
  end
end 