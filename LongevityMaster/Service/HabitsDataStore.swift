//
// Created by Banghua Zhao on 03/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

/// The habit gallery: the ready-made habits offered in onboarding, the habit form's gallery and
/// the programs.
///
/// Habits a program uses are named constants so the program and the gallery hand out the very
/// same draft. Starting a program matches the user's existing habits by `name`, so a habit
/// copied from the gallery earlier is reused rather than added a second time.
struct HabitsDataStore {

    // MARK: - 🥗 Diet

    static let eatSalmon = Habit.Draft(name: String(localized: "Eat salmon"), category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "3", antiAgingRating: 5, icon: "🐟", color: 0xB6E66B99, note: String(localized: "Consume a 4–6 oz portion of salmon for omega-3 fatty acids."))
    static let eatKale = Habit.Draft(name: String(localized: "Eat kale"), category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "4", antiAgingRating: 4, icon: "🥬", color: 0xD9D9D999, note: String(localized: "Include kale in meals for antioxidants and vitamins."))
    static let eatBerries = Habit.Draft(name: String(localized: "Eat berries"), category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "5", antiAgingRating: 5, icon: "🍓", color: 0xA084E899, note: String(localized: "Eat a handful of blueberries or strawberries for antioxidants."))
    static let drinkGreenTea = Habit.Draft(name: String(localized: "Drink green tea"), category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 3, icon: "🍵", color: 0xE0FFFF99, note: String(localized: "Drink 1–2 cups of green tea for polyphenols and hydration."))
    static let stayHydrated = Habit.Draft(name: String(localized: "Stay hydrated"), category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 5, icon: "💧", color: 0xAED6F1CC, note: String(localized: "Drink at least 8 cups of water per day to stay hydrated."))
    static let eatNuts = Habit.Draft(name: String(localized: "Eat nuts"), category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "4", antiAgingRating: 4, icon: "🥜", color: 0xEDBB99CC, note: String(localized: "Eat a small handful of nuts for healthy fats and protein."))

    // Antioxidant-rich foods
    static let eatTheRainbow = Habit.Draft(name: String(localized: "Eat the rainbow"), category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 5, icon: "🌈", color: 0xFFD6A599, note: String(localized: "Fill half your plate with vegetables and fruit of different colors. Each color brings different antioxidants — carotenoids, anthocyanins, flavonoids."))
    static let eatCruciferous = Habit.Draft(name: String(localized: "Eat cruciferous vegetables"), category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "4", antiAgingRating: 4, icon: "🥦", color: 0xB6E66B99, note: String(localized: "Broccoli, cabbage, cauliflower and Brussels sprouts contain sulforaphane, which switches on the body's own antioxidant defenses."))
    static let useOliveOil = Habit.Draft(name: String(localized: "Use extra virgin olive oil"), category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 5, icon: "🫒", color: 0xD4E09B99, note: String(localized: "Cook and dress salads with extra virgin olive oil. Its polyphenols are antioxidant and anti-inflammatory; about half a tablespoon a day is linked to lower mortality."))
    static let eatTomatoes = Habit.Draft(name: String(localized: "Eat cooked tomatoes"), category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "3", antiAgingRating: 3, icon: "🍅", color: 0xFFB3AB99, note: String(localized: "Cooked tomatoes are rich in lycopene, an antioxidant carotenoid that is better absorbed with a little olive oil."))
    static let eatCitrus = Habit.Draft(name: String(localized: "Eat citrus fruit"), category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "4", antiAgingRating: 3, icon: "🍊", color: 0xFFD18C99, note: String(localized: "An orange, grapefruit or kiwi supplies vitamin C and flavonoids, two of the body's key dietary antioxidants."))
    static let eatDarkChocolate = Habit.Draft(name: String(localized: "Eat a square of dark chocolate"), category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "3", antiAgingRating: 2, icon: "🍫", color: 0xD7B49E99, note: String(localized: "Choose 70% cocoa or higher for flavanols. Keep it to a small square — the benefit disappears in a whole bar."))
    static let cookWithHerbs = Habit.Draft(name: String(localized: "Cook with herbs and spices"), category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "5", antiAgingRating: 3, icon: "🌿", color: 0xBFD8B899, note: String(localized: "Turmeric, ginger, cinnamon, oregano and rosemary are among the most concentrated sources of polyphenol antioxidants."))
    static let eatLeafyGreens = Habit.Draft(name: String(localized: "Eat dark leafy greens"), category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "5", antiAgingRating: 4, icon: "🥗", color: 0xC5E1A599, note: String(localized: "Spinach, arugula and chard provide folate, lutein and nitrates that support the brain, eyes and blood vessels."))

    // Longevity staples
    static let eatLegumes = Habit.Draft(name: String(localized: "Eat beans or lentils"), category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "4", antiAgingRating: 5, icon: "🫘", color: 0xEDBB99CC, note: String(localized: "Beans, lentils and chickpeas are a daily staple in every Blue Zone — rich in fiber, plant protein and polyphenols."))
    static let eatWholeGrains = Habit.Draft(name: String(localized: "Choose whole grains"), category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "5", antiAgingRating: 4, icon: "🌾", color: 0xF9E79F99, note: String(localized: "Swap white rice, bread and pasta for whole-grain versions. Higher fiber intake is linked to lower mortality and heart disease."))
    static let eatFermented = Habit.Draft(name: String(localized: "Eat fermented foods"), category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "4", antiAgingRating: 3, icon: "🫙", color: 0xE8DAEF99, note: String(localized: "Yogurt, kefir, kimchi or sauerkraut. Fermented foods increase gut microbiome diversity and lower inflammation markers."))
    static let proteinEveryMeal = Habit.Draft(name: String(localized: "Protein at every meal"), category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 4, icon: "🍳", color: 0xFFE4E199, note: String(localized: "Aim for roughly 1.2–1.6 g of protein per kg of body weight a day, spread across meals, to keep muscle as you age."))
    static let skipSugaryDrinks = Habit.Draft(name: String(localized: "Skip sugary drinks"), category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 4, icon: "🥤", color: 0xAED6F1CC, note: String(localized: "Replace soda and juice with water, tea or coffee. Sugary drinks are linked to diabetes, heart disease and faster aging."))
    static let avoidUltraProcessed = Habit.Draft(name: String(localized: "Avoid ultra-processed food"), category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "5", antiAgingRating: 4, icon: "🍟", color: 0xFAD7A099, note: String(localized: "Cook from whole ingredients. Diets high in ultra-processed food are linked to higher mortality."))
    static let alcoholFreeDay = Habit.Draft(name: String(localized: "Alcohol-free day"), category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "5", antiAgingRating: 4, icon: "🍷", color: 0xE6D2D599, note: String(localized: "Alcohol raises the risk of cancer and heart disease at any amount. The fewer drinks, the better."))
    static let stopAt80Percent = Habit.Draft(name: String(localized: "Stop eating at 80% full"), category: .diet, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 3, icon: "🥢", color: 0xFFF5E199, note: String(localized: "The Okinawan habit of hara hachi bu: stop eating when you feel about 80% full."))

    // MARK: - 🏃‍♂️ Exercise

    static let swimming = Habit.Draft(name: String(localized: "Swimming"), category: .exercise, frequency: .fixedDaysInWeek, frequencyDetail: "1,3,5", antiAgingRating: 5, icon: "🏊‍♂️", color: 0x1AB3C199, note: String(localized: "Improves cardiovascular health and reduces stress."))
    static let strengthTraining = Habit.Draft(name: String(localized: "Strength training"), category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "3", antiAgingRating: 5, icon: "🏋️", color: 0xC084F599, note: String(localized: "Build muscle and improve bone density."))
    static let briskWalking = Habit.Draft(name: String(localized: "Brisk walking"), category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "5", antiAgingRating: 5, icon: "🚶", color: 0xBFD8B899, note: String(localized: "Walk 30 minutes at moderate pace."))
    static let yogaOrStretching = Habit.Draft(name: String(localized: "Yoga or stretching"), category: .exercise, frequency: .nDaysEachMonth, frequencyDetail: "10", antiAgingRating: 4, icon: "🧘", color: 0xFFF5E199, note: String(localized: "Improve flexibility and reduce stress."))
    static let takeTheStairs = Habit.Draft(name: String(localized: "Take the stairs"), category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "5", antiAgingRating: 3, icon: "🪜", color: 0xB6E66B99, note: String(localized: "Boost daily movement and heart health."))
    static let morningStretch = Habit.Draft(name: String(localized: "Do a morning stretch routine"), category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 3, icon: "🤸", color: 0xE0FFFF99, note: String(localized: "Start your day with light stretching to increase circulation and flexibility."))

    // Resistance and strength training
    static let squats = Habit.Draft(name: String(localized: "Squats"), category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "3", antiAgingRating: 4, icon: "🦵", color: 0xC084F599, note: String(localized: "3 sets of 10–15 bodyweight or goblet squats. Strong legs keep you independent as you age."))
    static let pushUps = Habit.Draft(name: String(localized: "Push-ups"), category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "3", antiAgingRating: 4, icon: "💪", color: 0xFBC5A999, note: String(localized: "3 sets, as many as you can with good form. Push-up capacity is linked to lower cardiovascular risk."))
    static let lunges = Habit.Draft(name: String(localized: "Lunges"), category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "2", antiAgingRating: 3, icon: "🧎", color: 0xBFD8B899, note: String(localized: "3 sets of 10 per leg. Builds single-leg strength and balance."))
    static let deadlifts = Habit.Draft(name: String(localized: "Deadlifts"), category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "2", antiAgingRating: 4, icon: "🏋️‍♀️", color: 0xA084E899, note: String(localized: "Hinge at the hips to lift a barbell, kettlebell or dumbbells. Trains the back, glutes and hamstrings — the muscles that protect your spine."))
    static let pullUpsOrRows = Habit.Draft(name: String(localized: "Pull-ups or rows"), category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "2", antiAgingRating: 4, icon: "🧗", color: 0xAED6F1CC, note: String(localized: "Use a bar, rings or a resistance band. Pulling balances all the pushing and sitting we do and supports posture."))
    static let plank = Habit.Draft(name: String(localized: "Plank"), category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "5", antiAgingRating: 3, icon: "🪵", color: 0xEDBB99CC, note: String(localized: "Hold 30–60 seconds, 3 times. A strong core protects the lower back."))
    static let gluteBridges = Habit.Draft(name: String(localized: "Glute bridges"), category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "3", antiAgingRating: 3, icon: "🌉", color: 0xFFD18C99, note: String(localized: "3 sets of 15. Strengthens the hips and eases lower-back pain from sitting."))
    static let wallSit = Habit.Draft(name: String(localized: "Wall sit"), category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "3", antiAgingRating: 3, icon: "🧱", color: 0xE6D2D599, note: String(localized: "Hold for 30–60 seconds, 3 times. Isometric exercise like this lowers resting blood pressure."))
    static let calfRaises = Habit.Draft(name: String(localized: "Calf raises"), category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "3", antiAgingRating: 2, icon: "🦶", color: 0xD9D9D999, note: String(localized: "3 sets of 20. Strong calves support balance and circulation."))
    static let resistanceBand = Habit.Draft(name: String(localized: "Resistance band workout"), category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "3", antiAgingRating: 4, icon: "➰", color: 0x4DD0AE99, note: String(localized: "20 minutes with bands: rows, presses, squats and pull-aparts. Strength training you can do anywhere."))
    static let kettlebellSwings = Habit.Draft(name: String(localized: "Kettlebell swings"), category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "2", antiAgingRating: 4, icon: "🔔", color: 0xFFB3AB99, note: String(localized: "3–5 sets of 15 swings. Builds hip power and gets your heart rate up at the same time."))
    static let farmersCarry = Habit.Draft(name: String(localized: "Farmer's carry"), category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "2", antiAgingRating: 4, icon: "🧳", color: 0xF9E79F99, note: String(localized: "Walk 30–40 m holding heavy weights at your sides. Grip strength is one of the strongest predictors of healthy aging."))
    static let deadHang = Habit.Draft(name: String(localized: "Dead hang"), category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "3", antiAgingRating: 3, icon: "🐒", color: 0xC5E1A599, note: String(localized: "Hang from a bar for 30–60 seconds. Builds grip strength and decompresses the shoulders and spine."))
    static let chairStands = Habit.Draft(name: String(localized: "Chair stands"), category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "5", antiAgingRating: 4, icon: "🪑", color: 0xFFE4E199, note: String(localized: "Stand up from a chair and sit back down 10 times without using your hands. Keeps getting up easy at any age."))

    // Cardio
    static let zone2Cardio = Habit.Draft(name: String(localized: "Zone 2 cardio"), category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "3", antiAgingRating: 5, icon: "🚴", color: 0x1AB3C199, note: String(localized: "30–60 minutes at a pace where you can still talk: cycling, jogging or rowing. Builds the aerobic base behind healthy aging."))
    static let hiitIntervals = Habit.Draft(name: String(localized: "HIIT intervals"), category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "1", antiAgingRating: 5, icon: "❤️‍🔥", color: 0xFF6B6B99, note: String(localized: "4 × 4 minutes hard with 3 minutes easy in between. Raises VO2 max, one of the strongest predictors of longevity."))
    static let running = Habit.Draft(name: String(localized: "Running"), category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "3", antiAgingRating: 5, icon: "🏃", color: 0xFBC5A999, note: String(localized: "Even 5–10 minutes a day of running is linked to a lower risk of death from all causes."))
    static let walk8000Steps = Habit.Draft(name: String(localized: "Walk 8,000 steps"), category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 5, icon: "👟", color: 0xBFD8B899, note: String(localized: "Mortality risk keeps falling up to about 8,000–10,000 steps a day."))
    static let hiking = Habit.Draft(name: String(localized: "Go hiking"), category: .exercise, frequency: .nDaysEachMonth, frequencyDetail: "2", antiAgingRating: 4, icon: "🥾", color: 0xC5E1A599, note: String(localized: "Walking on hills and trails builds leg strength and endurance — and gets you into nature."))
    static let dancing = Habit.Draft(name: String(localized: "Dancing"), category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "2", antiAgingRating: 3, icon: "💃", color: 0xA084E899, note: String(localized: "Dance to a few songs. Combines cardio, balance and memory."))
    static let racketSport = Habit.Draft(name: String(localized: "Play a racket sport"), category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "2", antiAgingRating: 4, icon: "🎾", color: 0xF9E79F99, note: String(localized: "Tennis, badminton or pickleball. Social sports are linked to the longest life expectancy of any activity studied."))
    static let vigorousBursts = Habit.Draft(name: String(localized: "Vigorous bursts"), category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 4, icon: "⚡", color: 0xFFD18C99, note: String(localized: "Three 1-minute bursts of vigorous activity in daily life — climb stairs fast, walk uphill briskly, carry heavy shopping."))
    static let jumpRope = Habit.Draft(name: String(localized: "Jump rope"), category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "3", antiAgingRating: 3, icon: "🪢", color: 0x4DD0AE99, note: String(localized: "5–10 minutes of skipping. Cardio that also loads your bones."))

    // Balance and mobility
    static let standOnOneLeg = Habit.Draft(name: String(localized: "Stand on one leg"), category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 4, icon: "🦩", color: 0xFFB3AB99, note: String(localized: "Balance on each leg for 30 seconds, e.g. while brushing your teeth. Being unable to stand 10 seconds on one leg is linked to higher mortality in midlife."))
    static let taiChi = Habit.Draft(name: String(localized: "Tai chi"), category: .exercise, frequency: .nDaysEachWeek, frequencyDetail: "3", antiAgingRating: 4, icon: "☯️", color: 0xD9D9D999, note: String(localized: "Slow, flowing movements that improve balance, cut fall risk and calm the mind."))
    static let standUpHourly = Habit.Draft(name: String(localized: "Stand up every hour"), category: .exercise, frequency: .fixedDaysInWeek, frequencyDetail: "2,3,4,5,6", antiAgingRating: 4, icon: "⏰", color: 0xFFF5E199, note: String(localized: "Break up long sitting with 2–3 minutes of standing or walking each hour. Long sitting is linked to higher mortality."))

    // MARK: - 💤 Sleep

    static let sleep = Habit.Draft(name: String(localized: "Sleep 7–9 hours"), category: .sleep, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 5, icon: "😴", color: 0xFFD18C99, note: String(localized: "Maintain a consistent schedule with enough rest."))
    static let bedtimeRoutine = Habit.Draft(name: String(localized: "Follow bedtime routine"), category: .sleep, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 4, icon: "🌙", color: 0xBFD8B899, note: String(localized: "Relax before bed to improve sleep quality."))
    static let shortNap = Habit.Draft(name: String(localized: "Take a short nap"), category: .sleep, frequency: .fixedDaysInWeek, frequencyDetail: "1,2,3,4,5", antiAgingRating: 3, icon: "🛌", color: 0xD9D9D999, note: String(localized: "Nap 20–30 minutes to boost alertness."))
    static let noLateCaffeine = Habit.Draft(name: String(localized: "Avoid caffeine after 2 PM"), category: .sleep, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 3, icon: "🍵", color: 0xFFF5E199, note: String(localized: "Prevent sleep disruption by avoiding stimulants late in the day."))
    static let sameWakeTime = Habit.Draft(name: String(localized: "Wake up at the same time"), category: .sleep, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 5, icon: "🕰️", color: 0xAED6F1CC, note: String(localized: "Keep the same wake time every day, weekends included. Sleep regularity predicts mortality better than sleep length."))
    static let morningSunlight = Habit.Draft(name: String(localized: "Get morning sunlight"), category: .sleep, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 4, icon: "🌅", color: 0xFFD18C99, note: String(localized: "Spend 10 minutes outside within an hour of waking. Morning light sets your body clock and improves sleep at night."))
    static let noScreensBeforeBed = Habit.Draft(name: String(localized: "No screens before bed"), category: .sleep, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 4, icon: "📴", color: 0xE8DAEF99, note: String(localized: "Put phones and screens away an hour before bed to help you fall asleep sooner."))
    static let coolDarkBedroom = Habit.Draft(name: String(localized: "Keep the bedroom cool and dark"), category: .sleep, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 3, icon: "🌡️", color: 0xCCDDEE99, note: String(localized: "About 18 °C (65 °F), dark and quiet. Cooler rooms help you fall into deep sleep."))
    static let earlyDinner = Habit.Draft(name: String(localized: "Finish eating 3 hours before bed"), category: .sleep, frequency: .nDaysEachWeek, frequencyDetail: "5", antiAgingRating: 3, icon: "🍽️", color: 0xFFE4E199, note: String(localized: "A late, heavy meal disrupts sleep and blood sugar overnight."))

    // MARK: - 🧠 Mental Health

    static let meditate = Habit.Draft(name: String(localized: "Meditate"), category: .mentalHealth, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 5, icon: "🧘‍♀️", color: 0x4DD0AE99, note: String(localized: "Practice mindfulness for calm and clarity."))
    static let practiceGratitude = Habit.Draft(name: String(localized: "Practice gratitude"), category: .mentalHealth, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 4, icon: "📝", color: 0xA084E899, note: String(localized: "Write 3 things you're grateful for daily."))
    static let connectSocially = Habit.Draft(name: String(localized: "Connect socially"), category: .mentalHealth, frequency: .nDaysEachMonth, frequencyDetail: "5", antiAgingRating: 4, icon: "🧑‍🤝‍🧑", color: 0xF9E79F99, note: String(localized: "Engage in meaningful conversation with loved ones."))
    static let digitalDetox = Habit.Draft(name: String(localized: "Digital detox"), category: .mentalHealth, frequency: .nDaysEachWeek, frequencyDetail: "2", antiAgingRating: 3, icon: "📵", color: 0xE6D2D599, note: String(localized: "Take screen breaks to reduce eye strain and stress."))
    static let deepBreathing = Habit.Draft(name: String(localized: "Deep breathing"), category: .mentalHealth, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 3, icon: "🌬️", color: 0xCCDDEE99, note: String(localized: "5 minutes of slow breathing — in for 4, hold for 4, out for 6. Calms the nervous system and lowers blood pressure."))
    static let readABook = Habit.Draft(name: String(localized: "Read a book"), category: .mentalHealth, frequency: .nDaysEachWeek, frequencyDetail: "5", antiAgingRating: 3, icon: "📚", color: 0xF9E79F99, note: String(localized: "30 minutes of reading a day. Book readers lived about two years longer in a 12-year study."))
    static let learnSomethingNew = Habit.Draft(name: String(localized: "Learn something new"), category: .mentalHealth, frequency: .nDaysEachWeek, frequencyDetail: "3", antiAgingRating: 3, icon: "🧩", color: 0xA084E899, note: String(localized: "A language, an instrument, a new skill. Challenging your brain builds cognitive reserve."))
    static let timeInNature = Habit.Draft(name: String(localized: "Spend time in nature"), category: .mentalHealth, frequency: .nDaysEachWeek, frequencyDetail: "2", antiAgingRating: 4, icon: "🌳", color: 0xBFD8B899, note: String(localized: "Aim for 2 hours a week in parks, woods or by water — the threshold linked to better health and wellbeing."))
    static let journal = Habit.Draft(name: String(localized: "Journal"), category: .mentalHealth, frequency: .nDaysEachWeek, frequencyDetail: "3", antiAgingRating: 3, icon: "✍️", color: 0xFFF5E199, note: String(localized: "Write for 10 minutes about your day or what's on your mind. Helps process stress."))
    static let callSomeone = Habit.Draft(name: String(localized: "Call a friend or family member"), category: .mentalHealth, frequency: .nDaysEachWeek, frequencyDetail: "3", antiAgingRating: 4, icon: "📞", color: 0xFFB3AB99, note: String(localized: "Strong relationships are linked to a 50% higher chance of survival — as strong an effect as quitting smoking."))
    static let helpSomeone = Habit.Draft(name: String(localized: "Help someone"), category: .mentalHealth, frequency: .nDaysEachMonth, frequencyDetail: "4", antiAgingRating: 3, icon: "🤝", color: 0x4DD0AE99, note: String(localized: "Volunteer, lend a hand or do a kind act. A sense of purpose is linked to lower mortality."))

    // MARK: - 🛡️ Preventive Health

    static let sunExposure = Habit.Draft(name: String(localized: "Get sun exposure"), category: .preventiveHealth, frequency: .fixedDaysInMonth, frequencyDetail: "1,7,14,21,28", antiAgingRating: 3, icon: "☀️", color: 0xCCDDEE99, note: String(localized: "10–15 minutes of sunlight for vitamin D."))
    static let brushAndFloss = Habit.Draft(name: String(localized: "Brush & floss teeth"), category: .preventiveHealth, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 2, icon: "🦷", color: 0xD9D9D999, note: String(localized: "Prevent gum disease and inflammation."))
    static let walkAfterMeals = Habit.Draft(name: String(localized: "Take a walk after meals"), category: .preventiveHealth, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 4, icon: "🚶‍♂️", color: 0xFFE4E199, note: String(localized: "Walk for 10–15 minutes after meals to support digestion and blood sugar control."))
    static let postureCheck = Habit.Draft(name: String(localized: "Posture check"), category: .preventiveHealth, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 3, icon: "🧍", color: 0xFFF5E199, note: String(localized: "Maintain good posture to reduce back and neck strain."))
    static let wearSunscreen = Habit.Draft(name: String(localized: "Wear sunscreen"), category: .preventiveHealth, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 4, icon: "🧴", color: 0xFFE4E199, note: String(localized: "SPF 30+ on face and hands every morning. In a randomized trial, daily sunscreen slowed visible skin aging."))
    static let sauna = Habit.Draft(name: String(localized: "Sauna session"), category: .preventiveHealth, frequency: .nDaysEachWeek, frequencyDetail: "2", antiAgingRating: 4, icon: "🧖", color: 0xFFD18C99, note: String(localized: "15–20 minutes at around 80 °C. Frequent sauna use is linked to lower cardiovascular and all-cause mortality."))
    static let checkBloodPressure = Habit.Draft(name: String(localized: "Check blood pressure"), category: .preventiveHealth, frequency: .nDaysEachMonth, frequencyDetail: "4", antiAgingRating: 4, icon: "🩺", color: 0xFF6B6B99, note: String(localized: "Measure at home at the same time of day. High blood pressure is the leading preventable risk for heart disease and stroke."))
    static let staySmokeFree = Habit.Draft(name: String(localized: "Stay smoke-free"), category: .preventiveHealth, frequency: .nDaysEachWeek, frequencyDetail: "7", antiAgingRating: 5, icon: "🚭", color: 0xD9D9D999, note: String(localized: "Not smoking is the single biggest thing you can do for a longer life. Quitting at any age helps."))
    static let eyeBreaks = Habit.Draft(name: String(localized: "20-20-20 eye breaks"), category: .preventiveHealth, frequency: .fixedDaysInWeek, frequencyDetail: "2,3,4,5,6", antiAgingRating: 2, icon: "👀", color: 0xE0FFFF99, note: String(localized: "Every 20 minutes of screen time, look at something 20 feet (6 m) away for 20 seconds."))
    static let coldShower = Habit.Draft(name: String(localized: "Cold shower"), category: .preventiveHealth, frequency: .nDaysEachWeek, frequencyDetail: "3", antiAgingRating: 2, icon: "🚿", color: 0xAED6F1CC, note: String(localized: "Finish with 30–60 seconds of cold water. May boost alertness and mood; long-term evidence is still limited."))

    // MARK: - Gallery

    /// Every gallery habit, grouped by category and, within a category, by kind. Names are
    /// unique: the gallery uses them as identity.
    static let all: [Habit.Draft] = [
        // 🥗 Diet
        eatSalmon, eatKale, eatBerries, drinkGreenTea, stayHydrated, eatNuts,
        eatTheRainbow, eatCruciferous, useOliveOil, eatTomatoes, eatCitrus, eatDarkChocolate,
        cookWithHerbs, eatLeafyGreens,
        eatLegumes, eatWholeGrains, eatFermented, proteinEveryMeal, skipSugaryDrinks,
        avoidUltraProcessed, alcoholFreeDay, stopAt80Percent,

        // 🏃‍♂️ Exercise
        swimming, strengthTraining, briskWalking, yogaOrStretching, takeTheStairs, morningStretch,
        squats, pushUps, lunges, deadlifts, pullUpsOrRows, plank, gluteBridges, wallSit,
        calfRaises, resistanceBand, kettlebellSwings, farmersCarry, deadHang, chairStands,
        zone2Cardio, hiitIntervals, running, walk8000Steps, hiking, dancing, racketSport,
        vigorousBursts, jumpRope,
        standOnOneLeg, taiChi, standUpHourly,

        // 💤 Sleep
        sleep, bedtimeRoutine, shortNap, noLateCaffeine, sameWakeTime, morningSunlight,
        noScreensBeforeBed, coolDarkBedroom, earlyDinner,

        // 🧠 Mental Health
        meditate, practiceGratitude, connectSocially, digitalDetox, deepBreathing, readABook,
        learnSomethingNew, timeInNature, journal, callSomeone, helpSomeone,

        // 🛡️ Preventive Health
        sunExposure, brushAndFloss, walkAfterMeals, postureCheck, wearSunscreen, sauna,
        checkBloodPressure, staySmokeFree, eyeBreaks, coldShower,
    ]

    /// What a fresh DEBUG database starts with. A handful per category rather than the whole
    /// gallery, which would bury the Today tab under 80-odd habits.
    static let debugSeed: [Habit.Draft] = [
        eatSalmon, eatKale, eatBerries, drinkGreenTea, stayHydrated, eatNuts,
        swimming, strengthTraining, briskWalking, yogaOrStretching, takeTheStairs, morningStretch,
        sleep, bedtimeRoutine, shortNap, noLateCaffeine,
        meditate, practiceGratitude, connectSocially, digitalDetox,
        sunExposure, brushAndFloss, walkAfterMeals, postureCheck,
    ]

    static func habits(forCategory category: HabitCategory) -> [Habit.Draft] {
        all.filter { $0.category == category }
    }
}
