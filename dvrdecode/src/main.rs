use std::env;
use std::io::BufReader;
use std::io::Read;
use std::fs::File;

const NAL_START: [u8; 6] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x01];

fn main() {
    match env::args().nth(1) {
        Some(x) => process_file(x),
        None => print_usage()
    };
}

fn print_usage() {
    println!("No input file specified");
    println!("Usage: dvrdecode <input_file>")
}

fn process_file(file_name: String) {
    println!("Processing {}", file_name);

    let file = match File::open(file_name) {
        Ok(file) => file,
        Err(e) => panic!("Failed to open input file: {}", e)
    };

    let bytes = BufReader::new(&file).bytes();
    let mut nal_overlap: usize = 0;
    let mut pos: usize = 0;

    for byte in bytes {
        if nal_overlap == NAL_START.len() {
            println!("Found NAL at 0x{:x}!", pos);
            nal_overlap = 0;
        }

        match byte {
            Ok(val) => {
                if val == NAL_START[nal_overlap] {
                    nal_overlap = nal_overlap + 1;
                } else {
                    nal_overlap = 0;
                }
            },
            Err(e) => {
                panic!("Failed to read from file: {}", e);
            }
        }

        pos += 1;
    }
}
