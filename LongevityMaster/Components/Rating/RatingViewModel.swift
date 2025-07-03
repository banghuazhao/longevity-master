//
// Created by Banghua Zhao on 01/01/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SharingGRDB
import SwiftNavigation

@Observable
@MainActor
class RatingViewModel {
    var scoreBreakdown: LongevityScoreBreakdown?
    var scoreBreakdownItems: [ScoreBreakdownItem]?
    var isLoading = false
    
    @ObservationIgnored
    @Dependency(\.ratingService) private var ratingService
    
    @CasePathable
    enum Route {
        case scoreBreakdownDetail(ScoreDetailViewModel)
        case ratingSystemExplanation
    }
    var route: Route?
    
    func loadRatingData() async {
        isLoading = true
        
        scoreBreakdown = ratingService.calculateLongevityScore()
        scoreBreakdownItems = ratingService.getScoreBreakdown()
        
        isLoading = false
    }
    
    func refreshData() async {
        await loadRatingData()
    }
    
    func onTapScoreBreakdownItem(_ item: ScoreBreakdownItem) {
        let detailViewModel = ScoreDetailViewModel(category: item.category)
        route = .scoreBreakdownDetail(detailViewModel)
    }
    
    func onTapRatingCard() {
        route = .ratingSystemExplanation
    }
    

}
