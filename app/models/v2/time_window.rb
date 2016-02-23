class V2::TimeWindow
  include ActiveModel::Model

  attr_accessor :date, :start_time, :end_time, :slot_length

  # def initialize(date: Date.today, start_time: '09:00', end_time: '09:15', slot_length: '15 mins')
  #   @date       = date
  #   @start_time = start_time
  #   @end_time   = end_time
  #   @slot_length = slot_length
  #   @slots      = []
  # end

  def slots
    slot_start = start_time
    slot_end   = slot_start + slot_length

    while slot_end <= end_time
      @slots << ::V2::TimeSlot.new(start_time: slot_start, end_time: slot_end)

      slot_start = slot_end
      slot_end   += slot_length
    end

    @slots
  end

  def date
    Date.strptime(@date, '%m/%d/%Y')
  end

  def start_time
    Time.zone.parse("#{date} #{@start_time}")
  end

  def end_time
    Time.zone.parse("#{date} #{@end_time}")
  end

  def slot_length
    @slot_length.delete(' mins').to_i.minutes
  end

end
