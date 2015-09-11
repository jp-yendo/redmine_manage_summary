class DayInfo
  attr_accessor :date
  attr_accessor :dayname
  attr_accessor :isHoliday

  def self.getDayCollection(startdate, enddate)
    result = []
    convert_wday = [7, 1, 2, 3, 4, 5, 6]
    for targetindex in 0..(enddate - startdate) do
      targetdate = startdate + targetindex
      dayinfo = DayInfo::new
      dayinfo.date = targetdate
      #dayinfo.dayname = day_name(targetdate.wday) #targetdate.wday 曜日 0:日曜日〜6:土曜日)
      dayinfo.dayname = targetdate.strftime("%a")
      #Redmineの休業日をまず取得
      datecalc = Object.new
      datecalc.extend Redmine::Utils::DateCalculation
      dayinfo.isHoliday = datecalc.non_working_week_days.include?(convert_wday[targetdate.wday])
      #日本の祝日と論理和
      dayinfo.isHoliday = dayinfo.isHoliday | targetdate.holiday?(:jp) 
      result[targetindex] = dayinfo
    end
    return result
  end
end