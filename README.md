# Workout
Do you go jogging and record your workout with your Apple Watch or record any workout in any other way? Do you want to have access to recorded data to organise it as you please?
With Workout you can export all your workouts saved inside the Health app to a CSV file and import them to your favorite spreadsheet app and view any detail:
- General data such as distance, duration, heart rate, calories (active and total), average pace and speed
- Minute by minute details for supported workouts:
  - Running & Walking: pace, heart rate, step count
  - Swimming: speed, heart rate, stroke count
- Heart zones for running workouts

[![Download on the AppStore](https://marcoboschi.altervista.org/img/app_store_en.svg)](https://itunes.apple.com/us/app/workout-csv-exporter/id1140433100?ls=1&mt=8)

## Project Setup
This project relies on CocoaPods not included the repository, after cloning run

```bash
pod install
```

in a terminal in the project directory to download linked frameworks and use `Workout.xcworkspace` to open the project.

The frameworks `MBLibrary` and `MBHealth` referenced by this project are available [here](https://github.com/piscoTech/MBLibrary), version currently in use is [1.5.1](https://github.com/piscoTech/MBLibrary/releases/tag/v1.5.1(16)).

## Customization
General behaviour of the app can be configured at compile time as specified in the [wiki](https://github.com/piscoTech/Workout/wiki#compile-time-setup).
