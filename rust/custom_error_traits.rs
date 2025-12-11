use std::error::Error;
use std::fmt::Display;
use std::fs;

// Create the custom Error type struct
#[derive(Debug)]
struct NumberIsUnimpressiveError;

// Create custom Error trait
impl Display for NumberIsUnimpressiveError {
    fn fmt(&self, formatter: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(formatter, "Number doesn't reach threshold.")
    }
}

// Implement the error trait for the newly created custom error
impl Error for NumberIsUnimpressiveError {}

fn read_num_from_file(path: &str) -> Result<i32, Box<dyn Error>> {
    let file_contents = fs::read_to_string(path)?;

    let number = match file_contents.parse::<i32>() {
        Ok(num) => num,
        Err(e) => return Err(Box::new(e)),
    };

    if number < 100 {
        Err(Box::new(NumberIsUnimpressiveError))
    } else {
        Ok(number)
    }
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
