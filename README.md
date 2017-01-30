# Workout
Do you go jogging and record your workout with your Apple Watch? Do you want to have access to recorded data to organise it as you please?

With Workout you can export all your jogging workout to a CSV file and import them to your favorite spreadsheet app and view any detail:
- General data such as distance, duration, average pace and heart rate
- Minute by minute pace, heart rate and step count

[![Download on the AppStore](http://www.marcoboschi.altervista.org/img/app_store_en.svg)](https://itunes.apple.com/us/app/workout-csv-exporter/id1140433100?ls=1&mt=8)

## Project Setup
This project relies on CocoaPods not included the repository, after cloning run

    pod install
    
in a terminal in the project directory to download linked frameworks and use `Workout.xcworkspace` to open the project.

The framework `MBLibrary` referenced by this project is available [here](https://github.com/piscoTech/MBLibrary), version currently in use is [1.0.2](https://github.com/piscoTech/MBLibrary/releases/tag/v1.0.2(3)).

## Customization
General behaviour of the app can be configured via global variables in `Main.swift`:

* `authRequired`: When the user authorizes (or denies) Health data access the value of this variable is saved in `UserDefaults`, upon launch the app check the stored values and if it's less than the declared value the authorization form will be displayed. New versions of the app that requires access to new data should increase this value to automatically display the authorization form.
* `adsEnable`: Display ads override, set this variable to `false` to always hide ads. If this is set to `true` ads will be displayed and hidden accordingly to In-App purchase.
* `adsID`: AdMob ads key.
* `stepSourceFilter`: Since both iPhone and Apple Watch track steps during workout only those step data point whose source cointains this value will be considered.
