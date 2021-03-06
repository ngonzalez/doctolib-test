# frozen_string_literal: true

require 'minitest/autorun'
require 'date'

require_relative '../lib/event'

describe Event do
  before { Event.delete_all }

  describe 'skeleton' do
    before do
      @start_date = Date.new(2020, 1, 1)

      @availabilities = Event.availabilities(@start_date)
    end

    it 'returns a Hash' do
      _(@availabilities).must_be_instance_of(Hash)
    end

    it 'key is a date string with format YYYY-MM-DD' do
      _(@availabilities.keys.first).must_equal('2020-01-01')
    end

    it 'value is an Array' do
      _(@availabilities.values.first).must_be_instance_of(Array)
    end

    it 'returns the next seven days' do
      _(@availabilities.size).must_equal(7)
    end

    it 'full flow' do
      _(@availabilities['2020-01-01']).must_be_empty
      _(@availabilities['2020-01-02']).must_be_empty
      _(@availabilities['2020-01-03']).must_be_empty
      _(@availabilities['2020-01-04']).must_be_empty
      _(@availabilities['2020-01-05']).must_be_empty
      _(@availabilities['2020-01-06']).must_be_empty
      _(@availabilities['2020-01-07']).must_be_empty
    end
  end

  describe 'openings' do
    it 'one opening' do
      Event.create(
        kind: :opening,
        starts_at: DateTime.parse('2020-01-01 11:00'),
        ends_at: DateTime.parse('2020-01-01 11:30')
      )

      availabilities = Event.availabilities(Date.new(2020, 1, 1))

      _(availabilities['2020-01-01']).must_equal(['11:00'])
    end

    it '30 minutes slots' do
      Event.create(
        kind: :opening,
        starts_at: DateTime.parse('2020-01-01 11:00'),
        ends_at: DateTime.parse('2020-01-01 12:00')
      )

      availabilities = Event.availabilities(Date.new(2020, 1, 1))

      _(availabilities['2020-01-01']).must_equal(['11:00', '11:30'])
    end

    it 'several openings on the same day' do
      Event.create(
        kind: :opening,
        starts_at: DateTime.parse('2020-01-01 11:00'),
        ends_at: DateTime.parse('2020-01-01 12:00')
      )

      Event.create(
        kind: :opening,
        starts_at: DateTime.parse('2020-01-01 14:00'),
        ends_at: DateTime.parse('2020-01-01 15:00')
      )

      availabilities = Event.availabilities(Date.new(2020, 1, 1))

      _(availabilities['2020-01-01']).must_equal(['11:00', '11:30', '14:00', '14:30'])
    end

    it 'format' do
      Event.create(
        kind: :opening,
        starts_at: DateTime.parse('2020-01-01 09:00'),
        ends_at: DateTime.parse('2020-01-01 09:30')
      )

      Event.create(
        kind: :opening,
        starts_at: DateTime.parse('2020-01-01 14:00'),
        ends_at: DateTime.parse('2020-01-01 14:30')
      )

      availabilities = Event.availabilities(Date.new(2020, 1, 1))

      _(availabilities['2020-01-01']).must_equal(['9:00', '14:00'])
    end
  end

  describe 'appointments' do
    before do
      Event.create(
        kind: :opening,
        starts_at: DateTime.parse('2020-01-01 09:00'),
        ends_at: DateTime.parse('2020-01-01 10:00')
      )
    end

    it 'an appointment of one slot' do
      Event.create(
        kind: :appointment,
        starts_at: DateTime.parse('2020-01-01 09:00'),
        ends_at: DateTime.parse('2020-01-01 09:30')
      )

      availabilities = Event.availabilities(Date.new(2020, 1, 1))

      _(availabilities['2020-01-01']).must_equal(['9:30'])
    end

    it 'an appointment of several slots' do
      Event.create(
        kind: :appointment,
        starts_at: DateTime.parse('2020-01-01 09:00'),
        ends_at: DateTime.parse('2020-01-01 10:00')
      )

      availabilities = Event.availabilities(Date.new(2020, 1, 1))

      _(availabilities['2020-01-01']).must_be_empty
    end

    it 'several appointment on the same day' do
      Event.create(
        kind: :appointment,
        starts_at: DateTime.parse('2020-01-01 09:00'),
        ends_at: DateTime.parse('2020-01-01 09:30')
      )

      Event.create(
        kind: :appointment,
        starts_at: DateTime.parse('2020-01-01 09:30'),
        ends_at: DateTime.parse('2020-01-01 10:00')
      )

      availabilities = Event.availabilities(Date.new(2020, 1, 1))

      _(availabilities['2020-01-01']).must_be_empty
    end

    it 'appointment at 9:45 overlapping 30 minutes slot' do
      Event.create(
        kind: :appointment,
        starts_at: DateTime.parse('2020-01-01 09:45'),
        ends_at: DateTime.parse('2020-01-01 10:15')
      )

      availabilities = Event.availabilities(Date.new(2020, 1, 1))

     _(availabilities['2020-01-01']).must_equal(['9:00'])
    end
  end

  describe 'weekly recurring openings' do
    it 'weekly recurring are taken into account day 1' do
      Event.create(
        kind: :opening,
        starts_at: DateTime.parse('2020-01-01 09:00'),
        ends_at: DateTime.parse('2020-01-01 09:30'),
        weekly_recurring: true
      )

      availabilities = Event.availabilities(Date.new(2020, 1, 1))

      _(availabilities['2020-01-01']).must_equal(['9:00'])
    end

    it 'weekly recurring are recurring' do
      Event.create(
        kind: :opening,
        starts_at: DateTime.parse('2020-01-01 09:00'),
        ends_at: DateTime.parse('2020-01-01 09:30'),
        weekly_recurring: true
      )

      availabilities = Event.availabilities(Date.new(2020, 1, 8))

      _(availabilities['2020-01-08']).must_equal(['9:00'])
    end

    it 'non weekly recurring are not recurring' do
      Event.create(
        kind: :opening,
        starts_at: DateTime.parse('2020-01-01 09:00'),
        ends_at: DateTime.parse('2020-01-01 09:30'),
        weekly_recurring: false
      )

      availabilities = Event.availabilities(Date.new(2020, 1, 8))

      _(availabilities['2020-01-08']).must_be_empty
    end
  end
end
