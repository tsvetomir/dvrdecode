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
                header = file.read(30).unpack('n*')
                file.seek(-30, IO::SEEK_CUR)

                #seq = '%05d' % header[0]

                file_name = "cam#{camera_id}.dav"
                if (header[13] == 1 && header[14] == 0x6742) # SPS
                    if !File.exist? file_name
                        File.open(file_name, 'wb')
                    end
                    file.seek(24, IO::SEEK_CUR)
                else
                    file.seek(16, IO::SEEK_CUR)
                end

                if File.exist? file_name
                    stream = file.read(stream_end - file.pos)
                    File.open("cam#{camera_id}.dav", 'ab') do |out_file|
                        out_file.write(stream)
                    end
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
