/*
Our program has received a vector of events from an
event tracking software. Each event is modeled as a
tuple containing a datetime stamp and the event
description. Unfortunately, some of the data was
corrupted in transit. Thus, some events are
modeled with a tuple of two "ERR" values.

Your goal is to:
- Filter out the valid events from the vector

- Create a DateTime struct from each valid event by
  parsing the correct data from each datetime string

- Iterate over the events. Print out each event time
  with the year, month, day, hour, minutes, and
  seconds. The time should be printed in UTC time

- For any event after the first, print out the time gap
  between the current event and the previous one

This should be the final output of your program
when it runs:

Event time: 2025-04-19 20:00:00
Event message: Started Rust study session

Event time: 2025-04-20 12:05:30
Event message: Made breakfast
Time since previous event: 16h 5m 30s

Event time: 2025-04-23 02:10:45
Event message: Went to bed
Time since previous event: 62h 5m 15s

Event time: 2025-04-25 13:00:03
Event message: Resumed Rust study
Time since previous event: 58h 49m 18s
*/

use chrono::DateTime;
use chrono_tz::{America::New_York, Tz};

fn main() {
    let event_data = vec![
        (
            "2025**04**19 !! 16:00:00 -04:00",
            "Started Rust study session",
        ),
        ("2025**04**20 !! 08:05:30 -04:00", "Made breakfast"),
        ("ERR", "ERR"),
        ("2025**04**22 !! 22:10:45 -04:00", "Went to bed"),
        ("ERR", "ERR"),
        ("2025**04**25 !! 09:00:03 -04:00", "Resumed Rust study"),
    ];

    let format = "%Y**%m**%d !! %H:%M:%S %z";

    let events = event_data
        .into_iter()
        .filter_map(|(timestamp, message)| {
            let parsed_datetime = DateTime::parse_from_str(timestamp, format);
            match parsed_datetime {
                Ok(datetime) => Some((datetime.with_timezone(&New_York), message)),
                Err(_) => None,
            }
        })
        .collect::<Vec<(DateTime<Tz>, &str)>>();

    let mut previous_event: Option<DateTime<Tz>> = None;

    for (new_york_date_time, message) in events {
        let display_time = new_york_date_time.format("%Y-%m-%d %H:%M:%S");
        println!("Event time: {display_time}");
        println!("Event message: {message}");

        if let Some(previous_datetime) = previous_event {
            let difference = new_york_date_time - previous_datetime;
            let hours = difference.num_hours();
            let minutes = difference.num_minutes() % 60;
            let seconds = difference.num_seconds() % 60;
            println!(
                "Time since previous event: {}h {}m {}s",
                hours, minutes, seconds
            );
        };
        println!();
        previous_event = Some(new_york_date_time);
    }
}
