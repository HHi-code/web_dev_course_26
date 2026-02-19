if ARGV.size != 4
  puts "Ошибка!  Неверное количество аргументов."
  puts "Необходимо: ruby build_calendar.rb teams.txt дд.мм.гг дд.мм.гг calendar.txt"
  exit 1
end

teams_file = ARGV[0]
start_date = ARGV[1]
end_date = ARGV[2]
output_file = ARGV[3]

require "date"

begin
  start_date = Date.strptime(start_date,'%d-%m-%Y')
  end_date = Date.strptime(end_date,'%d-%m-%Y')
rescue ArgumentError
  puts "Ошибка! Неверный формат даты. Используйте ДД-ММ-ГГ"
  exit 1
end

if start_date > end_date
  puts "Ошибка! Начальная дата не может быть позже конечной."
  exit 1
end

unless File.exist?(teams_file)
  puts "Ошибка! Данного файла не существует!"
  exit 1
end

teams = []
File.foreach(teams_file) do |line|
  line.strip!
  next if line.empty?
  parts = line.split(',',2).map(&:strip)
  if parts.size != 2
    pust "Ошибка! В файле есть строка неверного формата"
    exit 1
  end
  teams << { name : parts[0], city : parts[1]}

  if teams.empty?
    puts "Ошибка! В файле нет команд "
    exit 1
  end

  free_slots = []
  (start_date..end_date).each do |date|
    next unless [5,6,7].include?(date.cwday)
    ['12.00','15.00','18.00'].each do |time|
      free_slots << DateTime.parse("#{date} #{time}")
    end
  end

def generate_calendar(teams,start,end)
  calendar = []
  teams.combination(2).each_with_index do |(t1,t2),i|
    calendar << {datetime: start_date.to_datetime + i , team1: t1[:name], team2: t2[:name]}
  end
  calendar
end
