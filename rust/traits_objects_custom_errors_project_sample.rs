use std::{
    error::Error,
    fmt::{Display, Formatter},
};

// ================================================
trait TextTransformer {
    fn transform(&self, text: &str) -> Result<String, Box<dyn Error>>;
}
// ================================================

// ----------------------------------------------
// FULL CUSTOM ERROR PIZZA EMOJI

#[derive(Debug)]
struct PizzaEmojiError;

#[derive(Debug)]
struct EmptyStringError;

impl Display for PizzaEmojiError {
    fn fmt(&self, formatter: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(formatter, "Why 🍕?")
    }
}

impl Display for EmptyStringError {
    fn fmt(&self, formatter: &mut Formatter<'_>) -> std::fmt::Result {
        write!(formatter, "The string is empty.")
    }
}

impl Error for PizzaEmojiError {}

impl Error for EmptyStringError {}

// ----------------------------------------------

struct WhitespaceTransformer {
    start: bool,
    end: bool,
}

impl TextTransformer for WhitespaceTransformer {
    fn transform(&self, text: &str) -> Result<String, Box<dyn Error>> {
        if text.contains("🍕") {
            return Err(Box::new(PizzaEmojiError));
        }

        let transformed = if self.start && self.end {
            text.trim()
        } else if self.start && !self.end {
            text.trim_start()
        } else if !self.start && self.end {
            text.trim_end()
        } else {
            text
        };

        if transformed.is_empty() {
            return Err(Box::new(EmptyStringError));
        }

        Ok(transformed.to_string())
    }
}

// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
enum Case {
    Uppercase,
    Lowercase,
}

struct CaseTransformer {
    case: Case,
}

impl TextTransformer for CaseTransformer {
    fn transform(&self, text: &str) -> Result<String, Box<dyn Error>> {
        match self.case {
            Case::Uppercase => Ok(text.to_uppercase()),
            Case::Lowercase => Ok(text.to_lowercase()),
        }
    }
}
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

fn apply_transformations(text: String, pipeline: Vec<Box<dyn TextTransformer>>) -> String {
    pipeline.into_iter().fold(text, |accumulator, transformer| {
        match transformer.transform(&accumulator) {
            Ok(new_value) => new_value,
            Err(e) => {
                eprintln!("Something went wrong: {e}");
                accumulator
            }
        }
    })
}

fn main() {
    // Input
    // let text = String::from("  homer simpson  ");
    // Output
    // Content: "HOMER SIMPSON"

    // Input
    // let text = String::from("  data  🍕  ");
    // Output
    // Error Message: Something went wrong: Hey, there's a pizza emoji in the text. So cheesy. Moving on to next transform
    // Content: "  DATA  🍕  "

    // Input
    let text = String::from("    ");
    // Output:
    // Error Message: Something went wrong: The string has nothing left in it. Moving on to next transform
    // Content: "    "

    let pipeline: Vec<Box<dyn TextTransformer>> = vec![
        Box::new(WhitespaceTransformer {
            start: true,
            end: true,
        }),
        Box::new(CaseTransformer {
            case: Case::Uppercase,
        }),
    ];

    let transformed_text = apply_transformations(text, pipeline);
    println!("Output: {transformed_text}");
}
