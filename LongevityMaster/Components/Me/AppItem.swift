//
//  AppItem.swift
//  LongevityMaster
//
//  Created by Lulin Yang on 2025/6/27.
//

import UIKit

struct AppItem: Identifiable {
    var id: String {
        title
    }

    var title: String
    var detail: String
    let icon: UIImage?
    let url: URL?
    init(title: String, detail: String, icon: UIImage?, url: URL?) {
        self.title = title
        self.detail = detail
        self.icon = icon
        self.url = url
    }
}

extension Constants {

    struct AppID {
        static let tripMarkID = "6464474080"
        static let financeGoAppID = "1519476344"
        static let finanicalRatiosGoMacOSAppID = "1486184864"
        static let financialRatiosGoAppID = "1481582303"
        static let countdownDaysAppID = "1525084657"
        static let moneyTrackerAppID = "1534244892"
        static let BMIDiaryAppID = "1521281509"
        static let novelsHubAppID = "1528820845"
        static let nasaLoverID = "1595232677"
        static let mechanicalEngineeringToolkitID = "1601099443"
        static let longevityMasterID = "6747810020"
    }
}

struct AppItemStore {
    static let allItems = [
        AppItem(
            title: String(localized: "TripMark"),
            detail: String(localized: "Vacation, Itinerary Planner"),
            icon: UIImage(named: "appIcon_tripmark"),
            url: URL(string: "http://itunes.apple.com/app/id6464474080")),
        AppItem(
            title: String(localized: "SwiftSum"),
            detail: String(localized: "Math Solver & Calculator App"),
            icon: UIImage(named: "appIcon_swiftsum"),
            url: URL(string: "http://itunes.apple.com/app/id1610829871")),
        AppItem(
            title: String(localized: "Shows"),
            detail:String(localized:  "Movie,TV Show Tracker"),
            icon: UIImage(named: "appIcon_shows"),
            url: URL(string: "http://itunes.apple.com/app/id1624910011")),
        AppItem(
            title: String(localized: "Falling Block Puzzle"),
            detail: String(localized: "Retro"),
            icon: UIImage(named: "appIcon_falling_block_puzzle"),
            url: URL(string: "https://apps.apple.com/app/id1609440799")),
        AppItem(
            title: String(localized: "Money Tracker"),
            detail: String(localized: "Budget, Expense & Bill Planner"),
            icon: UIImage(named: "appIcon_money_tracker"),
            url: URL(string: "http://itunes.apple.com/app/id\(Constants.AppID.moneyTrackerAppID)")),
        AppItem(
            title: String(localized: "CalmCanvas"),
            detail: String(localized: "Meditation,Relaxing"),
            icon: UIImage(named: "appIcon_relaxing_up"),
            url: URL(string: "http://itunes.apple.com/app/id1618712178")),
        AppItem(
            title: String(localized: "We Play Piano"),
            detail: String(localized: "Piano Keyboard"),
            icon: UIImage(named: "appIcon_we_play_piano"),
            url: URL(string: "http://itunes.apple.com/app/id1625018611")),
        AppItem(
            title: String(localized: "ClassicReads"),
            detail: String(localized: "Novels & Fiction"),
            icon: UIImage(named: "appIcon_novels_Hub"),
            url: URL(string: "http://itunes.apple.com/app/id\(Constants.AppID.novelsHubAppID)")),
        AppItem(
            title: String(localized: "World Weather Live"),
            detail: String(localized: "All Cities"),
            icon: UIImage(named: "appIcon_world_weather_live"),
            url: URL(string: "http://itunes.apple.com/app/id1612773646")),
        AppItem(
            title: String(localized: "Minesweeper Z"),
            detail: String(localized: "Minesweeper App"),
            icon: UIImage(named: "appIcon_minesweeper"),
            url: URL(string: "http://itunes.apple.com/app/id1621899572")),
        AppItem(
            title: String(localized: "Sudoku Lover"),
            detail: String(localized: "sudoku puzzles"),
            icon: UIImage(named: "appIcon_sudoku_lover"),
            url: URL(string: "http://itunes.apple.com/app/id1620749798")),
        AppItem(
            title: String(localized: "BMI Diary"),
            detail: String(localized: "Fitness, Weight Loss &Health"),
            icon: UIImage(named: "appIcon_bmiDiary"),
            url: URL(string: "http://itunes.apple.com/app/id\(Constants.AppID.BMIDiaryAppID)")),
        AppItem(
            title: String(localized: "More Apps"),
            detail: String(localized: "Check out more Apps made by us"),
            icon: UIImage(named: "appIcon_appStore"),
            url: URL(string: "https://apps.apple.com/us/developer/%E7%92%90%E7%92%98-%E6%9D%A8/id1599035519")),
    ]
}
