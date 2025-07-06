//
//  AppItemStore.swift
//  MoreApps
//
//  Created by Lulin Yang on 2025/6/27.
//

#if canImport(UIKit)
import UIKit

public struct AppItemStore {
    public static let allItems = [
        AppItem(
            title: String(localized: "TripMark", bundle: .module),
            detail: String(localized: "Vacation, Itinerary Planner", bundle: .module),
            icon: UIImage(named: "appIcon_tripmark", in: .module, with: nil),
            url: URL(string: "http://itunes.apple.com/app/id6464474080")),
        AppItem(
            title: String(localized: "SwiftSum", bundle: .module),
            detail: String(localized: "Math Solver & Calculator App", bundle: .module),
            icon: UIImage(named: "appIcon_swiftsum", in: .module, with: nil),
            url: URL(string: "http://itunes.apple.com/app/id1610829871")),
        AppItem(
            title: String(localized: "Shows", bundle: .module),
            detail: String(localized: "Movie,TV Show Tracker", bundle: .module),
            icon: UIImage(named: "appIcon_shows", in: .module, with: nil),
            url: URL(string: "http://itunes.apple.com/app/id1624910011")),
        AppItem(
            title: String(localized: "Falling Block Puzzle", bundle: .module),
            detail: String(localized: "Retro", bundle: .module),
            icon: UIImage(named: "appIcon_falling_block_puzzle", in: .module, with: nil),
            url: URL(string: "https://apps.apple.com/app/id1609440799")),
        AppItem(
            title: String(localized: "Money Tracker", bundle: .module),
            detail: String(localized: "Budget, Expense & Bill Planner", bundle: .module),
            icon: UIImage(named: "appIcon_money_tracker", in: .module, with: nil),
            url: URL(string: "http://itunes.apple.com/app/id\(AppConstants.AppID.moneyTrackerAppID)")),
        AppItem(
            title: String(localized: "CalmCanvas", bundle: .module),
            detail: String(localized: "Meditation,Relaxing", bundle: .module),
            icon: UIImage(named: "appIcon_relaxing_up", in: .module, with: nil),
            url: URL(string: "http://itunes.apple.com/app/id1618712178")),
        AppItem(
            title: String(localized: "We Play Piano", bundle: .module),
            detail: String(localized: "Piano Keyboard", bundle: .module),
            icon: UIImage(named: "appIcon_we_play_piano", in: .module, with: nil),
            url: URL(string: "http://itunes.apple.com/app/id1625018611")),
        AppItem(
            title: String(localized: "ClassicReads", bundle: .module),
            detail: String(localized: "Novels & Fiction", bundle: .module),
            icon: UIImage(named: "appIcon_novels_Hub", in: .module, with: nil),
            url: URL(string: "http://itunes.apple.com/app/id\(AppConstants.AppID.novelsHubAppID)")),
        AppItem(
            title: String(localized: "World Weather Live", bundle: .module),
            detail: String(localized: "All Cities", bundle: .module),
            icon: UIImage(named: "appIcon_world_weather_live", in: .module, with: nil),
            url: URL(string: "http://itunes.apple.com/app/id1612773646")),
        AppItem(
            title: String(localized: "Minesweeper Z", bundle: .module),
            detail: String(localized: "Minesweeper App", bundle: .module),
            icon: UIImage(named: "appIcon_minesweeper", in: .module, with: nil),
            url: URL(string: "http://itunes.apple.com/app/id1621899572")),
        AppItem(
            title: String(localized: "Sudoku Lover", bundle: .module),
            detail: String(localized: "sudoku puzzles", bundle: .module),
            icon: UIImage(named: "appIcon_sudoku_lover", in: .module, with: nil),
            url: URL(string: "http://itunes.apple.com/app/id1620749798")),
        AppItem(
            title: String(localized: "BMI Diary", bundle: .module),
            detail: String(localized: "Fitness, Weight Loss &Health", bundle: .module),
            icon: UIImage(named: "appIcon_bmiDiary", in: .module, with: nil),
            url: URL(string: "http://itunes.apple.com/app/id\(AppConstants.AppID.BMIDiaryAppID)")),
        AppItem(
            title: String(localized: "More Apps", bundle: .module),
            detail: String(localized: "Check out more Apps made by us", bundle: .module),
            icon: UIImage(named: "appIcon_appStore", in: .module, with: nil),
            url: URL(string: "https://apps.apple.com/us/developer/%E7%92%90%E7%92%98-%E6%9D%A8/id1599035519")),
    ]
}
#endif 