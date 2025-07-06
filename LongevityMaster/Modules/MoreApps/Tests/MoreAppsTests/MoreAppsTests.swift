//
//  MoreAppsTests.swift
//  MoreAppsTests
//
//  Created by Lulin Yang on 2025/6/27.
//

import XCTest
@testable import MoreApps

final class MoreAppsTests: XCTestCase {
    
    func testAppItemStoreHasItems() throws {
        XCTAssertFalse(AppItemStore.allItems.isEmpty, "AppItemStore should contain app items")
    }
    
    func testAppItemStructure() throws {
        let firstItem = AppItemStore.allItems.first
        XCTAssertNotNil(firstItem, "Should have at least one app item")
        
        if let item = firstItem {
            XCTAssertFalse(item.title.isEmpty, "App title should not be empty")
            XCTAssertFalse(item.detail.isEmpty, "App detail should not be empty")
        }
    }
    
    func testMoreAppsViewInitialization() throws {
        let view = MoreAppsView()
        XCTAssertNotNil(view, "MoreAppsView should initialize successfully")
    }
} 