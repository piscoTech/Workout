# Workout
Do you go jogging and record your workout with your Apple Watch or record any workout in any other way? Do you want to have access to recorded data to organise it as you please?
With Workout you can export all your workouts saved inside the Health app to a CSV file and import them to your favorite spreadsheet app and view any detail:
- General data such as distance, duration, heart rate, average pace and speed
- Minute by minute details for supported workouts:
  - Running: pace, heart rate, step count
  - Swimming: speed, heart rate, stroke count


[![Download on the AppStore](http://www.marcoboschi.altervista.org/img/app_store_en.svg)](https://itunes.apple.com/us/app/workout-csv-exporter/id1140433100?ls=1&mt=8)

## Project Setup
This project relies on CocoaPods not included the repository, after cloning run

    pod install

in a terminal in the project directory to download linked frameworks and use `Workout.xcworkspace` to open the project.

The framework `MBLibrary` referenced by this project is available [here](https://github.com/piscoTech/MBLibrary), version currently in use is [1.2.1](https://github.com/piscoTech/MBLibrary/releases/tag/v1.2.1(8)).

## Customization
General behaviour of the app can be configured via global variables in `Main.swift`:

* `authRequired` and `healthReadData`: Used to save the latest authorization requested in `UserDefaults`, when the former is greater than the saved value the user will be promped for authorization upon next launch, refer to the [wiki](https://github.com/piscoTech/Workout/wiki) for additional details.
* `adsEnable`: Display ads override, set this variable to `false` to always hide ads. If this is set to `true` ads will be displayed and hidden accordingly to In-App purchase.
* `adsID`: AdMob ads key.
