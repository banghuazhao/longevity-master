//
// Created by Banghua Zhao on 23/09/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

/// The guided programs. Each one is built from gallery habits, so a program never adds a
/// habit the gallery does not also offer.
///
/// Every finding is stated as the source reports it — an association where the study is
/// observational — and each source is a real paper the reader can look up.
enum ProgramsDataStore {
    typealias Habits = HabitsDataStore

    static let strengthFoundations = Program(
        id: "strength-foundations",
        title: String(localized: "Strength Foundations"),
        subtitle: String(localized: "Build muscle that lasts"),
        icon: "💪",
        color: 0xC084F599,
        durationDays: 28,
        summary: String(localized: "Four weeks to build a simple, lasting strength habit with moves you can do at home. Muscle protects your joints, bones and blood sugar as you age — and it is never too late to build it."),
        weeklyFocus: [
            String(localized: "Learn the moves. Do 2 sets of each with good form, stopping a few reps short of failure."),
            String(localized: "Add a third set. Rest 60–90 seconds between sets."),
            String(localized: "Make it harder: lower slowly over 3 seconds, or add weight."),
            String(localized: "Test yourself: count your best set of push-ups and squats and compare with week 1."),
        ],
        habits: [Habits.squats, Habits.pushUps, Habits.pullUpsOrRows, Habits.plank, Habits.proteinEveryMeal],
        sources: [
            EvidenceSource(
                citation: "Momma H, et al. Br J Sports Med. 2022",
                title: "Muscle-strengthening activities are associated with lower risk and mortality in major non-communicable diseases: a systematic review and meta-analysis of cohort studies",
                finding: String(localized: "30–60 minutes a week of muscle-strengthening activity was associated with a 10–20% lower risk of death from all causes.")
            ),
            EvidenceSource(
                citation: "Yang J, et al. JAMA Netw Open. 2019",
                title: "Association Between Push-up Exercise Capacity and Future Cardiovascular Disease Events Among Active Adult Men",
                finding: String(localized: "Men who could do more than 40 push-ups had 96% fewer cardiovascular events over 10 years than those who managed fewer than 10.")
            ),
        ]
    )

    static let cardioBase = Program(
        id: "cardio-base",
        title: String(localized: "Cardio Base"),
        subtitle: String(localized: "Raise your fitness, add years"),
        icon: "🫀",
        color: 0x1AB3C199,
        durationDays: 28,
        summary: String(localized: "Cardiorespiratory fitness is one of the strongest predictors of how long you live. This plan combines easy Zone 2 sessions, daily steps and one hard interval workout a week."),
        weeklyFocus: [
            String(localized: "Keep Zone 2 truly easy — you should be able to hold a conversation."),
            String(localized: "Stretch your Zone 2 sessions to 40–45 minutes."),
            String(localized: "Make the intervals count: the last minute of each 4-minute effort should feel hard."),
            String(localized: "Keep it going. Fitness gained in four weeks is kept by doing a little less, not by stopping."),
        ],
        habits: [Habits.zone2Cardio, Habits.walk8000Steps, Habits.hiitIntervals],
        sources: [
            EvidenceSource(
                citation: "Mandsager K, et al. JAMA Netw Open. 2018",
                title: "Association of Cardiorespiratory Fitness With Long-term Mortality Among Adults Undergoing Exercise Treadmill Testing",
                finding: String(localized: "Low cardiorespiratory fitness carried a higher mortality risk than smoking or diabetes, and the benefit of higher fitness showed no upper limit.")
            ),
            EvidenceSource(
                citation: "Paluch AE, et al. Lancet Public Health. 2022",
                title: "Daily steps and all-cause mortality: a meta-analysis of 15 international cohorts",
                finding: String(localized: "More daily steps meant lower mortality, levelling off at about 6,000–8,000 steps for adults over 60 and 8,000–10,000 for younger adults.")
            ),
        ]
    )

    static let antioxidantPlate = Program(
        id: "antioxidant-plate",
        title: String(localized: "Antioxidant Plate"),
        subtitle: String(localized: "Eat more color every day"),
        icon: "🌈",
        color: 0xFFD6A599,
        durationDays: 21,
        summary: String(localized: "Antioxidants from whole foods — not pills — are what is linked to healthier aging. For three weeks, add color, polyphenols and healthy fats to every day."),
        weeklyFocus: [
            String(localized: "Start with breakfast: berries in yogurt or oats, and green tea instead of a second coffee."),
            String(localized: "Make half your plate vegetables at lunch and dinner, with something cruciferous most days."),
            String(localized: "Cook with olive oil and aim for five different colors on your plates each day."),
        ],
        habits: [Habits.eatTheRainbow, Habits.eatBerries, Habits.drinkGreenTea, Habits.eatCruciferous, Habits.useOliveOil],
        sources: [
            EvidenceSource(
                citation: "Aune D, et al. Int J Epidemiol. 2017",
                title: "Fruit and vegetable intake and the risk of cardiovascular disease, total cancer and all-cause mortality-a systematic review and dose-response meta-analysis of prospective studies",
                finding: String(localized: "Eating up to 800 g of fruit and vegetables a day was associated with a 31% lower risk of premature death.")
            ),
            EvidenceSource(
                citation: "Bondonno NP, et al. Nat Commun. 2019",
                title: "Flavonoid intake is associated with lower mortality in the Danish Diet Cancer and Health Cohort",
                finding: String(localized: "A moderate intake of flavonoids — about 500 mg a day, from tea, berries, apples and dark chocolate — was associated with lower mortality.")
            ),
            EvidenceSource(
                citation: "Guasch-Ferré M, et al. J Am Coll Cardiol. 2022",
                title: "Consumption of Olive Oil and Risk of Total and Cause-Specific Mortality Among U.S. Adults",
                finding: String(localized: "More than half a tablespoon of olive oil a day was associated with 19% lower all-cause mortality.")
            ),
            EvidenceSource(
                citation: "Bjelakovic G, et al. Cochrane Database Syst Rev. 2012",
                title: "Antioxidant supplements for prevention of mortality in healthy participants and patients with various diseases",
                finding: String(localized: "High-dose antioxidant supplements such as beta-carotene and vitamin E did not lower mortality and may raise it. Get your antioxidants from food.")
            ),
        ]
    )

    static let sleepReset = Program(
        id: "sleep-reset",
        title: String(localized: "Sleep Reset"),
        subtitle: String(localized: "Anchor your body clock"),
        icon: "🌙",
        color: 0xAED6F1CC,
        durationDays: 21,
        summary: String(localized: "Regular, sufficient sleep repairs the brain and body every night. Three weeks of anchoring your body clock can change how you sleep for good."),
        weeklyFocus: [
            String(localized: "Fix your wake-up time, weekends included, and get outside within an hour of waking."),
            String(localized: "Stop caffeine after 2 PM and put screens away an hour before bed."),
            String(localized: "Go to bed when you feel sleepy. With a fixed wake time, bedtime settles on its own."),
        ],
        habits: [Habits.sameWakeTime, Habits.morningSunlight, Habits.noLateCaffeine, Habits.noScreensBeforeBed, Habits.sleep],
        sources: [
            EvidenceSource(
                citation: "Windred DP, et al. Sleep. 2024",
                title: "Sleep regularity is a stronger predictor of mortality risk than sleep duration: A prospective cohort study",
                finding: String(localized: "How regular people's sleep was predicted their mortality risk more strongly than how long they slept.")
            ),
            EvidenceSource(
                citation: "Cappuccio FP, et al. Sleep. 2010",
                title: "Sleep duration and all-cause mortality: a systematic review and meta-analysis of prospective studies",
                finding: String(localized: "Regularly sleeping less than 6 hours a night was associated with a 12% higher risk of death.")
            ),
        ]
    )

    static let mediterraneanMonth = Program(
        id: "mediterranean-month",
        title: String(localized: "Mediterranean Month"),
        subtitle: String(localized: "The best-studied way to eat"),
        icon: "🫒",
        color: 0xD4E09B99,
        durationDays: 28,
        summary: String(localized: "In a large randomized trial, a Mediterranean diet cut heart attacks, strokes and cardiovascular deaths by about 30%. It is less a diet than a way of cooking: olive oil, legumes, fish, nuts and whole grains."),
        weeklyFocus: [
            String(localized: "Replace butter and other cooking fats with extra virgin olive oil."),
            String(localized: "Add beans or lentils to at least four meals this week."),
            String(localized: "Eat fish twice, and a handful of nuts most days."),
            String(localized: "Swap refined grains for whole grains, and keep the rest going."),
        ],
        habits: [Habits.useOliveOil, Habits.eatLegumes, Habits.eatSalmon, Habits.eatNuts, Habits.eatWholeGrains],
        sources: [
            EvidenceSource(
                citation: "Estruch R, et al. N Engl J Med. 2018",
                title: "Primary Prevention of Cardiovascular Disease with a Mediterranean Diet Supplemented with Extra-Virgin Olive Oil or Nuts",
                finding: String(localized: "A Mediterranean diet with extra olive oil or nuts reduced heart attacks, strokes and cardiovascular deaths by about 30%.")
            ),
            EvidenceSource(
                citation: "Aune D, et al. BMC Med. 2016",
                title: "Nut consumption and risk of cardiovascular disease, total cancer, all-cause and cause-specific mortality: a systematic review and dose-response meta-analysis of prospective studies",
                finding: String(localized: "A handful of nuts a day (about 28 g) was associated with a 22% lower risk of death from all causes.")
            ),
        ]
    )

    static let moveMoreSitLess = Program(
        id: "move-more-sit-less",
        title: String(localized: "Move More, Sit Less"),
        subtitle: String(localized: "Made for desk days"),
        icon: "🚶",
        color: 0xBFD8B899,
        durationDays: 21,
        summary: String(localized: "Long hours of sitting are linked to higher mortality, but the fix does not need a gym. Small, frequent bursts of movement through the day add up."),
        weeklyFocus: [
            String(localized: "Set a timer: stand or walk for 2–3 minutes every hour."),
            String(localized: "Walk for 10 minutes after your biggest meal."),
            String(localized: "Add vigorous bursts — take the stairs fast and walk uphill briskly."),
        ],
        habits: [Habits.standUpHourly, Habits.walkAfterMeals, Habits.takeTheStairs, Habits.vigorousBursts],
        sources: [
            EvidenceSource(
                citation: "Ekelund U, et al. Lancet. 2016",
                title: "Does physical activity attenuate, or even eliminate, the detrimental association of sitting time with mortality? A harmonised meta-analysis of data from more than 1 million men and women",
                finding: String(localized: "About 60–75 minutes of moderate activity a day appeared to eliminate the higher mortality linked to long sitting.")
            ),
            EvidenceSource(
                citation: "Stamatakis E, et al. Nat Med. 2022",
                title: "Association of wearable device-measured vigorous intermittent lifestyle physical activity with mortality",
                finding: String(localized: "Three 1–2 minute bursts of vigorous activity a day were associated with up to 40% lower all-cause mortality.")
            ),
            EvidenceSource(
                citation: "Buffey AJ, et al. Sports Med. 2022",
                title: "The Acute Effects of Interrupting Prolonged Sitting Time in Adults with Standing and Light-Intensity Walking on Biomarkers of Cardiometabolic Health in Adults: A Systematic Review and Meta-analysis",
                finding: String(localized: "Short light walks that break up sitting lowered blood sugar after meals.")
            ),
        ]
    )

    static let steadyAndStrong = Program(
        id: "steady-and-strong",
        title: String(localized: "Steady & Strong"),
        subtitle: String(localized: "Balance and strength for healthy aging"),
        icon: "🦩",
        color: 0xFFB3AB99,
        durationDays: 28,
        summary: String(localized: "Falls are a leading cause of injury as we get older, and many are preventable. This plan trains balance and leg strength — the two things that keep you on your feet."),
        weeklyFocus: [
            String(localized: "Hold on to a counter while you practise standing on one leg."),
            String(localized: "Try balancing without holding on, and do chair stands slowly."),
            String(localized: "Close your eyes for a few seconds while balancing, next to something you can grab."),
            String(localized: "Time your one-leg stand and count your chair stands, and compare with week 1."),
        ],
        habits: [Habits.standOnOneLeg, Habits.chairStands, Habits.taiChi, Habits.briskWalking],
        sources: [
            EvidenceSource(
                citation: "Sherrington C, et al. Cochrane Database Syst Rev. 2019",
                title: "Exercise for preventing falls in older people living in the community",
                finding: String(localized: "Exercise programs that train balance and everyday movement reduced the rate of falls by about 24%.")
            ),
            EvidenceSource(
                citation: "Araujo CG, et al. Br J Sports Med. 2022",
                title: "Successful 10-second one-legged stance performance predicts survival in middle-aged and older individuals",
                finding: String(localized: "Middle-aged and older adults who could not stand on one leg for 10 seconds had an 84% higher risk of death over the next 7 years.")
            ),
        ]
    )

    static let calmMind = Program(
        id: "calm-mind",
        title: String(localized: "Calm Mind"),
        subtitle: String(localized: "Less stress, more connection"),
        icon: "🧘",
        color: 0x4DD0AE99,
        durationDays: 21,
        summary: String(localized: "Chronic stress and loneliness wear the body down as surely as a poor diet. Three weeks of small daily practices to calm the mind and strengthen your relationships."),
        weeklyFocus: [
            String(localized: "Start each morning with 5 minutes of meditation or slow breathing."),
            String(localized: "Each evening, write down three things you are grateful for."),
            String(localized: "Get out into nature, and call someone you care about."),
        ],
        habits: [Habits.meditate, Habits.deepBreathing, Habits.practiceGratitude, Habits.timeInNature, Habits.callSomeone],
        sources: [
            EvidenceSource(
                citation: "Goyal M, et al. JAMA Intern Med. 2014",
                title: "Meditation programs for psychological stress and well-being: a systematic review and meta-analysis",
                finding: String(localized: "Mindfulness meditation programs brought moderate improvements in anxiety, depression and pain.")
            ),
            EvidenceSource(
                citation: "Holt-Lunstad J, et al. PLoS Med. 2010",
                title: "Social relationships and mortality risk: a meta-analytic review",
                finding: String(localized: "People with stronger social relationships had a 50% greater likelihood of survival.")
            ),
            EvidenceSource(
                citation: "White MP, et al. Sci Rep. 2019",
                title: "Spending at least 120 minutes a week in nature is associated with good health and wellbeing",
                finding: String(localized: "People who spent at least 120 minutes a week in nature were more likely to report good health and wellbeing.")
            ),
        ]
    )

    static let all: [Program] = [
        strengthFoundations,
        cardioBase,
        antioxidantPlate,
        sleepReset,
        mediterraneanMonth,
        moveMoreSitLess,
        steadyAndStrong,
        calmMind,
    ]

    private static let byID = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    static func program(id: String) -> Program? {
        byID[id]
    }
}
