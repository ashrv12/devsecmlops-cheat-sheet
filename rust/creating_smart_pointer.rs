use std::ops::{Deref, DerefMut};

struct CustomBox<T, U> {
    data: T,
    more_data: U
}

impl<T, U> CustomBox<T, U> {
   fn new(data: T, more_data: U) -> Self {
        Self { data, more_data }
   } 
}

impl<T, U> Deref for CustomBox<T, U> {
    type Target = T;

    fn deref(&self) -> &Self::Target {
        &self.data
    }
}

impl<T, U> DerefMut for CustomBox<T, U> {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.data
    }
}

impl<T, U> Drop for CustomBox<T, U> {
    fn drop(&mut self) {
        println!("I'm cleaning up related files.");
        println!("I'm terminating a network connection.");
        println!("I'm removing the CustomBox struct from Memory.");
    }
}

fn main() {
    let boxy = Box::new(3.14);
    println!("{}", *boxy);

    let custom_boxy = CustomBox::new(3.55, "hello");
    println!("{}", *custom_boxy);

    let mut boxee = Box::new(45);
    *boxee = 46;
    println!("{}", *boxee);

    let mut custom_boxee = CustomBox::new(7.89, "yo");
    *custom_boxee = 8.97;
    println!("{}", *custom_boxee);
}