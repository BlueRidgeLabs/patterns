class V2::TimeWindow
  include ActiveModel::Model

  attr_accessor :date, :start_time, :end_time, :slot_length

  def slots
    slot_start = start_datetime
    slot_end   = slot_start + converted_slot_length

    while slot_end <= end_time
      @slots << ::V2::TimeSlot.new(start_time: slot_start, end_time: slot_end)

      slot_start = slot_end
      slot_end   += converted_slot_length
    end

    @slots
  end

  private

    def formatted_date
      Date.strptime(date, '%m/%d/%Y')
    end

    def start_datetime
      Time.zone.parse("#{formatted_date} #{start_time}")
    end

    def converted_slot_length
      @slot_length.delete(' mins').to_i.minutes
    end

end
