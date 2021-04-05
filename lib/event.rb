# frozen_string_literal: true

require 'active_record'
require 'date'
require 'sqlite3'
require 'pry'

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

ActiveRecord::Schema.define do
  create_table :events do |t|
    t.datetime :starts_at, null: false
    t.datetime :ends_at, null: false
    t.string :kind, null: false
    t.boolean :weekly_recurring, null: false, default: false
  end
end

class Event < ActiveRecord::Base
  class << self
    def availabilities(start_date)
      hash = {}
      events = self.where(starts_at: (start_date.beginning_of_month..start_date.end_of_month))
      # Returns the next 7 days
      start_date.step(start_date + 6) do |date|
        hash[date.strftime('%Y-%m-%d')] ||= []
        events = events.select do |event|
          # We don't check the day if weekly recuring
          # but month and year have to match
          (event.weekly_recurring || (event.starts_at.day == date.day)) &&
          event.starts_at.month == date.month &&
          event.starts_at.year == date.year
        end
        appointments = events.select { |event| event.kind.to_sym == :appointment }
        openings = events.select { |event| event.kind.to_sym == :opening }
        openings.each do |opening|
          # Iterate over opening events by 30 minutes
          start_time = opening.starts_at
          end_time = opening.starts_at + 60 * 30
          (start_time.to_i..end_time.to_i).step(60 * 30) do |event_time|
            next if Time.at(event_time).utc == opening.ends_at
            next if appointments.any? do |appointment|
              (
              # Check if an appointment intersects with the 30min slot
              # 
                (appointment.starts_at..appointment.ends_at).include?(Time.at(event_time).utc) ||
                (appointment.starts_at..appointment.ends_at).include?(Time.at(event_time).utc + 30 * 60)
              ) &&
              # check if 30min slot corresponds to the end of the appointment
              (appointment.ends_at != Time.at(event_time).utc)
            end
            hash[date.strftime('%Y-%m-%d')] << Time.at(event_time).utc.strftime('%k:%M').strip
          end
        end
      end
      hash
    end
  end
end
