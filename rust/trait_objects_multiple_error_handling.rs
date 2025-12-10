use std::{fs};
use std::error::Error;

fn read_num_from_file(path: &str) -> Result<i32, Box<dyn Error>> {
    let file_contents= fs::read_to_string(path)?;
    
    match file_contents.parse::<i32>() {
        Ok(num) => return Ok(num),
        Err(e) => return Err(Box::new(e))
    };
}

fn main() {
    let content = read_num_from_file("./num.txt");

    match content {
        Ok(num) => println!("{num}"),
        Err(e) => {
            println!("{:#?}", e)
        }
    }
}
