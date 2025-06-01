# frozen_string_literal: true

class MetadataBuilder
  def initialize(board_data, list_count, card_count)
    @board = board_data
    @list_count = list_count
    @card_count = card_count
  end

  def build
    {
      'board-info.json' => board_info,
      'labels.json' => labels,
      'members.json' => members
    }
  end

  private

  def board_info
    {
      id: @board['id'],
      name: @board['name'],
      description: @board['desc'],
      url: @board['url'],
      created: @board['dateLastActivity'],
      lists_count: @list_count,
      cards_count: @card_count
    }
  end

  def labels
    @board['labelNames'] || {}
  end

  def members
    @board['members']&.map do |member|
      {
        id: member['id'],
        username: member['username'],
        fullName: member['fullName']
      }
    end || []
  end
end 