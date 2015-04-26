TOKEN = 'dcH264'
ID_LENGTH = 2
BS = 512

stream_start = nil
camera_id = nil

def to_perc(cur, total)
    ((cur.to_f / total) * 100).round
end

File.open(ARGV[0], 'rb') do |file|
    total = File.size(ARGV[0])
    puts "Processing #{ARGV[0]}, #{total} bytes..."

    next_pos = 0
    while next_pos < total
        block = file.read(BS)
        index = block.index(TOKEN)
        next_pos = file.pos

        if index != nil
            stream_end = next_pos - BS + index - ID_LENGTH

            if stream_start != nil && stream_end > stream_start
                file.seek(stream_start)
                stream = file.read([0, stream_end - stream_start - 4].max)

                File.open("cam#{camera_id}.dav", 'ab') do |out_file|
                    out_file.write(stream)
                end
            end

            file.seek(stream_end)
            camera_id = file.read(ID_LENGTH)

            stream_start = stream_end + ID_LENGTH + TOKEN.length
        end

        file.seek(next_pos - TOKEN.length)

        prev_complete = to_perc(next_pos - BS, total)
        complete = to_perc(next_pos, total)
        if complete != prev_complete
            print "\r#{complete}% complete, processing #{camera_id}"
        end
    end

    puts "\nDone"
end
