# -*- encoding : utf-8 -*-
#
#          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                  Version 2, December 2004
#
#  Copyright (C) 2004 Sam Hocevar
#  14 rue de Plaisance, 75014 Paris, France
#  Everyone is permitted to copy and distribute verbatim or modified
#  copies of this license document, and changing it is allowed as long
#  as the name is changed.
#  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#  0. You just DO WHAT THE FUCK YOU WANT TO.
#
#
#  David Hagege <david.hagege@gmail.com>
#

require 'exchanger'

# Monkey patch to be sure to have everything in UTC
module Exchanger
  class Field

    def value_from_xml(node)
      if type.respond_to?(:new_from_xml)
        type.new_from_xml(node)
      elsif type.is_a?(Array)
        node.children.map do |sub_node|
          sub_field.value_from_xml(sub_node)
        end
      elsif type == Boolean
        node.text == "true"
      elsif type == Integer
        node.text.to_i unless node.text.empty?
      elsif type == Time
        Time.xmlschema(node.text + 'Z') unless node.text.empty?
      else
        node.text
      end
    end

  end
end

module Exchangist
  class Exchangist

    def initialize(params = {})
      @endpoint = params[:endpoint]
      @username = params[:username]
      @password = params[:password]

      Exchanger.configure do |config|
        config.endpoint = @endpoint
        config.username = @username
        config.password = @password
        config.insecure_ssl = params[:insecure_ssl] || false
      end
    end

    def get_next_available_rooms
      res = []
      get_room_lists.map do |list|
        get_rooms(list.email_address).map do |room|
          if cal = get_calendar(email_address: room.email_address,
                          start_time: Date.today.to_time + 1,
                          end_time: ((Date.today + 1).to_time - 1),
                          time_zone: 'UTC')
            available_for = if cal.first
                              if cal.first.start_time - Time.now < 0
                                0
                              else
                                (cal.first.start_time - Time.now)
                              end
                            else
                              ((Date.today + 1).to_time - Time.now)
                            end
            res << {:list => list.name, :room => room.name, :cal => cal,
                    :email_address => room.email_address,
                    :available_for => available_for,
                    :available_for_pretty => seconds_to_units(available_for)}
          end
        end
      end
      res
    end

    def get_room_lists
      folder = Exchanger::GetRoomLists.run()
      folder.items
    end

    def get_rooms(room_list_mail)
      folder = Exchanger::GetRooms.run(:room_list_mail =>
                                       room_list_mail)
      folder.items
    end

    def get_calendar(params = {})
      Exchanger.configure do |config|
        config.endpoint = @endpoint
        config.username = @username
        config.password = @password
        config.insecure_ssl = true
      end

      folder =
        Exchanger::GetUserAvailability.run(email_address: params[:email_address],
                                           start_time: params[:start_time],
                                           end_time: params[:end_time],
                                          time_zone: params[:time_zone])
      folder.items
    end

    def book_meeting(params = {})
      meeting =
        Exchanger::Folder.find(:calendar)
                         .new_calendar_item
      meeting.subject = params[:subject]
      meeting.start = params[:start_time]
      meeting.end = params[:end_time]
      meeting.is_all_day_event = false
      meeting.location = params[:meeting_room_name]
      meetingroom =
        Exchanger::Attendee.new(:mailbox =>
                    Exchanger::Mailbox.search(params[:meeting_room_name]).first)
      meeting.required_attendees = [meetingroom]

      params[:required_attendees].map do |mail|
        meeting.required_attendees <<
          Exchanger::Attendee.new(:mailbox =>
                                  Exchanger::Mailbox.search(mail).first)
      end if params[:required_attendees]
      meeting.resources = [meetingroom]
      meeting.save
    end

    private
    def seconds_to_units(seconds)
      '%d hours, %d minutes' %
        [60,60].reverse.inject([seconds]) do |result, unitsize|
        result[0,0] = result.shift.divmod(unitsize)
        result
      end
    end


  end
end
