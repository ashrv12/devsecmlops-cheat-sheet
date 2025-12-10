trait Wearable {
    fn wear(&self) -> String;
}

#[derive(Debug)]
struct Tie {
    color: String
}

impl Wearable for Tie {
    fn wear(&self) -> String {
        format!("{} tie.", self.color)
    }
}

#[derive(Debug)]
struct Pants {
    color: String,
    size: u16
}

impl Wearable for Pants {
    fn wear(&self) -> String {
        format!("{}, {} size pants.", self.color, self.size)
    }
}

fn main() {
    let new_pants = Pants {
        color: String::from("Black"),
        size: 23
    };

    let tie = Tie {
        color: String::from("Yellow")
    };

    let outfit: Vec<Box<dyn Wearable>> = vec![Box::new(new_pants), Box::new(tie)];

    // for item in outfit {
    //     println!("{}", item.wear())
    // }

    let items: Vec<String> = outfit.iter().map(|item| item.wear()).collect();

    println!("{items:#?}");
}
