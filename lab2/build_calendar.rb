require 'date'


if ARGV.size  != 4 
    puts "Ошибка! Неверное кол-во аргументов."
    puts "Необходимо: ruby build_calendar.rb teams.txt дд.мм.гг дд.мм.гг calendar.txt"
    exit 1 
end

teams_file, start_date, end_date, output_file = ARGV

#~~~~~~~~~ Валидация дат
begin 
    start_date = Date.strptime(start_date,"%d.%m.%Y")
    end_date = Date.strptime(end_date, "%d.%m.%Y")
rescue ArgementError
    pust "Ошибка! Неверный формат даты. Испозьзуйте ДД.ММ.ГГГГ"
    exit 1
end

if start_date > end_date 
    puts "Ошибка! Начальная дата не может быть позде конечной."
    exit 1
end

#~~~~~~~~~ Валидация и чтение файла
unless File.exist?(teams_file)
    pust "Ошибка! Заданный файл с командами не найден!"
    exit 1
end

teams =[]
begin
 File.readlines(teams_file,encoding: 'UTF-8').each_with_index do |line,i|
    line = line.chomp.strip
    next if line.empty?

    if line =~ /^\d+\.\s+(.+?)\s+[-\—]\s+(.+)$/ || line =~ /^(.+?)\s+[—\-]\s+(.+)$/
        team_name = $1.strip
        city = $2.strip
        teams << [team_name,city]
    else
        puts "Ошибка! Строка #{i} неверного формата." 
        exit1
    end
end
rescue => e
    puts "Ошибка! Произошло ошибка во время чтения файла: #{e.message}"
    exit 1
end

if teams.size < 2
    puts "Ошибка! Кол-во команд должно быть >= 2"
    exit 1
end

puts "Файл был успешно прочитан! Всего было загружено #{teams.size}"
puts "Диапазон дат:  #{start_date} - #{end_date}"

#~~~~~~~~~ Кол-во игр. Каждая с каждой
count_games = []
teams.each_with_index do |team1,i|
    teams[(i+1)..teams.size-1].each do |team2|
        count_games << [team1,team2]
    end
end
count_games.shuffle!
puts "Всего игр: #{count_games.size}"

#~~~~~~~~~ Кол-во свободных мест для заданной даты
Slot = Struct.new(:date,:time,:games)

slots =[]
current = start_date
while current <= end_date
    if [5,6,0].include?(current.wday)
        ['12:00','15:00','18:00'].each do |time|
            slots << Slot.new(current,time,[])
        end
    end
    current = current.next_day
end
count_free_slots = slots.size * 2
puts "Максимальное кол-во игр, которое можно провести на заданном диапазоне дат = #{count_free_slots}"

if count_games.size > count_free_slots
    puts "Ошибка! Кол-во игр превышает кол-во доступных мест."
    puts "Кол-во игр = #{count_games.size} > Кол-во мест = #{count_free_slots}"
    exit 1
end

#~~~~~~~~~ Распределение игр по слотам
count_games.each do |game|
    team1 , team2 = game
    t = slots.select {|s| s.games.size < 2 && s.games.none? { |g| g.include?(team1) || g.include?(team2) }}
    free = t.min_by {|s| s.games.size}
    free.games << game
end

#~~~~~~~~~ Выходной файл
output_lines =[]
output_lines << "Календарь игр с #{start_date} по #{end_date}"
output_lines << "=" * 50
output_lines << ""

slots_by_date =slots.group_by{|slot| slot.date}.sort_by {|date, _| date}

slots_by_date.each do |date,day_slots|
    next unless day_slots.any? { |slot| slot.games.any? }
    weekday = %w[Воскресенье Понедельник Вторник Среда Четверг Пятница Суббота][date.wday]
    output_lines << "#{weekday} - #{date.strftime('%d.%m.%Y')}"

    day_slots.sort_by! {|s| s.time}
    day_slots.each do |slot|
        next if slot.games.empty?
        output_lines << "  #{slot.time}"
        slot.games.each do |game|
            team1, team2 = game
            line = "   #{team1[0]} (#{team1[1]})  -  #{team2[0]} (#{team2[1]})"
            output_lines << line
        end
    end
    output_lines <<""
end

begin
    File.open(output_file,"w:UTF-8") do |f|
        f.puts output_lines.join("\n")
    end
    puts "Календарь успешно записан в файл '#{output_file}'"
rescue => e
    puts "Ошибка! #{e.message}"
    exit 1
end
