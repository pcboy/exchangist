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
      folder =
        Exchanger::GetUserAvailability.run(email_address: params[:email_address],
                                           start_time: params[:start_time],
                                           end_time: params[:end_time])
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
      meeting.resources = [meetingroom]
      meeting
    end

  end
end
