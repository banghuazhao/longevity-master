//
//  AppItem.swift
//  MoreApps
//
//  Created by Lulin Yang on 2025/6/27.
//

#if canImport(UIKit)
import UIKit

public struct AppItem: Identifiable {
    public var id: String {
        title
    }

    public let title: String
    public let detail: String
    public let icon: UIImage?
    public let url: URL?
    
    public init(title: String, detail: String, icon: UIImage?, url: URL?) {
        self.title = title
        self.detail = detail
        self.icon = icon
        self.url = url
    }
}

public struct AppConstants {
    public struct AppID {
        public static let tripMarkID = "6464474080"
        public static let countdownDaysAppID = "1525084657"
        public static let moneyTrackerAppID = "1534244892"
        public static let BMIDiaryAppID = "1521281509"
        public static let novelsHubAppID = "1528820845"
        public static let nasaLoverID = "1595232677"
        public static let mechanicalEngineeringToolkitID = "1601099443"
        public static let longevityMasterID = "6747810020"
    }
}
#endif 
